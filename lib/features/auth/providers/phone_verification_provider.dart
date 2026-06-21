import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_config.dart';
import '../models/otp_verification_request.dart';
import '../models/otp_verification_response.dart';
import '../repositories/auth_repository.dart';
import '../repositories/http_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ApiConfig.useMockAuth
      ? const FrontendAuthRepository()
      : HttpAuthRepository(),
);

final phoneVerificationProvider =
    NotifierProvider.autoDispose<
      PhoneVerificationNotifier,
      PhoneVerificationState
    >(PhoneVerificationNotifier.new);

class PhoneVerificationState {
  const PhoneVerificationState({
    this.otp = '',
    this.secondsRemaining = 60,
    this.isVerifying = false,
    this.isResending = false,
    this.errorMessage,
  });

  final String otp;
  final int secondsRemaining;
  final bool isVerifying;
  final bool isResending;
  final String? errorMessage;

  bool get isOtpValid => RegExp(r'^\d{6}$').hasMatch(otp);
  bool get canVerify => isOtpValid && !isVerifying;
  bool get canResend => secondsRemaining == 0 && !isResending;

  PhoneVerificationState copyWith({
    String? otp,
    int? secondsRemaining,
    bool? isVerifying,
    bool? isResending,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PhoneVerificationState(
      otp: otp ?? this.otp,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isVerifying: isVerifying ?? this.isVerifying,
      isResending: isResending ?? this.isResending,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class PhoneVerificationNotifier extends Notifier<PhoneVerificationState> {
  Timer? _timer;

  @override
  PhoneVerificationState build() {
    ref.onDispose(() => _timer?.cancel());
    _startTimer();
    return const PhoneVerificationState();
  }

  void updateOtp(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    state = state.copyWith(
      otp: digits.length > 6 ? digits.substring(0, 6) : digits,
      clearError: true,
    );
  }

  Future<OtpVerificationResponse> verify({required String userId}) async {
    if (!state.isOtpValid) {
      const message = 'Enter the complete 6-digit code.';
      state = state.copyWith(errorMessage: message);
      return const OtpVerificationResponse(
        success: false,
        verified: false,
        message: message,
      );
    }

    state = state.copyWith(isVerifying: true, clearError: true);
    try {
      final response = await ref
          .read(authRepositoryProvider)
          .verifyPhoneOtp(
            OtpVerificationRequest(userId: userId, otp: state.otp),
          );
      if (!response.success || !response.verified) {
        state = state.copyWith(
          errorMessage: response.message ?? 'Invalid code',
        );
      }
      return response;
    } catch (error) {
      final message = error is AuthApiException
          ? error.message
          : 'Unable to verify the code. Please try again.';
      state = state.copyWith(errorMessage: message);
      return OtpVerificationResponse(
        success: false,
        verified: false,
        message: message,
      );
    } finally {
      state = state.copyWith(isVerifying: false);
    }
  }

  Future<bool> resend({required String userId}) async {
    if (!state.canResend) return false;
    state = state.copyWith(isResending: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).resendOtp(userId: userId);
      state = state.copyWith(otp: '', secondsRemaining: 60);
      _startTimer();
      return true;
    } catch (error) {
      state = state.copyWith(
        errorMessage: error is AuthApiException
            ? error.message
            : 'Unable to resend the code. Please try again.',
      );
      return false;
    } finally {
      state = state.copyWith(isResending: false);
    }
  }

  @visibleForTesting
  void expireResendTimer() {
    _timer?.cancel();
    state = state.copyWith(secondsRemaining: 0);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.secondsRemaining <= 1) {
        state = state.copyWith(secondsRemaining: 0);
        timer.cancel();
      } else {
        state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
      }
    });
  }
}
