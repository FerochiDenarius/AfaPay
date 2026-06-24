# Google Cloud Storage Media

AfaPay chat media is wired through the backend upload endpoint:

```text
POST /api/messages/upload
```

Flutter already uploads media to that endpoint through `ChatRepository`, so the
mobile app does not need a direct Google Cloud dependency.

## Current Bucket

```text
Project ID: afapay
Bucket: gs://afapay-media
Location: europe-west1
Storage class: Standard
Public media base URL: https://storage.googleapis.com/afapay-media
Uploader service account: afapay-media-uploader@afapay.iam.gserviceaccount.com
```

The bucket has public object read through `roles/storage.objectViewer` for
`allUsers` because the current app renders returned media URLs directly. The
uploader service account has `roles/storage.objectAdmin` on this bucket.

## Backend Variables

Production should use:

```env
MEDIA_STORAGE_PROVIDER=gcs
GOOGLE_CLOUD_PROJECT=afapay
GCS_MEDIA_BUCKET=afapay-media
GCS_PUBLIC_BASE_URL=https://storage.googleapis.com/afapay-media
GCS_SERVICE_ACCOUNT_JSON={...service account json...}
GCS_MAKE_PUBLIC=false
MEDIA_STORAGE_LOCAL_FALLBACK=false
```

Local development can use local disk while GCS credentials are not available:

```env
MEDIA_STORAGE_PROVIDER=local
LOCAL_MEDIA_ROOT=./uploads/media
LOCAL_MEDIA_PUBLIC_BASE_URL=http://localhost:8080/media
```

## Railway Setup

Railway CLI must be logged in before variables can be set:

```sh
railway login
```

Then set the non-secret values:

```sh
railway variable set MEDIA_STORAGE_PROVIDER=gcs \
  --service AfaPay \
  --project df8bf300-c874-42f3-8957-519f29f9c28d \
  --environment production

railway variable set GOOGLE_CLOUD_PROJECT=afapay \
  --service AfaPay \
  --project df8bf300-c874-42f3-8957-519f29f9c28d \
  --environment production

railway variable set GCS_MEDIA_BUCKET=afapay-media \
  --service AfaPay \
  --project df8bf300-c874-42f3-8957-519f29f9c28d \
  --environment production

railway variable set GCS_PUBLIC_BASE_URL=https://storage.googleapis.com/afapay-media \
  --service AfaPay \
  --project df8bf300-c874-42f3-8957-519f29f9c28d \
  --environment production

railway variable set MEDIA_STORAGE_LOCAL_FALLBACK=false \
  --service AfaPay \
  --project df8bf300-c874-42f3-8957-519f29f9c28d \
  --environment production
```

For the service account JSON, prefer stdin or Railway dashboard paste so the
secret is not stored in shell history.

## Verification

After deployment, send a chat image from the app. The backend should return an
upload response containing:

```json
{
  "success": true,
  "type": "image",
  "messageKey": "imageUrl",
  "url": "https://storage.googleapis.com/afapay-media/afapay-chat/..."
}
```

The subsequent `POST /api/messages` call stores that URL on the message.
