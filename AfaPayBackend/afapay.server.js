require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const mongoose = require('mongoose');

const afapayAuthRoutes = require('./routes/afapayAuth.routes');

const app = express();

app.set('trust proxy', 1);
app.use(helmet());
app.use(
  cors({
    origin: process.env.CORS_ORIGIN || true,
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  }),
);
app.use(express.json({ limit: '256kb' }));

app.get('/health', (_req, res) => {
  res.status(mongoose.connection.readyState === 1 ? 200 : 503).json({
    status: mongoose.connection.readyState === 1 ? 'ok' : 'database_unavailable',
    service: 'afapay',
  });
});

app.use('/api/afapay/auth', afapayAuthRoutes);

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
