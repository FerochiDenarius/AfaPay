# AfaPay UI Work Log

This file is updated after every completed UI task. It records what was built,
the behavior implemented, navigation decisions, tests, and device deployment.

## 2026-06-24 - Chat Room Bug Fixes and Compact Chat List

### Chat Room

- Fixed the Emoji/GIF/Sticker menu so it starts closed and only opens after the
  emoji button is tapped.
- Replaced real-room static mock messages with `ChatRepository.fetchMessages()`
  scoped to the active `roomId`.
- Replaced real-room local-only text sends with `ChatRepository.sendMessage()`
  scoped to the active `roomId`, using optimistic pending rows and failed-send
  indicators.
- Kept preview chat screens on static mock data for UI tests and screenshots.
- Added backend `status` parsing to chat messages and changed delivery icons so
  `sent` is one check, `delivered/read` are double checks, and pending/failed
  states are shown honestly.
- Media sends now replace the optimistic local media row with the backend
  message when upload/send succeeds, or mark it failed when it does not.

### Chat Contacts and App Icon

- Reduced chat contact card height, avatar size, text size, metadata badges,
  search field, segmented tabs, FAB, and bottom navigation sizing.
- Preserved separate Private and Groups tabs.
- Regenerated Android and iOS launcher icon assets from the high-resolution
  `UIdesignImages/logoEmblem.png` source instead of the low-resolution
  `appIcon.png` source.

### Verification

- Added a widget test that confirms the emoji menu stays closed until tapped.
- `flutter analyze`: passed.

## 2026-06-24 - Chat Contacts Light and Dark UI

### UI

- Refactored the chat contacts/list screen to match the supplied light and dark
  references.
- Added a large Chats header with a home action.
- Added the supplied `logo.png` as a visible brand mark in the chat contacts
  header.
- Rebuilt the search field as a rounded themed container with search and filter
  controls.
- Rebuilt the Private/Groups selector as a rounded segmented tab surface.
- Replaced the old list tiles with rounded chat cards, avatar initials, preview
  text, timestamps, unread badges, and muted indicators.
- Added a rounded yellow floating new-chat button.
- Added the chat bottom navigation surface for Chats, Contacts, Calls, and
  Settings.
- Removed old hardcoded chat-list colors from the screen and moved the UI to
  the existing chat theme resources.

### Logic and Backend

- Preserved existing repository calls for private chats, groups, user search,
  new private chat creation, and group creation.
- Preserved the existing authenticated navigation behavior.
- Regenerated Android and iOS launcher icon slots from the supplied
  `appIcon.png` asset.

### Verification

- `flutter analyze`: passed.
- `flutter test`: passed.
- `flutter build apk --debug --dart-define=INITIAL_ROUTE=/chats`: passed.
- Debug APK install and launch on OPPO `CPH2819`: blocked because ADB no
  longer listed the device after the build completed.

## 2026-06-24 - Chat Gallery Media Picker and Backend Media Wiring

### UI

- Added a WhatsApp-style gallery launcher for the chat attachment Gallery
  action.
- Added a full-screen image/video editor preview with top editing controls,
  caption input, recipient pill, and circular send button.
- Added media previews inside outgoing chat bubbles for selected images/videos.
- Registered supplied media picker reference images as Flutter assets for the
  local picker launcher sample grid.
- Fixed the attachment popup hit-test area so visible attachment actions are
  tappable.
- Added Android and iOS photo/video/camera permission declarations.

### Logic and Backend

- Added `image_picker` and `video_player` dependencies for device media
  selection and local video preview.
- Added `ChatMediaDraft` and reusable media upload/send models.
- Added authenticated multipart media upload support to `ChatRepository`.
- Added backend Afapay chat media upload endpoint at `/api/messages/upload`.
- Extended Afapay chat messages with image, video, audio, file, and media
  metadata fields.
