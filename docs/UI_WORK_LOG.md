# AfaPay UI Work Log

This file is updated after every completed UI task. It records what was built,
the behavior implemented, navigation decisions, tests, and device deployment.

## 2026-06-21 - Required Email Verification and Backend Wiring

### UI

- Added `EmailVerificationEntryScreen` from the supplied reference.
- Added required email OTP verification as the next route.
- Added the four-completed, step-five-active onboarding indicator.
- Added the secure email illustration, accessible email field, inline errors,
  privacy notice, loading states, and disabled/enabled button behavior.
- Extracted a reusable autofill-compatible six-digit `OtpCodeField` shared by
  phone and email verification.
- Required PIN setup now continues to required email verification.

### Logic and Backend

- Added Riverpod email entry and email OTP providers.
- Added email request/response models and retry/error behavior.
- Added a real HTTP repository selected with `USE_MOCK_AUTH=false`.
- Added configurable `API_BASE_URL` and `INITIAL_ROUTE` compile-time values.
- Added isolated Yenkasa backend routes under `/api/afapay/auth` for
  registration, sending email OTP, and confirming email OTP.
- Added MongoDB user fields for first and last name and SMTP/Mongo environment
  documentation.
- Phone verification remains skippable and uses mock mode until an SMS provider
  is configured. Email verification has no skip action.

### Verification

- Added tests for empty/invalid email, valid button state, normalized request
  payload, API success, and API failure/retry.
- Backend route, route-mount, and model files pass `node --check`.
- `flutter analyze`: passed.
- `flutter test`: 16 tests passed.
- Built in mock-auth UI test mode and installed/launched successfully on the
  connected TECNO BG6m with email verification as the test launch route.

## 2026-06-21 - Phone Verification

### UI

- Added `PhoneVerificationScreen` with a responsive navy gradient layout.
- Added the six-step onboarding indicator:
  - Step 1 completed with a green check.
  - Step 2 active in gold.
  - Steps 3-6 inactive.
- Added six visual OTP boxes backed by one numeric input for reliable typing,
  deletion, paste, and platform OTP autofill.
- Added selected-field gold highlighting, verification loading state, error
  feedback, and the disabled/enabled Verify button states.
- Added a 60-second resend countdown and resend loading state.

### Logic and Architecture

- Added Riverpod phone verification state in
  `phone_verification_provider.dart`.
- Added GoRouter routes for registration, login, phone verification, and PIN
  setup.
- Added `OtpVerificationRequest` and `OtpVerificationResponse` models.
- Added an `AuthRepository` contract with frontend-only implementations of
  `verifyPhoneOtp()` and `resendOtp()`.
- No backend requests are made. The repository simulates successful frontend
  responses and is ready to be replaced when the backend is available.

### Onboarding Rules

- Phone verification is optional and has a **Skip for now** action.
- Successful verification and Skip both continue to PIN setup.
- PIN setup is required and has no skip action.
- Future email verification is required.
- Future OCR onboarding is optional.

### Tests

- OTP must be exactly six digits.
- Verify button follows OTP validity and loading state.
- Countdown decreases once per second.
- Resend becomes available at zero and restarts the timer.
- Verification passes the expected request contract to the repository.
- `flutter analyze`: passed.
- `flutter test`: 11 tests passed.

## 2026-06-20 - Registration

- Added a responsive registration page with eight fields.
- Added a searchable country selector for Ghana, Nigeria, Kenya, South Africa,
  Cameroon, and Senegal.
- Added country-aware phone validation and dialing codes.
- Added live password requirements and password visibility controls.
- Added agreement checkboxes and form-wide Continue button validation.
- Added `RegisterRequest`, a frontend-only service boundary, loading behavior,
  error feedback, and verification navigation.
- Added Provider validation tests.

## 2026-06-19 - Login and Project Setup

- Created the Flutter project using the existing local Flutter/Dart SDK.
- Added the responsive AfaPay login screen from the supplied design reference.
- Added email/phone and password fields, visibility control, social login UI,
  and registration navigation.
- Verified Android and iOS builds.

## Completion Routine

After each UI task:

1. Update this work log.
2. Run `dart format`, `flutter analyze`, and `flutter test`.
3. Build the debug APK.
4. Install and launch it on the connected ADB device when available.
