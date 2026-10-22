import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models.dart';
import '../../providers/home_provider.dart';
import '../case/case_screen.dart';
import '../profile/profile_screen.dart';
import '../result/result_screen.dart';
import 'widgets/cases_section.dart';
import 'widgets/country_picker.dart';
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

  void _setPickerOpen(bool open) {
    if (open != _isPickerOpen) setState(() => _isPickerOpen = open);
  }

  @override
  Widget build(BuildContext context) {
    final country = context.select((HomeProvider home) => home.country);

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
                        onCountryTap: () => _setPickerOpen(true),
                        onProfileTap: () => Navigator.of(
                          context,
                        ).push(ProfileScreen.route()),
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
                      child: CasesSection(onCaseTap: _openCase),
                    ),
                  ],
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

  /// Completed cases open their result; the others open the case, then
  /// the result once a verdict is delivered.
  Future<void> _openCase(CaseSlot slot) async {
    if (!slot.isPlayable) return;
    final home = context.read<HomeProvider>();
    final navigator = Navigator.of(context);

    if (slot.state == CaseSlotState.completed) {
      final result = await home.pastResult(slot.courtCase.id);
      if (result != null && mounted) await _showResult(result);
      return;
    }

    final exit = await navigator.push(CaseScreen.route(slot.courtCase.id));
    await home.afterCase(exit);
    final result = exit?.result;
    // TODO: show the achievement screen first when result.newAchievements
    // is not empty
    if (result != null && mounted) await _showResult(result);
  }

  Future<void> _showResult(RulingResult result) async {
    final action = await Navigator.of(context).push(ResultScreen.route(result));
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
