import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/email_verification_request.dart';
import '../models/email_verification_response.dart';
import '../repositories/http_auth_repository.dart';
import 'phone_verification_provider.dart';

final emailVerificationProvider =
    NotifierProvider.autoDispose<
      EmailVerificationNotifier,
      EmailVerificationState
    >(EmailVerificationNotifier.new);

class EmailVerificationState {
  const EmailVerificationState({
    this.email = '',
    this.hasInteracted = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final String email;
  final bool hasInteracted;
  final bool isSubmitting;
  final String? errorMessage;

  String get normalizedEmail => email.trim().toLowerCase();
  String? get validationError => EmailVerificationNotifier.validateEmail(email);
  String? get visibleValidationError => hasInteracted ? validationError : null;
  bool get canSubmit => validationError == null && !isSubmitting;

  EmailVerificationState copyWith({
    String? email,
    bool? hasInteracted,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EmailVerificationState(
      email: email ?? this.email,
      hasInteracted: hasInteracted ?? this.hasInteracted,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class EmailVerificationNotifier extends Notifier<EmailVerificationState> {
  static final _emailPattern = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@"
    r'[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
    r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
  );

  @override
  EmailVerificationState build() => const EmailVerificationState();

  static String? validateEmail(String input) {
    final email = input.trim();
    if (email.isEmpty) return 'Email address is required';
    if (email.length > 254) return 'Email must not exceed 254 characters';
    if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  void updateEmail(String value) {
    state = state.copyWith(email: value, hasInteracted: true, clearError: true);
  }

  Future<EmailVerificationResponse> sendCode({required String userId}) async {
    final validationError = state.validationError;
    if (validationError != null) {
      state = state.copyWith(
        hasInteracted: true,
        errorMessage: validationError,
      );
      return EmailVerificationResponse(
        success: false,
        message: validationError,
      );
    }
    if (state.isSubmitting) {
      return const EmailVerificationResponse(
        success: false,
        message: 'A request is already in progress',
      );
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final response = await ref
          .read(authRepositoryProvider)
          .sendEmailVerification(
            EmailVerificationRequest(
              userId: userId,
              email: state.normalizedEmail,
            ),
          );
      if (!response.success) {
        state = state.copyWith(errorMessage: response.message);
      }
      return response;
    } catch (error) {
      final message = error is AuthApiException
          ? error.message
          : 'Unable to send a verification code. Please try again.';
      state = state.copyWith(errorMessage: message);
      return EmailVerificationResponse(success: false, message: message);
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
