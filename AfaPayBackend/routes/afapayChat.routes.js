const express = require('express');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const multer = require('multer');

const ChatRoom = require('../models/afapayChatRoom.model');
const ChatSetting = require('../models/afapayChatSetting.model');
const Message = require('../models/afapayMessage.model');
const User = require('../models/afapayUser.model');
const UserReport = require('../models/afapayUserReport.model');
const mediaStorage = require('../services/mediaStorage.service');
const { logUploadAudit } = require('../utils/cloudinaryMedia');

const router = express.Router();

const chatMediaUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 60 * 1024 * 1024 },
  fileFilter(_req, file, cb) {
    const mimetype = file.mimetype || '';
    const allowed =
      mimetype.startsWith('image/') ||
      mimetype.startsWith('video/') ||
      mimetype.startsWith('audio/') ||
      mimetype === 'application/pdf' ||
      mimetype === 'text/plain' ||
      mimetype === 'application/zip' ||
      mimetype === 'application/msword' ||
      mimetype === 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

    cb(allowed ? null : new Error('Unsupported file type'), allowed);
  },
});

function participantKeyFor(userA, userB) {
  return [userA.toString(), userB.toString()].sort().join(':');
}

function escapeRegExp(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function publicUser(user) {
  const isOnline = user.online === true || user.isOnline === true;
  return {
    _id: user._id.toString(),
    id: user._id.toString(),
    username: user.username || '',
    profileImage: '',
    avatar: '',
    online: isOnline,
    isOnline,
    lastSeen: user.lastSeen || null,
  };
}

function resolveChatUploadType(file, requestedType = '') {
  const type = String(requestedType || '').toLowerCase();
  if (['image', 'video', 'audio', 'file'].includes(type)) return type;
  if (file?.mimetype?.startsWith('image/')) return 'image';
  if (file?.mimetype?.startsWith('video/')) return 'video';
  if (file?.mimetype?.startsWith('audio/')) return 'audio';
  return 'file';
}

function mediaMessageKeyFor(type) {
  if (type === 'image') return 'imageUrl';
  if (type === 'video') return 'videoUrl';
  if (type === 'audio') return 'audioUrl';
  return 'fileUrl';
}

function mediaPreview(message) {
  if (message.imageUrl) return 'Photo';
  if (message.videoUrl) return 'Video';
  if (message.audioUrl) return 'Voice message';
  if (message.fileUrl) return 'File';
  return 'Media';
}

const VALID_THEMES = new Set(['gold', 'emerald', 'sky', 'rose']);
const VALID_WALLPAPERS = new Set(['midnight', 'graphite', 'aurora', 'clean']);
const VALID_DISAPPEARING_SECONDS = new Set([86400, 604800, 2592000]);

function settingForClient(setting) {
  return {
    roomId: setting.roomId.toString(),
    userId: setting.userId.toString(),
    theme: setting.theme || 'gold',
    wallpaper: setting.wallpaper || 'midnight',
    muted: setting.muted === true,
    disappearingSeconds: setting.disappearingSeconds || null,
    clearedBefore: setting.clearedBefore || null,
    updatedAt: setting.updatedAt,
  };
}

function normalizeChatSettingPatch(body) {
  const patch = {};
  if (body.theme !== undefined) {
    const theme = String(body.theme || '').trim();
    if (VALID_THEMES.has(theme)) patch.theme = theme;
  }
  if (body.wallpaper !== undefined) {
    const wallpaper = String(body.wallpaper || '').trim();
    if (VALID_WALLPAPERS.has(wallpaper)) patch.wallpaper = wallpaper;
  }
  if (body.muted !== undefined) {
    patch.muted = body.muted === true;
  }
  if (body.disappearingSeconds !== undefined) {
    const seconds = Number(body.disappearingSeconds);
    patch.disappearingSeconds = VALID_DISAPPEARING_SECONDS.has(seconds)
      ? seconds
      : null;
  }
  if (body.clearedBefore !== undefined) {
    const clearedBefore = body.clearedBefore
      ? new Date(String(body.clearedBefore))
      : null;
    patch.clearedBefore =
      clearedBefore && !Number.isNaN(clearedBefore.getTime())
        ? clearedBefore
        : null;
  }
  return patch;
}

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
    const user = await User.findById(decoded.userId || decoded.sub);
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'User session is no longer valid.',
      });
    }
    req.afapayUser = user;
    return next();
  } catch (_) {
    return res.status(401).json({
      success: false,
      message: 'Session expired. Please log in again.',
    });
  }
}

