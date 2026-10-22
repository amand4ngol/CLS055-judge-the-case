import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_styles.dart';
import '../../data/game_repository.dart';
import '../../providers/case_provider.dart';
import 'widgets/arguments_section.dart';
import 'widgets/case_header.dart';
import 'widgets/case_summary_section.dart';
import 'widgets/case_title_section.dart';
import 'widgets/charges_panel.dart';
import 'widgets/trigger_warning.dart';
import 'widgets/verdict_section.dart';

class CaseScreen extends StatelessWidget {
  const CaseScreen({super.key});

  /// Opens case [caseId] with its own [CaseProvider]. Completes with what
  /// happened in the case when the screen closes.
  static Route<CaseExit> route(String caseId) => MaterialPageRoute(
    builder: (context) => ChangeNotifierProvider(
      create: (context) =>
          CaseProvider(context.read<GameRepository>(), caseId)..load(),
      child: const CaseScreen(),
    ),
  );

  static const double _warningTop = 134;

  @override
  Widget build(BuildContext context) {
    final status = context.select((CaseProvider c) => c.status);

    return PopScope(
      // Back gestures go through [_leave] so the exit info is returned.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave(context);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              CaseHeader(onBack: () => _leave(context)),
              Expanded(
                child: switch (status) {
                  CaseScreenStatus.loading => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  CaseScreenStatus.error => const _ErrorView(),
                  CaseScreenStatus.warning => const Stack(
                    children: [
                      // The case shows faintly behind the warning but can't
                      // be used until the player enters.
                      IgnorePointer(child: _CaseContent()),
                      Positioned(
                        top: _warningTop,
                        left: 0,
                        right: 0,
                        child: _Warning(),
                      ),
                    ],
                  ),
                  CaseScreenStatus.ready => const _CaseContent(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _leave(BuildContext context) {
    Navigator.of(context).pop(context.read<CaseProvider>().exit);
  }
}

/// The scrolling case: title, charges, summary, arguments and verdict.
class _CaseContent extends StatelessWidget {
  const _CaseContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaseProvider>();
    final courtCase = provider.courtCase;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 512),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CaseTitleSection(courtCase: courtCase),
                if (courtCase.charges.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: ChargesPanel(charges: courtCase.charges),
                  ),
                CaseSummarySection(
                  shortSummary: courtCase.summaryShort,
                  longSummary: courtCase.summaryLong,
                  showLong: provider.showLongSummary,
                  onShowLongChanged: provider.setShowLongSummary,
                ),
                if (courtCase.arguments.isNotEmpty)
                  ArgumentsSection(
                    arguments: courtCase.arguments,
                    currentPage: provider.argumentPage,
                    onPageChanged: provider.showArgumentPage,
                  ),
                VerdictSection(
                  verdict: provider.verdict,
                  canDeliver: provider.canDeliver,
                  isDelivering: provider.isDelivering,
                  onToggle: provider.toggleOption,
                  onFineChanged: provider.setFine,
                  onPrisonChanged: provider.setPrison,
                  onSliderChangeEnd: provider.saveDraft,
                  onDeliver: () => _deliver(context),
                  onReturnHome: () => CaseScreen._leave(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deliver(BuildContext context) async {
    final provider = context.read<CaseProvider>();
    final result = await provider.deliver();
    if (!context.mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not deliver the verdict.')),
      );
      return;
    }
    Navigator.of(context).pop(provider.exit);
  }
}

class _Warning extends StatelessWidget {
  const _Warning();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaseProvider>();
    return TriggerWarning(
      warnings: provider.courtCase.contentWarnings,
      dontShowAgain: provider.dontShowWarningAgain,
      onDontShowAgainChanged: provider.setDontShowWarningAgain,
      onEnter: provider.enterCase,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not open this case.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: context.read<CaseProvider>().load,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
