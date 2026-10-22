import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/game_repository.dart';
import '../../../providers/account_provider.dart';
import '../../account/account_validators.dart';
import '../../account/widgets/account_text_field.dart';
import 'settings_dialog.dart';

/// "Delete account": asks for the password again. True once the account is
/// deleted and the player signed out.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  static Future<bool?> show(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (_) => const DeleteAccountDialog(),
  );

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _isDeleting = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_isDeleting || !_form.currentState!.validate()) return;
    setState(() {
      _isDeleting = true;
      _error = null;
    });
    try {
      await context.read<AccountProvider>().deleteAccount(
        password: _password.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AccountException catch (e) {
      // Only the password is asked here, so the username needs no mention.
      _fail(
        e.error == AccountError.wrongCredentials
            ? 'Wrong password.'
            : AccountProvider.messageFor(e.error),
      );
    } catch (e) {
      debugPrint('Could not delete the account: $e');
      _fail('Something went wrong. Please try again.');
    }
  }

  void _fail(String error) {
    if (!mounted) return;
    setState(() {
      _isDeleting = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SettingsDialog(
      title: 'Delete account?',
      message:
          'Your profile, statistics and judged cases are deleted for good. '
          'Enter your password to confirm.',
      actionLabel: 'Delete',
      onAction: _delete,
      isLoading: _isDeleting,
      error: _error,
      destructive: true,
      children: [
        Form(
          key: _form,
          child: AccountTextField(
            controller: _password,
            label: 'Password',
            hint: 'Password',
            isPassword: true,
            validator: AccountValidators.password,
          ),
        ),
      ],
    );
  }
}
