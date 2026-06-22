const crypto = require('crypto');
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');

const User = require('../models/afapayUser.model');

const router = express.Router();

const CODE_LIFETIME_SECONDS = Number(process.env.EMAIL_CODE_LIFETIME || 600);
const RESEND_COOLDOWN_SECONDS = Number(process.env.EMAIL_RESEND_COOLDOWN || 60);
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
      password: await bcrypt.hash(password, 12),
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
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials.',
      });
    }

    const payload = {
      sub: user._id.toString(),
      userId: user._id.toString(),
      username: user.username,
    };
    const accessToken = jwt.sign(payload, process.env.ACCESS_TOKEN_SECRET, {
      expiresIn: '15m',
      issuer: 'afapay',
      audience: 'afapay-mobile',
    });
    const refreshToken = jwt.sign(payload, process.env.REFRESH_TOKEN_SECRET, {
      expiresIn: '30d',
      issuer: 'afapay',
      audience: 'afapay-mobile',
    });
    user.refreshToken = hashCode(refreshToken);
    user.lastLoginAt = new Date();
    await user.save();

    return res.status(200).json({
      success: true,
      accessToken,
      refreshToken,
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
