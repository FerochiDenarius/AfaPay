import 'package:afa_pay/features/auth/models/country.dart';
import 'package:afa_pay/features/auth/providers/registration_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RegistrationProvider', () {
    test('starts with Ghana selected and an invalid form', () {
      final registration = RegistrationProvider();

      expect(registration.selectedCountry.name, 'Ghana');
      expect(registration.selectedCountry.dialCode, '+233');
      expect(registration.canSubmit, isFalse);
    });

    test('updates password requirements in real time', () {
      final registration = RegistrationProvider();

      registration.setPassword('Weak');
      expect(registration.hasUppercase, isTrue);
      expect(registration.hasNumber, isFalse);
      expect(registration.isPasswordValid, isFalse);

      registration.setPassword('Strong1!');
      expect(registration.hasMinimumLength, isTrue);
      expect(registration.hasLowercase, isTrue);
      expect(registration.hasNumber, isTrue);
      expect(registration.hasSpecialCharacter, isTrue);
      expect(registration.isPasswordValid, isTrue);
    });

    test('validates phone length for the selected country', () {
      final registration = RegistrationProvider();
      final nigeria = supportedCountries.firstWhere(
        (country) => country.name == 'Nigeria',
      );

      registration.selectCountry(nigeria);
      registration.setPhoneNumber('801234567');
      expect(registration.phoneError, isNotNull);

      registration.setPhoneNumber('08012345678');
      expect(registration.normalizedPhoneNumber, '8012345678');
      expect(registration.phoneError, isNull);
    });

    test('enables submission only when every requirement is met', () {
      final registration = RegistrationProvider()
        ..setFirstName('Ama')
        ..setLastName('Mensah')
        ..setUsername('ama_mensah')
        ..setPhoneNumber('0241234567')
        ..setEmail('ama@example.com')
        ..setPassword('Strong1!')
        ..setConfirmPassword('Strong1!')
        ..setAcceptedTerms(true)
        ..setAcceptedPrivacy(true);

      expect(registration.canSubmit, isTrue);
      expect(registration.formattedPhoneNumber, '+233 24 123 4567');
    });

    test('simulated frontend registration requires verification', () async {
      final registration = RegistrationProvider()
        ..setFirstName('Ama')
        ..setLastName('Mensah')
        ..setUsername('ama_mensah')
        ..setPhoneNumber('0241234567')
        ..setEmail('ama@example.com')
        ..setPassword('Strong1!')
        ..setConfirmPassword('Strong1!')
        ..setAcceptedTerms(true)
        ..setAcceptedPrivacy(true);

      final result = await registration.register();

      expect(result.success, isTrue);
      expect(result.verificationRequired, isTrue);
      expect(registration.isLoading, isFalse);
    });
  });
}
