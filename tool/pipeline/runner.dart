import 'dart:convert';

import 'package:judge_the_case/models.dart';

import 'case_pipeline.dart';
import 'classifier.dart';
import 'options.dart';
import 'rechtspraak.dart';
import 'registry.dart';

/// Counts of one launch.
class RunSummary {
  int published = 0;
  int needsReview = 0;
  int rejected = 0;
  int filtered = 0;
  int failed = 0;
  int alreadyKnown = 0;
  double costUsd = 0;

  @override
  String toString() => '$published published, $needsReview to review, $rejected rejected, '
      '$filtered off-category, $failed failed, $alreadyKnown already known. '
      'Cost: \$${costUsd.toStringAsFixed(3)}';
}

/// One pipeline launch: search, skip known rulings, pre-sort, full analysis, then publish or set aside.
class PipelineRunner {
  PipelineRunner({
    required this.options,
    required this.rechtspraak,
    required this.classifier,
    required this.extractor,
    required this.store,
    this.log = print,
    DateTime Function()? now,
    this.pageSize = 100,
  }) : _now = now ?? DateTime.now;

  final PipelineOptions options;
  final RechtspraakClient rechtspraak;
  final RulingClassifier classifier;
  final CasePipeline extractor;
  final CaseStore store;
  final void Function(String) log;
  final int pageSize;
  final DateTime Function() _now;

  final summary = RunSummary();

  /// Failures in a row that stop the run: past this, the cause is most likely systematic.
  static const maxFailuresInARow = 3;
  int _failuresInARow = 0;

  bool get _done =>
      summary.published >= options.limit ||
      summary.costUsd >= options.maxCostUsd ||
      _failuresInARow >= maxFailuresInARow;

  Future<RunSummary> run() async {
    final seen = <String>{};
    for (var offset = 0; !_done; offset += pageSize) {
      final page = options.eclis.isNotEmpty
          ? [for (final e in options.eclis) RulingSummary(ecli: e)]
          : await rechtspraak.searchCriminal(from: options.from, to: options.to, offset: offset, pageSize: pageSize);
      final rulings = page
          .where((r) => options.eclis.isNotEmpty || options.courts.contains(CourtLevel.ofEcli(r.ecli)))
          .where((r) => seen.add(r.ecli))
          .toList();
      final known = await store.lookup([for (final r in rulings) r.ecli]);
      for (final r in rulings) {
        if (_done) break;
        final entry = known[r.ecli];
        final process = entry == null ||
            (options.force && entry.status != IngestStatus.published) ||
            entry.shouldProcess(wants: options.wants, retryFailed: options.retryFailed, now: _now());
        if (!process) {
          summary.alreadyKnown++;
          continue;
        }
        await _process(r, entry);
      }
      if (options.eclis.isNotEmpty || page.length < pageSize) break;
    }
    if (summary.costUsd >= options.maxCostUsd) log('Budget of \$${options.maxCostUsd} reached: stopping.');
    if (_failuresInARow >= maxFailuresInARow) {
      log('Stopping: $maxFailuresInARow failures in a row, most likely a systematic problem (see the reasons above).');
    }
    return summary;
  }

  /// Re-checks the rulings set aside for review with today's checks, from their stored JSON: no new analysis.
  Future<RunSummary> recheck() async {
    for (final e in await store.listStatus(IngestStatus.needsReview)) {
      if (summary.costUsd >= options.maxCostUsd) break;
      if (e.result == null) continue;
      try {
        final json = jsonDecode(jsonEncode(e.result, toEncodable: (o) => o is DateTime ? o.toIso8601String() : '$o'))
            as Map<String, dynamic>;
        (json['case'] as Map)['addedAt'] = _now().toUtc().toIso8601String();
        final xml = RulingXml(await rechtspraak.fetchRulingXml(e.ecli));
        final (checks, cost) = await extractor.check(json, e.ecli, xml);
        summary.costUsd += cost;
        final result = ExtractionResult(ecli: e.ecli, responses: const [], caseJson: json, checks: checks);
        if (result.outcome == ExtractionOutcome.ready) {
          await store.publish(
            entry: _entry(e.ecli, IngestStatus.published, previous: e, cost: cost),
            caseDocument: result.caseDocument(),
            verdictDocument: result.verdictDocument(),
          );
          summary.published++;
          log('${e.ecli}  published after re-check');
        } else {
          await store.record(_entry(e.ecli, IngestStatus.needsReview,
              previous: e, reason: result.failedChecks, cost: cost, result: json));
          summary.needsReview++;
          log('${e.ecli}  still to review: ${result.failedChecks}');
        }
      } catch (err) {
        summary.failed++;
        log('${e.ecli}  re-check failed: $err');
      }
    }
    return summary;
  }

