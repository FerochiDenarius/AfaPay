const assert = require('node:assert/strict');
const http = require('node:http');
const test = require('node:test');

const express = require('express');
const jwt = require('jsonwebtoken');

const User = require('../models/afapayUser.model');
const afapayDashboardRoutes = require('../routes/afapayDashboard.routes');

const originalFindById = User.findById;

process.env.ACCESS_TOKEN_SECRET = 'test-access-token-secret-with-enough-length';

function createApp() {
  const app = express();
  app.use(express.json());
  app.use('/api', afapayDashboardRoutes);
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

async function getJson(baseUrl, path, token) {
  const response = await fetch(`${baseUrl}${path}`, {
    headers: {
      Accept: 'application/json',
      Authorization: `Bearer ${token}`,
    },
  });

  return {
    status: response.status,
    body: await response.json(),
  };
}

test.afterEach(() => {
  User.findById = originalFindById;
});

test('profile endpoint returns the authenticated AfaPay user', async () => {
  User.findById = () => ({
    lean: async () => ({
      _id: {
        toString: () => '507f1f77bcf86cd799439011',
      },
      firstName: 'Bright',
      lastName: 'Menya',
      email: 'bright@example.com',
      phoneNumber: '+233241234567',
    }),
  });
  const token = jwt.sign(
    {
      sub: '507f1f77bcf86cd799439011',
      userId: '507f1f77bcf86cd799439011',
      username: 'bright',
    },
    process.env.ACCESS_TOKEN_SECRET,
    {
      expiresIn: '15m',
      issuer: 'afapay',
      audience: 'afapay-mobile',
    },
  );

  await withServer(createApp(), async (baseUrl) => {
    const response = await getJson(baseUrl, '/api/user/profile', token);

    assert.equal(response.status, 200);
    assert.deepEqual(response.body, {
      id: '507f1f77bcf86cd799439011',
      firstName: 'Bright',
      lastName: 'Menya',
      email: 'bright@example.com',
      phoneNumber: '+233241234567',
    });
  });
});

test('wallet endpoint requires a valid access token', async () => {
  await withServer(createApp(), async (baseUrl) => {
    const response = await getJson(baseUrl, '/api/wallet/balance', 'bad-token');

    assert.equal(response.status, 401);
    assert.equal(response.body.success, false);
  });
});
