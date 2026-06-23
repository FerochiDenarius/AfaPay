const crypto = require('crypto');
const express = require('express');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');

const BiometricSetting = require('../models/afapayBiometricSetting.model');
const PinAttempt = require('../models/afapayPinAttempt.model');
const PinCredential = require('../models/afapayPinCredential.model');
const RefreshToken = require('../models/afapayRefreshToken.model');
const SecurityAuditLog = require('../models/afapaySecurityAuditLog.model');
const User = require('../models/afapayUser.model');
const UserDevice = require('../models/afapayUserDevice.model');
const { hashSecret, verifySecret } = require('../services/securityHash.service');

const router = express.Router();

const MAX_PIN_FAILURES = Number(process.env.MAX_PIN_FAILURES || 5);
const PIN_LOCK_MINUTES = Number(process.env.PIN_LOCK_MINUTES || 15);
const ACCESS_TOKEN_LIFETIME = process.env.ACCESS_TOKEN_LIFETIME || '15m';
const REFRESH_TOKEN_LIFETIME = process.env.REFRESH_TOKEN_LIFETIME || '60d';
const REFRESH_TOKEN_DAYS = Number(process.env.REFRESH_TOKEN_DAYS || 60);

const normalizeText = (value, max = 255) =>
  String(value || '').trim().slice(0, max);
const hashCode = (code) =>
  crypto.createHash('sha256').update(String(code)).digest('hex');

function clientIp(req) {
  return (
    req.headers['x-forwarded-for']?.toString().split(',')[0].trim() ||
    req.socket?.remoteAddress ||
    ''
  );
}

async function audit({ userId, eventType, status = 'success', req, deviceId = '', metadata = {} }) {
  await SecurityAuditLog.create({
    userId,
    eventType,
    status,
    ipAddress: clientIp(req),
    deviceId,
    metadata,
  }).catch((error) => {
    console.warn('[AfaPay] security audit failed:', error.message);
  });
}

function issueTokens(user, deviceId) {
  const payload = {
    sub: user._id.toString(),
    userId: user._id.toString(),
    username: user.username,
    deviceId,
    jti: crypto.randomUUID(),
  };
  return {
    accessToken: jwt.sign(payload, process.env.ACCESS_TOKEN_SECRET, {
      expiresIn: ACCESS_TOKEN_LIFETIME,
      issuer: 'afapay',
      audience: 'afapay-mobile',
    }),
    refreshToken: jwt.sign(payload, process.env.REFRESH_TOKEN_SECRET, {
      expiresIn: REFRESH_TOKEN_LIFETIME,
      issuer: 'afapay',
      audience: 'afapay-mobile',
    }),
  };
}

async function storeRefreshToken({ user, deviceId, refreshToken }) {
  await RefreshToken.create({
    userId: user._id,
    deviceId,
    tokenHash: hashCode(refreshToken),
    expiresAt: new Date(Date.now() + REFRESH_TOKEN_DAYS * 24 * 60 * 60 * 1000),
    revoked: false,
  });
}

async function requireAuth(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7).trim() : '';
    if (!token) {
      return res.status(401).json({ success: false, message: 'Authentication required.' });
    }
    const decoded = jwt.verify(token, process.env.ACCESS_TOKEN_SECRET, {
      issuer: 'afapay',
      audience: 'afapay-mobile',
    });
    const user = await User.findById(decoded.userId || decoded.sub).select(
      '_id username email firstName lastName',
    );
    if (!user) {
      return res.status(401).json({ success: false, message: 'User not found.' });
    }
    req.user = user;
    req.authDeviceId = normalizeText(decoded.deviceId || req.headers['x-device-id'], 128);
    return next();
  } catch (_) {
    return res.status(401).json({ success: false, message: 'Session expired.' });
  }
}

router.use(requireAuth);

router.post('/device/register', async (req, res) => {
  const deviceId = normalizeText(req.body.deviceId || req.authDeviceId || crypto.randomUUID(), 128);
  const update = {
    deviceName: normalizeText(req.body.deviceName, 160),
    platform: normalizeText(req.body.platform, 40),
    osVersion: normalizeText(req.body.osVersion, 80),
    pushNotificationToken: normalizeText(req.body.pushNotificationToken, 512),
    lastLogin: new Date(),
    lastIp: clientIp(req),
    revoked: false,
  };
  const device = await UserDevice.findOneAndUpdate(
    { userId: req.user._id, deviceId },
    { $set: update, $setOnInsert: { userId: req.user._id, deviceId } },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );
  await audit({ userId: req.user._id, eventType: 'device_register', req, deviceId });
  return res.status(200).json({ success: true, device: serializeDevice(device) });
});

router.get('/devices', async (req, res) => {
  const devices = await UserDevice.find({ userId: req.user._id, revoked: false })
    .sort({ lastLogin: -1 })
    .lean();
  return res.status(200).json({ success: true, devices: devices.map(serializeDevice) });
});

router.delete('/devices/:deviceId', async (req, res) => {
  const deviceId = normalizeText(req.params.deviceId, 128);
  await UserDevice.updateOne(
    { userId: req.user._id, deviceId },
    { $set: { revoked: true } },
  );
  await RefreshToken.updateMany(
    { userId: req.user._id, deviceId, revoked: false },
    { $set: { revoked: true, revokedAt: new Date() } },
  );
  await audit({ userId: req.user._id, eventType: 'device_remove', req, deviceId });
  return res.status(200).json({ success: true });
});

router.post('/logout-all', async (req, res) => {
  await RefreshToken.updateMany(
    { userId: req.user._id, revoked: false },
    { $set: { revoked: true, revokedAt: new Date() } },
  );
  await UserDevice.updateMany(
    { userId: req.user._id },
    { $set: { revoked: true } },
  );
  await audit({ userId: req.user._id, eventType: 'logout_all', req, deviceId: req.authDeviceId });
  return res.status(200).json({ success: true });
});

