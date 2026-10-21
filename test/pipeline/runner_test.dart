import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:judge_the_case/models.dart';

import '../../tool/pipeline/case_pipeline.dart';
import '../../tool/pipeline/claude_client.dart';
import '../../tool/pipeline/classifier.dart';
import '../../tool/pipeline/leak_judge.dart';
import '../../tool/pipeline/options.dart';
import '../../tool/pipeline/rechtspraak.dart';
import '../../tool/pipeline/registry.dart';
import '../../tool/pipeline/runner.dart';
import 'fakes.dart';

void main() {
  const theft = 'ECLI:NL:GHAMS:2026:1';
  const supreme = 'ECLI:NL:HR:2026:7';
  const unusable = 'ECLI:NL:RBAMS:2026:2';
  const noAmounts = 'ECLI:NL:RBDHA:2026:3';

  late Directory dir;
  late FakeWorld world;
  setUp(() {
    dir = tempDir();
    world = FakeWorld([
      const FakeRuling(redLightEcli),
      const FakeRuling(theft, category: 'theft'),
      const FakeRuling(supreme),
      const FakeRuling(unusable, usable: false),
      const FakeRuling(noAmounts, withAmounts: false),
    ]);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<RunSummary> run(List<String> args) {
    final rechtspraak = RechtspraakClient(client: world.client, minInterval: Duration.zero);
    final claude = ClaudeClient(apiKey: 'test', client: world.client, retryDelay: Duration.zero);
    return PipelineRunner(
      options: PipelineOptions.parse(args, today: DateTime(2026, 10, 20)),
      rechtspraak: rechtspraak,
      classifier: RulingClassifier(claude),
      extractor: CasePipeline(assets: assets, rechtspraak: rechtspraak, claude: claude, leakJudge: LeakJudge(claude)),
      store: LocalStore(dir),
      log: (_) {},
    ).run();
  }

  Future<RunSummary> recheck() {
    final rechtspraak = RechtspraakClient(client: world.client, minInterval: Duration.zero);
    final claude = ClaudeClient(apiKey: 'test', client: world.client, retryDelay: Duration.zero);
    return PipelineRunner(
      options: PipelineOptions.parse(['--recheck'], today: DateTime(2026, 10, 20)),
      rechtspraak: rechtspraak,
      classifier: RulingClassifier(claude),
      extractor: CasePipeline(assets: assets, rechtspraak: rechtspraak, claude: claude, leakJudge: LeakJudge(claude)),
      store: LocalStore(dir),
      log: (_) {},
    ).recheck();
  }

  Future<void> setAside(String ecli, String argument) async {
    final json = jsonDecode(exampleFor(ecli)) as Map<String, dynamic>;
    ((json['case'] as Map)['arguments'] as List).first['text'] = argument;
    await LocalStore(dir).record(IngestEntry(
        ecli: ecli, status: IngestStatus.needsReview, updatedAt: DateTime(2026), result: json, costUsd: 0.05));
  }

  Map<String, dynamic> registry() =>
      jsonDecode(File('${dir.path}/registry.json').readAsStringSync()) as Map<String, dynamic>;
  bool published(String ecli) => File('${dir.path}/cases/${ecli.replaceAll(':', '_')}.json').existsSync();

  test('a second run spends nothing on rulings already seen', () async {
    final first = await run(['--category', 'traffic']);
    expect(first.published, 1);
    expect(first.needsReview, 1);
    expect(first.filtered, 1);
    expect(first.rejected, 1);
    expect(world.claudeCalls, {'claude-haiku-5-5': 4, 'claude-sonnet-5-5': 2});
    expect(registry().keys, isNot(contains(supreme)));
    expect(registry()[theft]['status'], 'filtered');
    expect(registry()[theft]['category'], 'theft');
    expect(registry()[noAmounts]['status'], 'needs_review');
    expect(registry()[noAmounts]['result'], isNotNull);
    expect(published(redLightEcli), isTrue);
    expect(published(noAmounts), isFalse);

    world.claudeCalls.clear();
    final second = await run(['--category', 'traffic']);
    expect(world.totalClaudeCalls, 0);
    expect(second.alreadyKnown, 4);
    expect(second.costUsd, 0);
  });

  test('a filtered ruling is analysed later without a new pre-sort', () async {
    await run(['--category', 'traffic']);
    world.claudeCalls.clear();
    final later = await run(['--category', 'theft']);
    expect(world.claudeCalls, {'claude-sonnet-5-5': 1});
    expect(later.published, 1);
    expect(registry()[theft]['status'], 'published');
    final countries = jsonDecode(File('${dir.path}/countries.json').readAsStringSync()) as Map;
    expect(countries['NL'], {'name': 'Netherlands', 'publishedCases': 2});
    final doc = jsonDecode(File('${dir.path}/cases/${theft.replaceAll(':', '_')}.json').readAsStringSync());
    expect(CourtCase.fromFirestore(theft, doc as Map<String, dynamic>).status, CaseStatus.published);
  });

  test('the run stops at the limit and the supreme court is left out by default', () async {
    final summary = await run(['--limit', '1']);
    expect(summary.published, 1);
    expect(registry().keys, isNot(contains(supreme)));
    expect(registry().keys, isNot(contains(noAmounts)));
  });

  test('the run stops after three failed analyses in a row', () async {
    world = FakeWorld([for (var i = 1; i <= 6; i++) FakeRuling('ECLI:NL:RBAMS:2026:$i')], brokenExtraction: true);
    final summary = await run([]);
    expect(summary.failed, 3);
    expect(world.claudeCalls['claude-sonnet-5-5'], 6);
    expect(registry(), hasLength(3));
  });

  test('an unexpected argument stops the launch instead of being ignored', () {
    expect(() => PipelineOptions.parse(['--ecli A --ecli B']), throwsFormatException);
    expect(PipelineOptions.parse(['--ecli', 'A,B'], today: DateTime(2026)).eclis, ['A', 'B']);
  });

  test('recheck publishes a set-aside case when the judge sees no real leak, without a new analysis', () async {
    await setAside(redLightEcli, 'The defence asks for acquittal.');
    final summary = await recheck();
    expect(summary.published, 1);
    expect(world.claudeCalls, {'claude-haiku-5-5': 1});
    expect(registry()[redLightEcli]['status'], 'published');
    expect(published(redLightEcli), isTrue);
  });

  test('recheck keeps a case aside when the judge sees a real leak', () async {
    world = FakeWorld([const FakeRuling(redLightEcli)], revealsOutcome: true);
    await setAside(redLightEcli, 'The first court had sentenced him to prison.');
    final summary = await recheck();
    expect(summary.needsReview, 1);
    expect(registry()[redLightEcli]['status'], 'needs_review');
    expect(registry()[redLightEcli]['reason'], contains('judge test'));
    expect(published(redLightEcli), isFalse);
  });

  test('failed rulings are retried only on request', () async {
    final store = LocalStore(dir);
    await store.record(IngestEntry(ecli: redLightEcli, status: IngestStatus.failed, updatedAt: DateTime(2026)));
    await run(['--ecli', redLightEcli]);
    expect(world.totalClaudeCalls, 0);
    await run(['--ecli', redLightEcli, '--retry-failed']);
    expect(registry()[redLightEcli]['status'], 'published');
    expect(registry()[redLightEcli]['attempts'], 1);
  });
}
