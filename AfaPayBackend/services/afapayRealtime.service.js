const jwt = require('jsonwebtoken');
const { Server } = require('socket.io');

const ChatRoom = require('../models/afapayChatRoom.model');
const User = require('../models/afapayUser.model');
const onlineService = require('../src/services/online/online.service');

function parseCorsOrigin(value) {
  if (!value || value === '*') return true;
  return value
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
}

function tokenFromSocket(socket) {
  const authToken = socket.handshake.auth?.token;
  if (typeof authToken === 'string' && authToken.trim()) {
    return authToken.trim().replace(/^Bearer\s+/i, '');
  }
  const authorization = socket.handshake.headers?.authorization;
  if (typeof authorization === 'string' && authorization.trim()) {
    return authorization.trim().replace(/^Bearer\s+/i, '');
  }
  return '';
}

function verifySocketUser(socket) {
  const token = tokenFromSocket(socket);
  if (!token || !process.env.ACCESS_TOKEN_SECRET) return null;
  try {
    const payload = jwt.verify(token, process.env.ACCESS_TOKEN_SECRET, {
      issuer: 'afapay',
      audience: 'afapay-mobile',
    });
    const userId = String(payload.sub || payload.userId || payload.id || '').trim();
    return userId ? { userId, payload } : null;
  } catch (error) {
    return null;
  }
}

function initAfaPayRealtime(server) {
  const io = new Server(server, {
    cors: {
      origin: parseCorsOrigin(process.env.CORS_ORIGIN || '*'),
      methods: ['GET', 'POST'],
      allowedHeaders: ['Authorization', 'Content-Type'],
    },
    pingInterval: Number(process.env.SOCKET_PING_INTERVAL_MS || 25000),
    pingTimeout: Number(process.env.SOCKET_PING_TIMEOUT_MS || 60000),
    transports: ['websocket', 'polling'],
  });

  global.io = io;
  console.log('[AfaPayRealtime] Socket.IO attached');

  io.on('connection', async (socket) => {
    const auth = verifySocketUser(socket);
    if (!auth) {
      socket.emit('authError', { message: 'Socket authentication failed.' });
      socket.disconnect(true);
      return;
    }

    try {
      await onlineService.markUserOnline({
        io,
        User,
        socket,
        userId: auth.userId,
      });
    } catch (error) {
      console.error('[AfaPayRealtime] online update failed:', error.message);
    }

    socket.on('requestOnlineUsers', async () => {
      socket.emit('getOnlineUsers', await onlineService.getOnlineUserIdsAsync());
    });

    socket.on('userConnected', async () => {
      await onlineService.markUserOnline({
        io,
        User,
        socket,
        userId: auth.userId,
      }).catch((error) => {
        console.error('[AfaPayRealtime] userConnected failed:', error.message);
      });
    });

    socket.on('userOnline', async () => {
      await onlineService.markUserOnline({
        io,
        User,
        socket,
        userId: auth.userId,
      }).catch((error) => {
        console.error('[AfaPayRealtime] userOnline failed:', error.message);
      });
    });

    socket.on('userOffline', async () => {
      await onlineService.markUserOffline({
        io,
        User,
        socket,
        userId: auth.userId,
        immediate: true,
        reason: 'explicit_userOffline',
      }).catch((error) => {
        console.error('[AfaPayRealtime] userOffline failed:', error.message);
      });
    });

    socket.on('joinChatRoom', async (payload = {}) => {
      const roomId = String(payload?.roomId || payload || '').trim();
      if (!roomId) return;

      try {
        const room = await ChatRoom.findOne({
          _id: roomId,
          participants: auth.userId,
        })
          .select('_id')
          .lean();
        if (!room) return;
        socket.join(`chat:${room._id.toString()}`);
      } catch (error) {
        console.error('[AfaPayRealtime] joinChatRoom failed:', error.message);
      }
    });

    socket.on('leaveChatRoom', (roomId) => {
      const normalizedRoomId = String(roomId || '').trim();
      if (!normalizedRoomId) return;
      socket.leave(`chat:${normalizedRoomId}`);
    });

    socket.on('disconnect', async (reason) => {
      await onlineService.markUserOffline({
        io,
        User,
        socket,
        userId: auth.userId,
        reason,
      }).catch((error) => {
        console.error('[AfaPayRealtime] disconnect failed:', error.message);
      });
    });
  });

  return io;
}

module.exports = {
  initAfaPayRealtime,
  parseCorsOrigin,
  tokenFromSocket,
  verifySocketUser,
};
