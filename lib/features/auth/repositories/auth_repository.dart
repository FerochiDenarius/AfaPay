import '../models/email_verification_request.dart';
import '../models/email_verification_response.dart';
import '../models/otp_verification_request.dart';
import '../models/otp_verification_response.dart';

abstract interface class AuthRepository {
  Future<OtpVerificationResponse> verifyPhoneOtp(
    OtpVerificationRequest request,
  );

  Future<void> resendOtp({required String userId});

  Future<EmailVerificationResponse> sendEmailVerification(
    EmailVerificationRequest request,
  );

  Future<OtpVerificationResponse> verifyEmailOtp({
    required String userId,
    required String email,
    required String otp,
  });

  Future<void> resendEmailVerification({
    required String userId,
    required String email,
  });
}

class FrontendAuthRepository implements AuthRepository {
  const FrontendAuthRepository();

  @override
  Future<OtpVerificationResponse> verifyPhoneOtp(
    OtpVerificationRequest request,
  ) async {
    // Frontend-only placeholder for POST /api/auth/verify-phone.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const OtpVerificationResponse(
      success: true,
      verified: true,
      nextStep: 'pin_setup',
    );
  }

  @override
  Future<void> resendOtp({required String userId}) async {
    // Frontend-only placeholder for AuthService.resendOtp().
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }

  @override
  Future<EmailVerificationResponse> sendEmailVerification(
    EmailVerificationRequest request,
  ) async {
    // Frontend-only placeholder for POST /api/auth/send-email-verification.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return EmailVerificationResponse(
      success: true,
      message: 'Verification code sent',
      email: request.email,
    );
  }

  @override
  Future<OtpVerificationResponse> verifyEmailOtp({
    required String userId,
    required String email,
    required String otp,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const OtpVerificationResponse(
      success: true,
      verified: true,
      nextStep: 'onboarding_complete',
    );
  }

  @override
  Future<void> resendEmailVerification({
    required String userId,
    required String email,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }
}
