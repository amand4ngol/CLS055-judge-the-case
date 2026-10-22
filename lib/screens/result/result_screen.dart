import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_text_styles.dart';
import '../../models.dart';
import '../../shared/widgets/legal_area_badge.dart';
import '../../shared/widgets/primary_button.dart';
import '../case/widgets/arguments_section.dart';
import '../case/widgets/case_summary_section.dart';
import '../case/widgets/case_title_section.dart';
import '../case/widgets/charges_panel.dart';
import 'widgets/court_decision.dart';
import 'widgets/outcome_banner.dart';
import 'widgets/result_header.dart';
import 'widgets/ruling_cards.dart';

/// What the player chose on the result screen.
enum ResultAction { home, nextCase }

/// The court's real decision next to the player's, after "Deliver Verdict".
/// As a recap of a past case ([isRecap]), the case itself comes first and
/// the screen only offers to go back.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.result, this.isRecap = false});

  /// Completes with [ResultAction.nextCase] when the player taps
  /// "Next Case", otherwise with [ResultAction.home] (or null on back).
  /// A recap always completes with null.
  static Route<ResultAction> route(
    RulingResult result, {
    bool isRecap = false,
  }) => MaterialPageRoute(
    builder: (context) => ResultScreen(result: result, isRecap: isRecap),
  );

  final RulingResult result;
  final bool isRecap;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  // The recap's summary toggle and argument carousel.
  bool _showLongSummary = false;
  int _argumentPage = 0;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final isRecap = widget.isRecap;
    final courtCase = result.courtCase;
    final courtVerdict = result.courtVerdict;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ResultHeader(
              isRecap: isRecap,
              onBack: () =>
                  Navigator.of(context).pop(isRecap ? null : ResultAction.home),
              // TODO: open the profile screen.
              onProfile: () {},
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 512),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        isRecap ? 0 : 24,
                        20,
                        32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isRecap) ...[
                            ..._caseRecap(courtCase),
                            const SizedBox(height: 24),
                          ],
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
                          // The recap shows these in its title section.
                          if (!isRecap) ...[
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
                          ],
                          const SizedBox(height: 55),
                          PrimaryButton(
                            label: isRecap ? '← CLOSE RECAP' : 'NEXT CASE →',
                            height: 56,
                            labelStyle: AppTextStyles.resultNextCase,
                            onPressed: () => Navigator.of(
                              context,
                            ).pop(isRecap ? null : ResultAction.nextCase),
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

  /// The case as the player read it: title, charges, summary, arguments.
  List<Widget> _caseRecap(CourtCase courtCase) => [
    CaseTitleSection(courtCase: courtCase),
    if (courtCase.charges.isNotEmpty)
      Padding(
        padding: const EdgeInsets.only(top: 20),
        child: ChargesPanel(charges: courtCase.charges),
      ),
    CaseSummarySection(
      shortSummary: courtCase.summaryShort,
      longSummary: courtCase.summaryLong,
      showLong: _showLongSummary,
      onShowLongChanged: (value) => setState(() => _showLongSummary = value),
    ),
    if (courtCase.arguments.isNotEmpty)
      ArgumentsSection(
        arguments: courtCase.arguments,
        currentPage: _argumentPage,
        onPageChanged: (page) => setState(() => _argumentPage = page),
      ),
  ];

  /// Opens the full judgment on the court's website.
  Future<void> _openSource(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launchUrl(
        widget.result.courtCase.sourceUrl,
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
