import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/email_verification_provider.dart';
import '../widgets/email_security_illustration.dart';
import '../widgets/onboarding_stepper.dart';

const _gold = Color(0xFFF5B81F);
const _muted = Color(0xFFA9ABB2);

class EmailVerificationEntryScreen extends ConsumerStatefulWidget {
  const EmailVerificationEntryScreen({
    super.key,
    required this.userId,
    this.initialEmail = '',
  });

  final String userId;
  final String initialEmail;

  @override
  ConsumerState<EmailVerificationEntryScreen> createState() =>
      _EmailVerificationEntryScreenState();
}

class _EmailVerificationEntryScreenState
    extends ConsumerState<EmailVerificationEntryScreen> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    if (widget.initialEmail.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(emailVerificationProvider.notifier)
            .updateEmail(widget.initialEmail);
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final response = await ref
        .read(emailVerificationProvider.notifier)
        .sendCode(userId: widget.userId);
    if (!mounted) return;
    if (response.success) {
      context.go(
        '/email-verification-code',
        extra: <String, String>{
          'userId': widget.userId,
          'email':
              response.email ??
              ref.read(emailVerificationProvider).normalizedEmail,
        },
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(response.message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emailVerificationProvider);
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go(
                                '/pin-setup',
                                extra: <String, String>{
                                  'userId': widget.userId,
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
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'Please enter your email address\n'
                      'to receive a verification code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 18,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 31),
                    const OnboardingStepper(currentStep: 5, completedSteps: 4),
                    const SizedBox(height: 29),
                    const EmailSecurityIllustration(),
                    const SizedBox(height: 28),
                    const Text(
                      'Email Address',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      label: 'Email address for verification',
                      textField: true,
                      child: TextField(
                        controller: _emailController,
                        enabled: !state.isSubmitting,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.none,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        enableSuggestions: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                          LengthLimitingTextInputFormatter(254),
                        ],
                        onChanged: ref
                            .read(emailVerificationProvider.notifier)
                            .updateEmail,
                        onSubmitted: (_) {
                          if (state.canSubmit) _sendCode();
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter your email address',
                          prefixIcon: const Icon(Icons.mail_outline_rounded),
                          suffixIcon: const Icon(
                            Icons.contact_mail_outlined,
                            color: _gold,
                          ),
                          errorText: state.visibleValidationError,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF30394A),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: _gold,
                              width: 1.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (state.errorMessage != null &&
                        state.errorMessage != state.visibleValidationError) ...[
                      const SizedBox(height: 8),
                      Text(
                        state.errorMessage!,
                        style: const TextStyle(color: Color(0xFFFF7373)),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: _gold,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            "We'll never share your email with anyone",
                            style: TextStyle(color: _muted, fontSize: 15.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 31),
                    SizedBox(
                      height: 62,
                      child: FilledButton(
                        onPressed: state.canSubmit ? _sendCode : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: _gold,
                          disabledBackgroundColor: const Color(0xFF5B4C24),
                          foregroundColor: Colors.black,
                          disabledForegroundColor: const Color(0xFFAAA18E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: state.isSubmitting
                            ? const SizedBox(
                                width: 25,
                                height: 25,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2.6,
                                ),
                              )
                            : const Text(
                                'Send Verification Code',
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
