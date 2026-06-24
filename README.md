# AfaPay

AfaPay is a Flutter fintech application currently under UI and frontend-logic
development. Backend services will be connected later through the existing
repository and service boundaries.

## Current Stack

- Flutter and Dart
- Provider for registration form state
- Riverpod for phone verification state
- GoRouter for application navigation
- Android and iOS targets

## Implemented UI

- Login screen
- Multi-field registration screen
- Optional phone OTP verification screen
- Required PIN setup screen placeholder
- Required email entry and OTP verification screens
- Chat room UI refactor with dark/light themes, mock messages, reusable header,
  message bubble, emoji menu, attachment menu, and responsive input bar

Email verification will be required when implemented. OCR onboarding will be
optional.

## Verification

```sh
flutter analyze
flutter test
```

Completed mobile UI work is also built as a debug APK, installed on the
connected OPPO `CPH2819` device when available, and launched for manual testing.

See [docs/UI_WORK_LOG.md](docs/UI_WORK_LOG.md) for implementation details and
the ongoing UI development history.

Backend configuration and deployment requirements are documented in
[docs/BACKEND_SETUP.md](docs/BACKEND_SETUP.md).
