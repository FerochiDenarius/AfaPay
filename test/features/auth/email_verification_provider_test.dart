import 'package:afa_pay/features/auth/models/email_verification_request.dart';
import 'package:afa_pay/features/auth/models/email_verification_response.dart';
import 'package:afa_pay/features/auth/models/otp_verification_request.dart';
import 'package:afa_pay/features/auth/models/otp_verification_response.dart';
import 'package:afa_pay/features/auth/providers/email_verification_provider.dart';
import 'package:afa_pay/features/auth/providers/phone_verification_provider.dart';
import 'package:afa_pay/features/auth/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  late EmailRepositoryFake repository;
  late ProviderSubscription<EmailVerificationState> subscription;

  setUp(() {
    repository = EmailRepositoryFake();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    subscription = container.listen(emailVerificationProvider, (_, _) {});
  });

  tearDown(() {
    subscription.close();
    container.dispose();
  });

  test('rejects an empty email', () {
    expect(
      EmailVerificationNotifier.validateEmail(''),
      'Email address is required',
    );
    expect(container.read(emailVerificationProvider).canSubmit, isFalse);
  });

  test('rejects invalid email formats', () {
    expect(
      EmailVerificationNotifier.validateEmail('not-an-email'),
      'Enter a valid email address',
    );
    expect(
      EmailVerificationNotifier.validateEmail('user@example'),
      'Enter a valid email address',
    );
  });

  test('button enables only for a valid email', () {
    final notifier = container.read(emailVerificationProvider.notifier);
    notifier.updateEmail('wrong');
    expect(container.read(emailVerificationProvider).canSubmit, isFalse);

    notifier.updateEmail('User@Example.com');
    expect(container.read(emailVerificationProvider).canSubmit, isTrue);
  });

  test('success normalizes email and forwards the API contract', () async {
    final notifier = container.read(emailVerificationProvider.notifier);
    notifier.updateEmail('  John.Doe@Gmail.com  ');

    final response = await notifier.sendCode(userId: 'user-1');

    expect(response.success, isTrue);
    expect(repository.lastRequest?.toJson(), {
      'userId': 'user-1',
      'email': 'john.doe@gmail.com',
    });
    expect(container.read(emailVerificationProvider).isSubmitting, isFalse);
  });

  test('API failure is exposed for retry', () async {
    repository.shouldFail = true;
    final notifier = container.read(emailVerificationProvider.notifier);
    notifier.updateEmail('user@example.com');

    final response = await notifier.sendCode(userId: 'user-1');

    expect(response.success, isFalse);
    expect(
      container.read(emailVerificationProvider).errorMessage,
      'Email already in use',
    );
    expect(container.read(emailVerificationProvider).canSubmit, isTrue);
  });
}

class EmailRepositoryFake implements AuthRepository {
  bool shouldFail = false;
  EmailVerificationRequest? lastRequest;

  @override
  Future<EmailVerificationResponse> sendEmailVerification(
    EmailVerificationRequest request,
  ) async {
    lastRequest = request;
    if (shouldFail) {
      return const EmailVerificationResponse(
        success: false,
        message: 'Email already in use',
      );
    }
    return EmailVerificationResponse(
      success: true,
      message: 'Verification code sent',
      email: request.email,
    );
  }

  @override
  Future<void> resendEmailVerification({
    required String userId,
    required String email,
  }) async {}

  @override
  Future<void> resendOtp({required String userId}) async {}

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
    return const OtpVerificationResponse(success: true, verified: true);
  }
}