  IngestEntry _entry(String ecli, IngestStatus status, {IngestEntry? previous, CaseCategory? category, String? reason,
          double cost = 0, String? model, Map<String, dynamic>? result, bool attempt = false}) =>
      IngestEntry(
        ecli: ecli,
        status: status,
        updatedAt: _now(),
        category: category ?? previous?.category,
        reason: reason,
        model: model ?? previous?.model,
        costUsd: (previous?.costUsd ?? 0) + cost,
        attempts: (previous?.attempts ?? 0) + (attempt ? 1 : 0),
        result: result,
      );

  Future<void> _process(RulingSummary r, IngestEntry? previous) async {
    String? xml;
    var category = previous?.status == IngestStatus.filtered ? previous?.category : null;
    var spent = 0.0;
    try {
      if (category == null) {
        final text = r.hasSummary ? r.summary : RulingXml(xml ??= await rechtspraak.fetchRulingXml(r.ecli)).excerpt();
        final c = await classifier.classify(ecli: r.ecli, title: r.title, text: text);
        spent += c.costUsd;
        summary.costUsd += c.costUsd;
        category = c.category;
        if (!c.usable) {
          await store.record(_entry(r.ecli, IngestStatus.rejected,
              previous: previous, category: category, reason: 'Pre-sort: ${c.reason}', cost: spent));
          summary.rejected++;
          log('${r.ecli}  rejected by the pre-sort (${c.reason})');
          return;
        }
        if (!options.wants(category)) {
          await store.record(_entry(r.ecli, IngestStatus.filtered, previous: previous, category: category, cost: spent));
          summary.filtered++;
          log('${r.ecli}  ${category.value}, not in the requested categories');
          return;
        }
      }

      final claim = _entry(r.ecli, IngestStatus.processing, previous: previous, category: category, cost: spent);
      if (options.force) {
        await store.record(claim);
      } else if (!await store.claim(claim, previous: previous)) {
        summary.alreadyKnown++;
        log('${r.ecli}  already taken by another run');
        return;
      }

      log('${r.ecli}  ${category.value}: full analysis…');
      final result = await extractor.run(r.ecli, xml: xml);
      summary.costUsd += result.costUsd;
      final cost = '\$${result.costUsd.toStringAsFixed(3)}';
      _failuresInARow = result.outcome == ExtractionOutcome.failed ? _failuresInARow + 1 : 0;
      switch (result.outcome) {
        case ExtractionOutcome.ready:
          await store.publish(
            entry: _entry(r.ecli, IngestStatus.published,
                previous: claim, category: result.category, cost: result.costUsd, model: result.model, attempt: true),
            caseDocument: result.caseDocument(),
            verdictDocument: result.verdictDocument(),
          );
          summary.published++;
          log('${r.ecli}  published (${summary.published}/${options.limit}), $cost');
        case ExtractionOutcome.needsReview:
          await store.record(_entry(r.ecli, IngestStatus.needsReview,
              previous: claim, category: result.category, reason: result.failedChecks, cost: result.costUsd,
              model: result.model, result: result.caseJson, attempt: true));
          summary.needsReview++;
          log('${r.ecli}  to review: ${result.failedChecks}, $cost');
        case ExtractionOutcome.rejected:
          final notes = (result.caseJson!['pipeline'] as Map)['notes'];
          await store.record(_entry(r.ecli, IngestStatus.rejected,
              previous: claim, category: result.category, reason: '$notes', cost: result.costUsd,
              model: result.model, attempt: true));
          summary.rejected++;
          log('${r.ecli}  rejected by the model ($notes), $cost');
        case ExtractionOutcome.failed:
          await store.record(_entry(r.ecli, IngestStatus.failed,
              previous: claim, reason: result.error, cost: result.costUsd, model: result.model, attempt: true));
          summary.failed++;
          log('${r.ecli}  failed: ${result.error}, $cost');
      }
    } catch (e) {
      await store.record(_entry(r.ecli, IngestStatus.failed,
          previous: previous, category: category, reason: '$e', cost: spent, attempt: true));
      summary.failed++;
      _failuresInARow++;
      log('${r.ecli}  failed: $e');
    }
  }
}
