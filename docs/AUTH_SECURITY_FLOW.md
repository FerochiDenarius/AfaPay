# AfaPay Authentication And Security Flow

## Session Model

AfaPay uses a short-lived access token and a device-bound refresh token.

- Access token: JWT, 15 minutes, sent as `Authorization: Bearer <token>`.
- Refresh token: JWT, 60 days, stored only as a SHA-256 hash in `afapay_refresh_tokens`.
- Refresh tokens are bound to `deviceId` and rotated on every refresh.
- New login revokes existing active refresh tokens for the same user/device pair.

## Login Flow

1. User submits email, phone, or username plus password.
2. Backend verifies the password. New passwords are Argon2id hashes; older bcrypt hashes remain verifiable.
3. Backend registers or updates the device in `afapay_user_devices`.
4. Backend issues access and refresh tokens.
5. Backend returns `deviceId`, `pinConfigured`, and `biometricEnabled`.
6. Mobile app stores tokens and `deviceId` in secure storage.
7. If `pinConfigured` is false, mobile routes to `/pin-setup`.
8. After PIN setup, mobile routes to `/enable-biometrics`, then dashboard.

## PIN Flow

PINs are 4-6 numeric digits. The backend stores only an Argon2id hash in `afapay_pin_credentials`.

- `POST /api/security/pin/setup`: creates or replaces the user PIN.
- `POST /api/security/pin/verify`: validates PIN for app unlock or transaction confirmation.
- `POST /api/security/pin/reauth`: validates PIN and issues a new token pair for a registered device.

Failed PIN attempts are tracked in `afapay_pin_attempts`.

- 5 failures locks PIN verification for 15 minutes.
- Failed, blocked, and successful PIN checks are written to `afapay_security_audit_logs`.

## Biometrics

The mobile app includes a biometrics setup screen and backend hook:

- `POST /api/security/biometrics`

The server stores whether biometrics are enabled in `afapay_biometric_settings`. Native biometric prompting should be enforced on-device before calling protected transaction or unlock flows.

## Device Management

Device records are stored in `afapay_user_devices`.

- `POST /api/security/device/register`
- `GET /api/security/devices`
- `DELETE /api/security/devices/:deviceId`
- `POST /api/security/logout-all`

Removing a device revokes its active refresh tokens. Logout-all revokes all refresh tokens and device records for the user.

## Transaction Security

Money-related actions must call PIN or biometric verification before execution. Chat, group chat, voice call, and video call do not require additional verification. Financial actions started inside chat must verify PIN or biometrics before processing payment.

## Audit Logging

Security events are stored in `afapay_security_audit_logs`, including:

- Login
- Refresh token rotation
- Device registration
- Device removal
- Logout-all
- PIN setup
- PIN verification
- PIN reauthentication
- Biometric enable/disable

## Collections

- `afapay_users`
- `afapay_user_devices`
- `afapay_refresh_tokens`
- `afapay_pin_credentials`
- `afapay_biometric_settings`
- `afapay_login_history`
- `afapay_pin_attempts`
- `afapay_security_audit_logs`

## Future Extension Points

This model leaves room for KYC, transaction limits, AML monitoring, fraud detection, risk scoring, multi-currency wallets, and compliance rules by adding risk checks before token issue, transaction authorization, or device registration without redesigning the login model.
