import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';

const _gold = Color(0xFFF2A900);
const _goldLight = Color(0xFFFFD23C);
const _muted = Color(0xFFA9ABB2);
const _field = Color(0xFF0B111D);
const _border = Color(0xFF303541);

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.52),
            radius: 1.18,
            colors: [Color(0xFF071735), Color(0xFF020712), Color(0xFF01040B)],
            stops: [0, 0.48, 1],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 30),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _AfaLogo(),
                    const SizedBox(height: 14),
                    const Text(
                      'Create Your Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Let's get you started with AFA",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, fontSize: 20),
                    ),
                    const SizedBox(height: 28),
                    const _StepIndicator(currentStep: 1, steps: 6),
                    const SizedBox(height: 28),
                    const _FieldLabel('First Name'),
                    const SizedBox(height: 8),
                    const _AfaTextField(
                      hint: 'Enter first name',
                      icon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Last Name'),
                    const SizedBox(height: 8),
                    const _AfaTextField(
                      hint: 'Enter last name',
                      icon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Username'),
                    const SizedBox(height: 8),
                    const _AfaTextField(
                      hint: 'Choose a username',
                      icon: Icons.alternate_email_rounded,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Country'),
                    const SizedBox(height: 8),
                    const _CountrySelector(),
                    const SizedBox(height: 16),
                    const _FieldLabel('Phone Number'),
                    const SizedBox(height: 8),
                    const _PhoneNumberField(),
                    const SizedBox(height: 16),
                    const _FieldLabel('Email Address'),
                    const SizedBox(height: 8),
                    const _AfaTextField(
                      hint: 'Enter email address',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Password'),
                    const SizedBox(height: 8),
                    _AfaTextField(
                      hint: 'Create password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Confirm Password'),
                    const SizedBox(height: 8),
                    _AfaTextField(
                      hint: 'Confirm password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        tooltip: _obscureConfirmPassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _PasswordChecklist(),
                    const SizedBox(height: 18),
                    _AgreementRow(
                      value: _acceptedTerms,
                      onChanged: (value) =>
                          setState(() => _acceptedTerms = value ?? false),
                      label: 'I agree to the ',
                      linkLabel: 'Terms & Conditions',
                    ),
                    const SizedBox(height: 8),
                    _AgreementRow(
                      value: _acceptedPrivacy,
                      onChanged: (value) =>
                          setState(() => _acceptedPrivacy = value ?? false),
                      label: 'I agree to the ',
                      linkLabel: 'Privacy Policy',
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 64,
                      child: FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Flexible(
                          child: Text(
                            'Already have an account? ',
                            style: TextStyle(color: _muted, fontSize: 16),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: _gold,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AfaLogo extends StatelessWidget {
  const _AfaLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 96,
          height: 88,
          child: Stack(
            alignment: Alignment.center,
            children: const [
              Positioned(top: 0, child: _GoldCoin()),
              Positioned(left: 9, bottom: 0, child: _GoldCoin()),
              Positioned(right: 9, bottom: 0, child: _GoldCoin()),
            ],
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_goldLight, _gold, Color(0xFF9E6500)],
          ).createShader(bounds),
          child: const Text(
            'AFA',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              height: 0.88,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'ALL FEATURES AFRICA',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}

class _GoldCoin extends StatelessWidget {
  const _GoldCoin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_goldLight, _gold, Color(0xFF8D5B00)],
        ),
        border: Border.all(color: const Color(0xFFFFE184), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x662C1C00),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.eco_rounded, size: 26, color: Color(0xFF241700)),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.steps});

  final int currentStep;
  final int steps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps * 2 - 1, (index) {
        if (index.isOdd) {
          final active = index < (currentStep * 2 - 1);
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: active ? _gold : _border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }
        final step = (index ~/ 2) + 1;
        final active = step == currentStep;
        return Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? _gold : _field.withValues(alpha: 0.88),
            border: Border.all(color: active ? _gold : _border, width: 1.4),
          ),
          child: Text(
            '$step',
            style: TextStyle(
              color: active ? Colors.black : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      }),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    );
  }
}

class _AfaTextField extends StatelessWidget {
  const _AfaTextField({
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.textInputAction,
  });

  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      style: const TextStyle(fontSize: 17),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class _CountrySelector extends StatelessWidget {
  const _CountrySelector();

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      child: Row(
        children: const [
          Icon(Icons.language_rounded, color: _muted, size: 28),
          SizedBox(width: 18),
          Text('🇬🇭', style: TextStyle(fontSize: 25)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ghana (+233)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: _muted, size: 30),
        ],
      ),
    );
  }
}

class _PhoneNumberField extends StatelessWidget {
  const _PhoneNumberField();

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      child: Row(
        children: const [
          Icon(Icons.phone_iphone_rounded, color: _muted, size: 28),
          SizedBox(width: 20),
          Text(
            '+233',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          SizedBox(width: 6),
          Icon(Icons.keyboard_arrow_down_rounded, color: _muted, size: 26),
          SizedBox(width: 18),
          SizedBox(
            height: 34,
            child: VerticalDivider(color: _border, width: 1),
          ),
          SizedBox(width: 22),
          Expanded(
            child: Text(
              'Enter phone number',
              style: TextStyle(color: _muted, fontSize: 17),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _field.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Center(child: child),
    );
  }
}

class _PasswordChecklist extends StatelessWidget {
  const _PasswordChecklist();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: _field.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password must contain:',
            style: TextStyle(color: _muted, fontSize: 16),
          ),
          SizedBox(height: 8),
          _ChecklistItem('At least 8 characters'),
          _ChecklistItem('One uppercase letter'),
          _ChecklistItem('One number'),
          _ChecklistItem('One special character'),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _gold, width: 1.5),
            ),
            child: const Icon(Icons.check_rounded, color: _gold, size: 13),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: _muted, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.linkLabel,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final String linkLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: _gold,
            checkColor: Colors.black,
            side: const BorderSide(color: _muted, width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: _muted, fontSize: 16),
              children: [
                TextSpan(text: label),
                TextSpan(
                  text: linkLabel,
                  style: const TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.w700,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
