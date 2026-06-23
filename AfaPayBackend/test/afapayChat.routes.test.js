const assert = require('node:assert/strict');
const http = require('node:http');
const test = require('node:test');

const express = require('express');
const jwt = require('jsonwebtoken');

const User = require('../models/afapayUser.model');
const afapayChatRoutes = require('../routes/afapayChat.routes');

const originalFind = User.find;
const originalFindById = User.findById;

process.env.ACCESS_TOKEN_SECRET = 'test-access-token-secret-with-enough-length';

function createApp() {
  const app = express();
  app.use(express.json());
  app.use('/api', afapayChatRoutes);
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

function tokenFor(userId = '507f1f77bcf86cd799439011') {
  return jwt.sign(
    {
      sub: userId,
      userId,
      username: 'bright',
    },
    process.env.ACCESS_TOKEN_SECRET,
    {
      expiresIn: '15m',
      issuer: 'afapay',
      audience: 'afapay-mobile',
    },
  );
}

test.afterEach(() => {
  User.find = originalFind;
  User.findById = originalFindById;
});

test('username search returns matching AfaPay users', async () => {
  User.findById = () => Promise.resolve({
    _id: {
      toString: () => '507f1f77bcf86cd799439011',
    },
    username: 'bright',
  });
  User.find = (query) => {
    assert.equal(query.username.source, '^ama');
    assert.equal(query.username.flags, 'i');
    return {
      select: () => ({
        sort: () => ({
          limit: () => ({
            lean: async () => [
              {
                _id: {
                  toString: () => '507f1f77bcf86cd799439012',
                },
                username: 'ama',
              },
            ],
          }),
        }),
      }),
    };
  };

  await withServer(createApp(), async (baseUrl) => {
    const response = await fetch(`${baseUrl}/api/users/search?query=ama`, {
      headers: {
        Accept: 'application/json',
        Authorization: `Bearer ${tokenFor()}`,
      },
    });
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.deepEqual(body, [
      {
        _id: '507f1f77bcf86cd799439012',
        id: '507f1f77bcf86cd799439012',
        username: 'ama',
        profileImage: '',
        avatar: '',
        online: false,
        isOnline: false,
        lastSeen: null,
      },
    ]);
  });
});
