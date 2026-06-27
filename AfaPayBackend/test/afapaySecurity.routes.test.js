const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const http = require('node:http');
const test = require('node:test');

const express = require('express');
const jwt = require('jsonwebtoken');

const PinCredential = require('../models/afapayPinCredential.model');
const RefreshToken = require('../models/afapayRefreshToken.model');
const SecurityAuditLog = require('../models/afapaySecurityAuditLog.model');
const User = require('../models/afapayUser.model');
const UserDevice = require('../models/afapayUserDevice.model');
const afapaySecurityRoutes = require('../routes/afapaySecurity.routes');
const { hashSecret } = require('../services/securityHash.service');

const originalUserMethods = {
  findById: User.findById,
};
const originalUserDeviceMethods = {
  findOne: UserDevice.findOne,
};
const originalRefreshTokenMethods = {
  create: RefreshToken.create,
  findOne: RefreshToken.findOne,
  updateMany: RefreshToken.updateMany,
};
const originalSecurityMethods = {
  pinFindOne: PinCredential.findOne,
  auditCreate: SecurityAuditLog.create,
};

process.env.ACCESS_TOKEN_SECRET = 'test-access-token-secret-with-enough-length';
process.env.REFRESH_TOKEN_SECRET = 'test-refresh-token-secret-with-enough-length';

function createApp() {
  const app = express();
  app.use(express.json());
  app.use('/api/security', afapaySecurityRoutes);
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

async function postJson(baseUrl, path, body, token) {
  const response = await fetch(`${baseUrl}${path}`, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(body),
  });

  return {
    status: response.status,
    body: await response.json(),
  };
}

test.afterEach(() => {
  User.findById = originalUserMethods.findById;
  UserDevice.findOne = originalUserDeviceMethods.findOne;
  RefreshToken.create = originalRefreshTokenMethods.create;
  RefreshToken.findOne = originalRefreshTokenMethods.findOne;
  RefreshToken.updateMany = originalRefreshTokenMethods.updateMany;
  PinCredential.findOne = originalSecurityMethods.pinFindOne;
  SecurityAuditLog.create = originalSecurityMethods.auditCreate;
});

test('pin reauth issues tokens for a registered device with an expired access token', async () => {
  const userId = '507f1f77bcf86cd799439011';
  const deviceId = 'device-1';
  const user = {
    _id: {
      toString: () => userId,
    },
    username: 'amapay',
    email: 'ama@example.com',
    firstName: 'Ama',
    lastName: 'Mensah',
  };
  const expiredAccessToken = jwt.sign(
    {
      sub: userId,
      userId,
      username: user.username,
      deviceId,
      exp: Math.floor(Date.now() / 1000) - 60,
    },
    process.env.ACCESS_TOKEN_SECRET,
    {
      issuer: 'afapay',
      audience: 'afapay-mobile',
    },
  );
  const refreshToken = jwt.sign(
    {
      sub: userId,
      userId,
      username: user.username,
      deviceId,
    },
    process.env.REFRESH_TOKEN_SECRET,
    {
      expiresIn: '60d',
      issuer: 'afapay',
      audience: 'afapay-mobile',
    },
  );
  const refreshTokenHash = crypto
    .createHash('sha256')
    .update(refreshToken)
    .digest('hex');
  let revokedDeviceTokens = false;
  let storedRefreshToken;
  let refreshLookup;

  User.findById = () => ({
    select: async () => user,
  });
  PinCredential.findOne = async () => ({
    userId,
    pinHash: await hashSecret('1234'),
  });
  UserDevice.findOne = async () => ({
    userId,
    deviceId,
    revoked: false,
  });
  RefreshToken.findOne = async (query) => {
    refreshLookup = query;
    return {
      userId,
      deviceId,
      tokenHash: refreshTokenHash,
      revoked: false,
      expiresAt: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000),
    };
  };
  RefreshToken.updateMany = async () => {
    revokedDeviceTokens = true;
    return { modifiedCount: 1 };
  };
  RefreshToken.create = async (doc) => {
    storedRefreshToken = doc;
    return doc;
  };
  SecurityAuditLog.create = async () => ({});

  await withServer(createApp(), async (baseUrl) => {
    const response = await postJson(
      baseUrl,
      '/api/security/pin/reauth',
      { pin: '1234', deviceId, refreshToken },
      expiredAccessToken,
    );

    assert.equal(response.status, 200);
    assert.equal(response.body.success, true);
    assert.equal(response.body.deviceId, deviceId);
    assert.match(response.body.accessToken, /^[\w-]+\.[\w-]+\.[\w-]+$/);
    assert.match(response.body.refreshToken, /^[\w-]+\.[\w-]+\.[\w-]+$/);
    assert.equal(revokedDeviceTokens, true);
    assert.equal(refreshLookup.tokenHash, refreshTokenHash);
    assert.equal(refreshLookup.deviceId, deviceId);
    assert.equal(storedRefreshToken.deviceId, deviceId);

    const decoded = jwt.verify(
      response.body.accessToken,
      process.env.ACCESS_TOKEN_SECRET,
      {
        audience: 'afapay-mobile',
        issuer: 'afapay',
      },
    );
    assert.equal(decoded.userId, userId);
    assert.equal(decoded.deviceId, deviceId);
  });
});
