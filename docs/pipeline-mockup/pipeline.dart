import 'dart:convert';

import 'package:json_schema/json_schema.dart';

import '../models.dart';

import 'claude_client.dart';
import 'rechtspraak.dart';

/// The prompt, schema and example, read from data-model/ (copied in assets/).
class PipelineAssets {
  PipelineAssets({required this.promptMarkdown, required this.schemaJson, required this.exampleJson}) {
    systemTemplate = _block(promptMarkdown, 'System prompt');
    userTemplate = _block(promptMarkdown, 'User message');
    schema = JsonSchema.create(jsonDecode(schemaJson));
  }

  final String promptMarkdown;
  final String schemaJson;
  final String exampleJson;
  late final String systemTemplate;
  late final String userTemplate;
  late final JsonSchema schema;

  /// First ```text fenced block after the "## heading" line.
  static String _block(String md, String heading) {
    final m = RegExp('## ${RegExp.escape(heading)}\\s*```text\\n([\\s\\S]*?)\\n```').firstMatch(md);
    if (m == null) throw StateError('Bloc "$heading" introuvable dans le prompt');
    return m.group(1)!;
  }

  String systemPrompt() => systemTemplate.replaceAll('{{CASE_SCHEMA}}', schemaJson.trim());

  String userMessage(String ecli, String xml, {bool withExample = false}) {
    final msg = userTemplate.replaceAll('{{ECLI}}', ecli).replaceAll('{{RULING_XML}}', xml);
    if (!withExample) return msg;
    return 'Example output for another ruling:\n${exampleJson.trim()}\n\n$msg';
  }
}

/// One automatic check from the "Contrôles automatiques" list.
class Check {
  Check(this.label, this.ok, [this.detail]);

  final String label;
  final bool ok;
  final String? detail;
}

/// One call to Claude, kept for the cost and the debug view.
class Attempt {
  Attempt(this.response, this.duration, this.schemaErrors, this.parseError);

  final ClaudeResponse response;
  final Duration duration;
  final List<String> schemaErrors;
  final String? parseError;
}

class PipelineResult {
  PipelineResult({
    required this.ecli,
    required this.xml,
    required this.attempts,
    this.caseJson,
    this.checks = const [],
  });

  final String ecli;
  final String xml;
  final List<Attempt> attempts;

  /// The final Case document, after the code-filled fields; null if unusable.
  final Map<String, dynamic>? caseJson;
  final List<Check> checks;

  bool get schemaValid => checks.isNotEmpty && checks.first.ok;

  /// The `cases/{id}` document as the app reads it.
  CourtCase? get courtCase {
    final c = caseJson?['case'];
    return c is Map<String, dynamic> ? CourtCase.fromFirestore('${caseJson!['id']}', c) : null;
  }

  /// The `verdicts/{id}` document as the app reads it.
  CaseVerdict? get verdict {
    final v = caseJson?['verdict'];
    return v is Map<String, dynamic> ? CaseVerdict.fromFirestore('${caseJson!['id']}', v) : null;
  }
  bool get allChecksPass => checks.isNotEmpty && checks.every((c) => c.ok);

  double costUsd(ClaudeModel model) => attempts.fold(
      0,
      (sum, a) =>
          sum +
          a.response.inputTokens * model.inputPrice / 1e6 +
          a.response.outputTokens * model.outputPrice / 1e6);
}

typedef StepCallback = void Function(String step);

/// Fetch -> Claude -> parse -> validate (one correction round) -> code fields -> checks.
class CasePipeline {
  CasePipeline({required this.assets, required this.rechtspraak, required this.claude});

  final PipelineAssets assets;
  final RechtspraakClient rechtspraak;
  final ClaudeClient claude;

