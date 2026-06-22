# Railway Environment

Backend project:

```text
Project ID: df8bf300-c874-42f3-8957-519f29f9c28d
Production environment ID: 6d836367-e220-41d8-9402-ef9f6bbad253
Variables workspace environment ID: b2636daf-e0ad-462e-9f1b-468c8c40e7c7
Service name: AfaPay
Service ID from variable metadata: ae947918-acfd-4f5b-b22f-f1cd979ea5ac
Variables URL: https://railway.com/project/df8bf300-c874-42f3-8957-519f29f9c28d/settings/variables?environmentId=b2636daf-e0ad-462e-9f1b-468c8c40e7c7
```

## CLI Link

The local Railway CLI must be authenticated before variables can be managed.

```sh
railway login
railway link \
  --project df8bf300-c874-42f3-8957-519f29f9c28d \
  --environment production
```

Current local link status:

```text
Workspace: Afapay's Projects
Project: afapay
Environment: production
Linked service: None
```

`railway service link AfaPay` and linking by service ID did not resolve a
default service locally, but variable commands work when `--service AfaPay` is
passed explicitly.

## Required Backend Variables

Set these in the Railway environment:

```env
NODE_ENV=production
PORT=8080
MONGODB_URI=mongodb+srv://...
API_PUBLIC_URL=https://afapay.xyz
ACCESS_TOKEN_SECRET=...
REFRESH_TOKEN_SECRET=...
PHONE_OTP_ENABLED=false
RESEND_API_KEY=...
EMAIL_FROM="AfaPay <noreply@afapay.xyz>"
EMAIL_CODE_LIFETIME=600
EMAIL_RESEND_COOLDOWN=60
CORS_ORIGIN=https://afapay.xyz,https://www.afapay.xyz
```

`RESEND_API_KEY`, `ACCESS_TOKEN_SECRET`, `REFRESH_TOKEN_SECRET`, and
`MONGODB_URI` are secrets. Do not commit them.

## Current Production Status

The production `AfaPay` service builds correctly from the repository
`Dockerfile`, installs dependencies with `npm ci --omit=dev`, and starts the
Node entrypoint. The current deployment fails because MongoDB Atlas rejects
Railway's outbound connection:

```text
Could not connect to any servers in your MongoDB Atlas cluster.
One common reason is that you're trying to access the database from an IP
that isn't whitelisted.
```

Until this is fixed, `https://afapay.xyz/health` returns Railway's fallback
404 because Railway stops the unhealthy deployment.

Fix one of these ways:

1. In MongoDB Atlas, open `Security > Network Access` and add
   `0.0.0.0/0` temporarily for Railway testing. Railway free deployments do
   not provide a stable outbound IP. Restrict this later if you move to a plan
   with static egress.
2. Or create a Railway Mongo database with `railway add --database mongo` and
   switch `MONGODB_URI` to that database URL. This creates a new empty database,
   so existing Atlas data will not be present unless migrated.

After the database is reachable, redeploy:

```sh
railway up --detach --yes --service AfaPay --environment production
```

Then verify:

```sh
curl -i https://afapay.xyz/health
```

## CLI Variable Commands

After `railway login` succeeds, variables can be set with:

```sh
railway variable set EMAIL_FROM="AfaPay <noreply@afapay.xyz>" \
  --service AfaPay \
  --project df8bf300-c874-42f3-8957-519f29f9c28d \
  --environment production

railway variable set EMAIL_CODE_LIFETIME=600 \
  --service AfaPay \
  --project df8bf300-c874-42f3-8957-519f29f9c28d \
  --environment production

railway variable set EMAIL_RESEND_COOLDOWN=60 \
  --service AfaPay \
  --project df8bf300-c874-42f3-8957-519f29f9c28d \
  --environment production
```

For `RESEND_API_KEY`, prefer stdin so the key is not saved in shell history:

```sh
printf '%s' "$RESEND_API_KEY" | railway variable set RESEND_API_KEY --stdin \
  --service AfaPay \
  --project df8bf300-c874-42f3-8957-519f29f9c28d \
  --environment production
```

Verified on the Railway environment:

```text
MONGODB_URI=present
ACCESS_TOKEN_SECRET=present
REFRESH_TOKEN_SECRET=present
RESEND_API_KEY=present
EMAIL_FROM=present
EMAIL_CODE_LIFETIME=present
EMAIL_RESEND_COOLDOWN=present
CORS_ORIGIN=present
```
