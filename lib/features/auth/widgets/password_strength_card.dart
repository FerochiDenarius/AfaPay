import 'package:flutter/material.dart';

class PasswordStrengthCard extends StatelessWidget {
  const PasswordStrengthCard({
    super.key,
    required this.hasMinimumLength,
    required this.hasUppercase,
    required this.hasNumber,
    required this.hasSpecialCharacter,
  });

  final bool hasMinimumLength;
  final bool hasUppercase;
  final bool hasNumber;
  final bool hasSpecialCharacter;

  static const _gold = Color(0xFFF5B81F);
  static const _muted = Color(0xFFA9ABB2);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 11),
      decoration: BoxDecoration(
        color: const Color(0xFF0B111D).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF303541)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password must contain:',
            style: TextStyle(color: _muted, fontSize: 16),
          ),
          const SizedBox(height: 8),
          _Requirement(label: 'At least 8 characters', isMet: hasMinimumLength),
          _Requirement(label: 'One uppercase letter', isMet: hasUppercase),
          _Requirement(label: 'One number', isMet: hasNumber),
          _Requirement(
            label: 'One special character',
            isMet: hasSpecialCharacter,
          ),
        ],
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.label, required this.isMet});

  final String label;
  final bool isMet;

  @override
  Widget build(BuildContext context) {
    final color = isMet
        ? PasswordStrengthCard._gold
        : PasswordStrengthCard._muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMet ? PasswordStrengthCard._gold : Colors.transparent,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(
              Icons.check_rounded,
              color: isMet ? Colors.black : color,
              size: 13,
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontSize: 15)),
        ],
      ),
    );
  }
}
