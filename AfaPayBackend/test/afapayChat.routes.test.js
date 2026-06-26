const assert = require('node:assert/strict');
const http = require('node:http');
const test = require('node:test');

const express = require('express');
const jwt = require('jsonwebtoken');

const ChatRoom = require('../models/afapayChatRoom.model');
const ChatSetting = require('../models/afapayChatSetting.model');
const Message = require('../models/afapayMessage.model');
const User = require('../models/afapayUser.model');
const afapayChatRoutes = require('../routes/afapayChat.routes');

const originalFind = User.find;
const originalFindById = User.findById;
const originalChatRoomFindOne = ChatRoom.findOne;
const originalChatSettingFindOne = ChatSetting.findOne;
const originalChatSettingFindOneAndUpdate = ChatSetting.findOneAndUpdate;
const originalMessageFind = Message.find;
const originalMessageCreate = Message.create;
const originalMessageFindById = Message.findById;

process.env.ACCESS_TOKEN_SECRET = 'test-access-token-secret-with-enough-length';

function createApp() {
  const app = express();
  app.use(express.json());
  app.use('/api', afapayChatRoutes);
  return app;
}

async function withServer(handler, callback) {
  const server = http.createServer(handler);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address();

  try {
    await callback(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve, reject) => {
      server.close((error) => (error ? reject(error) : resolve()));
    });
  }
}

function tokenFor(userId = '507f1f77bcf86cd799439011') {
  return jwt.sign(
    {
      sub: userId,
      userId,
      username: 'bright',
    },
    process.env.ACCESS_TOKEN_SECRET,
    {
      expiresIn: '15m',
      issuer: 'afapay',
      audience: 'afapay-mobile',
    },
  );
}

test.afterEach(() => {
  User.find = originalFind;
  User.findById = originalFindById;
  ChatRoom.findOne = originalChatRoomFindOne;
  ChatSetting.findOne = originalChatSettingFindOne;
  ChatSetting.findOneAndUpdate = originalChatSettingFindOneAndUpdate;
  Message.find = originalMessageFind;
  Message.create = originalMessageCreate;
  Message.findById = originalMessageFindById;
});

test('username search returns matching AfaPay users', async () => {
  User.findById = () => Promise.resolve({
    _id: {
      toString: () => '507f1f77bcf86cd799439011',
    },
    username: 'bright',
  });
  User.find = (query) => {
    assert.equal(query.username.source, '^ama');
    assert.equal(query.username.flags, 'i');
    return {
      select: () => ({
        sort: () => ({
          limit: () => ({
            lean: async () => [
              {
                _id: {
                  toString: () => '507f1f77bcf86cd799439012',
                },
                username: 'ama',
              },
            ],
          }),
        }),
      }),
    };
  };

  await withServer(createApp(), async (baseUrl) => {
    const response = await fetch(`${baseUrl}/api/users/search?query=ama`, {
      headers: {
        Accept: 'application/json',
        Authorization: `Bearer ${tokenFor()}`,
      },
    });
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.deepEqual(body, [
      {
        _id: '507f1f77bcf86cd799439012',
        id: '507f1f77bcf86cd799439012',
        username: 'ama',
        profileImage: '',
        avatar: '',
        online: false,
        isOnline: false,
        lastSeen: null,
      },
    ]);
  });
});

test('clear chat route is registered and requires authentication', async () => {
  await withServer(createApp(), async (baseUrl) => {
    const response = await fetch(
      `${baseUrl}/api/chatrooms/507f1f77bcf86cd799439013/clear`,
      {
        method: 'POST',
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
        },
        body: '{}',
      },
    );
    const body = await response.json();

    assert.equal(response.status, 401);
    assert.equal(body.success, false);
    assert.match(body.message, /Authentication required|Session expired/);
  });
});

