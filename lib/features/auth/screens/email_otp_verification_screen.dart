import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/email_otp_verification_provider.dart';
import '../widgets/email_security_illustration.dart';
import '../widgets/onboarding_stepper.dart';
import '../widgets/otp_code_field.dart';

const _gold = Color(0xFFF5B81F);
const _muted = Color(0xFFA9ABB2);

class EmailOtpVerificationScreen extends ConsumerStatefulWidget {
  const EmailOtpVerificationScreen({
    super.key,
    required this.userId,
    required this.email,
  });

  final String userId;
  final String email;

  @override
  ConsumerState<EmailOtpVerificationScreen> createState() =>
      _EmailOtpVerificationScreenState();
}

class _EmailOtpVerificationScreenState
    extends ConsumerState<EmailOtpVerificationScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final response = await ref
        .read(emailOtpVerificationProvider.notifier)
        .verify(userId: widget.userId, email: widget.email);
    if (!mounted) return;
    if (response.success && response.verified) {
      context.go('/dashboard');
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(response.message ?? 'Invalid code')));
  }

  Future<void> _resend() async {
    final sent = await ref
        .read(emailOtpVerificationProvider.notifier)
        .resend(userId: widget.userId, email: widget.email);
    if (!mounted) return;
    if (sent) {
      _controller.clear();
      _focusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new code was sent to your email.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emailOtpVerificationProvider);
    ref.listen(emailOtpVerificationProvider, (previous, next) {
      if (_controller.text != next.otp) {
        _controller.value = TextEditingValue(
          text: next.otp,
          selection: TextSelection.collapsed(offset: next.otp.length),
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.25,
            colors: [Color(0xFF02153D), Color(0xFF010B1F), Color(0xFF010714)],
            stops: [0, 0.6, 1],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(30, 12, 30, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Back',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () => context.go(
                          '/email-verification',
                          extra: <String, String>{
                            'userId': widget.userId,
                            'email': widget.email,
                          },
                        ),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                    ),
                    const SizedBox(height: 27),
                    Semantics(
                      header: true,
                      child: const Text(
                        'Verify Your Email',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 31,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'Please enter the 6-digit code sent to',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, fontSize: 18),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      widget.email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const OnboardingStepper(currentStep: 5, completedSteps: 4),
                    const SizedBox(height: 29),
                    const EmailSecurityIllustration(),
                    const SizedBox(height: 28),
                    const Text(
                      'Enter 6-digit code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "We've sent a 6-digit verification code\n"
                      'to your email address.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 16.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 31),
                    OtpCodeField(
                      controller: _controller,
                      focusNode: _focusNode,
                      otp: state.otp,
                      onChanged: ref
                          .read(emailOtpVerificationProvider.notifier)
                          .updateOtp,
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        state.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFFF7373)),
                      ),
                    ],
                    const SizedBox(height: 31),
                    _EmailResendRow(
                      secondsRemaining: state.secondsRemaining,
                      isResending: state.isResending,
                      onResend: state.canResend ? _resend : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 62,
                      child: FilledButton(
                        onPressed: state.canVerify ? _verify : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: _gold,
                          disabledBackgroundColor: const Color(0xFF5B4C24),
                          foregroundColor: Colors.black,
                          disabledForegroundColor: const Color(0xFFAAA18E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: state.isVerifying
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
          ),
        ),
      ),
    );
  }
}

class _EmailResendRow extends StatelessWidget {
  const _EmailResendRow({
    required this.secondsRemaining,
    required this.isResending,
    required this.onResend,
  });

  final int secondsRemaining;
  final bool isResending;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final timer = '00:${secondsRemaining.toString().padLeft(2, '0')}';
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          "Didn't receive code? ",
          style: TextStyle(color: _muted, fontSize: 16),
        ),
        GestureDetector(
          onTap: onResend,
          child: Text(
            isResending ? 'Sending... ' : 'Resend code ',
            style: TextStyle(
              color: secondsRemaining == 0 ? _gold : _muted,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (secondsRemaining > 0)
          Text(timer, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
