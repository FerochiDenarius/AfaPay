# AfaPay

AfaPay is a Flutter fintech application currently under UI, frontend logic, and
incremental backend integration through existing repository and service
boundaries.

## Current Stack

- Flutter and Dart
- Provider for registration form state
- Riverpod for phone verification state
- GoRouter for application navigation
- HTTP multipart chat media upload through the chat repository
- Android and iOS targets

## Implemented UI

- Login screen
- Light and dark login screen themes
- AFA launcher icon on mobile targets
- Multi-field registration screen
- Optional phone OTP verification screen
- Required PIN setup screen placeholder
- Required email entry and OTP verification screens
- Chat room UI refactor with dark/light themes, mock messages, reusable header,
  message bubble, emoji menu, attachment menu, and responsive input bar
- Chat contacts/list page with light and dark themes, rounded search,
  Private/Groups tabs, app logo header mark, compact chat cards, floating
  new-chat action, and chat bottom nav
- Chat gallery attachment launcher, image/video editor preview, caption entry,
  and backend-ready media send flow
- Room-scoped chat message loading/sending through the chat repository, with
  optimistic pending/failed UI states and no fake delivered/read indicators
- Light and dark main dashboard themes

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
