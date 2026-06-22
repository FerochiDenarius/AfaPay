const express = require('express');
const jwt = require('jsonwebtoken');

const User = require('../models/afapayUser.model');

const router = express.Router();

async function requireAfaPayAuth(req, res, next) {
  try {
    const header = req.get('authorization') || '';
    const [scheme, token] = header.split(/\s+/);
    if (scheme?.toLowerCase() !== 'bearer' || !token) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required.',
      });
    }
    if (!process.env.ACCESS_TOKEN_SECRET) {
      return res.status(503).json({
        success: false,
        message: 'Authentication is not configured on the server.',
      });
    }

    const decoded = jwt.verify(token, process.env.ACCESS_TOKEN_SECRET, {
      issuer: 'afapay',
      audience: 'afapay-mobile',
    });
    const user = await User.findById(decoded.userId || decoded.sub).lean();
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'User session is no longer valid.',
      });
    }
    req.afapayUser = user;
    return next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Session expired. Please log in again.',
    });
  }
}

router.get('/user/profile', requireAfaPayAuth, (req, res) => {
  const user = req.afapayUser;
  return res.status(200).json({
    id: user._id.toString(),
    firstName: user.firstName || '',
    lastName: user.lastName || '',
    email: user.email || '',
    phoneNumber: user.phoneNumber || '',
  });
});

router.get('/wallet/balance', requireAfaPayAuth, (req, res) => {
  return res.status(200).json({
    balance: 0,
    currency: 'NGN',
  });
});

router.get('/transactions/recent', requireAfaPayAuth, (_req, res) => {
  return res.status(200).json([]);
});

router.get('/notifications/unread-count', requireAfaPayAuth, (_req, res) => {
  return res.status(200).json({ count: 0 });
});

module.exports = router;
