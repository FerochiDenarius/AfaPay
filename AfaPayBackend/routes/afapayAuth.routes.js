const crypto = require('crypto');
const express = require('express');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');

const User = require('../models/afapayUser.model');
const BiometricSetting = require('../models/afapayBiometricSetting.model');
const LoginHistory = require('../models/afapayLoginHistory.model');
const PinCredential = require('../models/afapayPinCredential.model');
const RefreshToken = require('../models/afapayRefreshToken.model');
const SecurityAuditLog = require('../models/afapaySecurityAuditLog.model');
const UserDevice = require('../models/afapayUserDevice.model');
const { hashSecret, verifySecret } = require('../services/securityHash.service');

const router = express.Router();

const CODE_LIFETIME_SECONDS = Number(process.env.EMAIL_CODE_LIFETIME || 900);
const RESEND_COOLDOWN_SECONDS = Number(process.env.EMAIL_RESEND_COOLDOWN || 90);
const ACCESS_TOKEN_LIFETIME = process.env.ACCESS_TOKEN_LIFETIME || '15m';
const REFRESH_TOKEN_LIFETIME = process.env.REFRESH_TOKEN_LIFETIME || '60d';
const REFRESH_TOKEN_DAYS = Number(process.env.REFRESH_TOKEN_DAYS || 60);
const MAX_VERIFY_ATTEMPTS = 5;

const normalizeEmail = (value) => String(value || '').trim().toLowerCase();
const normalizeText = (value, max = 255) =>
  String(value || '').trim().slice(0, max);
const hashCode = (code) =>
  crypto.createHash('sha256').update(String(code)).digest('hex');
const isEmail = (value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
const phoneOtpEnabled = () => process.env.PHONE_OTP_ENABLED === 'true';

function resendConfigured() {
  return Boolean(process.env.RESEND_API_KEY && process.env.EMAIL_FROM);
}

function userTokenPayload(user) {
  return {
    sub: user._id.toString(),
    userId: user._id.toString(),
    username: user.username,
  };
}

function issueTokens(user, deviceId = '') {
  const payload = userTokenPayload(user);
  return {
    accessToken: jwt.sign({ ...payload, deviceId, jti: crypto.randomUUID() }, process.env.ACCESS_TOKEN_SECRET, {
      expiresIn: ACCESS_TOKEN_LIFETIME,
      issuer: 'afapay',
      audience: 'afapay-mobile',
    }),
    refreshToken: jwt.sign({ ...payload, deviceId, jti: crypto.randomUUID() }, process.env.REFRESH_TOKEN_SECRET, {
      expiresIn: REFRESH_TOKEN_LIFETIME,
      issuer: 'afapay',
      audience: 'afapay-mobile',
    }),
  };
}

function clientIp(req) {
  return (
    req.headers['x-forwarded-for']?.toString().split(',')[0].trim() ||
    req.socket?.remoteAddress ||
    ''
  );
}

function requestDevice(req) {
  const bodyDevice = req.body?.device && typeof req.body.device === 'object' ? req.body.device : {};
  return {
    deviceId: normalizeText(
      req.body?.deviceId || bodyDevice.deviceId || req.headers['x-device-id'] || crypto.randomUUID(),
      128,
    ),
    deviceName: normalizeText(req.body?.deviceName || bodyDevice.deviceName, 160),
    platform: normalizeText(req.body?.platform || bodyDevice.platform, 40),
    osVersion: normalizeText(req.body?.osVersion || bodyDevice.osVersion, 80),
    pushNotificationToken: normalizeText(
      req.body?.pushNotificationToken || bodyDevice.pushNotificationToken,
      512,
    ),
  };
}

async function audit({ userId = null, eventType, status = 'success', req, deviceId = '', metadata = {} }) {
  try {
    await SecurityAuditLog.create({
      userId,
      eventType,
      status,
      ipAddress: req ? clientIp(req) : '',
      deviceId,
      metadata,
    });
  } catch (error) {
    console.warn('[AfaPay] audit log failed:', error.message);
  }
}

async function registerDevice({ user, req, device }) {
  return UserDevice.findOneAndUpdate(
    { userId: user._id, deviceId: device.deviceId },
    {
      $set: {
        deviceName: device.deviceName,
        platform: device.platform,
        osVersion: device.osVersion,
        pushNotificationToken: device.pushNotificationToken,
        lastLogin: new Date(),
        lastIp: clientIp(req),
        revoked: false,
      },
      $setOnInsert: {
        userId: user._id,
        deviceId: device.deviceId,
      },
    },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );
}

async function storeRefreshToken({ user, deviceId, refreshToken }) {
  const expiresAt = new Date(Date.now() + REFRESH_TOKEN_DAYS * 24 * 60 * 60 * 1000);
  await RefreshToken.create({
    userId: user._id,
    deviceId,
    tokenHash: hashCode(refreshToken),
    expiresAt,
    revoked: false,
  });
  return expiresAt;
}

async function userSecurityStatus(userId) {
  const [pin, biometric] = await Promise.all([
    PinCredential.findOne({ userId }).lean(),
    BiometricSetting.findOne({ userId }).lean(),
  ]);
  return {
    pinConfigured: Boolean(pin),
    biometricEnabled: Boolean(biometric?.biometricEnabled),
  };
}

async function sendEmailVerificationCode({ to, code }) {
  const expiresInMinutes = Math.ceil(CODE_LIFETIME_SECONDS / 60);
  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${process.env.RESEND_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: process.env.EMAIL_FROM,
      to,
      subject: 'Your AfaPay verification code',
      text: `Your AfaPay verification code is ${code}. It expires in ${expiresInMinutes} minutes.`,
      html: `<p>Your AfaPay verification code is:</p><h2>${code}</h2><p>It expires in ${expiresInMinutes} minutes.</p>`,
    }),
  });

  if (!response.ok) {
    let message = 'Resend email delivery failed.';
    try {
      const body = await response.json();
      message = body?.message || body?.error || message;
    } catch (_) {
      // Keep the generic delivery failure.
    }
    throw new Error(message);
  }
}

