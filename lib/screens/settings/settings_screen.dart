import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models.dart';
import '../../providers/account_provider.dart';
import '../../providers/home_provider.dart';
import '../../shared/widgets/app_svg.dart';
import '../account/create_account_screen.dart';
import '../account/log_in_screen.dart';
import 'widgets/delete_account_dialog.dart';
import 'widgets/edit_information_dialog.dart';
import 'widgets/sensitive_filter.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/trigger_warnings_switch.dart';

/// Content preferences, account editing and sign out.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const SettingsScreen());

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final preferences = home.player?.preferences ?? ContentPreferences.none;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                children: [
                  Text(
                    'CONTENT PREFERENCES',
                    style: AppTextStyles.settingsSection,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Filter sensitive subjects from future cases. You can '
                    'change these preferences at any time.',
                    style: AppTextStyles.settingsBody,
                  ),
                  const SizedBox(height: 13),
                  SensitiveFilter(
                    preferences: preferences,
                    onChanged: home.setPreferences,
                  ),
                  const SizedBox(height: 8),
                  TriggerWarningsSwitch(
                    value: preferences.showTriggerWarnings,
                    onChanged: (value) => home.setPreferences(
                      preferences.copyWith(showTriggerWarnings: value),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.settingsNote,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.settingsNoteBorder,
                        width: 0.624,
                      ),
                    ),
                    child: Text(
                      'Preferences save automatically and affect new sessions.',
                      style: AppTextStyles.settingsNote,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('MANAGE ACCOUNT', style: AppTextStyles.settingsSection),
                  const SizedBox(height: 22),
                  _button(
                    onTap: () => _editInformation(context),
                    radius: 8,
                    child: Row(
                      children: [
                        const SizedBox.square(
                          dimension: 24,
                          child: AppSvg(AppAssets.edit),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Edit information',
                          style: AppTextStyles.settingsItem,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _button(
                    onTap: () => _deleteAccount(context),
                    radius: 8,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          size: 24,
                          color: AppColors.resultIncorrect,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Delete account',
                          style: AppTextStyles.settingsItem.copyWith(
                            color: AppColors.resultIncorrect,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(43, 8, 43, 24),
              child: _button(
                onTap: () => _confirmSignOut(context),
                radius: 4,
                child: Center(
                  child: Text('Sign out', style: AppTextStyles.settingsItem),
                ),
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
              'SETTINGS',
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

  /// Beige 56 px button of "Edit information", "Delete account" and "Sign
  /// out".
  Widget _button({
    required VoidCallback onTap,
    required double radius,
    required Widget child,
  }) {
    return Material(
      color: AppColors.argumentCard,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: child,
        ),
      ),
    );
  }

  Future<void> _editInformation(BuildContext context) async {
    final player = context.read<HomeProvider>().player;
    if (player == null) return;
    final saved = await EditInformationDialog.show(context, player);
    if (saved != true || !context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Your information is saved.')));
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final signOut = await showDialog<bool>(
      context: context,
      builder: (context) => SettingsDialog(
        title: 'Sign out?',
        message:
            'You can log back in any time with your username and password.',
        actionLabel: 'Sign out',
        onAction: () => Navigator.of(context).pop(true),
      ),
    );
    if (signOut != true || !context.mounted) return;

    final navigator = Navigator.of(context);
    final home = context.read<HomeProvider>();
    await context.read<AccountProvider>().signOut();
    await home.load();
    navigator.pushAndRemoveUntil(LogInScreen.route(), (_) => false);
  }

  /// The dialog deletes the account and signs out; then, as after "Sign
  /// out", home reloads and the player starts over on "Create account".
  Future<void> _deleteAccount(BuildContext context) async {
    final deleted = await DeleteAccountDialog.show(context);
    if (deleted != true || !context.mounted) return;

    final navigator = Navigator.of(context);
    await context.read<HomeProvider>().load();
    navigator.pushAndRemoveUntil(CreateAccountScreen.route(), (_) => false);
  }
}
