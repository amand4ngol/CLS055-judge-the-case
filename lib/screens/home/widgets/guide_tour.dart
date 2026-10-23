import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class GuideStep {
  const GuideStep({
    required this.target,
    required this.text,
    this.focus,
    this.isRound = false,
  });

  final GlobalKey target;
  final String text;

  /// Narrows the target's box to the part worth showing (e.g. the next
  /// case's medallion inside the whole case board).
  final Rect Function(Rect target)? focus;

  /// Lights up a circle instead of a rounded rectangle.
  final bool isRound;
}

/// First-time tour of the home screen: dims everything but one target at a
/// time, with a bouncing arrow and a tip. "Next" moves on, "Skip" and the
/// last step's "Got it" close it.
class GuideTour extends StatefulWidget {
  const GuideTour({super.key, required this.steps, required this.onDone});

  final List<GuideStep> steps;
  final VoidCallback onDone;

  @override
  State<GuideTour> createState() => _GuideTourState();
}

class _GuideTourState extends State<GuideTour>
    with SingleTickerProviderStateMixin {
  static const double _holePadding = 8;
  static const double _arrowSize = 32;
  static const double _gap = 6;

  /// The arrow bounces a few times on each step, then rests.
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  int _index = 0;

  /// Where the current target is, in this widget's coordinates. Null until
  /// the step is measured.
  Rect? _hole;

  GuideStep get _step => widget.steps[_index];
  bool get _isLast => _index == widget.steps.length - 1;

  @override
  void initState() {
    super.initState();
    _showStep();
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) return widget.onDone();
    setState(() {
      _index++;
      _hole = null;
    });
    _showStep();
  }

  /// Scrolls the target into view, then measures it once laid out.
  void _showStep() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final target = _step.target.currentContext;
      // Not on screen (e.g. no flag yet): skip the step rather than leave
      // the page dimmed with no tip.
      if (target == null) return _next();
      await Scrollable.ensureVisible(
        target,
        alignment: 0.3,
        duration: const Duration(milliseconds: 250),
      );
      if (!mounted || !target.mounted) return;
      final box = target.findRenderObject()! as RenderBox;
      final tour = context.findRenderObject()! as RenderBox;
      var rect = box.localToGlobal(Offset.zero, ancestor: tour) & box.size;
      rect = _step.focus?.call(rect) ?? rect;
      setState(() => _hole = rect.inflate(_holePadding));
      _bounce.repeat(reverse: true, count: 8);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hole = _hole;
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = constraints.biggest;
        // The tip goes on the side of the target with more room.
        final below = hole == null || hole.center.dy < screen.height / 2;
        return Stack(
          children: [
            // Taps on the dimmed page go nowhere; the tip drives the tour.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: CustomPaint(
                  painter: _DimPainter(hole: hole, isRound: _step.isRound),
                ),
              ),
            ),
            if (hole != null) ...[
              Positioned(
                left: (hole.center.dx - _arrowSize / 2).clamp(
                  8,
                  screen.width - _arrowSize - 8,
                ),
                top: below ? hole.bottom + _gap : null,
                bottom: below ? null : screen.height - hole.top + _gap,
                child: AnimatedBuilder(
                  animation: _bounce,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, (below ? 1 : -1) * 8 * _bounce.value),
                    child: child,
                  ),
                  child: Icon(
                    below ? Icons.arrow_upward : Icons.arrow_downward,
                    size: _arrowSize,
                    color: AppColors.white,
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: below ? hole.bottom + _gap + _arrowSize + 16 : null,
                bottom: below
                    ? null
                    : screen.height - hole.top + _gap + _arrowSize + 16,
                child: Center(
                  child: _TipCard(
                    text: _step.text,
                    progress: '${_index + 1}/${widget.steps.length}',
                    nextLabel: _isLast ? 'Got it' : 'Next',
                    onNext: _next,
                    onSkip: _isLast ? null : widget.onDone,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Darkens the screen except around [hole].
class _DimPainter extends CustomPainter {
  const _DimPainter({required this.hole, required this.isRound});

  final Rect? hole;
  final bool isRound;

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Path()..addRect(Offset.zero & size);
    final hole = this.hole;
    final dim = hole == null
        ? screen
        : Path.combine(
            PathOperation.difference,
            screen,
            Path()..addRRect(
              RRect.fromRectAndRadius(
                hole,
                Radius.circular(isRound ? hole.shortestSide / 2 : 12),
              ),
            ),
          );
    canvas.drawPath(dim, Paint()..color = AppColors.guideDim);
  }

  @override
  bool shouldRepaint(_DimPainter old) =>
      old.hole != hole || old.isRound != isRound;
}

/// White box with the tip, the step count and the buttons.
class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.text,
    required this.progress,
    required this.nextLabel,
    required this.onNext,
    this.onSkip,
  });

  final String text;

  /// "1/3"
  final String progress;
  final String nextLabel;
  final VoidCallback onNext;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final onSkip = this.onSkip;
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.guideCard,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              text.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTextStyles.guideTip,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(progress, style: AppTextStyles.guideProgress),
              const Spacer(),
              if (onSkip != null)
                TextButton(
                  onPressed: onSkip,
                  child: Text('Skip', style: AppTextStyles.guideProgress),
                ),
              TextButton(
                onPressed: onNext,
                child: Text(nextLabel, style: AppTextStyles.guideAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
