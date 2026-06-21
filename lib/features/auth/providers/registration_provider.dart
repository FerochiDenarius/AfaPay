import 'package:flutter/foundation.dart';

import '../models/country.dart';
import '../models/register_request.dart';
import '../services/auth_service.dart';

class RegistrationProvider extends ChangeNotifier {
  RegistrationProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  String firstName = '';
  String lastName = '';
  String username = '';
  String phoneNumber = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  Country selectedCountry = supportedCountries.first;
  bool acceptedTerms = false;
  bool acceptedPrivacy = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  bool get hasMinimumLength => password.length >= 8;
  bool get hasUppercase => RegExp(r'[A-Z]').hasMatch(password);
  bool get hasLowercase => RegExp(r'[a-z]').hasMatch(password);
  bool get hasNumber => RegExp(r'[0-9]').hasMatch(password);
  bool get hasSpecialCharacter =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>_+\-=\[\]\\;/`~]').hasMatch(password);
  bool get isPasswordValid =>
      hasMinimumLength &&
      hasUppercase &&
      hasLowercase &&
      hasNumber &&
      hasSpecialCharacter;

  String get normalizedPhoneNumber {
    var digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits;
  }

  String get formattedPhoneNumber {
    final digits = normalizedPhoneNumber;
    if (selectedCountry.name == 'Ghana' && digits.length == 9) {
      return '${selectedCountry.dialCode} ${digits.substring(0, 2)} '
          '${digits.substring(2, 5)} ${digits.substring(5)}';
    }
    return '${selectedCountry.dialCode} $digits';
  }

  bool get canSubmit =>
      firstNameError == null &&
      lastNameError == null &&
      usernameError == null &&
      phoneError == null &&
      emailError == null &&
      passwordError == null &&
      confirmPasswordError == null &&
      acceptedTerms &&
      acceptedPrivacy &&
      !isLoading;

  String? get firstNameError => _nameError(firstName, 'First name');
  String? get lastNameError => _nameError(lastName, 'Last name');

  String? get usernameError {
    final value = username.trim();
    if (value.isEmpty) return 'Username is required';
    if (value.length < 4 || value.length > 20) {
      return 'Use between 4 and 20 characters';
    }
    if (!RegExp(r'^\w+$').hasMatch(value)) {
      return 'Use letters, numbers, and underscores only';
    }
    return null;
  }

  String? get phoneError {
    if (normalizedPhoneNumber.isEmpty) return 'Phone number is required';
    if (normalizedPhoneNumber.length != selectedCountry.localNumberLength) {
      return 'Enter a valid ${selectedCountry.name} phone number';
    }
    return null;
  }

  String? get emailError {
    final value = email.trim();
    if (value.isEmpty) return 'Email address is required';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? get passwordError {
    if (password.isEmpty) return 'Password is required';
    if (!isPasswordValid) return 'Password does not meet the requirements';
    return null;
  }

  String? get confirmPasswordError {
    if (confirmPassword.isEmpty) return 'Please confirm your password';
    if (confirmPassword != password) return 'Passwords do not match';
    return null;
  }

  String? _nameError(String input, String label) {
    final value = input.trim();
    if (value.isEmpty) return '$label is required';
    if (value.length < 2) return '$label must be at least 2 characters';
    return null;
  }

  void setFirstName(String value) => _update(() => firstName = value);
  void setLastName(String value) => _update(() => lastName = value);
  void setUsername(String value) => _update(() => username = value);
  void setPhoneNumber(String value) => _update(() => phoneNumber = value);
  void setEmail(String value) => _update(() => email = value);
  void setPassword(String value) => _update(() => password = value);
  void setConfirmPassword(String value) =>
      _update(() => confirmPassword = value);
  void setAcceptedTerms(bool value) => _update(() => acceptedTerms = value);
  void setAcceptedPrivacy(bool value) => _update(() => acceptedPrivacy = value);

  void selectCountry(Country country) {
    selectedCountry = country;
    phoneNumber = '';
    notifyListeners();
  }

  void togglePasswordVisibility() =>
      _update(() => obscurePassword = !obscurePassword);
  void toggleConfirmPasswordVisibility() =>
      _update(() => obscureConfirmPassword = !obscureConfirmPassword);

  Future<RegisterResult> register() async {
    if (!canSubmit) {
      throw const AuthException('Please complete all required fields.');
    }

    isLoading = true;
    notifyListeners();
    try {
      return await _authService.register(
        RegisterRequest(
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          username: username.trim(),
          country: selectedCountry.name,
          phoneNumber: '${selectedCountry.dialCode}$normalizedPhoneNumber',
          email: email.trim().toLowerCase(),
          password: password,
        ),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _update(VoidCallback mutation) {
    mutation();
    notifyListeners();
  }
}