router.post('/pin/setup', async (req, res) => {
  const pin = String(req.body.pin || '');
  if (!/^\d{4,6}$/.test(pin)) {
    return res.status(400).json({
      success: false,
      message: 'PIN must be 4 to 6 digits.',
    });
  }
  await PinCredential.findOneAndUpdate(
    { userId: req.user._id },
    { $set: { pinHash: await hashSecret(pin) } },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );
  await PinAttempt.findOneAndUpdate(
    { userId: req.user._id },
    { $set: { failedCount: 0, lockedUntil: null } },
    { upsert: true, setDefaultsOnInsert: true },
  );
  await audit({ userId: req.user._id, eventType: 'pin_setup', req, deviceId: req.authDeviceId });
  return res.status(200).json({ success: true, pinConfigured: true });
});

router.post('/pin/verify', async (req, res) => {
  const pin = String(req.body.pin || '');
  const credential = await PinCredential.findOne({ userId: req.user._id });
  if (!credential) {
    return res.status(409).json({ success: false, message: 'PIN setup is required.' });
  }
  const attempt = await PinAttempt.findOneAndUpdate(
    { userId: req.user._id },
    { $setOnInsert: { failedCount: 0, lockedUntil: null } },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );
  if (attempt.lockedUntil && attempt.lockedUntil.getTime() > Date.now()) {
    await audit({
      userId: req.user._id,
      eventType: 'pin_verify',
      status: 'blocked',
      req,
      deviceId: req.authDeviceId,
      metadata: { lockedUntil: attempt.lockedUntil },
    });
    return res.status(423).json({
      success: false,
      lockedUntil: attempt.lockedUntil,
      message: 'PIN is temporarily locked. Try again later.',
    });
  }
  if (!/^\d{4,6}$/.test(pin) || !(await verifySecret(credential.pinHash, pin))) {
    attempt.failedCount += 1;
    if (attempt.failedCount >= MAX_PIN_FAILURES) {
      attempt.lockedUntil = new Date(Date.now() + PIN_LOCK_MINUTES * 60 * 1000);
    }
    await attempt.save();
    await audit({
      userId: req.user._id,
      eventType: 'pin_verify',
      status: 'failed',
      req,
      deviceId: req.authDeviceId,
      metadata: { failedCount: attempt.failedCount },
    });
    return res.status(attempt.lockedUntil ? 423 : 401).json({
      success: false,
      failedCount: attempt.failedCount,
      lockedUntil: attempt.lockedUntil,
      message: attempt.lockedUntil ? 'Too many failed PIN attempts.' : 'Incorrect PIN.',
    });
  }
  attempt.failedCount = 0;
  attempt.lockedUntil = null;
  await attempt.save();
  await audit({ userId: req.user._id, eventType: 'pin_verify', req, deviceId: req.authDeviceId });
  return res.status(200).json({ success: true });
});

router.post('/pin/reauth', async (req, res) => {
  const pin = String(req.body.pin || '');
  const deviceId = normalizeText(req.body.deviceId || req.authDeviceId, 128);
  const credential = await PinCredential.findOne({ userId: req.user._id });
  const device = await UserDevice.findOne({ userId: req.user._id, deviceId, revoked: false });
  if (!credential || !device || !(await verifySecret(credential.pinHash, pin))) {
    await audit({
      userId: req.user._id,
      eventType: 'pin_reauth',
      status: 'failed',
      req,
      deviceId,
    });
    return res.status(401).json({ success: false, message: 'Full authentication is required.' });
  }
  await RefreshToken.updateMany(
    { userId: req.user._id, deviceId, revoked: false },
    { $set: { revoked: true, revokedAt: new Date() } },
  );
  const tokens = issueTokens(req.user, deviceId);
  await storeRefreshToken({ user: req.user, deviceId, refreshToken: tokens.refreshToken });
  await audit({ userId: req.user._id, eventType: 'pin_reauth', req, deviceId });
  return res.status(200).json({ success: true, deviceId, ...tokens });
});

router.post('/biometrics', async (req, res) => {
  const biometricEnabled = req.body.enabled === true;
  await BiometricSetting.findOneAndUpdate(
    { userId: req.user._id },
    { $set: { biometricEnabled } },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );
  await audit({
    userId: req.user._id,
    eventType: biometricEnabled ? 'biometric_enable' : 'biometric_disable',
    req,
    deviceId: req.authDeviceId,
  });
  return res.status(200).json({ success: true, biometricEnabled });
});

router.get('/audit', async (req, res) => {
  const logs = await SecurityAuditLog.find({ userId: req.user._id })
    .sort({ createdAt: -1 })
    .limit(50)
    .lean();
  return res.status(200).json({
    success: true,
    logs: logs.map((log) => ({
      id: log._id.toString(),
      eventType: log.eventType,
      status: log.status,
      deviceId: log.deviceId,
      ipAddress: log.ipAddress,
      createdAt: log.createdAt,
      metadata: log.metadata || {},
    })),
  });
});

function serializeDevice(device) {
  const doc = typeof device?.toObject === 'function' ? device.toObject() : device;
  return {
    id: doc?._id?.toString() || '',
    deviceId: doc?.deviceId || '',
    deviceName: doc?.deviceName || 'Unknown device',
    platform: doc?.platform || '',
    osVersion: doc?.osVersion || '',
    lastLogin: doc?.lastLogin || null,
    lastIp: doc?.lastIp || '',
    createdAt: doc?.createdAt || null,
  };
}

module.exports = router;
