import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models.dart';
import 'widgets/previous_cases.dart';

/// Every case the player has judged, newest first. Opened from the profile.
class PreviousCasesScreen extends StatelessWidget {
  const PreviousCasesScreen({
    super.key,
    required this.rulings,
    required this.onPreview,
  });

  static Route<void> route(
    List<PlayerRuling> rulings, {
    required ValueChanged<PlayerRuling> onPreview,
  }) => MaterialPageRoute(
    builder: (_) => PreviousCasesScreen(rulings: rulings, onPreview: onPreview),
  );

  final List<PlayerRuling> rulings;
  final ValueChanged<PlayerRuling> onPreview;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                children: [
                  if (rulings.isEmpty) const NoPreviousCases(),
                  for (final ruling in rulings)
                    PreviousCaseButton(ruling, onTap: () => onPreview(ruling)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.caseDivider, width: 0.624),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back, color: AppColors.textSubtle),
          ),
          Expanded(
            child: Text(
              'PREVIOUS CASES',
              textAlign: TextAlign.center,
              style: AppTextStyles.profileHeader,
            ),
          ),
          // Balances the back button so the title stays centred.
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
