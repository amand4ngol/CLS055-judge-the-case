import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// What the hand on the target acts out.
enum GuideGesture { tap, swipe }

class GuideStep {
  const GuideStep({
    required this.target,
    required this.text,
    this.focus,
    this.isRound = false,
    this.gesture = GuideGesture.tap,
  });

  final GlobalKey target;
  final String text;

  /// Narrows the target's box to the part worth showing (e.g. the next
  /// case's medallion inside the whole case board).
  final Rect Function(Rect target)? focus;

  /// Lights up a circle instead of a rounded rectangle.
  final bool isRound;

  final GuideGesture gesture;
}

/// First-time tour of the home screen: dims everything but one target at a
/// time, with a hand tapping (or swiping) it and a tip next to it. Doing
/// what the hand shows on the target, or "Next", moves on; "Skip" and the
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
  static const double _gap = 16;

  /// The hand acts out the gesture a few times on each step, then rests.
  late final AnimationController _touch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  int _index = 0;

  /// Where the current target is, in this widget's coordinates. Null until
  /// the step is measured.
  Rect? _hole;

  /// Whether the current drag started on the target.
  bool _dragOnTarget = false;

  GuideStep get _step => widget.steps[_index];
  bool get _isLast => _index == widget.steps.length - 1;

  @override
  void initState() {
    super.initState();
    _showStep();
  }

  @override
  void dispose() {
    _touch.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) return widget.onDone();
    _touch.reset();
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
      if (!MediaQuery.of(context).disableAnimations) {
        _touch.repeat(count: 4);
      }
    });
  }

  bool _onTarget(Offset position) => _hole?.contains(position) ?? false;

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
            // Doing the step's gesture on the target moves on, without the
            // target's own action (which would leave the home screen).
            // Anywhere else, touches go nowhere.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  if (_step.gesture == GuideGesture.tap &&
                      _onTarget(details.localPosition)) {
                    _next();
                  }
                },
                onHorizontalDragStart: (details) =>
                    _dragOnTarget = _onTarget(details.localPosition),
                onHorizontalDragEnd: (details) {
                  if (_step.gesture == GuideGesture.swipe && _dragOnTarget) {
                    _next();
                  }
                },
                child: CustomPaint(
                  painter: _DimPainter(hole: hole, isRound: _step.isRound),
                ),
              ),
            ),
            if (hole != null) ...[
              Positioned(
                left: hole.center.dx - _TouchHint.fingertip.dx,
                top: hole.center.dy - _TouchHint.fingertip.dy,
                child: _TouchHint(animation: _touch, gesture: _step.gesture),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: below ? hole.bottom + _gap : null,
                bottom: below ? null : screen.height - hole.top + _gap,
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

/// A white hand whose fingertip sits on the target: it presses with a
/// ripple for a tap, or slides right to left for a swipe.
class _TouchHint extends StatelessWidget {
  const _TouchHint({required this.animation, required this.gesture});

  static const double _size = 44;
  static const double _rippleSize = 56;

  /// Where the tip of the finger is in the hand icon.
  static const Offset fingertip = Offset(21, 11);

  /// How far the hand travels each way for a swipe.
  static const double _swipeReach = 40;

  final Animation<double> animation;
  final GuideGesture gesture;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => switch (gesture) {
          GuideGesture.tap => _tap(animation.value),
          GuideGesture.swipe => _swipe(animation.value),
        },
      ),
    );
  }

  Widget _tap(double t) {
    // Press down, let go, then the ripple spreads out from the fingertip.
    final press = t < 0.2
        ? 0.0
        : t < 0.35
        ? (t - 0.2) / 0.15
        : t < 0.5
        ? 1 - (t - 0.35) / 0.15
        : 0.0;
    final ripple = t < 0.35 ? 0.0 : (t - 0.35) / 0.65;
    return SizedBox.square(
      dimension: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (ripple > 0)
            Positioned(
              left: fingertip.dx - _rippleSize / 2,
              top: fingertip.dy - _rippleSize / 2,
              child: Opacity(
                opacity: 1 - ripple,
                child: Transform.scale(
                  scale: 0.3 + 0.7 * ripple,
                  child: Container(
                    width: _rippleSize,
                    height: _rippleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.guideTouch, width: 3),
                    ),
                  ),
                ),
              ),
            ),
          Transform.scale(
            scale: 1 - 0.15 * press,
            alignment: Alignment(
              fingertip.dx / _size * 2 - 1,
              fingertip.dy / _size * 2 - 1,
            ),
            child: _hand,
          ),
        ],
      ),
    );
  }

  Widget _swipe(double t) {
    final slide = Curves.easeInOut.transform(t.clamp(0.1, 0.8) / 0.8);
    final opacity = t < 0.1
        ? t / 0.1
        : t > 0.8
        ? 1 - (t - 0.8) / 0.2
        : 1.0;
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(_swipeReach * (1 - 2 * slide), 0),
        child: _hand,
      ),
    );
  }

  static const _hand = Icon(
    Icons.touch_app,
    size: _size,
    color: AppColors.white,
    shadows: [Shadow(color: AppColors.guideTouch, blurRadius: 6)],
  );
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
