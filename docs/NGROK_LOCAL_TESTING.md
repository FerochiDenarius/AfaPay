# AfaPay ngrok Local Testing

Use this flow while production email/domain verification is pending.

## 1. One-time ngrok setup

ngrok is installed on this laptop. Add your ngrok auth token locally:

```sh
ngrok config add-authtoken YOUR_NGROK_TOKEN
```

Do not commit or paste the token into project files.

## 2. Fix local MongoDB URI

`AfaPayBackend/.env` must contain a valid MongoDB Atlas URI. If the database
password contains reserved URL characters like `@`, `$`, `<`, `>`, or `#`,
URL-encode the password before placing it in the URI.

Example:

```text
@ becomes %40
$ becomes %24
< becomes %3C
> becomes %3E
```

The URI should look like:

```env
MONGODB_URI=mongodb+srv://USER:URL_ENCODED_PASSWORD@CLUSTER/afapay?retryWrites=true&w=majority&appName=Cluster0
```

## 3. Start the local backend

```sh
cd AfaPayBackend
npm run dev
```

Expected success:

```text
[AfaPay] API listening on port 8080
```

## 4. Start ngrok

In a second terminal:

```sh
cd AfaPayBackend
npm run tunnel
```

Copy the HTTPS forwarding URL, for example:

```text
https://abc123.ngrok-free.app
```

## 5. Run Flutter against the tunnel

Use the ngrok HTTPS URL as the API base URL:

```sh
flutter run \
  --dart-define=USE_MOCK_AUTH=false \
  --dart-define=API_BASE_URL=https://abc123.ngrok-free.app \
  --dart-define=REQUIRE_EMAIL_VERIFICATION=false
```

`REQUIRE_EMAIL_VERIFICATION=false` is only for local testing while Resend domain
ownership is pending. Production should omit that flag so email verification
remains required.

## Current Test Scope

Works locally once MongoDB connects:

- Registration
- Login
- Dashboard profile fetch
- Dashboard wallet/transactions/notification default endpoints

Still pending until providers are configured:

- Email delivery through Resend
- Phone OTP
