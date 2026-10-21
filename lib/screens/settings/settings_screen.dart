import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models.dart';
import '../../providers/account_provider.dart';
import '../../providers/home_provider.dart';
import '../../shared/widgets/app_svg.dart';
import '../account/log_in_screen.dart';
import 'widgets/sensitive_filter.dart';

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

  /// Beige 56 px button of "Edit information" and "Sign out".
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

  Widget _dialogButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.settingsItem.copyWith(color: textColor),
            ),
          ),
        ),
      ),
    );
  }

  void _editInformation(BuildContext context) {
    // TODO: the repository cannot change a name or username yet, and the
    // edit screen is not designed.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Editing your information is coming soon.')),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final signOut = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.beige,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sign out?', style: AppTextStyles.title),
              const SizedBox(height: 8),
              Text(
                'You can log back in any time with your username and '
                'password.',
                style: AppTextStyles.settingsBody,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _dialogButton(
                      label: 'Cancel',
                      color: AppColors.argumentCard,
                      textColor: AppColors.countryPickerName,
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dialogButton(
                      label: 'Sign out',
                      color: AppColors.blue,
                      textColor: AppColors.white,
                      onTap: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (signOut != true || !context.mounted) return;

    final navigator = Navigator.of(context);
    final home = context.read<HomeProvider>();
    await context.read<AccountProvider>().signOut();
    await home.load();
    navigator.pushAndRemoveUntil(LogInScreen.route(), (_) => false);
  }
}