- Extended Afapay chat send to accept media messages with optional captions.
- Exposed `online` and `lastSeen` fields from Afapay chat participants and
  added a best-effort chat room presence refresh on the Flutter side.

### Verification

- Added widget coverage for opening the Gallery media picker launcher from the
  attachment menu.
- `flutter analyze`: pending.
- `flutter test`: pending.
- Backend `node --check` for modified Afapay chat files: passed.
- Debug APK install and launch on OPPO `CPH2819`: pending.

## 2026-06-24 - Login Light Theme

### UI

- Added a light-theme login experience matching the supplied
  `loginLightTheme.png` reference.
- Added a light-theme main dashboard experience matching the supplied
  `mainPageLightTheme.png` reference.
- Added the light login artwork asset to Flutter assets.
- Added the light main dashboard artwork asset to Flutter assets for the logo
  card crop.
- Declared the actual app logo asset, `logo.png`, for in-app branding.
- Replaced Android and iOS launcher icon assets with the supplied AFA app icon.
- Updated the login screen to choose the light or dark artwork from the active
  app theme.
- Added light-theme field styling with pale surfaces, visible borders, dark
  labels, muted placeholders, yellow action button, forgot-password chevron,
  divider copy, and outlined Sign Up button.
- Preserved the existing dark login layout and social-login row for dark mode.
- Updated the main dashboard to use a white background, rounded logo card,
  white feature tiles, gold icons, dark labels, and light bottom navigation in
  light mode.
- Preserved the dark dashboard layout for dark mode.

### Logic and Backend

- No backend changes.
- Existing login authentication flow remains unchanged.

### Verification

- Added widget coverage for the light login Sign Up section.
- `flutter analyze`: passed.
- `flutter test`: passed.
- Debug APK install and launch on OPPO `CPH2819`: passed.

## 2026-06-24 - Chat Room Input Attachments and Composer Behavior

### UI

- Added a reusable attachment popup for the chat composer.
- Attachment actions are UI-only and include Document, Gallery, Contact,
  Location, Poll, and Event.
- Updated the composer action button to show a microphone when the input is
  empty.
- The microphone switches to the send icon immediately when typing starts.
- The camera button remains inside the input field and disappears while text is
  present.
- Kept composer tool icons smaller and bottom-aligned inside the input area.

### Logic and Backend

- Kept the feature UI-only with no backend, socket, database, or API wiring.
- Send appends a local mock outgoing message, clears the input, and scrolls the
  mock conversation for frontend testing.
- Attachment, emoji, GIF, sticker, and voice actions show temporary UI feedback
  only.

### Verification

- Added widget coverage for camera hiding, mic/send switching, local mock send,
  and attachment menu labels.
- Updated chat dark/light golden screenshots.
- `flutter analyze`: passed.
- `flutter test test/features/chat/chat_room_screen_golden_test.dart`: passed.
- Debug APK install and launch on OPPO `CPH2819`: passed.

## 2026-06-24 - Chat Room UI Refactor

### UI

- Replaced the previous chat room presentation with a mock-data chat UI matching
  the supplied dark and light chat mockups.
- Added dark and light chat theme resources through a Flutter `ThemeExtension`.
- Added reusable chat header, message bubble, message input bar, emoji popup,
  and preview wrappers.
- Implemented a custom header with back, avatar, username, online indicator,
  call, video, and more buttons.
- Added outgoing yellow bubbles, incoming dark/light bubbles, timestamps,
  double-check receipts, and a centered Today divider.
- Added a rounded input field with add, text entry, camera, emoji, and a
  circular action button.

### Logic and Backend

- Removed repository polling, message fetch, send endpoint, and read-marking
  calls from the chat room screen.
- Used static mock conversation data only.
- Kept components reusable for future backend integration.

### Verification

- Added dark and light golden screenshot tests.
- `flutter analyze`: passed.
- `flutter test`: passed.
- Built and installed a debug APK on OPPO `CPH2819` after completed UI work.

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
