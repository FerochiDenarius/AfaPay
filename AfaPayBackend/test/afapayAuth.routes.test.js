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
  findOne: User.findOne,
};

process.env.ACCESS_TOKEN_SECRET = 'test-access-token-secret-with-enough-length';
process.env.REFRESH_TOKEN_SECRET = 'test-refresh-token-secret-with-enough-length';

function createApp() {
  const app = express();
  app.use(express.json());
  app.use('/api/afapay/auth', afapayAuthRoutes);
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
  User.findOne = originalUserMethods.findOne;
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
