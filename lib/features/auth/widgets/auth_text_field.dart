import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    required this.onChanged,
    this.validator,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.prefix,
    this.inputFormatters,
  });

  final String label;
  final String hintText;
  final IconData prefixIcon;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String>? validator;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefix;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 17),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefix ?? Icon(prefixIcon),
            suffixIcon: suffixIcon,
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}
