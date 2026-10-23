import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models.dart';
import '../../shared/widgets/app_svg.dart';
import '../../shared/widgets/primary_button.dart';
import '../profile/profile_screen.dart';
import '../result/result_screen.dart';
import '../result/widgets/result_header.dart';

/// "New achievement!", shown after the result screen for each achievement
/// the verdict just unlocked. It builds up in order: the banner slides in,
/// the badge pops with a glow, the bench lands, then the text and button.
class AchievementScreen extends StatefulWidget {
  const AchievementScreen({
    super.key,
    required this.achievement,
    this.isLast = true,
  });

  /// Completes with [ResultAction.nextCase] when the player taps the button
  /// ("Continue" on all pages but the last), [ResultAction.home] with the
  /// home pillar, or null on back.
  static Route<ResultAction> route(
    Achievement achievement, {
    bool isLast = true,
  }) => MaterialPageRoute(
    builder: (context) =>
        AchievementScreen(achievement: achievement, isLast: isLast),
  );

  /// Shows [achievements] one page after another. Completes with
  /// [ResultAction.nextCase] only if the last page asked for the next case;
  /// leaving any page another way stops there and goes home.
  static Future<ResultAction> showAll(
    NavigatorState navigator,
    List<Achievement> achievements,
  ) async {
    for (final (i, achievement) in achievements.indexed) {
      final action = await navigator.push(
        route(achievement, isLast: i == achievements.length - 1),
      );
      if (action != ResultAction.nextCase) return ResultAction.home;
    }
    return ResultAction.nextCase;
  }

  final Achievement achievement;
  final bool isLast;

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen>
    with TickerProviderStateMixin {
  /// The whole entrance; each part plays in its own slice of it.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  /// The ring that ripples out of the badge a few times once it has landed.
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  bool _started = false;
  bool _buzzed = false;

  late final Animation<Offset> _bannerSlide = Tween(
    begin: const Offset(-1, 0),
    end: Offset.zero,
  ).animate(_part(0, 0.3, Curves.easeOutCubic));

  late final Animation<double> _badgeScale = TweenSequence([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.15,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 70,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.15,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 30,
    ),
  ]).animate(_part(0.15, 0.6));

  late final Animation<Offset> _benchDrop = Tween(
    begin: const Offset(0, -0.25),
    end: Offset.zero,
  ).animate(_part(0.45, 0.85, Curves.bounceOut));

  late final Animation<double> _benchFade = _part(0.45, 0.6);

  late final Animation<Offset> _textRise = Tween(
    begin: const Offset(0, 0.3),
    end: Offset.zero,
  ).animate(_part(0.7, 1, Curves.easeOut));

  late final Animation<double> _textFade = _part(0.7, 1);

  Animation<double> _part(
    double begin,
    double end, [
    Curve curve = Curves.linear,
  ]) => CurvedAnimation(
    parent: _intro,
    curve: Interval(begin, end, curve: curve),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // "Reduce motion" in the phone's settings: show everything at once.
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
      return;
    }
    _intro.addListener(_buzzOnPop);
    _intro.forward().whenCompleteOrCancel(() {
      if (mounted) _glow.repeat(count: 3);
    });
  }

  /// A light tap on the phone as the badge pops.
  void _buzzOnPop() {
    if (_buzzed || _intro.value < 0.15) return;
    _buzzed = true;
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _intro.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievement = widget.achievement;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ResultHeader(
              onBack: () => Navigator.of(context).pop(ResultAction.home),
              onProfile: () =>
                  Navigator.of(context).push(ProfileScreen.route()),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 48, bottom: 24),
                child: Column(
                  children: [
                    Semantics(
                      header: true,
                      label: 'New achievement: ${achievement.title}',
                      excludeSemantics: true,
                      child: Column(
                        children: [
                          ClipRect(
                            child: SlideTransition(
                              position: _bannerSlide,
                              child: const _Banner(),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              _GlowRing(_glow),
                              ScaleTransition(
                                scale: _badgeScale,
                                child: _Badge(achievement.badge),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          FadeTransition(
                            opacity: _benchFade,
                            child: SlideTransition(
                              position: _benchDrop,
                              child: _Bench(achievement.title),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 1, color: AppColors.textDark),
                    const SizedBox(height: 28),
                    _rise(
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          achievement.unlockMessage,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.achievementMessage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 512),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: _rise(
                    Column(
                      children: [
                        Text(
                          'Keep up the good work, Judge',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.achievementCheer,
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: widget.isLast ? 'NEXT CASE →' : 'CONTINUE →',
                          height: 56,
                          labelStyle: AppTextStyles.resultNextCase,
                          onPressed: () =>
                              Navigator.of(context).pop(ResultAction.nextCase),
                        ),
                      ],
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

  /// The text and the button fade in and rise last.
  Widget _rise(Widget child) => FadeTransition(
    opacity: _textFade,
    child: SlideTransition(position: _textRise, child: child),
  );
}

/// Soft ring that ripples out of the badge and fades.
class _GlowRing extends AnimatedWidget {
  const _GlowRing(Animation<double> glow) : super(listenable: glow);

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    // Hidden before the first ripple and after the last one.
    if (t == 0) return const SizedBox.shrink();
    return Transform.scale(
      scale: 1 + 0.5 * t,
      child: Container(
        width: _Badge.size,
        height: _Badge.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.statAccuracy.withValues(alpha: 0.6 * (1 - t)),
            width: 6,
          ),
        ),
      ),
    );
  }
}

/// Full-width blue band between two white lines.
class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.white, width: 4),
        ),
        gradient: LinearGradient(
          colors: [
            AppColors.achievementBannerEdge,
            AppColors.statStreak,
            AppColors.achievementBannerEdge,
          ],
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text('New achievement!', style: AppTextStyles.achievementBanner),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.badge);

  final String badge;

  static const double size = 125;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.statAccuracy,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(badge, style: AppTextStyles.achievementBadgeLarge),
        ),
      ),
    );
  }
}

/// The judge's bench, with the achievement's title written left of the
/// gavel. The bench stands on the floor line drawn under it.
class _Bench extends StatelessWidget {
  const _Bench(this.title);

  final String title;

  // Size of judge_bench.svg; its desk top is at y = 49.
  static const _size = Size(264, 149);

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(
            child: AppSvg(AppAssets.judgeBench, excludeFromSemantics: true),
          ),
          // Left of the gavel, whose handle starts at x ≈ 178.
          Positioned(
            left: 12,
            width: 156,
            top: 6,
            height: 40,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.bottomCenter,
              child: Text(title, style: AppTextStyles.achievementScreenTitle),
            ),
          ),
        ],
      ),
    );
  }
}