router.post('/register', async (req, res) => {
  try {
    const firstName = normalizeText(req.body.firstName, 80);
    const lastName = normalizeText(req.body.lastName, 80);
    const username = normalizeText(req.body.username, 20).toLowerCase();
    const country = normalizeText(req.body.country, 80);
    const phoneNumber = normalizeText(req.body.phoneNumber, 30);
    const email = normalizeEmail(req.body.email);
    const password = String(req.body.password || '');

    if (
      firstName.length < 2 ||
      lastName.length < 2 ||
      !/^[a-z0-9_]{4,20}$/i.test(username) ||
      !country ||
      !phoneNumber ||
      !isEmail(email) ||
      password.length < 8
    ) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or missing registration fields.',
      });
    }

    const duplicate = await User.findOne({
      $or: [{ username }, { email }, { phoneNumber }],
    }).lean();
    if (duplicate) {
      return res.status(409).json({
        success: false,
        message: 'Username, email, or phone number is already in use.',
      });
    }

    const user = await User.create({
      firstName,
      lastName,
      username,
      country,
      location: country,
      phoneNumber,
      email,
      password: await hashSecret(password),
    });

    return res.status(201).json({
      success: true,
      verificationRequired: true,
      phoneVerificationRequired: phoneOtpEnabled(),
      nextStep: phoneOtpEnabled() ? 'verify_phone' : 'pin_setup',
      userId: user._id.toString(),
    });
  } catch (error) {
    if (error?.code === 11000) {
      return res.status(409).json({
        success: false,
        message: 'Username, email, or phone number is already in use.',
      });
    }
    console.error('[AfaPay] registration failed:', error);
    return res.status(500).json({
      success: false,
      message: 'Registration could not be completed.',
    });
  }
});