async function ensureRoomParticipant(roomId, userId) {
  if (!mongoose.isValidObjectId(roomId)) return null;
  return ChatRoom.findOne({ _id: roomId, participants: userId });
}

async function getOrCreateRoomSetting(roomId, userId) {
  return ChatSetting.findOneAndUpdate(
    { roomId, userId },
    { $setOnInsert: { roomId, userId } },
    { new: true, upsert: true },
  );
}

function messageVisibleForSetting(message, setting, now = Date.now()) {
  if (!setting) return true;
  const createdAt = message.timestamp || message.createdAt;
  const createdTime = createdAt ? new Date(createdAt).getTime() : null;
  if (!createdTime || Number.isNaN(createdTime)) return true;

  const clearedBefore = setting.clearedBefore
    ? new Date(setting.clearedBefore).getTime()
    : null;
  if (clearedBefore && createdTime <= clearedBefore) return false;

  if (setting.disappearingSeconds) {
    const disappearingCutoff = now - Number(setting.disappearingSeconds) * 1000;
    if (createdTime <= disappearingCutoff) return false;
  }

  return true;
}

function hasBlocked(user, targetUserId) {
  const target = targetUserId?.toString();
  return Boolean(
    target &&
      user?.blockedUsers?.some((blockedUserId) => blockedUserId.toString() === target),
  );
}

async function privateRoomBlockState(room, userId) {
  if (room.roomType !== 'private') return { blocked: false };
  const otherId = (room.participants || [])
    .map((participant) => participant.toString())
    .find((participant) => participant !== userId.toString());
  if (!otherId) return { blocked: false };

  const [currentUser, otherUser] = await Promise.all([
    User.findById(userId).select('blockedUsers').lean(),
    User.findById(otherId).select('blockedUsers username').lean(),
  ]);
  if (hasBlocked(currentUser, otherId)) {
    return { blocked: true, message: 'You have blocked this contact.' };
  }
  if (hasBlocked(otherUser, userId)) {
    return { blocked: true, message: 'This contact is unavailable.' };
  }
  return { blocked: false };
}

async function replyForClient(message) {
  if (!message) return null;
  const isPopulatedMessage =
    typeof message === 'object' &&
    (Object.prototype.hasOwnProperty.call(message, 'text') ||
      Object.prototype.hasOwnProperty.call(message, 'senderId'));
  const replyMessage =
    isPopulatedMessage
      ? message
      : await Message.findById(message).lean();
  if (!replyMessage) return null;

  const senderId = replyMessage.senderId?.toString();
  const sender = senderId
    ? await User.findById(senderId).select('username _id').lean()
    : null;
  return {
    _id: replyMessage._id.toString(),
    id: replyMessage._id.toString(),
    roomId: replyMessage.roomId?.toString() || '',
    conversationId: replyMessage.roomId?.toString() || '',
    senderId: senderId || '',
    sender: sender ? publicUser(sender) : null,
    text: replyMessage.text || '',
    imageUrl: replyMessage.imageUrl || '',
    videoUrl: replyMessage.videoUrl || '',
    audioUrl: replyMessage.audioUrl || '',
    fileUrl: replyMessage.fileUrl || '',
    mediaType: replyMessage.mediaType || '',
    mediaName: replyMessage.mediaName || '',
    mediaMimeType: replyMessage.mediaMimeType || '',
    mediaSizeBytes: replyMessage.mediaSizeBytes || 0,
    timestamp: replyMessage.timestamp || replyMessage.createdAt,
    createdAt: replyMessage.createdAt,
    status: replyMessage.status || 'sent',
  };
}

