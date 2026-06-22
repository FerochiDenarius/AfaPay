const assert = require('node:assert/strict');
const http = require('node:http');
const test = require('node:test');

const bcrypt = require('bcryptjs');
const express = require('express');
const jwt = require('jsonwebtoken');

const User = require('../models/afapayUser.model');
const afapayAuthRoutes = require('../routes/afapayAuth.routes');

const originalUserMethods = {
  create: User.create,
  findById: User.findById,
  findOne: User.findOne,
};
const originalFetch = globalThis.fetch;

process.env.ACCESS_TOKEN_SECRET = 'test-access-token-secret-with-enough-length';
process.env.REFRESH_TOKEN_SECRET = 'test-refresh-token-secret-with-enough-length';
process.env.RESEND_API_KEY = 're_test_api_key';
process.env.EMAIL_FROM = 'AfaPay <noreply@afapay.xyz>';

function createApp() {
  const app = express();
  app.use(express.json());
  app.use('/api/afapay/auth', afapayAuthRoutes);
  app.use('/api/auth', afapayAuthRoutes);
  return app;
}

async function withServer(handler, callback) {
  const server = http.createServer(handler);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address();

  try {
    await callback(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve, reject) => {
      server.close((error) => (error ? reject(error) : resolve()));
    });
  }
}

