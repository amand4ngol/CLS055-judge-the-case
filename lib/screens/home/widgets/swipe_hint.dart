import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SwipeHint extends StatelessWidget {
  const SwipeHint({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.hairline, width: 0.696),
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('↔', style: AppTextStyles.swipeArrow),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                ' Swipe to explore cases',
                style: AppTextStyles.swipeHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