async function messageForClient(message) {
  const sender = await User.findById(message.senderId)
    .select('username _id')
    .lean();
  return {
    _id: message._id.toString(),
    id: message._id.toString(),
    roomId: message.roomId.toString(),
    conversationId: message.roomId.toString(),
    senderId: message.senderId.toString(),
    sender: sender ? publicUser(sender) : null,
    text: message.text || '',
    imageUrl: message.imageUrl || '',
    videoUrl: message.videoUrl || '',
    audioUrl: message.audioUrl || '',
    fileUrl: message.fileUrl || '',
    mediaType: message.mediaType || '',
    mediaName: message.mediaName || '',
    mediaMimeType: message.mediaMimeType || '',
    mediaSizeBytes: message.mediaSizeBytes || 0,
    repliedTo: await replyForClient(message.repliedTo),
    timestamp: message.timestamp || message.createdAt,
    createdAt: message.createdAt,
    status: message.status || 'sent',
  };
}

async function privateRoomForClient(room, userId) {
  const otherId = (room.participants || [])
    .map((participant) => participant.toString())
    .find((participant) => participant !== userId.toString());
  const otherUser = otherId
    ? await User.findById(otherId).select('username _id online lastSeen').lean()
    : null;
  const lastMessage = await Message.findOne({ roomId: room._id })
    .sort({ timestamp: -1, createdAt: -1 })
    .lean();

  return {
    _id: room._id.toString(),
    roomId: room._id.toString(),
    roomType: 'private',
    participants: otherUser ? [publicUser(otherUser)] : [],
    lastMessage: lastMessage ? await messageForClient(lastMessage) : null,
    lastMessageTime:
      lastMessage?.timestamp || room.lastMessageAt || room.updatedAt || room.createdAt,
    unreadCount: 0,
    createdAt: room.createdAt,
  };
}

async function groupForClient(room) {
  const lastMessage = await Message.findOne({ roomId: room._id })
    .sort({ timestamp: -1, createdAt: -1 })
    .lean();
  const memberIds = room.groupMembers?.length ? room.groupMembers : room.participants;
  const members = memberIds?.length
    ? await User.find({ _id: { $in: memberIds } }).select('username _id online lastSeen').lean()
    : [];

  return {
    _id: room._id.toString(),
    roomId: room._id.toString(),
    roomType: 'group',
    groupName: room.groupName || 'Group Chat',
    groupImage: '',
    groupMembers: members.map(publicUser),
    participants: members.map(publicUser),
    memberCount: members.length,
    lastMessage: lastMessage ? await messageForClient(lastMessage) : null,
    lastMessageTime:
      lastMessage?.timestamp || room.lastMessageAt || room.updatedAt || room.createdAt,
    unreadCount: 0,
    createdAt: room.createdAt,
    updatedAt: room.updatedAt,
  };
}

router.get('/users/search', requireAfaPayAuth, async (req, res) => {
  const query = String(req.query.query || req.query.q || '').trim().toLowerCase();
  if (query.length < 2) return res.json([]);

  const users = await User.find({
    _id: { $ne: req.afapayUser._id },
    username: new RegExp(`^${escapeRegExp(query)}`, 'i'),
  })
    .select('username _id online lastSeen')
    .sort({ username: 1 })
    .limit(20)
    .lean();

  return res.json(users.map(publicUser));
});

router.get('/chatrooms', requireAfaPayAuth, async (req, res) => {
  const rooms = await ChatRoom.find({
    roomType: 'private',
    participants: req.afapayUser._id,
  })
    .sort({ lastMessageAt: -1, updatedAt: -1 })
    .lean();

  return res.json(await Promise.all(rooms.map((room) => privateRoomForClient(room, req.afapayUser._id))));
});

router.post('/chatrooms', requireAfaPayAuth, async (req, res) => {
  const username = String(req.body.username || '').trim().toLowerCase();
  const userId = String(req.body.userId || '').trim();
  const otherUser = userId && mongoose.isValidObjectId(userId)
    ? await User.findById(userId)
    : await User.findOne({ username });

  if (!otherUser) {
    return res.status(404).json({ success: false, message: 'Recipient not found.' });
  }
  if (otherUser._id.toString() === req.afapayUser._id.toString()) {
    return res.status(400).json({ success: false, message: 'You cannot chat with yourself.' });
  }
  if (hasBlocked(req.afapayUser, otherUser._id)) {
    return res.status(403).json({ success: false, message: 'Unblock this contact before starting a chat.' });
  }
  if (hasBlocked(otherUser, req.afapayUser._id)) {
    return res.status(403).json({ success: false, message: 'This contact is unavailable.' });
  }

  const participantKey = participantKeyFor(req.afapayUser._id, otherUser._id);
  let room = await ChatRoom.findOne({ participantKey });
  if (!room) {
    room = await ChatRoom.create({
      roomType: 'private',
      participants: [req.afapayUser._id, otherUser._id],
      participantKey,
    });
  }

  return res.status(200).json({
    success: true,
    roomId: room._id.toString(),
    message: 'Chat room ready',
    participant: publicUser(otherUser),
  });
});