async function postJson(baseUrl, path, body) {
  const response = await fetch(`${baseUrl}${path}`, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  return {
    status: response.status,
    body: await response.json(),
  };
}

test.afterEach(() => {
  User.create = originalUserMethods.create;
  User.findById = originalUserMethods.findById;
  User.findOne = originalUserMethods.findOne;
  globalThis.fetch = originalFetch;
});

test('register creates an AfaPay user with a hashed password', async () => {
  let createdUser;

  User.findOne = () => ({
    lean: async () => null,
  });
  User.create = async (doc) => {
    createdUser = doc;
    return {
      _id: {
        toString: () => '507f1f77bcf86cd799439011',
      },
    };
  };

  await withServer(createApp(), async (baseUrl) => {
    const response = await postJson(baseUrl, '/api/afapay/auth/register', {
      firstName: 'Ama',
      lastName: 'Mensah',
      username: 'amapay',
      country: 'Ghana',
      phoneNumber: '+233241234567',
      email: 'AMA@example.com',
      password: 'StrongPass1!',
    });

    assert.equal(response.status, 201);
    assert.deepEqual(response.body, {
      success: true,
      verificationRequired: true,
      phoneVerificationRequired: false,
      nextStep: 'pin_setup',
      userId: '507f1f77bcf86cd799439011',
    });
    assert.equal(createdUser.email, 'ama@example.com');
    assert.equal(createdUser.username, 'amapay');
    assert.equal(createdUser.country, 'Ghana');
    assert.notEqual(createdUser.password, 'StrongPass1!');
    assert.equal(await bcrypt.compare('StrongPass1!', createdUser.password), true);
  });
});

test('login returns signed access and refresh tokens for a valid user', async () => {
  const passwordHash = await bcrypt.hash('StrongPass1!', 4);
  let savedUser;

  User.findOne = async () => ({
    _id: {
      toString: () => '507f1f77bcf86cd799439011',
    },
    firstName: 'Ama',
    lastName: 'Mensah',
    username: 'amapay',
    email: 'ama@example.com',
    phoneNumber: '+233241234567',
    emailVerified: true,
    phoneVerified: false,
    password: passwordHash,
    async save() {
      savedUser = this;
    },
  });

  await withServer(createApp(), async (baseUrl) => {
    const response = await postJson(baseUrl, '/api/afapay/auth/login', {
      identifier: 'ama@example.com',
      password: 'StrongPass1!',
    });

    assert.equal(response.status, 200);
    assert.equal(response.body.success, true);
    assert.equal(response.body.user.id, '507f1f77bcf86cd799439011');
    assert.equal(response.body.user.username, 'amapay');
    assert.match(response.body.accessToken, /^[\w-]+\.[\w-]+\.[\w-]+$/);
    assert.match(response.body.refreshToken, /^[\w-]+\.[\w-]+\.[\w-]+$/);
    assert.match(savedUser.refreshToken, /^[a-f0-9]{64}$/);
    assert.ok(savedUser.lastLoginAt instanceof Date);

    const decoded = jwt.verify(
      response.body.accessToken,
      process.env.ACCESS_TOKEN_SECRET,
      {
        audience: 'afapay-mobile',
        issuer: 'afapay',
      },
    );
    assert.equal(decoded.userId, '507f1f77bcf86cd799439011');
    assert.equal(decoded.username, 'amapay');
  });
});

test('send-email-verification stores hashed OTP and sends through Resend API', async () => {
  const user = {
    _id: {
      toString: () => '507f1f77bcf86cd799439011',
    },
    email: 'ama@example.com',
    emailVerified: true,
    async save() {},
  };
  let savedUser;
  let resendRequest;

  User.findById = async () => user;
  User.findOne = () => ({
    lean: async () => null,
  });
  user.save = async function save() {
    savedUser = this;
  };
  globalThis.fetch = async (url, options) => {
    if (url === 'https://api.resend.com/emails') {
      resendRequest = {
        headers: options.headers,
        body: JSON.parse(options.body),
      };
      return {
        ok: true,
        json: async () => ({ id: 'email_123' }),
      };
    }
    return originalFetch(url, options);
  };

  await withServer(createApp(), async (baseUrl) => {
    const response = await postJson(
      baseUrl,
      '/api/afapay/auth/send-email-verification',
      {
        userId: '507f1f77bcf86cd799439011',
        email: 'AMA@example.com',
      },
    );

    assert.equal(response.status, 200);
    assert.equal(response.body.success, true);
    assert.equal(response.body.email, 'ama@example.com');
    assert.equal(response.body.expiresInSeconds, 600);
    assert.equal(savedUser.email, 'ama@example.com');
    assert.equal(savedUser.emailVerified, false);
    assert.match(savedUser.emailVerificationCode, /^[a-f0-9]{64}$/);
    assert.ok(savedUser.emailVerificationExpires instanceof Date);
    assert.equal(savedUser.emailVerificationAttempts, 0);
    assert.equal(
      Math.round((savedUser.emailVerificationExpires.getTime() - Date.now()) / 1000),
      600,
    );
    assert.equal(resendRequest.headers.Authorization, 'Bearer re_test_api_key');
    assert.equal(resendRequest.body.from, 'AfaPay <noreply@afapay.xyz>');
    assert.equal(resendRequest.body.to, 'ama@example.com');
    assert.match(resendRequest.body.text, /\d{6}/);
  });
});

test('verify-email validates OTP and marks the account email as verified', async () => {
  const otp = '123456';
  const user = {
    _id: {
      toString: () => '507f1f77bcf86cd799439011',
    },
    email: 'ama@example.com',
    emailVerified: false,
    accountStatus: 'pending',
    emailVerificationCode: cryptoHash(otp),
    emailVerificationExpires: new Date(Date.now() + 600000),
    emailVerificationCooldown: new Date(Date.now() + 60000),
    emailVerificationAttempts: 0,
    async save() {},
  };
  let savedUser;

  User.findOne = async () => user;
  user.save = async function save() {
    savedUser = this;
  };

  await withServer(createApp(), async (baseUrl) => {
    const response = await postJson(baseUrl, '/api/auth/verify-email', {
      userId: '507f1f77bcf86cd799439011',
      email: 'ama@example.com',
      otp,
    });

    assert.equal(response.status, 200);
    assert.deepEqual(response.body, {
      success: true,
      verified: true,
      nextStep: 'onboarding_complete',
    });
    assert.equal(savedUser.emailVerified, true);
    assert.equal(savedUser.accountStatus, 'active');
    assert.equal(savedUser.emailVerificationCode, undefined);
    assert.equal(savedUser.emailVerificationExpires, undefined);
  });
});

function cryptoHash(value) {
  return require('crypto').createHash('sha256').update(String(value)).digest('hex');
}
