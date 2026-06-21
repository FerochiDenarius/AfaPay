import 'package:afa_pay/features/auth/models/email_verification_request.dart';
import 'package:afa_pay/features/auth/models/email_verification_response.dart';
import 'package:afa_pay/features/auth/models/otp_verification_request.dart';
import 'package:afa_pay/features/auth/models/otp_verification_response.dart';
import 'package:afa_pay/features/auth/providers/phone_verification_provider.dart';
import 'package:afa_pay/features/auth/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  late FakeAuthRepository repository;
  late ProviderSubscription<PhoneVerificationState> subscription;

  setUp(() {
    repository = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    subscription = container.listen(phoneVerificationProvider, (_, _) {});
  });

  tearDown(() {
    subscription.close();
    container.dispose();
  });

  test('OTP must contain exactly six digits', () {
    final notifier = container.read(phoneVerificationProvider.notifier);

    notifier.updateOtp('12a34');
    expect(container.read(phoneVerificationProvider).otp, '1234');
    expect(container.read(phoneVerificationProvider).isOtpValid, isFalse);

    notifier.updateOtp('1234567');
    expect(container.read(phoneVerificationProvider).otp, '123456');
    expect(container.read(phoneVerificationProvider).isOtpValid, isTrue);
  });

  test('verify button state follows OTP validity and loading state', () {
    final notifier = container.read(phoneVerificationProvider.notifier);
    expect(container.read(phoneVerificationProvider).canVerify, isFalse);

    notifier.updateOtp('123456');
    expect(container.read(phoneVerificationProvider).canVerify, isTrue);
  });

  test('countdown timer decreases once per second', () async {
    expect(container.read(phoneVerificationProvider).secondsRemaining, 60);

    await Future<void>.delayed(const Duration(milliseconds: 1100));

    expect(container.read(phoneVerificationProvider).secondsRemaining, 59);
  });

  test('resend is enabled at zero and restarts the timer', () async {
    final notifier = container.read(phoneVerificationProvider.notifier);
    notifier.expireResendTimer();
    expect(container.read(phoneVerificationProvider).canResend, isTrue);

    final sent = await notifier.resend(userId: 'user-1');

    expect(sent, isTrue);
    expect(repository.resendCalls, 1);
    expect(container.read(phoneVerificationProvider).secondsRemaining, 60);
    expect(container.read(phoneVerificationProvider).canResend, isFalse);
  });

  test('verification forwards the contract and returns success', () async {
    final notifier = container.read(phoneVerificationProvider.notifier);
    notifier.updateOtp('123456');

    final response = await notifier.verify(userId: 'user-1');

    expect(response.verified, isTrue);
    expect(repository.lastRequest?.toJson(), {
      'userId': 'user-1',
      'otp': '123456',
    });
    expect(container.read(phoneVerificationProvider).isVerifying, isFalse);
  });
}

class FakeAuthRepository implements AuthRepository {
  int resendCalls = 0;
  OtpVerificationRequest? lastRequest;

  @override
  Future<void> resendEmailVerification({
    required String userId,
    required String email,
  }) async {}

  @override
  Future<void> resendOtp({required String userId}) async {
    resendCalls++;
  }

  @override
  Future<EmailVerificationResponse> sendEmailVerification(
    EmailVerificationRequest request,
  ) async {
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
    return const OtpVerificationResponse(success: true, verified: true);
  }

  @override
  Future<OtpVerificationResponse> verifyPhoneOtp(
    OtpVerificationRequest request,
  ) async {
    lastRequest = request;
    return const OtpVerificationResponse(
      success: true,
      verified: true,
      nextStep: 'pin_setup',
    );
  }
}
