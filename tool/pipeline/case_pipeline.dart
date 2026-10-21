import 'dart:convert';
import 'dart:io';

import 'package:json_schema/json_schema.dart';
import 'package:judge_the_case/models.dart';

import 'claude_client.dart';
import 'leak_judge.dart';
import 'rechtspraak.dart';

/// The prompt, schema and example read from `tool/pipeline/assets/`.
class PipelineAssets {
  PipelineAssets({required this.promptMarkdown, required this.schemaJson, required this.exampleJson}) {
    systemTemplate = _block(promptMarkdown, 'System prompt');
    userTemplate = _block(promptMarkdown, 'User message');
    final decoded = jsonDecode(schemaJson) as Map<String, dynamic>;
    schema = JsonSchema.create(decoded);
    outputSchema = structuredSchema(decoded) as Map<String, dynamic>;
  }

  static PipelineAssets load(String dir) => PipelineAssets(
        promptMarkdown: File('$dir/prompt-rechtspraak-to-case.md').readAsStringSync(),
        schemaJson: File('$dir/case.schema.json').readAsStringSync(),
        exampleJson: File('$dir/example-case.json').readAsStringSync(),
      );

  final String promptMarkdown;
  final String schemaJson;
  final String exampleJson;
  late final String systemTemplate;
  late final String userTemplate;
  late final JsonSchema schema;

  /// The schema sent to the API as the output format.
  late final Map<String, dynamic> outputSchema;

  static String _block(String md, String heading) {
    final m = RegExp('## ${RegExp.escape(heading)}\\s*```text\\n([\\s\\S]*?)\\n```').firstMatch(md);
    if (m == null) throw StateError('Block "$heading" not found in the prompt');
    return m.group(1)!;
  }

  String systemPrompt() => systemTemplate.replaceAll('{{CASE_SCHEMA}}', schemaJson.trim());

  String userMessage(String ecli, String xml) =>
      userTemplate.replaceAll('{{ECLI}}', ecli).replaceAll('{{RULING_XML}}', xml);

  static const _unsupported = {
    r'$schema', r'$id', 'title', 'pattern', 'minimum', 'maximum', 'minLength', 'maxLength', //
    'minItems', 'maxItems', 'uniqueItems',
  };

  /// Removes the keywords structured outputs do not accept; the full schema is still checked locally.
  /// Keys under `properties` and `$defs` are field names, so they are always kept.
  static Object? structuredSchema(Object? node) {
    if (node is List) return node.map(structuredSchema).toList();
    if (node is! Map) return node;
    final out = <String, dynamic>{};
    for (final e in node.entries) {
      final key = e.key as String;
      if (_unsupported.contains(key)) continue;
      out[key] = key == 'properties' || key == r'$defs'
          ? {for (final p in (e.value as Map).entries) p.key as String: structuredSchema(p.value)}
          : structuredSchema(e.value);
    }
    final type = out['type'];
    if (type is List) {
      out.remove('type');
      return {
        'anyOf': [for (final t in type) t == 'null' ? {'type': 'null'} : {...out, 'type': t}],
      };
    }
    return out;
  }
}

/// One automatic check on the converted case.
class Check {
  Check(this.label, this.ok, [this.detail]);

  final String label;
  final bool ok;
  final String? detail;
}

enum ExtractionOutcome { ready, needsReview, rejected, failed }

/// What the full analysis of one ruling produced.
class ExtractionResult {
  ExtractionResult({
    required this.ecli,
    required this.responses,
    this.caseJson,
    this.checks = const [],
    this.error,
    this.extraCostUsd = 0,
  });

  final String ecli;
  final List<ClaudeResponse> responses;

  /// The converted case, with the fields set by the code; null if unusable.
  final Map<String, dynamic>? caseJson;
  final List<Check> checks;
  final String? error;

  /// Calls outside the analysis itself, such as the leak judge.
  final double extraCostUsd;

  double get costUsd => responses.fold(extraCostUsd, (sum, r) => sum + r.costUsd);
  String get model => responses.isEmpty ? '' : responses.last.model;

  Map<String, dynamic> get _case => caseJson!['case'] as Map<String, dynamic>;

  ExtractionOutcome get outcome {
    if (caseJson == null) return ExtractionOutcome.failed;
    if (_case['status'] == 'rejected') return ExtractionOutcome.rejected;
    return checks.every((c) => c.ok) ? ExtractionOutcome.ready : ExtractionOutcome.needsReview;
  }

  CaseCategory? get category => caseJson == null ? null : CaseCategory.fromValue(_case['category'] as String?);

  String get failedChecks => checks.where((c) => !c.ok).map((c) => '${c.label} (${c.detail ?? ''})').join('; ');

  /// The `cases/{ECLI}` document: the app model plus the admin `pipeline` block.
  Map<String, dynamic> caseDocument() {
    final c = Map<String, dynamic>.from(_case);
    final date = c['decisionDate'];
    if (date is String && date.length == 10) c['decisionDate'] = '${date}T00:00:00Z';
    final pipeline = Map<String, dynamic>.from(caseJson!['pipeline'] as Map);
    for (final key in ['extractedAt', 'sourceModifiedAt']) {
      final v = pipeline[key];
      if (v is String) pipeline[key] = DateTime.parse(v).toUtc();
    }
    return {...CourtCase.fromFirestore(ecli, c).toMap(), 'pipeline': pipeline};
  }

