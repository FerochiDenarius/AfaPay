require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const mongoose = require('mongoose');

const afapayAuthRoutes = require('./routes/afapayAuth.routes');
const afapayDashboardRoutes = require('./routes/afapayDashboard.routes');

const app = express();

function parseCorsOrigin(value) {
  if (!value || value === '*') return true;
  const origins = value
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
  return origins.length === 1 ? origins[0] : origins;
}

app.set('trust proxy', 1);
app.use(helmet());
app.use(
  cors({
    origin: parseCorsOrigin(
      process.env.CORS_ORIGIN || 'https://afapay.xyz,https://www.afapay.xyz',
    ),
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  }),
);
app.use(express.json({ limit: '256kb' }));

app.get('/health', (_req, res) => {
  res.status(mongoose.connection.readyState === 1 ? 200 : 503).json({
    status: mongoose.connection.readyState === 1 ? 'ok' : 'database_unavailable',
    service: 'afapay',
    publicUrl: process.env.API_PUBLIC_URL || 'https://afapay.xyz',
  });
});

app.use('/api/afapay/auth', afapayAuthRoutes);
app.use('/api/auth', afapayAuthRoutes);
app.use('/api', afapayDashboardRoutes);

app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Route not found.' });
});

app.use((error, _req, res, _next) => {
  console.error('[AfaPay] unhandled request error:', error);
  res.status(500).json({
    success: false,
    message: 'Internal server error.',
  });
});

async function start() {
  if (!process.env.MONGODB_URI) {
    throw new Error('MONGODB_URI is required.');
  }

  await mongoose.connect(process.env.MONGODB_URI, {
    serverSelectionTimeoutMS: 10000,
  });

  const port = Number(process.env.PORT || 8080);
  app.listen(port, '0.0.0.0', () => {
    console.log(`[AfaPay] API listening on port ${port}`);
  });
}

start().catch((error) => {
  console.error('[AfaPay] startup failed:', error.message);
  process.exit(1);
});

module.exports = app;
