import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models.dart';
import '../../providers/home_provider.dart';
import '../achievement/achievement_screen.dart';
import '../case/case_screen.dart';
import '../profile/profile_screen.dart';
import '../result/result_screen.dart';
import 'widgets/cases_section.dart';
import 'widgets/country_picker.dart';
import 'widgets/guide_tour.dart';
import 'widgets/home_header.dart';
import 'widgets/home_hero.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _gapAboveHero = 24;
  static const double _gapAboveCases = 30.9;

  /// Where the country picker opens, over the header.
  static const Offset _pickerOffset = Offset(16, 12);

  bool _isPickerOpen = false;

  // Targets of the first-time tour.
  final _countryKey = GlobalKey();
  final _categoriesKey = GlobalKey();
  final _casesKey = GlobalKey();
  final _profileKey = GlobalKey();

  void _setPickerOpen(bool open) {
    if (open != _isPickerOpen) setState(() => _isPickerOpen = open);
  }

  @override
  Widget build(BuildContext context) {
    final country = context.select((HomeProvider home) => home.country);
    final showsGuide = context.select((HomeProvider home) => home.showsGuide);

    return PopScope(
      // Back closes the picker first.
      canPop: !_isPickerOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _setPickerOpen(false);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: HomeHeader.height,
                      child: HomeHeader(
                        country: country,
                        countryKey: _countryKey,
                        profileKey: _profileKey,
                        onCountryTap: () => _setPickerOpen(true),
                        onProfileTap: () =>
                            Navigator.of(context).push(ProfileScreen.route()),
                      ),
                    ),
                    const SizedBox(height: _gapAboveHero),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: HomeHero(),
                    ),
                    const SizedBox(height: _gapAboveCases),
                    // A Stack inside: the pillars overlap the chips and
                    // the beige band, so this part keeps fixed positions.
                    SizedBox(
                      height: CasesSection.height,
                      child: CasesSection(
                        onCaseTap: _openCase,
                        categoriesKey: _categoriesKey,
                        casesKey: _casesKey,
                      ),
                    ),
                  ],
                ),
              ),
              if (showsGuide && !_isPickerOpen)
                Positioned.fill(
                  child: GuideTour(
                    steps: _guideSteps,
                    onDone: context.read<HomeProvider>().dismissGuide,
                  ),
                ),
              if (_isPickerOpen) ...[
                // Tapping anywhere outside the picker closes it.
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _setPickerOpen(false),
                  ),
                ),
                Positioned(
                  left: _pickerOffset.dx,
                  top: _pickerOffset.dy,
                  child: _CountryPickerPanel(
                    onClose: () => _setPickerOpen(false),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<GuideStep> get _guideSteps => [
    GuideStep(
      target: _countryKey,
      text: 'Your country: the real court cases you judge come from here. '
          'Tap the flag to change it',
    ),
    GuideStep(target: _categoriesKey, text: 'Swipe and pick a category'),
    GuideStep(
      target: _casesKey,
      text: 'Your cases in the category will showcase here. Tap one to start '
          'judging',
      // The next case's medallion, in the middle of the board.
      focus: (board) => Rect.fromCenter(
        center: Offset(board.center.dx, board.top + 255),
        width: 130,
        height: 130,
      ),
      isRound: true,
    ),
    GuideStep(
      target: _profileKey,
      text: 'Your profile: stats, achievements and settings',
      isRound: true,
    ),
  ];

  /// Completed cases open their recap; the others open the case, then
  /// the result once a verdict is delivered.
  Future<void> _openCase(CaseSlot slot) async {
    if (!slot.isPlayable) return;
    final home = context.read<HomeProvider>()..dismissGuide();
    final navigator = Navigator.of(context);

    if (slot.state == CaseSlotState.completed) {
      final result = await home.pastResult(slot.courtCase.id);
      if (result == null || !mounted) return;
      await navigator.push(ResultScreen.route(result, isRecap: true));
      home.focusNextCase();
      return;
    }

    final exit = await navigator.push(CaseScreen.route(slot.courtCase.id));
    await home.afterCase(exit);
    final result = exit?.result;
    if (result != null && mounted) await _showResult(result);
  }

  /// The result, then one page per achievement it unlocked; the last page
  /// left decides between home and the next case.
  Future<void> _showResult(RulingResult result) async {
    final navigator = Navigator.of(context);
    var action = await navigator.push(ResultScreen.route(result));
    if (result.newAchievements.isNotEmpty && mounted) {
      action = await AchievementScreen.showAll(
        navigator,
        result.newAchievements,
      );
    }
    if (action == ResultAction.nextCase && mounted) await _openNextCase();
  }

  /// "Next Case" on the result screen: the next playable case of the
  /// selected category.
  Future<void> _openNextCase() async {
    final next = context.read<HomeProvider>().nextCase;
    if (next == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have judged every case in this category.'),
        ),
      );
      return;
    }
    await _openCase(next);
  }
}

class _CountryPickerPanel extends StatelessWidget {
  const _CountryPickerPanel({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    return CountryPicker(
      countries: home.countries,
      selectedCode: home.player?.countryCode,
      stats: home.player?.stats ?? PlayerStats.zero,
      onClose: onClose,
      onSelected: (country) {
        onClose();
        home.selectCountry(country.code);
      },
    );
  }
}
