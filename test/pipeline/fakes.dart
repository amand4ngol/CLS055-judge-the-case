import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../tool/pipeline/case_pipeline.dart';

final assets = PipelineAssets.load('tool/pipeline/assets');

const redLightEcli = 'ECLI:NL:RBNHO:2026:13327';

/// A ruling XML whose decision section holds the amounts of example-case.json.
String rulingXml({bool withAmounts = true}) => '''<open-rechtspraak xmlns:dcterms="http://purl.org/dc/terms/">
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"><rdf:Description>
<dcterms:modified>2026-10-01T14:24:39</dcterms:modified></rdf:Description></rdf:RDF>
<uitspraak><section><title>Feiten</title><para>De verdachte reed door rood licht.</para></section>
<section><title>Beslissing</title><para>${withAmounts ? 'gevangenisstraf van 8 (acht) maanden, waarvan 4 maanden voorwaardelijk, proeftijd 2 jaar; ontzegging 3 jaar waarvan 1 jaar voorwaardelijk; € 10.500,00' : 'zie hierboven'}</para></section></uitspraak>
</open-rechtspraak>''';

/// The example case converted for [ecli].
String exampleFor(String ecli) => assets.exampleJson.replaceAll(redLightEcli, ecli);

/// One fake ruling: where it comes from and what the fake models answer about it.
class FakeRuling {
  const FakeRuling(this.ecli, {this.category = 'traffic', this.usable = true, this.withAmounts = true});

  final String ecli;
  final String category;
  final bool usable;
  final bool withAmounts;
}

/// Fake Rechtspraak and Claude, counting the Claude calls per model.
class FakeWorld {
  FakeWorld(this.rulings, {this.brokenExtraction = false, this.revealsOutcome = false});

  final List<FakeRuling> rulings;

  /// The full analysis answers an empty object, as when the output schema is wrong.
  final bool brokenExtraction;

  /// What the fake leak judge answers.
  final bool revealsOutcome;
  final claudeCalls = <String, int>{};
  final sentBodies = <Map<String, dynamic>>[];

  int get totalClaudeCalls => claudeCalls.values.fold(0, (a, b) => a + b);

  FakeRuling _ruling(String ecli) => rulings.firstWhere((r) => r.ecli == ecli);

  late final http.Client client = MockClient((req) async {
    if (req.url.host == 'data.rechtspraak.nl') {
      if (req.url.path.endsWith('/zoeken')) return _bytes(_feed());
      return _bytes(rulingXml(withAmounts: _ruling(req.url.queryParameters['id']!).withAmounts));
    }
    final body = jsonDecode(req.body) as Map<String, dynamic>;
    sentBodies.add(body);
    final model = body['model'] as String;
    claudeCalls[model] = (claudeCalls[model] ?? 0) + 1;
    final message = jsonEncode(body['messages']);
    final ecli = RegExp(r'ECLI: (ECLI:[A-Z0-9:]+)').firstMatch(message)!.group(1)!;
    final r = _ruling(ecli);
    final isJudge = '${body['system']}'.contains('You review cases');
    final text = isJudge
        ? jsonEncode({'revealsOutcome': revealsOutcome, 'reason': 'judge test'})
        : model == 'claude-haiku-5-5'
        ? jsonEncode({'usable': r.usable, 'category': r.category, 'reason': 'test'})
        : brokenExtraction
            ? '{}'
            : exampleFor(ecli);
    return _bytes(jsonEncode({
      'model': model,
      'stop_reason': 'end_turn',
      'content': [
        {'type': 'text', 'text': text},
      ],
      'usage': {'input_tokens': 10000, 'output_tokens': 1000, 'cache_read_input_tokens': 4000},
    }));
  });

  String _feed() => '<feed xmlns="http://www.w3.org/2005/Atom">'
      '${rulings.map((r) => '<entry><id>${r.ecli}</id><title>${r.ecli}</title>'
          '<summary>A long enough official summary of the ruling ${r.ecli} for the pre-sort.</summary></entry>').join()}'
      '</feed>';

  static http.Response _bytes(String s) => http.Response.bytes(utf8.encode(s), 200);
}

Directory tempDir() => Directory.systemTemp.createTempSync('pipeline_test_');
