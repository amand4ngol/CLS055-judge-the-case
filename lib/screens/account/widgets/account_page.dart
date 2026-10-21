import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_logo.dart';

/// Shared layout of "Create account" and "Log in": the logo on top, then
/// the form.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Center(
            child: Column(children: [const AppLogo(), ...children]),
          ),
        ),
      ),
    );
  }
}
