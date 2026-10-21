import 'dart:io';

import 'case_pipeline.dart';
import 'claude_client.dart';
import 'classifier.dart';
import 'firestore_store.dart';
import 'leak_judge.dart';
import 'options.dart';
import 'rechtspraak.dart';
import 'registry.dart';
import 'runner.dart';

const _dir = 'tool/pipeline';

/// Usage: `dart run tool/pipeline/main.dart --help`, from the root of the repository.
Future<void> main(List<String> args) async {
  final PipelineOptions options;
  try {
    if (args.contains('--help') || args.contains('-h')) {
      stdout.writeln('Rechtspraak → Claude → Firestore pipeline. Guide: $_dir/README.md\n');
      stdout.writeln(PipelineOptions.parser.usage);
      return;
    }
    options = PipelineOptions.parse(args);
  } on FormatException catch (e) {
    _fail('${e.message}\n\n${PipelineOptions.parser.usage}');
  }
  if (!Directory('$_dir/assets').existsSync()) _fail('Run the command from the root of the repository.');

  final env = {...readEnvFile(File('$_dir/.env')), ...Platform.environment};
  String require(String key, String hint) {
    final v = env[key]?.trim() ?? '';
    if (v.isEmpty) _fail('$key is missing. $hint');
    return v;
  }

  final apiKey = require('ANTHROPIC_API_KEY', 'Add it to $_dir/.env (see $_dir/README.md).');
  final CaseStore store;
  if (options.local) {
    store = LocalStore(Directory('$_dir/out'));
  } else {
    const hint = 'Follow the Firebase setup in $_dir/README.md, or run with --local.';
    store = await FirestoreStore.connect(
      projectId: require('FIREBASE_PROJECT_ID', hint),
      credentialsPath: require('GOOGLE_APPLICATION_CREDENTIALS', hint),
    );
  }

  final rechtspraak = RechtspraakClient();
  final claude = ClaudeClient(apiKey: apiKey);
  final runner = PipelineRunner(
    options: options,
    rechtspraak: rechtspraak,
    classifier: RulingClassifier(claude),
    extractor: CasePipeline(
      assets: PipelineAssets.load('$_dir/assets'),
      rechtspraak: rechtspraak,
      claude: claude,
      model: options.model,
      effort: options.effort,
      leakJudge: LeakJudge(claude),
    ),
    store: store,
  );
  final storage = options.local ? '$_dir/out' : 'Firestore';
  stdout.writeln(options.recheck
      ? 'Re-checking the cases set aside for review, budget: \$${options.maxCostUsd}, storage: $storage.'
      : 'Rulings from ${_day(options.from)} to ${_day(options.to)}, '
          'categories: ${options.categories.isEmpty ? 'all' : options.categories.map((c) => c.value).join(', ')}, '
          'target: ${options.limit} case(s), budget: \$${options.maxCostUsd}, storage: $storage.');
  final summary = options.recheck ? await runner.recheck() : await runner.run();
  stdout.writeln('\n$summary');
  exit(0);
}

/// Reads KEY=VALUE lines; blank lines and # comments are ignored, surrounding quotes removed.
Map<String, String> readEnvFile(File file) {
  if (!file.existsSync()) return {};
  final out = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final t = line.trim();
    final i = t.indexOf('=');
    if (t.isEmpty || t.startsWith('#') || i <= 0) continue;
    var v = t.substring(i + 1).trim();
    if (v.length >= 2 && (v.startsWith('"') && v.endsWith('"') || v.startsWith("'") && v.endsWith("'"))) {
      v = v.substring(1, v.length - 1);
    }
    out[t.substring(0, i).trim()] = v;
  }
  return out;
}

String _day(DateTime d) => d.toIso8601String().substring(0, 10);

Never _fail(String message) {
  stderr.writeln(message);
  exit(64);
}
