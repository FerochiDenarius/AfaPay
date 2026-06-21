# AfaPay Backend Setup

The `AfaPayBackend/` directory contains a copied Yenkasa Express/Mongoose
backend. AfaPay-specific onboarding routes are isolated under:

```text
/api/afapay/auth
```

This prevents the new mobile onboarding contracts from changing existing
Yenkasa `/api/auth` clients.

## Implemented Endpoints

```text
POST /api/afapay/auth/register
POST /api/afapay/auth/send-email-verification
POST /api/afapay/auth/verify-email
POST /api/afapay/auth/verify-phone          (501 until SMS is configured)
POST /api/afapay/auth/resend-phone-otp      (501 until SMS is configured)
```

Registration and email verification use the existing Yenkasa `User` Mongoose
model and MongoDB connection. Verification codes are cryptographically random,
stored only as SHA-256 hashes, expire after three minutes by default, enforce a
60-second resend cooldown, and allow no more than five verification attempts.

## Required Server Environment

Copy `AfaPayBackend/.env.example` to the deployment environment and set real
values for:

- `MONGODB_URI`
- `ACCESS_TOKEN_SECRET`
- `REFRESH_TOKEN_SECRET`
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURE`
- `EMAIL_USER`, `EMAIL_PASS`, `EMAIL_FROM`

Do not commit the real `.env` file.

## Missing Deployment Files

The copied backend currently does **not** contain `package.json` or a lockfile.
Copy the original Yenkasa backend package manifest and lockfile before running
`npm install`, tests, or deployment. Creating a guessed manifest here would risk
incorrect dependency versions across the large existing backend.

## Flutter Configuration

UI/device testing uses the frontend mock repository by default:

```sh
flutter run
```

Connect to the hosted backend with:

```sh
flutter run \
  --dart-define=USE_MOCK_AUTH=false \
  --dart-define=API_BASE_URL=https://your-afapay-api.example.com
```

`API_BASE_URL` must be HTTPS for production Android and iOS builds.