router.get('/contacts', requireAfaPayAuth, async (req, res) => {
  const rooms = await ChatRoom.find({
    roomType: 'private',
    participants: req.afapayUser._id,
  })
    .select('participants updatedAt lastMessageAt')
    .sort({ lastMessageAt: -1, updatedAt: -1 })
    .lean();

  const contactIds = Array.from(
    new Set(
      rooms
        .flatMap((room) => room.participants || [])
        .map((participant) => participant.toString())
        .filter((participant) => participant !== req.afapayUser._id.toString()),
    ),
  );
  const users = contactIds.length
    ? await User.find({ _id: { $in: contactIds } }).select('username _id online lastSeen').lean()
    : [];
  const roomByContactId = new Map();
  rooms.forEach((room) => {
    const contactId = room.participants
      .map((participant) => participant.toString())
      .find((participant) => participant !== req.afapayUser._id.toString());
    if (contactId && !roomByContactId.has(contactId)) roomByContactId.set(contactId, room);
  });

  return res.json(
    users.map((user) => {
      const room = roomByContactId.get(user._id.toString());
      return {
        ...publicUser(user),
        contactId: user._id.toString(),
        roomId: room?._id?.toString() || null,
        lastInteraction: room?.lastMessageAt || room?.updatedAt || null,
        unreadCount: 0,
      };
    }),
  );
});

router.get('/groups', requireAfaPayAuth, async (req, res) => {
  const rooms = await ChatRoom.find({
    roomType: 'group',
    participants: req.afapayUser._id,
  })
    .sort({ lastMessageAt: -1, updatedAt: -1 })
    .lean();

  return res.json({
    success: true,
    groups: await Promise.all(rooms.map(groupForClient)),
    page: 1,
    hasMore: false,
  });
});

router.post('/groups/create', requireAfaPayAuth, async (req, res) => {
  const groupName = String(req.body.groupName || req.body.name || '').trim();
  const requestedIds = Array.isArray(req.body.memberIds) ? req.body.memberIds : [];
  const memberIds = Array.from(
    new Set(
      requestedIds
        .map((id) => String(id || '').trim())
        .filter((id) => mongoose.isValidObjectId(id) && id !== req.afapayUser._id.toString()),
    ),
  );

  if (!groupName) {
    return res.status(400).json({ success: false, message: 'Group name is required.' });
  }
  if (memberIds.length === 0) {
    return res.status(400).json({ success: false, message: 'Select at least one member.' });
  }

  const members = await User.find({ _id: { $in: memberIds } }).select('_id').lean();
  const allMemberIds = [req.afapayUser._id, ...members.map((member) => member._id)];
  const room = await ChatRoom.create({
    roomType: 'group',
    participants: allMemberIds,
    groupMembers: allMemberIds,
    groupName: groupName.slice(0, 80),
    groupCreatedBy: req.afapayUser._id,
  });

  return res.status(201).json({
    success: true,
    group: await groupForClient(room),
  });
});

router.get('/messages/:roomId', requireAfaPayAuth, async (req, res) => {
  const room = await ensureRoomParticipant(req.params.roomId, req.afapayUser._id);
  if (!room) return res.status(403).json({ success: false, message: 'Not authorized for this room.' });
  const blockState = await privateRoomBlockState(room, req.afapayUser._id);
  if (blockState.blocked) {
    return res.status(403).json({ success: false, message: blockState.message });
  }

  const messages = await Message.find({ roomId: room._id })
    .sort({ timestamp: 1, createdAt: 1 })
    .populate('repliedTo')
    .lean();
  const setting = await ChatSetting.findOne({
    roomId: room._id,
    userId: req.afapayUser._id,
  }).lean();
  const visibleMessages = messages.filter((message) =>
    messageVisibleForSetting(message, setting),
  );

  return res.json(await Promise.all(visibleMessages.map(messageForClient)));
});

