const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');

const mediaStorage = require('../services/mediaStorage.service');

const originalEnv = { ...process.env };

test.afterEach(async () => {
  process.env = { ...originalEnv };
});

test('media storage defaults to local when no GCS bucket is configured', () => {
  delete process.env.MEDIA_STORAGE_PROVIDER;
  delete process.env.PRIMARY_MEDIA_STORAGE;
  delete process.env.GCS_MEDIA_BUCKET;
  delete process.env.GOOGLE_CLOUD_STORAGE_BUCKET;

  assert.equal(mediaStorage.configuredProvider(), mediaStorage.PROVIDERS.LOCAL);
});

test('local media upload writes a file and returns a public media URL', async () => {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), 'afapay-media-'));
  process.env.MEDIA_STORAGE_PROVIDER = 'local';
  process.env.LOCAL_MEDIA_ROOT = root;
  process.env.API_PUBLIC_URL = 'https://api.afapay.test';

  const result = await mediaStorage.upload(
    {
      buffer: Buffer.from('hello media'),
      originalname: 'Chat Photo.JPG',
      mimetype: 'image/jpeg',
      size: 11,
    },
    {
      folder: 'afapay-chat',
      type: 'image',
      area: 'afapay_chat_image',
    },
  );

  assert.equal(result.provider, mediaStorage.PROVIDERS.LOCAL);
  assert.match(result.key, /^afapay-chat\/image-\d+-[a-z0-9]+-chat-photo\.jpg$/);
  assert.equal(result.secure_url, `https://api.afapay.test/media/${result.key}`);
  assert.equal(await fs.readFile(path.join(root, result.key), 'utf8'), 'hello media');

  await fs.rm(root, { recursive: true, force: true });
});
