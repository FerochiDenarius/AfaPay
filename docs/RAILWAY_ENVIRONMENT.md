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
Environment: afapayVariables
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
Node entrypoint. Deployment `35308ae2-2af5-4d49-ad27-f607b85fed89` is live and
successfully connected to MongoDB Atlas.

```text
GET https://afapay.xyz/health
HTTP 200
{"status":"ok","service":"afapay","publicUrl":"https://afapay.xyz"}
```

### Recovery and verification record (2026-06-22)

- An earlier deployment was submitted as
  `c357cea6-df93-403c-8b0f-1e138f6036fc`. The image built and the container
  started, but the deployment failed during MongoDB server selection.
- Railway network traces showed successful DNS queries and TCP traffic to all
  three Atlas nodes on port `27017`. This proves basic network reachability,
  but it does not mean that Atlas has authorized the source IP.
- A direct connection probe returned Atlas's IP access-list error.
- The laptop's current public IP is `154.161.142.63`; the previously recorded
  `154.161.151.26` address is no longer current. Dynamic ISP addresses must be
  updated in Atlas when they change.
- Atlas Network Access was updated with `154.161.142.63/32` for current local
  testing and `0.0.0.0/0` for Railway's dynamic egress during testing.
- A direct local connection then completed successfully, confirming Atlas
  authorization before the final Railway deployment.
- Final deployment `35308ae2-2af5-4d49-ad27-f607b85fed89` reached `SUCCESS`.
  Its logs show `[AfaPay] API listening on port 8080`.
- The public health endpoint returned HTTP 200, the login endpoint queried
  Atlas and returned the expected `401 Invalid credentials` for a nonexistent
  probe account, and the CORS preflight returned HTTP 204 for
  `https://afapay.xyz`.
- Final regression verification passed: backend tests `6/6` and Flutter tests
  `21/21`.

## Atlas Network Access

`0.0.0.0/0` is temporary for Railway testing because the current Railway
deployment does not have stable outbound IP addresses. Replace it with static
egress addresses when the hosting plan supports them. Remove obsolete laptop
addresses when the ISP changes the public IP.

Redeploy with:

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
