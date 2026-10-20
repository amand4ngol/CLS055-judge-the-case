import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../models.dart';
import '../../../shared/widgets/legal_area_badge.dart';
import 'case_section.dart';

/// Legal area badge, case title and "Country · Year".
class CaseTitleSection extends StatelessWidget {
  const CaseTitleSection({super.key, required this.courtCase});

  final CourtCase courtCase;

  @override
  Widget build(BuildContext context) {
    return CaseSection(
      padding: const EdgeInsets.only(top: 24, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: LegalAreaBadge(courtCase.legalArea),
          ),
          const SizedBox(height: 12),
          Text(courtCase.title, style: AppTextStyles.caseTitle),
          const SizedBox(height: 8),
          Text(courtCase.originLabel, style: AppTextStyles.caseOrigin),
        ],
      ),
    );
  }
}
