import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/registration_provider.dart';
import '../services/auth_service.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/country_selector.dart';
import '../widgets/onboarding_stepper.dart';
import '../widgets/password_strength_card.dart';

const _gold = Color(0xFFF5B81F);
const _muted = Color(0xFFA9ABB2);

class RegistrationPage extends StatelessWidget {
  const RegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegistrationProvider(),
      child: const _RegistrationView(),
    );
  }
}

class _RegistrationView extends StatefulWidget {
  const _RegistrationView();

  @override
  State<_RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<_RegistrationView> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit(RegistrationProvider registration) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false) ||
        !registration.canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    try {
      final result = await registration.register();
      if (!mounted) return;
      if (result.success && result.verificationRequired) {
        if (result.nextStep == 'verify_phone') {
          context.push(
            '/verify-phone',
            extra: <String, String>{
              'userId': result.userId,
              'phoneNumber': registration.formattedPhoneNumber,
              'email': registration.email.trim().toLowerCase(),
            },
          );
          return;
        }
        context.go(
          '/pin-setup',
          extra: <String, String>{
            'userId': result.userId,
            'email': registration.email.trim().toLowerCase(),
          },
        );
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final registration = context.watch<RegistrationProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.45),
            radius: 1.18,
            colors: [Color(0xFF071735), Color(0xFF020712), Color(0xFF01040B)],
            stops: [0, 0.5, 1],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(28, 6, 28, 30),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _AfaLogo(),
                      const SizedBox(height: 10),
                      const Text(
                        'Create Your Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 31,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        "Let's get you started with AFA",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted, fontSize: 19),
                      ),
                      const SizedBox(height: 28),
                      const OnboardingStepper(),
                      const SizedBox(height: 28),
                      AuthTextField(
                        label: 'First Name',
                        hintText: 'Enter first name',
                        prefixIcon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        onChanged: registration.setFirstName,
                        validator: (_) => registration.firstNameError,
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'Last Name',
                        hintText: 'Enter last name',
                        prefixIcon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        onChanged: registration.setLastName,
                        validator: (_) => registration.lastNameError,
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'Username',
                        hintText: 'Choose a username',
                        prefixIcon: Icons.alternate_email_rounded,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9_]'),
                          ),
                          LengthLimitingTextInputFormatter(20),
                        ],
                        onChanged: registration.setUsername,
                        validator: (_) => registration.usernameError,
                      ),
                      const SizedBox(height: 16),
                      CountrySelector(
                        selectedCountry: registration.selectedCountry,
                        onSelected: (country) {
                          _phoneController.clear();
                          registration.selectCountry(country);
                        },
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hintText: 'Enter phone number',
                        prefixIcon: Icons.phone_iphone_rounded,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(
                            registration.selectedCountry.localNumberLength + 1,
                          ),
                        ],
                        prefix: _PhonePrefix(
                          dialCode: registration.selectedCountry.dialCode,
                        ),
                        onChanged: registration.setPhoneNumber,
                        validator: (_) => registration.phoneError,
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'Email Address',
                        hintText: 'Enter email address',
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onChanged: registration.setEmail,
                        validator: (_) => registration.emailError,
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'Password',
                        hintText: 'Create password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: registration.obscurePassword,
                        textInputAction: TextInputAction.next,
                        suffixIcon: IconButton(
                          tooltip: registration.obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: registration.togglePasswordVisibility,
                          icon: Icon(
                            registration.obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                        onChanged: registration.setPassword,
                        validator: (_) => registration.passwordError,
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'Confirm Password',
                        hintText: 'Confirm password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: registration.obscureConfirmPassword,
                        suffixIcon: IconButton(
                          tooltip: registration.obscureConfirmPassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed:
                              registration.toggleConfirmPasswordVisibility,
                          icon: Icon(
                            registration.obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                        onChanged: registration.setConfirmPassword,
                        validator: (_) => registration.confirmPasswordError,
                      ),
                      const SizedBox(height: 14),
                      PasswordStrengthCard(
                        hasMinimumLength: registration.hasMinimumLength,
                        hasUppercase: registration.hasUppercase,
                        hasNumber: registration.hasNumber,
                        hasSpecialCharacter: registration.hasSpecialCharacter,
                      ),
                      const SizedBox(height: 18),
                      _AgreementRow(
                        value: registration.acceptedTerms,
                        onChanged: registration.setAcceptedTerms,
                        label: 'I agree to the ',
                        linkLabel: 'Terms & Conditions',
                      ),
                      const SizedBox(height: 9),
                      _AgreementRow(
                        value: registration.acceptedPrivacy,
                        onChanged: registration.setAcceptedPrivacy,
                        label: 'I agree to the ',
                        linkLabel: 'Privacy Policy',
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 62,
                        child: FilledButton(
                          onPressed: registration.canSubmit
                              ? () => _submit(registration)
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: _gold,
                            disabledBackgroundColor: const Color(0xFF5B4C24),
                            foregroundColor: Colors.black,
                            disabledForegroundColor: const Color(0xFFAAA18E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: registration.isLoading
                              ? const SizedBox(
                                  width: 25,
                                  height: 25,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.6,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 23),
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
                            onTap: () => context.go('/login'),
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
      ),
    );
  }
}

class _AfaLogo extends StatelessWidget {
  const _AfaLogo();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'AFA All Features Africa',
      image: true,
      child: SizedBox(
        height: 116,
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final pageWidth = MediaQuery.sizeOf(
                context,
              ).width.clamp(0, 520).toDouble();
              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    top: -pageWidth * 0.035,
                    left: -(pageWidth - constraints.maxWidth) / 2,
                    width: pageWidth,
                    child: Image.asset(
                      'UIdesignImages/registrationsPage.png',
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 20,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xFF051027)],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PhonePrefix extends StatelessWidget {
  const _PhonePrefix({required this.dialCode});

  final String dialCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.phone_iphone_rounded, color: _muted, size: 25),
          const SizedBox(width: 13),
          Text(
            dialCode,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 9),
          const SizedBox(
            height: 32,
            child: VerticalDivider(color: Color(0xFF303541), width: 1),
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
  final ValueChanged<bool> onChanged;
  final String label;
  final String linkLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: (checked) => onChanged(checked ?? false),
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
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(label, style: const TextStyle(color: _muted, fontSize: 16)),
              GestureDetector(
                onTap: () {},
                child: Text(
                  linkLabel,
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