router.post('/messages/upload', requireAfaPayAuth, chatMediaUpload.single('file'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'No chat media file uploaded.' });
  }

  try {
    const type = resolveChatUploadType(req.file, req.body?.type);
    const result = await mediaStorage.upload(req.file, {
      folder: 'afapay-chat',
      type,
      area: `afapay_chat_${type}`,
    });
    logUploadAudit({ area: `afapay_chat_${type}`, file: req.file, result });

    return res.json({
      success: true,
      type,
      messageKey: mediaMessageKeyFor(type),
      url: result.secure_url,
      publicId: result.public_id,
      originalName: req.file.originalname,
      mimeType: req.file.mimetype,
      bytes: result.bytes || req.file.size || 0,
    });
  } catch (err) {
    console.error('[AfaPayChat] media upload failed:', err.message);
    return res.status(500).json({
      success: false,
      message: 'Failed to upload chat media.',
    });
  }
});

router.post('/messages', requireAfaPayAuth, async (req, res) => {
  const roomId = String(req.body.roomId || '').trim();
  const text = String(req.body.text || '').trim();
  const repliedTo = String(req.body.repliedTo || '').trim();
  const imageUrl = String(req.body.imageUrl || '').trim();
  const videoUrl = String(req.body.videoUrl || '').trim();
  const audioUrl = String(req.body.audioUrl || '').trim();
  const fileUrl = String(req.body.fileUrl || '').trim();
  const mediaType = String(req.body.mediaType || '').trim();
  const mediaName = String(req.body.mediaName || '').trim();
  const mediaMimeType = String(req.body.mediaMimeType || '').trim();
  const mediaSizeBytes = Number(req.body.mediaSizeBytes || 0);
  if (!text && !imageUrl && !videoUrl && !audioUrl && !fileUrl) {
    return res.status(400).json({ success: false, message: 'Message content is required.' });
  }

  const room = await ensureRoomParticipant(roomId, req.afapayUser._id);
  if (!room) return res.status(403).json({ success: false, message: 'Not authorized for this room.' });
  const blockState = await privateRoomBlockState(room, req.afapayUser._id);
  if (blockState.blocked) {
    return res.status(403).json({ success: false, message: blockState.message });
  }

  const replyMessage =
    repliedTo && mongoose.isValidObjectId(repliedTo)
      ? await Message.findOne({ _id: repliedTo, roomId: room._id }).lean()
      : null;

  const message = await Message.create({
    roomId: room._id,
    conversationId: room._id,
    senderId: req.afapayUser._id,
    text: text.slice(0, 2000),
    imageUrl,
    videoUrl,
    audioUrl,
    fileUrl,
    mediaType: ['image', 'video', 'audio', 'file'].includes(mediaType)
      ? mediaType
      : resolveChatUploadType(null, imageUrl ? 'image' : videoUrl ? 'video' : audioUrl ? 'audio' : fileUrl ? 'file' : ''),
    mediaName: mediaName.slice(0, 255),
    mediaMimeType: mediaMimeType.slice(0, 120),
    mediaSizeBytes: Number.isFinite(mediaSizeBytes) && mediaSizeBytes > 0 ? mediaSizeBytes : 0,
    repliedTo: replyMessage?._id || null,
    timestamp: new Date(),
  });
  room.lastMessage = message.text || mediaPreview(message);
  room.lastMessageAt = message.timestamp;
  await room.save();

  const savedMessage = await Message.findById(message._id).populate('repliedTo').lean();
  const clientMessage = await messageForClient(savedMessage || message);
  if (global.io) {
    global.io.to(`chat:${room._id.toString()}`).emit('messageCreated', clientMessage);
  }
  return res.status(201).json(clientMessage);
});

router.post('/messages/:roomId/mark-as-read', requireAfaPayAuth, async (req, res) => {
  const room = await ensureRoomParticipant(req.params.roomId, req.afapayUser._id);
  if (!room) return res.status(403).json({ success: false, message: 'Not authorized for this room.' });
  return res.json({ success: true, message: 'Room marked as read.' });
});

