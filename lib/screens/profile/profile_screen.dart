import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/game_repository.dart';
import '../../models.dart';
import '../../providers/home_provider.dart';
import '../../shared/widgets/app_svg.dart';
import '../result/result_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/achievements_grid.dart';
import 'widgets/previous_cases.dart';
import 'widgets/stats_row.dart';
import 'widgets/welcome_card.dart';

/// "My Profile": rank, statistics, previous cases and achievements.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const ProfileScreen());

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Loaded fresh, so the stats include the cases judged since home loaded.
  late Future<(PlayerProfile?, List<PlayerRuling>)> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<(PlayerProfile?, List<PlayerRuling>)> _load() {
    final repository = context.read<GameRepository>();
    return (repository.currentPlayer(), repository.completedRulings()).wait;
  }

  /// The name or username may have changed in the settings.
  Future<void> _openSettings() async {
    await Navigator.of(context).push(SettingsScreen.route());
    // After "Sign out" or "Delete account" this page is being removed.
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    setState(() {
      _data = _load();
    });
  }

  Future<void> _preview(PlayerRuling ruling) async {
    final navigator = Navigator.of(context);
    final result = await context.read<HomeProvider>().pastResult(ruling.caseId);
    if (result == null || !mounted) return;
    final action = await navigator.push(ResultScreen.route(result));
    // "Home" or "Next Case" on the result screen: back to home.
    if (action != null && mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: FutureBuilder(
                future: _data,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Could not load your profile.'),
                    );
                  }
                  final (player, rulings) = snapshot.data ?? (null, null);
                  if (player == null || rulings == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _content(player, rulings);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.caseDivider, width: 0.624),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const SizedBox.square(
              dimension: 30,
              child: AppSvg(AppAssets.caseHome),
            ),
          ),
          Text('MY PROFILE', style: AppTextStyles.profileHeader),
          GestureDetector(
            onTap: _openSettings,
            child: const SizedBox.square(
              dimension: 32,
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: AppSvg(AppAssets.settings),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(PlayerProfile player, List<PlayerRuling> rulings) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        WelcomeCard(player: player),
        const SizedBox(height: 20),
        _section(
          top: 0,
          children: [
            Text('CASES STATISTICS', style: AppTextStyles.profileSection),
            const SizedBox(height: 12),
            StatsRow(stats: player.stats),
          ],
        ),
        _section(
          children: [
            Text(
              'REVISE YOUR PREVIOUS CASES',
              style: AppTextStyles.profileSection,
            ),
            const SizedBox(height: 4),
            PreviousCases(rulings: rulings, onPreview: _preview),
          ],
        ),
        _section(
          divider: false,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ACHIEVEMENTS', style: AppTextStyles.profileSectionBold),
                Text(
                  player.achievementsLabel,
                  style: AppTextStyles.achievementCount,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AchievementsGrid(player: player),
          ],
        ),
      ],
    );
  }

  /// A block of the page with a thin line under it.
  Widget _section({
    required List<Widget> children,
    double top = 20,
    bool divider = true,
  }) {
    return Container(
      padding: EdgeInsets.only(top: top, bottom: 20),
      decoration: divider
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.caseDivider, width: 0.624),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
