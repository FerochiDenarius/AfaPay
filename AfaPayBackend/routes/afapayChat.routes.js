const express = require('express');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');

const ChatRoom = require('../models/afapayChatRoom.model');
const Message = require('../models/afapayMessage.model');
const User = require('../models/afapayUser.model');
const UserReport = require('../models/afapayUserReport.model');

const router = express.Router();

function participantKeyFor(userA, userB) {
  return [userA.toString(), userB.toString()].sort().join(':');
}

function escapeRegExp(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function publicUser(user) {
  return {
    _id: user._id.toString(),
    id: user._id.toString(),
    username: user.username || '',
    profileImage: '',
    avatar: '',
    online: false,
    isOnline: false,
    lastSeen: null,
  };
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
    ? await User.findById(otherId).select('username _id').lean()
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
    ? await User.find({ _id: { $in: memberIds } }).select('username _id').lean()
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
    .select('username _id')
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
    ? await User.find({ _id: { $in: contactIds } }).select('username _id').lean()
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

  return res.json(await Promise.all(messages.map(messageForClient)));
});

router.post('/messages', requireAfaPayAuth, async (req, res) => {
  const roomId = String(req.body.roomId || '').trim();
  const text = String(req.body.text || '').trim();
  const repliedTo = String(req.body.repliedTo || '').trim();
  if (!text) return res.status(400).json({ success: false, message: 'Message text is required.' });

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
    repliedTo: replyMessage?._id || null,
    timestamp: new Date(),
  });
  room.lastMessage = message.text;
  room.lastMessageAt = message.timestamp;
  await room.save();

  const savedMessage = await Message.findById(message._id).populate('repliedTo').lean();
  return res.status(201).json(await messageForClient(savedMessage || message));
});

router.post('/messages/:roomId/mark-as-read', requireAfaPayAuth, async (req, res) => {
  const room = await ensureRoomParticipant(req.params.roomId, req.afapayUser._id);
  if (!room) return res.status(403).json({ success: false, message: 'Not authorized for this room.' });
  return res.json({ success: true, message: 'Room marked as read.' });
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