router.get('/chatrooms/:roomId/settings', requireAfaPayAuth, async (req, res) => {
  const room = await ensureRoomParticipant(req.params.roomId, req.afapayUser._id);
  if (!room) return res.status(403).json({ success: false, message: 'Not authorized for this room.' });

  const setting = await getOrCreateRoomSetting(room._id, req.afapayUser._id);
  return res.json({ success: true, settings: settingForClient(setting) });
});

router.post('/chatrooms/:roomId/settings', requireAfaPayAuth, async (req, res) => {
  const room = await ensureRoomParticipant(req.params.roomId, req.afapayUser._id);
  if (!room) return res.status(403).json({ success: false, message: 'Not authorized for this room.' });

  const patch = normalizeChatSettingPatch(req.body || {});
  if (Object.keys(patch).length === 0) {
    const setting = await getOrCreateRoomSetting(room._id, req.afapayUser._id);
    return res.json({ success: true, settings: settingForClient(setting) });
  }
  const setting = await ChatSetting.findOneAndUpdate(
    { roomId: room._id, userId: req.afapayUser._id },
    { $set: patch, $setOnInsert: { roomId: room._id, userId: req.afapayUser._id } },
    { new: true, upsert: true },
  );
  return res.json({ success: true, settings: settingForClient(setting) });
});

router.post('/chatrooms/:roomId/clear', requireAfaPayAuth, async (req, res) => {
  const room = await ensureRoomParticipant(req.params.roomId, req.afapayUser._id);
  if (!room) return res.status(403).json({ success: false, message: 'Not authorized for this room.' });

  const setting = await ChatSetting.findOneAndUpdate(
    { roomId: room._id, userId: req.afapayUser._id },
    {
      $set: { clearedBefore: new Date() },
      $setOnInsert: { roomId: room._id, userId: req.afapayUser._id },
    },
    { new: true, upsert: true },
  );
  return res.json({ success: true, settings: settingForClient(setting) });
});

router.post('/users/:userId/block', requireAfaPayAuth, async (req, res) => {
  const targetUserId = String(req.params.userId || '').trim();
  if (!mongoose.isValidObjectId(targetUserId)) {
    return res.status(400).json({ success: false, message: 'Valid userId is required.' });
  }
  if (targetUserId === req.afapayUser._id.toString()) {
    return res.status(400).json({ success: false, message: 'You cannot block yourself.' });
  }

  const targetUser = await User.findById(targetUserId).select('_id username').lean();
  if (!targetUser) return res.status(404).json({ success: false, message: 'User not found.' });

  await User.updateOne(
    { _id: req.afapayUser._id },
    { $addToSet: { blockedUsers: targetUser._id } },
  );
  return res.json({
    success: true,
    message: `${targetUser.username || 'Contact'} blocked.`,
  });
});

router.post('/users/:userId/report', requireAfaPayAuth, async (req, res) => {
  const targetUserId = String(req.params.userId || '').trim();
  const roomId = String(req.body.roomId || '').trim();
  const reason = String(req.body.reason || 'Reported from chat').trim().slice(0, 500);
  if (!mongoose.isValidObjectId(targetUserId)) {
    return res.status(400).json({ success: false, message: 'Valid userId is required.' });
  }
  if (targetUserId === req.afapayUser._id.toString()) {
    return res.status(400).json({ success: false, message: 'You cannot report yourself.' });
  }

  const [targetUser, room] = await Promise.all([
    User.findById(targetUserId).select('_id username').lean(),
    roomId && mongoose.isValidObjectId(roomId)
      ? ensureRoomParticipant(roomId, req.afapayUser._id)
      : null,
  ]);
  if (!targetUser) return res.status(404).json({ success: false, message: 'User not found.' });

  const report = await UserReport.findOneAndUpdate(
    {
      reporterId: req.afapayUser._id,
      targetUserId: targetUser._id,
      status: 'pending',
    },
    {
      $setOnInsert: {
        reporterId: req.afapayUser._id,
        targetUserId: targetUser._id,
        roomId: room?._id || null,
        reason: reason || 'Reported from chat',
      },
    },
    { new: true, upsert: true },
  );

  return res.json({
    success: true,
    reportId: report._id.toString(),
    message: 'Report received. Our team will review it.',
  });
});

module.exports = router;
