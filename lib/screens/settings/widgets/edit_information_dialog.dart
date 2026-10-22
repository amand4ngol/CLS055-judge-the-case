import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/game_repository.dart';
import '../../../models.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/home_provider.dart';
import '../../account/account_validators.dart';
import '../../account/widgets/account_text_field.dart';
import 'settings_dialog.dart';

/// "Edit information": the player's name and username. True once saved.
class EditInformationDialog extends StatefulWidget {
  const EditInformationDialog({super.key, required this.player});

  final PlayerProfile player;

  static Future<bool?> show(BuildContext context, PlayerProfile player) =>
      showDialog<bool>(
        context: context,
        builder: (_) => EditInformationDialog(player: player),
      );

  @override
  State<EditInformationDialog> createState() => _EditInformationDialogState();
}

class _EditInformationDialogState extends State<EditInformationDialog> {
  final _form = GlobalKey<FormState>();
  var _autovalidate = AutovalidateMode.disabled;
  late final _name = TextEditingController(text: widget.player.name);
  late final _username = TextEditingController(text: widget.player.username);
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_form.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }

    // Only what the player edited goes to the repository.
    final name = _name.text.trim();
    final username = Usernames.normalize(_username.text);
    final nameChanged = name != widget.player.name;
    final usernameChanged = username != widget.player.username;
    if (!nameChanged && !usernameChanged) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await context.read<HomeProvider>().updateProfile(
        name: nameChanged ? name : null,
        username: usernameChanged ? username : null,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AccountException catch (e) {
      _fail(AccountProvider.messageFor(e.error));
    } catch (e) {
      debugPrint('Could not update the profile: $e');
      _fail('Something went wrong. Please try again.');
    }
  }

  void _fail(String error) {
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SettingsDialog(
      title: 'Edit information',
      message: 'After changing your username, log in with the new one.',
      actionLabel: 'Save',
      onAction: _save,
      isLoading: _isSaving,
      error: _error,
      children: [
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
            ],
          ),
        ),
      ],
    );
  }
}
