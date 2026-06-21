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

Email verification will be required when implemented. OCR onboarding will be
optional.

## Verification

```sh
flutter analyze
flutter test
```

See [docs/UI_WORK_LOG.md](docs/UI_WORK_LOG.md) for implementation details and
the ongoing UI development history.

Backend configuration and deployment requirements are documented in
[docs/BACKEND_SETUP.md](docs/BACKEND_SETUP.md).