  /// The `verdicts/{ECLI}` document.
  Map<String, dynamic> verdictDocument() =>
      CaseVerdict.fromFirestore(ecli, Map<String, dynamic>.from(caseJson!['verdict'] as Map)).toMap();
}

/// Converts one ruling with Claude: XML, JSON, validation with one correction round, code fields, checks.
class CasePipeline {
  CasePipeline({
    required this.assets,
    required this.rechtspraak,
    required this.claude,
    this.model = ClaudeModel.sonnet,
    this.effort = 'high',
    this.leakJudge,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final PipelineAssets assets;
  final RechtspraakClient rechtspraak;
  final ClaudeClient claude;
  final ClaudeModel model;
  final String effort;

  /// Asked when the word search flags the texts shown before the verdict.
  final LeakJudge? leakJudge;
  final DateTime Function() _now;

  static const leakCheckLabel = 'The case texts do not reveal the outcome';

  Future<ExtractionResult> run(String ecli, {String? xml}) async {
    xml ??= await rechtspraak.fetchRulingXml(ecli);
    final messages = <Map<String, dynamic>>[
      {'role': 'user', 'content': assets.userMessage(ecli, xml)},
    ];
    final responses = <ClaudeResponse>[];
    Map<String, dynamic>? parsed;
    String? error;

    for (var round = 0; round < 2; round++) {
      final res = await claude.create(
        model: model,
        system: assets.systemPrompt(),
        messages: messages,
        effort: effort,
        schema: assets.outputSchema,
      );
      responses.add(res);
      if (res.stopReason == 'refusal') {
        error = 'The model refused the request';
        parsed = null;
        break;
      }
      var errors = <String>[];
      try {
        parsed = extractJson(res.text);
        errors = validate(parsed);
        error = errors.isEmpty ? null : 'Invalid JSON: ${errors.take(5).join(' | ')}';
      } on FormatException catch (e) {
        parsed = null;
        error = res.stopReason == 'max_tokens' ? 'Answer cut off (max_tokens)' : 'Unreadable JSON: ${e.message}';
      }
      if (error == null) break;
      messages
        ..add({'role': 'assistant', 'content': res.content})
        ..add({
          'role': 'user',
          'content': 'Your JSON is not valid against the schema:\n'
              '${errors.isEmpty ? error : errors.take(30).join('\n')}\n'
              'Return the corrected, complete Case JSON only.',
        });
    }

    if (parsed == null || error != null) {
      return ExtractionResult(ecli: ecli, responses: responses, error: error);
    }
    final ruling = RulingXml(xml);
    _fillCodeFields(parsed, ruling, responses.last.model);
    final (checks, judgeCost) = await check(parsed, ecli, ruling);
    return ExtractionResult(
        ecli: ecli, responses: responses, caseJson: parsed, checks: checks, extraCostUsd: judgeCost);
  }

  /// Runs the checks, asks the leak judge when words are flagged, then sets `status` and `validated`.
  Future<(List<Check>, double)> check(Map<String, dynamic> json, String ecli, RulingXml ruling) async {
    final checks = runChecks(json, ecli, ruling);
    var cost = 0.0;
    final i = checks.indexWhere((c) => c.label == leakCheckLabel);
    final judge = leakJudge;
    if (judge != null && !checks[i].ok) {
      final words = leakedWords(json);
      final v = await judge.judge(json, words);
      cost = v.costUsd;
      checks[i] = Check(leakCheckLabel, !v.revealsOutcome, "Words: ${words.join(', ')}; Haiku's opinion: ${v.reason}");
    }
    final allOk = checks.every((c) => c.ok);
    (json['pipeline'] as Map<String, dynamic>)['validated'] = allOk;
    final caseBlock = json['case'] as Map<String, dynamic>;
    if (caseBlock['status'] != 'rejected') caseBlock['status'] = allOk ? 'published' : 'draft';
    return (checks, cost);
  }

  /// Parses the model output, tolerating stray text around the object.
  static Map<String, dynamic> extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) throw const FormatException('no JSON object found');
    final decoded = jsonDecode(text.substring(start, end + 1));
    if (decoded is! Map<String, dynamic>) throw const FormatException('the root is not an object');
    return decoded;
  }

  List<String> validate(Map<String, dynamic> json) => assets.schema
      .validate(json, validateFormats: true)
      .errors
      .map((e) => '${e.instancePath.isEmpty ? '/' : e.instancePath}: ${e.message}')
      .toList();

