import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_styles.dart';
import '../../providers/account_provider.dart';
import '../../providers/home_provider.dart';
import '../home/home_screen.dart';
import 'account_validators.dart';
import 'log_in_screen.dart';
import 'widgets/account_button.dart';
import 'widgets/account_page.dart';
import 'widgets/account_text_field.dart';
import 'widgets/country_dropdown.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const CreateAccountScreen());

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _form = GlobalKey<FormState>();

  /// Errors show once the player taps "Create account", then update as
  /// they type.
  var _autovalidate = AutovalidateMode.disabled;

  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AccountProvider>()
      ..clearError()
      ..loadCountries();
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_form.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    final created = await context.read<AccountProvider>().createAccount(
      name: _name.text,
      username: _username.text,
      password: _password.text,
    );
    if (!created || !mounted) return;
    context.read<HomeProvider>().load();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountProvider>();
    return AccountPage(
      children: [
        const SizedBox(height: 79),
        Text(
          'CREATE ACCOUNT TO START JUDGING',
          style: AppTextStyles.accountEyebrow,
        ),
        const SizedBox(height: 24),
        Form(
          key: _form,
          autovalidateMode: _autovalidate,
          child: Column(
            children: [
              AccountTextField(
                controller: _name,
                label: 'Name',
                hint: 'Your name',
                validator: AccountValidators.name,
              ),
              const SizedBox(height: 10),
              AccountTextField(
                controller: _username,
                label: 'Username',
                hint: 'For future log-ins',
                validator: AccountValidators.newUsername,
              ),
              const SizedBox(height: 10),
              AccountTextField(
                controller: _password,
                label: 'Password',
                hint: 'Password',
                isPassword: true,
                validator: AccountValidators.newPassword,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        CountryDropdown(
          countries: account.countries,
          selected: account.country,
          showSelectedName: account.hasChosenCountry,
          onSelected: account.selectCountry,
        ),
        if (account.error != null) ...[
          const SizedBox(height: 12),
          Text(account.error!, style: AppTextStyles.fieldError),
        ],
        const SizedBox(height: 33),
        AccountButton(
          label: 'Create account',
          isLoading: account.isSubmitting,
          onPressed: _createAccount,
        ),
        const SizedBox(height: 23),
        GestureDetector(
          onTap: () => Navigator.of(context).push(LogInScreen.route()),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'I already have an account',
              style: AppTextStyles.accountLinkMuted,
            ),
          ),
        ),
      ],
    );
  }
}
