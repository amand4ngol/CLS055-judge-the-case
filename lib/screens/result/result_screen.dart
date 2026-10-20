import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_text_styles.dart';
import '../../models.dart';
import '../../shared/widgets/legal_area_badge.dart';
import '../../shared/widgets/primary_button.dart';
import 'widgets/court_decision.dart';
import 'widgets/outcome_banner.dart';
import 'widgets/result_header.dart';
import 'widgets/ruling_cards.dart';

/// What the player chose on the result screen.
enum ResultAction { home, nextCase }

/// The court's real decision next to the player's, after "Deliver Verdict"
/// or when revising a past case.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.result});

  /// Completes with [ResultAction.nextCase] when the player taps
  /// "Next Case", otherwise with [ResultAction.home] (or null on back).
  static Route<ResultAction> route(RulingResult result) =>
      MaterialPageRoute(builder: (context) => ResultScreen(result: result));

  final RulingResult result;

  @override
  Widget build(BuildContext context) {
    final courtCase = result.courtCase;
    final courtVerdict = result.courtVerdict;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ResultHeader(
              onHome: () => Navigator.of(context).pop(ResultAction.home),
              // TODO: open the profile screen.
              onProfile: () {},
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 512),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutcomeBanner(isCorrect: result.isCorrect),
                          const SizedBox(height: 20),
                          RulingCards(comparison: result.comparison),
                          if (courtVerdict.actualSentence.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            ActualSentenceCard(
                              sentence: courtVerdict.actualSentence,
                            ),
                          ],
                          if (courtVerdict.courtReasoning.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            CourtReasoning(
                              reasoning: courtVerdict.courtReasoning,
                            ),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              LegalAreaBadge(courtCase.legalArea),
                              const SizedBox(width: 12),
                              Text(
                                courtCase.originLabel,
                                style: AppTextStyles.resultOrigin,
                              ),
                            ],
                          ),
                          const SizedBox(height: 55),
                          PrimaryButton(
                            label: 'NEXT CASE →',
                            height: 56,
                            labelStyle: AppTextStyles.resultNextCase,
                            onPressed: () => Navigator.of(
                              context,
                            ).pop(ResultAction.nextCase),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 53,
                            child: TextButton(
                              onPressed: () => _openSource(context),
                              child: Text(
                                'Get to the detailed case here.',
                                style: AppTextStyles.resultSourceLink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the full judgment on the court's website.
  Future<void> _openSource(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launchUrl(
        result.courtCase.sourceUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the court website.')),
      );
    }
  }
}