router.post('/login', async (req, res) => {
  try {
    const identifier = normalizeText(req.body.identifier).toLowerCase();
    const password = String(req.body.password || '');
    if (!identifier || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email, phone number, or username and password are required.',
      });
    }
    if (!process.env.ACCESS_TOKEN_SECRET || !process.env.REFRESH_TOKEN_SECRET) {
      return res.status(503).json({
        success: false,
        message: 'Authentication is not configured on the server.',
      });
    }

    const user = await User.findOne({
      $or: [
        { email: identifier },
        { phoneNumber: normalizeText(req.body.identifier, 30) },
        { username: identifier },
      ],
    });
    if (!user || !(await verifySecret(user.password, password))) {
      await LoginHistory.create({
        userId: user?._id || new mongoose.Types.ObjectId(),
        ipAddress: clientIp(req),
        deviceId: normalizeText(req.body?.deviceId || req.body?.device?.deviceId, 128),
        status: 'failed',
        reason: 'invalid_credentials',
      }).catch(() => {});
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials.',
      });
    }

    const device = requestDevice(req);
    await registerDevice({ user, req, device });
    await RefreshToken.updateMany(
      { userId: user._id, deviceId: device.deviceId, revoked: false },
      { $set: { revoked: true, revokedAt: new Date() } },
    );
    const { accessToken, refreshToken } = issueTokens(user, device.deviceId);
    const refreshTokenExpiresAt = await storeRefreshToken({
      user,
      deviceId: device.deviceId,
      refreshToken,
    });
    user.refreshToken = hashCode(refreshToken);
    user.lastLoginAt = new Date();
    user.lastLoginIp = clientIp(req);
    user.lastLoginUserAgent = normalizeText(req.headers['user-agent'], 255);
    await user.save();
    await LoginHistory.create({
      userId: user._id,
      ipAddress: clientIp(req),
      deviceId: device.deviceId,
      status: 'success',
    }).catch(() => {});
    await audit({
      userId: user._id,
      eventType: 'login',
      req,
      deviceId: device.deviceId,
    });
    const security = await userSecurityStatus(user._id);

    return res.status(200).json({
      success: true,
      accessToken,
      refreshToken,
      deviceId: device.deviceId,
      refreshTokenExpiresAt,
      ...security,
      user: {
        id: user._id.toString(),
        firstName: user.firstName || '',
        lastName: user.lastName || '',
        username: user.username,
        email: user.email || '',
        phoneNumber: user.phoneNumber || '',
        emailVerified: Boolean(user.emailVerified),
        phoneVerified: Boolean(user.phoneVerified),
      },
    });
  } catch (error) {
    console.error('[AfaPay] login failed:', error);
    return res.status(500).json({
      success: false,
      message: 'Login could not be completed.',
    });
  }
});

router.post('/refresh', async (req, res) => {
  try {
    const refreshToken = String(req.body.refreshToken || '').trim();
    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        message: 'Refresh token is required.',
      });
    }
    if (!process.env.ACCESS_TOKEN_SECRET || !process.env.REFRESH_TOKEN_SECRET) {
      return res.status(503).json({
        success: false,
        message: 'Authentication is not configured on the server.',
      });
    }

    const decoded = jwt.verify(refreshToken, process.env.REFRESH_TOKEN_SECRET, {
      issuer: 'afapay',
      audience: 'afapay-mobile',
    });
    const user = await User.findById(decoded.userId || decoded.sub);
    const tokenHash = hashCode(refreshToken);
    const suppliedDeviceId = normalizeText(req.body.deviceId || decoded.deviceId, 128);
    const storedToken = await RefreshToken.findOne({
      userId: decoded.userId || decoded.sub,
      tokenHash,
      revoked: false,
      expiresAt: { $gt: new Date() },
      ...(suppliedDeviceId ? { deviceId: suppliedDeviceId } : {}),
    });
    if (!user || (!storedToken && user.refreshToken !== tokenHash)) {
      return res.status(401).json({
        success: false,
        message: 'Session expired. Please log in again.',
      });
    }

    const deviceId = storedToken?.deviceId || suppliedDeviceId || decoded.deviceId || '';
    if (storedToken) {
      storedToken.revoked = true;
      storedToken.revokedAt = new Date();
      await storedToken.save();
    }
    const tokens = issueTokens(user, deviceId);
    await storeRefreshToken({ user, deviceId, refreshToken: tokens.refreshToken });
    user.refreshToken = hashCode(tokens.refreshToken);
    await user.save();
    if (deviceId) {
      await UserDevice.updateOne(
        { userId: user._id, deviceId, revoked: false },
        { $set: { lastLogin: new Date(), lastIp: clientIp(req) } },
      );
    }
    await audit({
      userId: user._id,
      eventType: 'refresh_token_rotate',
      req,
      deviceId,
    });

    return res.status(200).json({
      success: true,
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      deviceId,
    });
  } catch (_) {
    return res.status(401).json({
      success: false,
      message: 'Session expired. Please log in again.',
    });
  }
});