test('clear chat only hides messages for the authenticated user', async () => {
  const userAId = '507f1f77bcf86cd799439011';
  const userBId = '507f1f77bcf86cd799439012';
  const roomId = '507f1f77bcf86cd799439013';
  const messageId = '507f1f77bcf86cd799439014';
  const oldMessageTime = new Date('2026-01-01T00:00:00.000Z');
  const users = new Map([
    [userAId, { _id: userAId, username: 'bright' }],
    [userBId, { _id: userBId, username: 'ama' }],
  ]);
  const room = {
    _id: roomId,
    roomType: 'private',
    participants: [userAId, userBId],
  };
  const settings = new Map();

  function userQuery(user) {
    return {
      then: (resolve, reject) => Promise.resolve(user).then(resolve, reject),
      select: () => ({
        lean: async () => user,
      }),
    };
  }

  User.findById = (id) => userQuery(users.get(id.toString()) || null);
  ChatRoom.findOne = (query) => {
    const participant = query.participants?.toString();
    return Promise.resolve(
      query._id?.toString() === roomId &&
        [userAId, userBId].includes(participant)
        ? room
        : null,
    );
  };
  ChatSetting.findOne = (query) => ({
    lean: async () =>
      settings.get(`${query.roomId.toString()}:${query.userId.toString()}`) ||
      null,
  });
  ChatSetting.findOneAndUpdate = (query, update) => {
    const key = `${query.roomId.toString()}:${query.userId.toString()}`;
    const current = settings.get(key) || {
      roomId: query.roomId,
      userId: query.userId,
      theme: 'gold',
      wallpaper: 'midnight',
      muted: false,
      disappearingSeconds: null,
      clearedBefore: null,
      updatedAt: new Date(),
    };
    const next = {
      ...current,
      ...(update.$set || {}),
      updatedAt: new Date(),
    };
    settings.set(key, next);
    return Promise.resolve(next);
  };
  Message.find = () => ({
    sort: () => ({
      populate: () => ({
        lean: async () => [
          {
            _id: messageId,
            roomId,
            senderId: userBId,
            text: 'message before clear',
            timestamp: oldMessageTime,
            createdAt: oldMessageTime,
            status: 'sent',
          },
        ],
      }),
    }),
  });

  await withServer(createApp(), async (baseUrl) => {
    const userBMessagesBefore = await fetch(`${baseUrl}/api/messages/${roomId}`, {
      headers: {
        Accept: 'application/json',
        Authorization: `Bearer ${tokenFor(userBId)}`,
      },
    });
    assert.equal(userBMessagesBefore.status, 200);
    assert.equal((await userBMessagesBefore.json()).length, 1);

    const clearResponse = await fetch(`${baseUrl}/api/chatrooms/${roomId}/clear`, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        Authorization: `Bearer ${tokenFor(userAId)}`,
        'Content-Type': 'application/json',
      },
      body: '{}',
    });
    assert.equal(clearResponse.status, 200);
    const clearBody = await clearResponse.json();
    assert.equal(clearBody.settings.userId, userAId);
    assert.ok(clearBody.settings.clearedBefore);

    const userAMessagesAfter = await fetch(`${baseUrl}/api/messages/${roomId}`, {
      headers: {
        Accept: 'application/json',
        Authorization: `Bearer ${tokenFor(userAId)}`,
      },
    });
    assert.equal(userAMessagesAfter.status, 200);
    assert.equal((await userAMessagesAfter.json()).length, 0);

    const userBMessagesAfter = await fetch(`${baseUrl}/api/messages/${roomId}`, {
      headers: {
        Accept: 'application/json',
        Authorization: `Bearer ${tokenFor(userBId)}`,
      },
    });
    assert.equal(userBMessagesAfter.status, 200);
    assert.equal((await userBMessagesAfter.json()).length, 1);
  });
});

test('message endpoint stores structured location attachments', async () => {
  const userAId = '507f1f77bcf86cd799439011';
  const userBId = '507f1f77bcf86cd799439012';
  const roomId = '507f1f77bcf86cd799439013';
  const messageId = '507f1f77bcf86cd799439014';
  const users = new Map([
    [userAId, { _id: userAId, username: 'bright', blockedUsers: [] }],
    [userBId, { _id: userBId, username: 'ama', blockedUsers: [] }],
  ]);
  const room = {
    _id: roomId,
    roomType: 'private',
    participants: [userAId, userBId],
    save: async () => room,
  };
  let createdMessage = null;

  function userQuery(user) {
    return {
      then: (resolve, reject) => Promise.resolve(user).then(resolve, reject),
      select: () => ({
        lean: async () => user,
      }),
    };
  }

  User.findById = (id) => userQuery(users.get(id.toString()) || null);
  ChatRoom.findOne = (query) => {
    const participant = query.participants?.toString();
    return Promise.resolve(
      query._id?.toString() === roomId &&
        [userAId, userBId].includes(participant)
        ? room
        : null,
    );
  };
  Message.create = async (payload) => {
    createdMessage = {
      _id: messageId,
      ...payload,
      createdAt: payload.timestamp,
      status: 'sent',
    };
    return createdMessage;
  };
  Message.findById = () => ({
    populate: () => ({
      lean: async () => createdMessage,
    }),
    lean: async () => createdMessage,
  });

  await withServer(createApp(), async (baseUrl) => {
    const response = await fetch(`${baseUrl}/api/messages`, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        Authorization: `Bearer ${tokenFor(userAId)}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        roomId,
        attachmentType: 'location',
        attachmentPayload: {
          latitude: 5.603717,
          longitude: -0.186964,
        },
      }),
    });
    const body = await response.json();

    assert.equal(response.status, 201);
    assert.equal(body.attachmentType, 'location');
    assert.deepEqual(body.attachmentPayload, {
      latitude: 5.603717,
      longitude: -0.186964,
    });
    assert.equal(room.lastMessage, 'Location');
  });
});
