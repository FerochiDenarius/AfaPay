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
GET  /api/user/profile                     (JWT required)
GET  /api/wallet/balance                   (JWT required)
GET  /api/transactions/recent              (JWT required)
GET  /api/notifications/unread-count       (JWT required)
```

Registration, login, and email verification use the AfaPay `AfaPayUser`
Mongoose model stored in the `afapay_users` collection. This keeps new AfaPay
accounts separate from the copied Yenkasa `users` collection while the backend
is being refactored.

Email verification codes are cryptographically random, stored only as SHA-256
hashes, expire after three minutes by default, enforce a 60-second resend
cooldown, and allow no more than five verification attempts. Phone OTP remains
optional until an SMS provider is wired; with `PHONE_OTP_ENABLED=false`,
registration returns `nextStep: "pin_setup"` so the app does not claim a phone
code was sent.

The dashboard endpoints are wired for the Flutter main activity screen. Profile
data is read from `afapay_users`; wallet, recent transactions, and unread
notifications currently return safe defaults until those product modules are
implemented.

## Required Server Environment

Copy `AfaPayBackend/.env.example` to the deployment environment and set real
values for:

- `MONGODB_URI`
- `API_PUBLIC_URL=https://afapay.xyz`
- `ACCESS_TOKEN_SECRET`
- `REFRESH_TOKEN_SECRET`
- `PHONE_OTP_ENABLED=false` until SMS is configured
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURE`
- `EMAIL_USER`, `EMAIL_PASS`, `EMAIL_FROM`
- `CORS_ORIGIN=https://afapay.xyz,https://www.afapay.xyz`

Do not commit the real `.env` file.

## Package And Deployment

`AfaPayBackend/package.json` and `AfaPayBackend/package-lock.json` are now
present for the active AfaPay server. The package is deliberately small because
`npm start` runs `afapay.server.js`, not the larger copied Yenkasa server.

Railway should use the repository `Dockerfile`. Set the production database and
secret values in Railway environment variables, then attach the custom domain
`afapay.xyz` to the deployed service.

## Flutter Configuration

UI/device testing uses the frontend mock repository by default:

```sh
flutter run
```

Connect to the hosted backend with:

```sh
flutter run \
  --dart-define=USE_MOCK_AUTH=false \
  --dart-define=API_BASE_URL=https://afapay.xyz
```

`API_BASE_URL` must be HTTPS for production Android and iOS builds.
