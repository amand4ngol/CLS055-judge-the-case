import 'package:args/args.dart';
import 'package:judge_the_case/models.dart';

import 'claude_client.dart';
import 'rechtspraak.dart';

/// The filters and limits of one pipeline launch, read from the command line.
class PipelineOptions {
  const PipelineOptions({
    required this.from,
    required this.to,
    this.categories = const {},
    this.courts = const {CourtLevel.district, CourtLevel.appeal},
    this.limit = 10,
    this.maxCostUsd = 5,
    this.model = ClaudeModel.sonnet,
    this.effort = 'high',
    this.eclis = const [],
    this.local = false,
    this.retryFailed = false,
    this.force = false,
    this.recheck = false,
  });

  final DateTime from;
  final DateTime to;

  /// Empty means every category.
  final Set<CaseCategory> categories;
  final Set<CourtLevel> courts;
  final int limit;
  final double maxCostUsd;
  final ClaudeModel model;
  final String effort;
  final List<String> eclis;
  final bool local;
  final bool retryFailed;
  final bool force;
  final bool recheck;

  bool wants(CaseCategory c) => categories.isEmpty || categories.contains(c);

  static final parser = ArgParser()
    ..addOption('from', help: 'Earliest decision date (YYYY-MM-DD). Default: one year ago.')
    ..addOption('to', help: 'Latest decision date (YYYY-MM-DD). Default: today.')
    ..addMultiOption('category',
        help: 'Wanted categories, comma-separated. Default: all.',
        allowed: [for (final c in CaseCategory.values) c.value])
    ..addMultiOption('court',
        help: 'Courts: district (district court), appeal (court of appeal), supreme (Supreme Court).',
        allowed: ['district', 'appeal', 'supreme'],
        defaultsTo: ['district', 'appeal'])
    ..addOption('limit', help: 'Number of cases to publish.', defaultsTo: '10')
    ..addOption('max-cost', help: 'Maximum budget of the run, in dollars.', defaultsTo: '5')
    ..addOption('model',
        help: 'Model of the full analysis.',
        allowed: [ClaudeModel.sonnet.id, ClaudeModel.opus.id],
        defaultsTo: ClaudeModel.sonnet.id)
    ..addOption('effort', allowed: ['low', 'medium', 'high', 'xhigh', 'max'], defaultsTo: 'high')
    ..addMultiOption('ecli',
        help: 'Process only these rulings, comma-separated (search filters are ignored).')
    ..addFlag('local', negatable: false, help: 'Without Firebase: registry and results in tool/pipeline/out/.')
    ..addFlag('retry-failed', negatable: false, help: 'Retry the failed rulings.')
    ..addFlag('force', negatable: false, help: 'Process rulings already seen again, except published ones.')
    ..addFlag('recheck',
        negatable: false,
        help: 'Re-check the cases set aside for review from their stored JSON, without a new full analysis.')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

  /// Throws [FormatException] with a readable message for a wrong value.
  static PipelineOptions parse(List<String> args, {DateTime? today}) {
    final r = parser.parse(args);
    if (r.rest.isNotEmpty) throw FormatException('Unexpected argument: "${r.rest.first}"');
    final now = today ?? DateTime.now();
    DateTime date(String name, DateTime fallback) {
      final v = r.option(name);
      if (v == null) return fallback;
      final d = DateTime.tryParse(v);
      if (d == null || d.toIso8601String().substring(0, 10) != v) throw FormatException('--$name expects a YYYY-MM-DD date, got "$v"');
      return d;
    }

    num number(String name, {required bool integer}) {
      final v = r.option(name)!;
      final n = integer ? int.tryParse(v) : double.tryParse(v);
      if (n == null || n <= 0) throw FormatException('--$name expects a positive number, got "$v"');
      return n;
    }

    final from = date('from', DateTime(now.year - 1, now.month, now.day));
    final to = date('to', DateTime(now.year, now.month, now.day));
    if (from.isAfter(to)) throw const FormatException('--from is after --to');
    return PipelineOptions(
      from: from,
      to: to,
      categories: {for (final v in r.multiOption('category')) CaseCategory.fromValue(v)},
      courts: {for (final v in r.multiOption('court')) CourtLevel.values.byName(v)},
      limit: number('limit', integer: true).toInt(),
      maxCostUsd: number('max-cost', integer: false).toDouble(),
      model: ClaudeModel.byId(r.option('model')!)!,
      effort: r.option('effort')!,
      eclis: r.multiOption('ecli'),
      local: r.flag('local'),
      retryFailed: r.flag('retry-failed'),
      force: r.flag('force'),
      recheck: r.flag('recheck'),
    );
  }
}
