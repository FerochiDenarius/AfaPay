require('dotenv').config();

const express = require('express');
const http = require('http');
const cors = require('cors');
const helmet = require('helmet');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const { Server } = require('socket.io');

const afapayAuthRoutes = require('./routes/afapayAuth.routes');
const afapayChatRoutes = require('./routes/afapayChat.routes');
const afapayDashboardRoutes = require('./routes/afapayDashboard.routes');
const afapaySecurityRoutes = require('./routes/afapaySecurity.routes');
const AfaPayChatRoom = require('./models/afapayChatRoom.model');
const AfaPayUser = require('./models/afapayUser.model');

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
    methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
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
app.use('/api/security', afapaySecurityRoutes);
app.use('/api', afapayChatRoutes);
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

  const server = http.createServer(app);
  const io = new Server(server, {
    cors: {
      origin: parseCorsOrigin(
        process.env.CORS_ORIGIN || 'https://afapay.xyz,https://www.afapay.xyz',
      ),
      methods: ['GET', 'POST'],
    },
    transports: ['websocket', 'polling'],
  });
  global.afapayIo = io;

  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token || socket.handshake.query?.token;
      if (!token || !process.env.ACCESS_TOKEN_SECRET) {
        return next(new Error('Authentication required.'));
      }
      const decoded = jwt.verify(token, process.env.ACCESS_TOKEN_SECRET, {
        issuer: 'afapay',
        audience: 'afapay-mobile',
      });
      const user = await AfaPayUser.findById(decoded.userId || decoded.sub).select('_id');
      if (!user) return next(new Error('Invalid session.'));
      socket.data.userId = user._id.toString();
      socket.join(socket.data.userId);
      return next();
    } catch (_) {
      return next(new Error('Session expired.'));
    }
  });

  io.on('connection', (socket) => {
    socket.on('joinChatRoom', async (payload = {}) => {
      const roomId = (payload.roomId || payload)?.toString();
      if (!mongoose.isValidObjectId(roomId)) return;
      const room = await AfaPayChatRoom.findOne({
        _id: roomId,
        participants: socket.data.userId,
      }).select('_id').lean();
      if (room) socket.join(roomId);
    });

    socket.on('leaveChatRoom', (payload = {}) => {
      const roomId = (payload.roomId || payload)?.toString();
      if (roomId) socket.leave(roomId);
    });

    socket.on('chatTyping', async (payload = {}) => {
      const roomId = payload.roomId?.toString();
      if (!mongoose.isValidObjectId(roomId)) return;
      const room = await AfaPayChatRoom.findOne({
        _id: roomId,
        participants: socket.data.userId,
      }).select('_id').lean();
      if (!room) return;
      socket.to(roomId).emit('chatTyping', {
        roomId,
        userId: socket.data.userId,
        isTyping: payload.isTyping === true,
      });
    });

    for (const eventName of ['callOffer', 'callAnswer', 'callIceCandidate', 'callEnded']) {
      socket.on(eventName, async (payload = {}) => {
        const roomId = payload.roomId?.toString();
        if (!mongoose.isValidObjectId(roomId)) return;
        const room = await AfaPayChatRoom.findOne({
          _id: roomId,
          participants: socket.data.userId,
        }).select('_id').lean();
        if (!room) return;
        socket.to(roomId).emit(eventName, {
          ...payload,
          roomId,
          senderId: socket.data.userId,
          sentAt: new Date().toISOString(),
        });
      });
    }
  });

  const port = Number(process.env.PORT || 8080);
  server.listen(port, '0.0.0.0', () => {
    console.log(`[AfaPay] API listening on port ${port}`);
  });
}

start().catch((error) => {
  console.error('[AfaPay] startup failed:', error.message);
  process.exit(1);
});

module.exports = app;
