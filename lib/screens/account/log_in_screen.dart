import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_styles.dart';
import '../../providers/account_provider.dart';
import '../../providers/home_provider.dart';
import '../home/home_screen.dart';
import 'account_validators.dart';
import 'create_account_screen.dart';
import 'widgets/account_button.dart';
import 'widgets/account_page.dart';
import 'widgets/account_text_field.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const LogInScreen());

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final _form = GlobalKey<FormState>();

  /// Errors show once the player taps "Log in", then update as they type.
  var _autovalidate = AutovalidateMode.disabled;

  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AccountProvider>().clearError();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _logIn() async {
    if (!_form.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    final signedIn = await context.read<AccountProvider>().signIn(
      username: _username.text,
      password: _password.text,
    );
    if (!signedIn || !mounted) return;
    context.read<HomeProvider>().load();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  /// Back to "Create account" if it opened this screen, otherwise opens it.
  void _createAccount() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacement(CreateAccountScreen.route());
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountProvider>();
    return AccountPage(
      children: [
        const SizedBox(height: 67),
        Text('Welcome Back, Judge', style: AppTextStyles.accountTitle),
        const SizedBox(height: 41),
        Form(
          key: _form,
          autovalidateMode: _autovalidate,
          child: Column(
            children: [
              AccountTextField(
                controller: _username,
                label: 'Username',
                hint: 'Your username',
                validator: AccountValidators.username,
              ),
              const SizedBox(height: 10),
              AccountTextField(
                controller: _password,
                label: 'Password',
                hint: 'Password',
                isPassword: true,
                validator: AccountValidators.password,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 262,
          child: GestureDetector(
            // Accounts have no real email, so there is nowhere to send a
            // reset link yet.
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password reset is not available yet.'),
              ),
            ),
            child: Text('Forgot password?', style: AppTextStyles.accountLink),
          ),
        ),
        if (account.error != null) ...[
          const SizedBox(height: 12),
          Text(account.error!, style: AppTextStyles.fieldError),
        ],
        const SizedBox(height: 67),
        AccountButton(
          label: 'Log in',
          isLoading: account.isSubmitting,
          onPressed: _logIn,
        ),
        const SizedBox(height: 23),
        AccountButton(
          label: 'Create new account',
          secondary: true,
          onPressed: _createAccount,
        ),
      ],
    );
  }
}