  Future<PipelineResult> run(
    String ecli, {
    required ClaudeModel model,
    String effort = 'medium',
    bool withExample = false,
    StepCallback? onStep,
  }) async {
    onStep?.call('Récupération du XML Rechtspraak…');
    final xml = await rechtspraak.fetchRulingXml(ecli);

    final messages = <Map<String, dynamic>>[
      {'role': 'user', 'content': assets.userMessage(ecli, xml, withExample: withExample)},
    ];
    final attempts = <Attempt>[];
    Map<String, dynamic>? parsed;

    for (var round = 0; round < 2; round++) {
      onStep?.call(round == 0 ? 'Conversion par ${model.label}…' : 'Correction demandée à ${model.label}…');
      final sw = Stopwatch()..start();
      final res = await claude.create(model: model, system: assets.systemPrompt(), messages: messages, effort: effort);
      sw.stop();

      if (res.stopReason == 'refusal') {
        attempts.add(Attempt(res, sw.elapsed, const [], 'Le modèle a refusé la demande (stop_reason: refusal)'));
        break;
      }
      String? parseError;
      var errors = <String>[];
      try {
        parsed = extractJson(res.text);
        errors = validate(parsed);
      } on FormatException catch (e) {
        parsed = null;
        parseError = res.stopReason == 'max_tokens'
            ? 'Réponse coupée (max_tokens atteint)'
            : 'JSON illisible : ${e.message}';
      }
      attempts.add(Attempt(res, sw.elapsed, errors, parseError));
      if (parseError == null && errors.isEmpty) break;

      // Send the errors back once, then give up (as the prompt doc says).
      messages
        ..add({'role': 'assistant', 'content': res.content})
        ..add({
          'role': 'user',
          'content': 'Your JSON is not valid against the schema:\n'
              '${parseError ?? errors.take(30).join('\n')}\n'
              'Return the corrected, complete Case JSON only.',
        });
    }

    if (parsed == null) {
      return PipelineResult(ecli: ecli, xml: xml, attempts: attempts);
    }

    onStep?.call('Contrôles automatiques…');
    final ruling = RulingXml(xml);
    _fillCodeFields(parsed, ruling, attempts.last.response.model);
    final checks = runChecks(parsed, ecli, ruling);
    final allOk = checks.every((c) => c.ok);
    (parsed['pipeline'] as Map<String, dynamic>?)?['validated'] = allOk;
    final caseBlock = parsed['case'];
    if (!allOk && caseBlock is Map && caseBlock['status'] == 'published') caseBlock['status'] = 'draft';
    return PipelineResult(ecli: ecli, xml: xml, attempts: attempts, caseJson: parsed, checks: checks);
  }

