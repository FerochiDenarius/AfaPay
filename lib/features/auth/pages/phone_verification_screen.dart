import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/phone_verification_provider.dart';
import '../widgets/onboarding_stepper.dart';
import '../widgets/otp_code_field.dart';

const _gold = Color(0xFFF5B81F);
const _muted = Color(0xFFA9ABB2);

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({
    super.key,
    required this.userId,
    required this.phoneNumber,
    this.email = '',
  });

  final String userId;
  final String phoneNumber;
  final String email;

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final response = await ref
        .read(phoneVerificationProvider.notifier)
        .verify(userId: widget.userId);
    if (!mounted) return;
    if (response.success && response.verified) {
      context.go(
        '/pin-setup',
        extra: <String, String>{'userId': widget.userId, 'email': widget.email},
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(response.message ?? 'Invalid code')));
  }

  Future<void> _resend() async {
    final sent = await ref
        .read(phoneVerificationProvider.notifier)
        .resend(userId: widget.userId);
    if (!mounted) return;
    if (sent) {
      _otpController.clear();
      _otpFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new verification code was sent.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final verification = ref.watch(phoneVerificationProvider);
    ref.listen(phoneVerificationProvider, (previous, next) {
      if (_otpController.text != next.otp) {
        _otpController.value = TextEditingValue(
          text: next.otp,
          selection: TextSelection.collapsed(offset: next.otp.length),
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.55),
            radius: 1.2,
            colors: [Color(0xFF071735), Color(0xFF020712), Color(0xFF01040B)],
            stops: [0, 0.52, 1],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 520,
                      minHeight: constraints.maxHeight - 36,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Back',
                              onPressed: () => context.canPop()
                                  ? context.pop()
                                  : context.go('/register'),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => context.go(
                                '/pin-setup',
                                extra: <String, String>{
                                  'userId': widget.userId,
                                  'email': widget.email,
                                },
                              ),
                              child: const Text(
                                'Skip for now',
                                style: TextStyle(
                                  color: _gold,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const OnboardingStepper(
                          currentStep: 2,
                          completedSteps: 1,
                        ),
                        const SizedBox(height: 54),
                        Container(
                          width: 82,
                          height: 82,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _gold.withValues(alpha: 0.12),
                            border: Border.all(
                              color: _gold.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Icon(
                            Icons.sms_outlined,
                            color: _gold,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Verify Your Phone',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 31,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 11),
                        const Text(
                          "We've sent a 6-digit code to",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _muted, fontSize: 17),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.phoneNumber,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 42),
                        OtpCodeField(
                          controller: _otpController,
                          focusNode: _otpFocusNode,
                          otp: verification.otp,
                          onChanged: ref
                              .read(phoneVerificationProvider.notifier)
                              .updateOtp,
                        ),
                        if (verification.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            verification.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFF7373),
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 30),
                        _ResendSection(
                          secondsRemaining: verification.secondsRemaining,
                          isResending: verification.isResending,
                          onResend: verification.canResend ? _resend : null,
                        ),
                        const SizedBox(height: 80),
                        SizedBox(
                          height: 62,
                          child: FilledButton(
                            onPressed: verification.canVerify ? _verify : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: _gold,
                              disabledBackgroundColor: const Color(0xFF5B4C24),
                              foregroundColor: Colors.black,
                              disabledForegroundColor: const Color(0xFFAAA18E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: verification.isVerifying
                                ? const SizedBox(
                                    width: 25,
                                    height: 25,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.6,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Text(
                                    'Verify & Continue',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ResendSection extends StatelessWidget {
  const _ResendSection({
    required this.secondsRemaining,
    required this.isResending,
    required this.onResend,
  });

  final int secondsRemaining;
  final bool isResending;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final countdown = '00:${secondsRemaining.toString().padLeft(2, '0')}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Didn't receive code? ",
          style: TextStyle(color: _muted, fontSize: 16),
        ),
        if (secondsRemaining > 0)
          Text(
            'Resend in $countdown',
            style: const TextStyle(color: _gold, fontSize: 16),
          )
        else if (isResending)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: _gold),
          )
        else
          GestureDetector(
            onTap: onResend,
            child: const Text(
              'Resend',
              style: TextStyle(
                color: _gold,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
