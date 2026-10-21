import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AccountTextField extends StatefulWidget {
  const AccountTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.isPassword = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final FormFieldValidator<String>? validator;
  final bool isPassword;

  @override
  State<AccountTextField> createState() => _AccountTextFieldState();
}

class _AccountTextFieldState extends State<AccountTextField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: color, width: width),
        );

    return SizedBox(
      width: 262,
      child: TextFormField(
        controller: widget.controller,
        validator: widget.validator,
        obscureText: widget.isPassword && _hidden,
        autocorrect: !widget.isPassword,
        style: AppTextStyles.fieldInput,
        cursorColor: AppColors.brown,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: AppTextStyles.fieldLabel,
          floatingLabelStyle: AppTextStyles.fieldLabel,
          hintStyle: AppTextStyles.fieldHint,
          errorStyle: AppTextStyles.fieldError,
          errorMaxLines: 2,
          contentPadding: const EdgeInsets.all(16),
          enabledBorder: border(AppColors.fieldOutline),
          focusedBorder: border(AppColors.brown, 2),
          errorBorder: border(AppColors.resultIncorrect),
          focusedErrorBorder: border(AppColors.resultIncorrect, 2),
          suffixIcon: widget.isPassword
              ? IconButton(
                  onPressed: () => setState(() => _hidden = !_hidden),
                  tooltip: _hidden ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.fieldLabel,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