  /// Parses the model output, tolerating stray fences or text around the object.
  static Map<String, dynamic> extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) throw const FormatException('aucun objet JSON trouvé');
    final decoded = jsonDecode(text.substring(start, end + 1));
    if (decoded is! Map<String, dynamic>) throw const FormatException('la racine n\'est pas un objet');
    return decoded;
  }

  List<String> validate(Map<String, dynamic> json) {
    final result = assets.schema.validate(json, validateFormats: true);
    return result.errors.map((e) => '${e.instancePath.isEmpty ? '/' : e.instancePath}: ${e.message}').toList();
  }

  /// Fields the code sets itself (table "Champs remplis par le code").
  void _fillCodeFields(Map<String, dynamic> json, RulingXml ruling, String modelId) {
    final now = DateTime.now().toUtc().toIso8601String();
    final caseBlock = json['case'];
    if (caseBlock is Map<String, dynamic>) {
      caseBlock['sourceUrl'] = 'https://deeplink.rechtspraak.nl/uitspraak?id=${json['id']}';
      caseBlock['addedAt'] = now;
    }
    final pipeline = (json['pipeline'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    json['pipeline'] = pipeline
      ..['extractedAt'] = now
      ..['model'] = modelId
      ..putIfAbsent('notes', () => null);
    final modified = ruling.modified;
    if (modified != null) {
      pipeline['sourceModifiedAt'] = RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(modified) ? modified : '${modified}Z';
    }
  }

  List<Check> runChecks(Map<String, dynamic> json, String ecli, RulingXml ruling) {
    final errors = validate(json);
    final checks = <Check>[
      Check('Le JSON valide case.schema.json', errors.isEmpty, errors.isEmpty ? null : errors.join('\n')),
      Check('id est égal à l\'ECLI demandé', json['id'] == ecli, 'id = ${json['id']}'),
    ];

    final verdict = json['verdict'] is Map ? json['verdict'] as Map : const {};

    // Sentence amounts must appear in the dictum (months may be written as days, weeks or years).
    final dictumNumbers = numbersIn(ruling.dictumText);
    final sentence = verdict['sentence'] is Map ? verdict['sentence'] as Map : const {};
    final missing = <String>[];
    var checked = 0;
    for (final key in ['prisonMonths', 'prisonSuspendedMonths', 'fineEur', 'communityServiceHours', 'probationMonths']) {
      final v = sentence[key];
      if (v is! num || v == 0) continue;
      checked++;
      if (!amountInDictum(v.toDouble(), months: key.endsWith('Months'), dictumNumbers: dictumNumbers)) {
        missing.add('$key = $v');
      }
    }
    checks.add(Check('Les montants de la peine sont dans la « beslissing »', missing.isEmpty,
        missing.isEmpty ? '$checked montant(s) vérifié(s)' : 'Introuvables : ${missing.join(', ')}'));

    // Acquitted and case dismissed exclude every penalty.
    final ruled = (verdict['courtRuled'] as List? ?? const []).whereType<String>().toSet();
    final exclusive = ruled.intersection({'acquitted', 'case_dismissed'});
    checks.add(Check('Acquitted / case dismissed ne sont pas combinés à une peine',
        exclusive.isEmpty || ruled.length == 1, 'courtRuled = ${ruled.join(', ')}'));

    // Leak detection: outcome words in the pre-verdict block.
    final leaks = leakedWords(json);
    checks.add(Check('Le bloc case ne révèle pas l\'issue', leaks.isEmpty,
        leaks.isEmpty ? null : 'Mots trouvés : ${leaks.join(', ')}'));
    return checks;
  }

  /// A month amount may be written in days (x30), weeks (x30/7) or years (/12).
  static bool amountInDictum(double value, {required bool months, required Set<double> dictumNumbers}) {
    bool has(double n) => dictumNumbers.any((d) => (d - n).abs() < 0.51);
    if (has(value)) return true;
    if (!months) return false;
    return has(value * 30) || has(value * 30 / 7) || has(value / 12);
  }

  /// Words that reveal the outcome wherever they appear ("convicted" is left out:
  /// "previously convicted" is a legitimate argument).
  static const _alwaysLeaks = [
    'sentenced', 'acquitted', 'acquittal', 'found guilty', 'the court found', 'the court held',
  ];

  /// Penalty words, flagged only when the real sentence uses them too.
  static const _penaltyWords = ['prison', 'jail', 'fine', 'fined', 'community service', 'months', 'hours'];

  /// Outcome words found in the pre-verdict texts (summaries and arguments).
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
    'een': 1, 'twee': 2, 'drie': 3, 'vier': 4, 'vijf': 5, 'zes': 6, 'zeven': 7, 'acht': 8,
    'negen': 9, 'tien': 10, 'elf': 11, 'twaalf': 12, 'dertien': 13, 'veertien': 14, 'vijftien': 15,
    'zestien': 16, 'zeventien': 17, 'achttien': 18, 'negentien': 19, 'twintig': 20, 'dertig': 30,
    'veertig': 40, 'vijftig': 50, 'zestig': 60, 'zeventig': 70, 'tachtig': 80, 'negentig': 90,
    'honderd': 100,
  };

  /// Every number written in the text, Dutch style ("1.500,00") or as a simple Dutch word.
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
