import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models.dart';
import 'argument_card.dart';

/// "ARGUMENTS" with the read counter, the progress segments and the card
/// carousel (intro card first, then one card per argument).
class ArgumentsSection extends StatelessWidget {
  const ArgumentsSection({
    super.key,
    required this.arguments,
    required this.argumentsRead,
    required this.onPageChanged,
  });

  final List<CaseArgument> arguments;
  final int argumentsRead;

  /// Page 0 is the intro card; page n is argument n.
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ARGUMENTS', style: AppTextStyles.caseSectionLabel),
              Text(
                '$argumentsRead/ ${arguments.length}',
                style: AppTextStyles.argumentsCount,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ProgressSegments(total: arguments.length, filled: argumentsRead),
          SizedBox(
            height: 326,
            child: PageView.builder(
              itemCount: arguments.length + 1,
              onPageChanged: onPageChanged,
              itemBuilder: (context, page) => Padding(
                padding: const EdgeInsets.fromLTRB(8, 18, 8, 20),
                child: page == 0
                    ? const ArgumentCard.intro()
                    : ArgumentCard.argument(arguments[page - 1]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSegments extends StatelessWidget {
  const _ProgressSegments({required this.total, required this.filled});

  final int total;
  final int filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 6,
              decoration: BoxDecoration(
                color: i < filled
                    ? AppColors.brown
                    : AppColors.caseProgressInactive,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
