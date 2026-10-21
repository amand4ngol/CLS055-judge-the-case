import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:judge_the_case/models.dart';

import '../../tool/pipeline/case_pipeline.dart';
import '../../tool/pipeline/claude_client.dart';
import '../../tool/pipeline/leak_judge.dart';
import '../../tool/pipeline/rechtspraak.dart';
import 'fakes.dart';

void main() {
  final pipeline = CasePipeline(assets: assets, rechtspraak: RechtspraakClient(), claude: ClaudeClient(apiKey: ''));
  Map<String, dynamic> example() => CasePipeline.extractJson(assets.exampleJson);

  test('prompt blocks are extracted and filled', () {
    expect(assets.systemTemplate, startsWith('You convert Dutch criminal court rulings'));
    expect(assets.systemPrompt(), isNot(contains('{{CASE_SCHEMA}}')));
    final user = assets.userMessage('ECLI:NL:X:2026:1', '<xml/>');
    expect(user, contains('ECLI: ECLI:NL:X:2026:1'));
    expect(user, contains('<ruling>\n<xml/>\n</ruling>'));
  });

  test('example case passes the schema and does not leak the outcome', () {
    expect(pipeline.validate(example()), isEmpty);
    expect(CasePipeline.leakedWords(example()), isEmpty);
  });

  test('the output schema drops what structured outputs reject', () {
    final text = jsonEncode(assets.outputSchema);
    for (final key in ['pattern', 'minLength', 'maxLength', 'minItems', 'maxItems', 'uniqueItems', 'minimum']) {
      expect(text, isNot(contains('"$key"')), reason: key);
    }
    expect(text, isNot(contains('"type":["')));
    expect(text, contains('"anyOf"'));
    expect(text, contains('"sexual_offences"'));
  });

  test('the output schema keeps every required field, even one named like a keyword', () {
    void visit(Object? node, String path) {
      if (node is List) {
        for (final x in node) {
          visit(x, path);
        }
      }
      if (node is! Map) return;
      final props = (node['properties'] as Map?)?.keys.toSet() ?? {};
      for (final name in (node['required'] as List?) ?? const []) {
        expect(props, contains(name), reason: '$path.$name');
      }
      for (final e in node.entries) {
        visit(e.value, '$path/${e.key}');
      }
    }

    visit(assets.outputSchema, '');
    final caseProps = assets.outputSchema['properties']['case']['properties'] as Map;
    expect(caseProps['title'], {'type': 'string'});
  });

  test('schema errors are reported', () {
    final broken = example()
      ..['schemaVersion'] = 1
      ..remove('verdict');
    expect(pipeline.validate(broken), isNotEmpty);
  });

  test('leak detection catches outcome words', () {
    final leaky = example();
    (leaky['case'] as Map)['summaryShort'] = 'He was sentenced to prison.';
    expect(CasePipeline.leakedWords(leaky), containsAll(['sentenced', 'prison']));
  });

  test('Dutch amounts are read from the dictum, months also as days, weeks or years', () {
    final n = CasePipeline.numbersIn('gevangenisstraf van 8 (acht) maanden, waarvan vier maanden '
        'voorwaardelijk; geldboete van € 1.500,00 en € 250,50; proeftijd van 2 jaren; hechtenis van 14 dagen');
    expect(n, containsAll([8.0, 4.0, 1500.0, 250.5]));
    expect(CasePipeline.amountInDictum(24, months: true, dictumNumbers: n), isTrue);
    expect(CasePipeline.amountInDictum(0.5, months: true, dictumNumbers: n), isTrue);
    expect(CasePipeline.amountInDictum(24, months: false, dictumNumbers: n), isFalse);
  });

  test('acquitted combined with a penalty fails a check', () {
    final bad = example();
    (bad['verdict'] as Map)['courtRuled'] = ['acquitted', 'prison'];
    final checks = pipeline.runChecks(bad, bad['id'] as String, RulingXml('<x/>'));
    expect(checks.firstWhere((c) => c.label.startsWith('Acquitted')).ok, isFalse);
  });

  test('beslissing section, modified date and excerpt are read from the XML', () {
    final r = RulingXml(rulingXml());
    expect(r.modified, '2026-10-01T14:24:39');
    expect(r.dictumText, contains('8 (acht) maanden'));
    expect(r.dictumText, isNot(contains('rood licht')));
    expect(r.excerpt(), startsWith('Feiten De verdachte'));
  });

  test('court level comes from the ECLI', () {
    expect(CourtLevel.ofEcli('ECLI:NL:RBNHO:2026:1'), CourtLevel.district);
    expect(CourtLevel.ofEcli('ECLI:NL:GHAMS:2026:1'), CourtLevel.appeal);
    expect(CourtLevel.ofEcli('ECLI:NL:HR:2026:1'), CourtLevel.supreme);
    expect(CourtLevel.ofEcli('ECLI:NL:PHR:2026:1'), CourtLevel.other);
  });

  group('leak judge', () {
    Future<(List<Check>, double, Map<String, dynamic>)> checkWith({required bool reveals}) async {
      final mock = MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['model'], 'claude-haiku-5-5');
        expect('${body['messages']}', contains('FLAGGED WORDS: acquittal'));
        return http.Response.bytes(
            utf8.encode(jsonEncode({
              'model': 'claude-haiku-5-5',
              'stop_reason': 'end_turn',
              'content': [
                {'type': 'text', 'text': jsonEncode({'revealsOutcome': reveals, 'reason': 'a request'})},
              ],
              'usage': {'input_tokens': 2000, 'output_tokens': 100},
            })),
            200);
      });
      final claude = ClaudeClient(apiKey: 'k', client: mock);
      final p = CasePipeline(
          assets: assets, rechtspraak: RechtspraakClient(), claude: claude, leakJudge: LeakJudge(claude));
      final json = example();
      (json['case'] as Map)['summaryShort'] = 'The defence asks for acquittal.';
      final (checks, cost) = await p.check(json, redLightEcli, RulingXml(rulingXml()));
      return (checks, cost, json);
    }

    test('a flagged request is cleared by the judge', () async {
      final (checks, cost, json) = await checkWith(reveals: false);
      expect(checks.every((c) => c.ok), isTrue);
      expect(cost, closeTo((2000 * 0.10 + 100 * 0.50) / 1e6, 1e-12));
      expect(json['case']['status'], 'published');
    });

    test('a real leak stays flagged', () async {
      final (checks, _, json) = await checkWith(reveals: true);
      final leak = checks.firstWhere((c) => c.label == CasePipeline.leakCheckLabel);
      expect(leak.ok, isFalse);
      expect(leak.detail, contains('a request'));
      expect(json['case']['status'], 'draft');
    });

    test('the judge is not asked when no word is flagged', () async {
      final p = CasePipeline(
        assets: assets,
        rechtspraak: RechtspraakClient(),
        claude: ClaudeClient(apiKey: ''),
        leakJudge: LeakJudge(ClaudeClient(apiKey: '', client: MockClient((_) async => fail('no call expected')))),
      );
      final (checks, cost) = await p.check(example(), redLightEcli, RulingXml(rulingXml()));
      expect(checks.every((c) => c.ok), isTrue);
      expect(cost, 0);
    });
  });

  group('full run with mocked Claude', () {
    Future<(ExtractionResult, List<Map<String, dynamic>>)> run({required bool withAmounts}) async {
      final bodies = <Map<String, dynamic>>[];
      final mock = MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        bodies.add(body);
        final out = bodies.length == 1 ? assets.exampleJson.replaceFirst('"traffic"', '"roads"') : assets.exampleJson;
        return http.Response.bytes(
            utf8.encode(jsonEncode({
              'model': 'claude-sonnet-5-5',
              'stop_reason': 'end_turn',
              'content': [
                {'type': 'thinking', 'thinking': '', 'signature': 'x'},
                {'type': 'text', 'text': out},
              ],
              'usage': {'input_tokens': 20000, 'output_tokens': 3000},
            })),
            200);
      });
      final p = CasePipeline(
        assets: assets,
        rechtspraak: RechtspraakClient(),
        claude: ClaudeClient(apiKey: 'test-key', client: mock),
        now: () => DateTime.utc(2026, 10, 20, 12),
      );
      return (await p.run(redLightEcli, xml: rulingXml(withAmounts: withAmounts)), bodies);
    }

    test('one correction round, then a case ready to publish', () async {
      final (r, bodies) = await run(withAmounts: true);
      expect(bodies, hasLength(2));
      final first = bodies.first;
      expect(first['model'], 'claude-sonnet-5-5');
      expect(first['fallbacks'], 'default');
      expect((first['system'] as List).single['cache_control'], {'type': 'ephemeral'});
      expect(first['output_config']['format']['type'], 'json_schema');
      final msgs = bodies.last['messages'] as List;
      expect((msgs[1]['content'] as List).first['type'], 'thinking');

      expect(r.outcome, ExtractionOutcome.ready);
      expect(r.costUsd, closeTo(2 * (0.04 + 0.03), 1e-9));
      final doc = r.caseDocument();
      expect(doc['status'], 'published');
      expect(doc['sourceUrl'], 'https://deeplink.rechtspraak.nl/uitspraak?id=$redLightEcli');
      expect(doc['addedAt'], DateTime.utc(2026, 10, 20, 12));
      expect((doc['decisionDate'] as DateTime).isUtc, isTrue);
      expect(doc['pipeline']['sourceModifiedAt'], DateTime.utc(2026, 10, 1, 14, 24, 39));
      expect(doc['pipeline']['validated'], isTrue);
      expect(CourtCase.fromFirestore(redLightEcli, doc).title, 'Red Light at 130');
      expect(CaseVerdict.fromFirestore(redLightEcli, r.verdictDocument()).courtRuled,
          {VerdictOption.prison, VerdictOption.probation});
    });

    test('a failed check sets the case aside for review', () async {
      final (r, _) = await run(withAmounts: false);
      expect(r.outcome, ExtractionOutcome.needsReview);
      expect(r.failedChecks, contains('beslissing'));
      expect(r.caseJson!['case']['status'], 'draft');
    });
  });
}