router.post('/send-email-verification', async (req, res) => {
  try {
    const { userId } = req.body;
    const email = normalizeEmail(req.body.email);
    if (!mongoose.isValidObjectId(userId) || !isEmail(email)) {
      return res.status(400).json({
        success: false,
        message: 'A valid user and email address are required.',
      });
    }
    if (!resendConfigured()) {
      return res.status(503).json({
        success: false,
        message: 'Email delivery is not configured on the server.',
      });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    const duplicate = await User.findOne({
      _id: { $ne: user._id },
      email,
    }).lean();
    if (duplicate) {
      return res.status(409).json({
        success: false,
        message: 'Email already in use',
      });
    }

    const now = Date.now();
    if (
      user.emailVerificationCooldown &&
      user.emailVerificationCooldown.getTime() > now
    ) {
      const retryAfterSeconds = Math.ceil(
        (user.emailVerificationCooldown.getTime() - now) / 1000,
      );
      return res.status(429).json({
        success: false,
        message: 'Please wait before requesting another code.',
        retryAfterSeconds,
      });
    }

    const code = crypto.randomInt(100000, 1000000).toString();
    user.email = email;
    user.emailVerified = false;
    user.emailVerificationCode = hashCode(code);
    user.emailVerificationExpires = new Date(
      now + CODE_LIFETIME_SECONDS * 1000,
    );
    user.emailVerificationCooldown = new Date(
      now + RESEND_COOLDOWN_SECONDS * 1000,
    );
    user.emailVerificationAttempts = 0;
    await user.save();

    await sendEmailVerificationCode({ to: email, code });

    return res.status(200).json({
      success: true,
      message: 'Verification code sent',
      email,
      expiresInSeconds: CODE_LIFETIME_SECONDS,
    });
  } catch (error) {
    console.error('[AfaPay] send email verification failed:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to send the verification code.',
    });
  }
});

router.post('/verify-email', async (req, res) => {
  try {
    const { userId } = req.body;
    const email = normalizeEmail(req.body.email);
    const otp = String(req.body.otp || '').trim();
    if (
      !mongoose.isValidObjectId(userId) ||
      !isEmail(email) ||
      !/^\d{6}$/.test(otp)
    ) {
      return res.status(400).json({
        success: false,
        verified: false,
        message: 'A valid 6-digit code is required.',
      });
    }

    const user = await User.findOne({ _id: userId, email });
    if (!user) {
      return res.status(404).json({
        success: false,
        verified: false,
        message: 'User not found.',
      });
    }
    if (!user.emailVerificationCode || !user.emailVerificationExpires) {
      return res.status(400).json({
        success: false,
        verified: false,
        message: 'No verification is in progress.',
      });
    }
    if (user.emailVerificationAttempts >= MAX_VERIFY_ATTEMPTS) {
      return res.status(429).json({
        success: false,
        verified: false,
        message: 'Too many attempts. Request a new code.',
      });
    }
    if (Date.now() > user.emailVerificationExpires.getTime()) {
      return res.status(400).json({
        success: false,
        verified: false,
        message: 'Verification code expired.',
      });
    }
    if (hashCode(otp) !== user.emailVerificationCode) {
      user.emailVerificationAttempts += 1;
      await user.save();
      return res.status(400).json({
        success: false,
        verified: false,
        message: 'Invalid code',
      });
    }

    user.emailVerified = true;
    user.accountStatus = 'active';
    user.emailVerificationCode = undefined;
    user.emailVerificationExpires = undefined;
    user.emailVerificationCooldown = undefined;
    user.emailVerificationAttempts = 0;
    await user.save();

    return res.status(200).json({
      success: true,
      verified: true,
      nextStep: 'onboarding_complete',
    });
  } catch (error) {
    console.error('[AfaPay] email confirmation failed:', error);
    return res.status(500).json({
      success: false,
      verified: false,
      message: 'Unable to verify the code.',
    });
  }
});

router.post('/verify-phone', (_req, res) => {
  return res.status(501).json({
    success: false,
    verified: false,
    message: 'Phone OTP delivery is not configured yet.',
  });
});

router.post('/resend-phone-otp', (_req, res) => {
  return res.status(501).json({
    success: false,
    message: 'Phone OTP delivery is not configured yet.',
  });
});

module.exports = router;
