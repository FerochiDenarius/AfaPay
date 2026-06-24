# AfaPay Backend Setup

The `AfaPayBackend/` directory contains copied Yenkasa backend files, but the
active AfaPay deployment is intentionally isolated to the lightweight
`afapay.server.js` entrypoint. AfaPay-specific onboarding routes are mounted
under:

```text
/api/afapay/auth
```

This prevents the new mobile onboarding contracts from changing existing
Yenkasa `/api/auth` clients.

## Implemented Endpoints

```text
POST /api/afapay/auth/register
POST /api/afapay/auth/login
POST /api/afapay/auth/send-email-verification
POST /api/afapay/auth/verify-email
POST /api/afapay/auth/verify-phone          (501 until SMS is configured)
POST /api/afapay/auth/resend-phone-otp      (501 until SMS is configured)
POST /api/auth/send-email-verification      (alias)
POST /api/auth/verify-email                 (alias)
GET  /api/user/profile                     (JWT required)
GET  /api/wallet/balance                   (JWT required)
GET  /api/transactions/recent              (JWT required)
GET  /api/notifications/unread-count       (JWT required)
POST /api/messages/upload                  (JWT required, multipart media)
```

Registration, login, and email verification use the AfaPay `AfaPayUser`
Mongoose model stored in the `afapay_users` collection. This keeps new AfaPay
accounts separate from the copied Yenkasa `users` collection while the backend
is being refactored.

Email verification uses Resend's HTTP API. Codes are cryptographically random,
stored only as SHA-256 hashes, expire after ten minutes by default, enforce a 60-second resend
cooldown, and allow no more than five verification attempts. Phone OTP remains
optional until an SMS provider is wired; with `PHONE_OTP_ENABLED=false`,
registration returns `nextStep: "pin_setup"` so the app does not claim a phone
code was sent.

The dashboard endpoints are wired for the Flutter main activity screen. Profile
data is read from `afapay_users`; wallet, recent transactions, and unread
notifications currently return safe defaults until those product modules are
implemented.

Chat media uploads are wired through the shared media storage service. Local
development can use disk storage, while production should use the AfaPay Google
Cloud Storage bucket documented in [GOOGLE_CLOUD_STORAGE.md](GOOGLE_CLOUD_STORAGE.md).

## Required Server Environment

Copy `AfaPayBackend/.env.example` to the deployment environment and set real
values for:

- `MONGODB_URI`
- `API_PUBLIC_URL=https://afapay.xyz`
- `ACCESS_TOKEN_SECRET`
- `REFRESH_TOKEN_SECRET`
- `PHONE_OTP_ENABLED=false` until SMS is configured
- `RESEND_API_KEY`
- `EMAIL_FROM="AfaPay <noreply@afapay.xyz>"`
- `CORS_ORIGIN=https://afapay.xyz,https://www.afapay.xyz`
- `MEDIA_STORAGE_PROVIDER=gcs`
- `GOOGLE_CLOUD_PROJECT=afapay`
- `GCS_MEDIA_BUCKET=afapay-media`
- `GCS_PUBLIC_BASE_URL=https://storage.googleapis.com/afapay-media`
- `GCS_SERVICE_ACCOUNT_JSON`

Do not commit the real `.env` file.

## Package And Deployment

`AfaPayBackend/package.json` and `AfaPayBackend/package-lock.json` are now
present for the active AfaPay server. The package is deliberately small because
`npm start` runs `afapay.server.js`, not the larger copied Yenkasa server.

Railway should use the repository `Dockerfile`. Set the production database and
secret values in Railway environment variables, then attach the custom domain
`afapay.xyz` to the deployed service.

Production deployment `35308ae2-2af5-4d49-ad27-f607b85fed89` was verified on
2026-06-22. `https://afapay.xyz/health` returns HTTP 200, MongoDB-backed login
requests reach Atlas, and CORS allows the production origin.

## Flutter Configuration

Flutter now points to the hosted Railway backend by default:

```sh
flutter run
```

This uses:

```text
API_BASE_URL=https://afapay.xyz
USE_MOCK_AUTH=false
```

Use local or ngrok testing only when you explicitly override the base URL:

```sh
flutter run \
  --dart-define=USE_MOCK_AUTH=false \
  --dart-define=API_BASE_URL=https://abc123.ngrok-free.app
```

`API_BASE_URL` must be HTTPS for production Android and iOS builds.