  void _fillCodeFields(Map<String, dynamic> json, RulingXml ruling, String modelId) {
    final now = _now().toUtc().toIso8601String();
    final caseBlock = json['case'] as Map<String, dynamic>;
    caseBlock['sourceUrl'] = 'https://deeplink.rechtspraak.nl/uitspraak?id=${json['id']}';
    caseBlock['addedAt'] = now;
    final pipeline = json['pipeline'] as Map<String, dynamic>
      ..['extractedAt'] = now
      ..['model'] = modelId;
    final modified = ruling.modified;
    if (modified != null) {
      pipeline['sourceModifiedAt'] = RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(modified) ? modified : '${modified}Z';
    }
  }

  List<Check> runChecks(Map<String, dynamic> json, String ecli, RulingXml ruling) {
    final errors = validate(json);
    final checks = <Check>[
      Check('The JSON is valid against case.schema.json', errors.isEmpty, errors.isEmpty ? null : errors.join('\n')),
      Check('id equals the requested ECLI', json['id'] == ecli, 'id = ${json['id']}'),
    ];

    final verdict = json['verdict'] is Map ? json['verdict'] as Map : const {};
    final dictumNumbers = numbersIn(ruling.dictumText);
    final sentence = verdict['sentence'] is Map ? verdict['sentence'] as Map : const {};
    final missing = <String>[];
    for (final key in ['prisonMonths', 'prisonSuspendedMonths', 'fineEur', 'communityServiceHours', 'probationMonths']) {
      final v = sentence[key];
      if (v is! num || v == 0) continue;
      if (!amountInDictum(v.toDouble(), months: key.endsWith('Months'), dictumNumbers: dictumNumbers)) {
        missing.add('$key = $v');
      }
    }
    checks.add(Check('Sentence amounts appear in the decision (beslissing)', missing.isEmpty,
        missing.isEmpty ? null : 'Not found: ${missing.join(', ')}'));

    final ruled = (verdict['courtRuled'] as List? ?? const []).whereType<String>().toSet();
    final exclusive = ruled.intersection({'acquitted', 'case_dismissed'});
    checks.add(Check('Acquitted / case dismissed are not combined with a penalty',
        exclusive.isEmpty || ruled.length == 1, 'courtRuled = ${ruled.join(', ')}'));

    final leaks = leakedWords(json);
    checks.add(Check(leakCheckLabel, leaks.isEmpty,
        leaks.isEmpty ? null : 'Words found: ${leaks.join(', ')}'));
    return checks;
  }

  /// A month amount may be written in days (x30), weeks (x30/7) or years (/12).
  static bool amountInDictum(double value, {required bool months, required Set<double> dictumNumbers}) {
    bool has(double n) => dictumNumbers.any((d) => (d - n).abs() < 0.51);
    if (has(value)) return true;
    if (!months) return false;
    return has(value * 30) || has(value * 30 / 7) || has(value / 12);
  }

  static const _alwaysLeaks = [
    'sentenced', 'acquitted', 'acquittal', 'found guilty', 'the court found', 'the court held', //
  ];

  static const _penaltyWords = ['prison', 'jail', 'fine', 'fined', 'community service', 'months', 'hours'];

  /// Outcome words found in the texts shown before the verdict.
  static List<String> leakedWords(Map<String, dynamic> json) {
    final verdict = json['verdict'];
    final caseBlock = json['case'];
    if (verdict is! Map || caseBlock is! Map) return const [];
    final sentence = (verdict['actualSentence'] ?? '').toString().toLowerCase();
    final texts = [
      caseBlock['summaryShort'],
      caseBlock['summaryLong'],
      ...((caseBlock['arguments'] as List?) ?? const []).map((a) => a is Map ? a['text'] : a),
    ].whereType<String>().join(' ').toLowerCase();
    bool inTexts(String w) => RegExp('\\b${RegExp.escape(w)}\\b').hasMatch(texts);
    return [
      ..._alwaysLeaks.where(inTexts),
      ..._penaltyWords.where((w) => sentence.contains(w) && inTexts(w)),
    ];
  }

  static const _dutchNumbers = {
    'een': 1, 'twee': 2, 'drie': 3, 'vier': 4, 'vijf': 5, 'zes': 6, 'zeven': 7, 'acht': 8, //
    'negen': 9, 'tien': 10, 'elf': 11, 'twaalf': 12, 'dertien': 13, 'veertien': 14, 'vijftien': 15,
    'zestien': 16, 'zeventien': 17, 'achttien': 18, 'negentien': 19, 'twintig': 20, 'dertig': 30,
    'veertig': 40, 'vijftig': 50, 'zestig': 60, 'zeventig': 70, 'tachtig': 80, 'negentig': 90,
    'honderd': 100,
  };

  /// Every number in the text, Dutch style ("1.500,00") or as a simple Dutch word.
  static Set<double> numbersIn(String text) {
    final out = <double>{};
    for (final m in RegExp(r'\d{1,3}(?:\.\d{3})+(?:,\d+)?|\d+(?:,\d+)?').allMatches(text)) {
      final v = double.tryParse(m.group(0)!.replaceAll('.', '').replaceAll(',', '.'));
      if (v != null) out.add(v);
    }
    for (final m in RegExp(r'[a-z]+').allMatches(text.toLowerCase())) {
      final v = _dutchNumbers[m.group(0)];
      if (v != null) out.add(v.toDouble());
    }
    return out;
  }
}
