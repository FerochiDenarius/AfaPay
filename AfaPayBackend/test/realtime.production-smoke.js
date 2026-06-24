const assert = require('node:assert/strict');
const { io } = require('socket.io-client');

if (process.env.AFAPAY_RUN_PRODUCTION_SMOKE !== 'true') {
  console.log('[smoke] skipped; set AFAPAY_RUN_PRODUCTION_SMOKE=true to run production realtime smoke test');
  process.exit(0);
}

const baseUrl = (process.env.AFAPAY_SMOKE_BASE_URL || 'https://afapay.xyz').replace(/\/+$/, '');
const password = `SmokePass${Date.now()}!`;
const suffix = Date.now().toString(36).slice(-8);

function timeout(ms, label) {
  return new Promise((_, reject) => {
    setTimeout(() => reject(new Error(`${label} timed out after ${ms}ms`)), ms);
  });
}

async function request(path, options = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    ...options,
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
  });
  const body = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(`${options.method || 'GET'} ${path} failed: ${response.status} ${JSON.stringify(body)}`);
  }
  return body;
}

async function registerAndLogin(label) {
  const username = `rt${suffix}${label}`;
  const email = `${username}@example.com`;
  const phoneNumber = `+23355${Date.now().toString().slice(-8)}${label === 'a' ? '1' : '2'}`;
  await request('/api/afapay/auth/register', {
    method: 'POST',
    body: JSON.stringify({
      firstName: 'Realtime',
      lastName: `Smoke${label.toUpperCase()}`,
      username,
      country: 'Ghana',
      phoneNumber,
      email,
      password,
    }),
  });
  const login = await request('/api/afapay/auth/login', {
    method: 'POST',
    body: JSON.stringify({
      identifier: username,
      password,
      deviceId: `codex-realtime-${suffix}-${label}`,
      deviceName: 'codex-smoke',
      platform: 'node',
      osVersion: process.version,
    }),
  });
  return {
    username,
    userId: login.user.id,
    accessToken: login.accessToken,
  };
}

function connectSocket(user) {
  const socket = io(baseUrl, {
    auth: { token: user.accessToken },
    extraHeaders: { Authorization: `Bearer ${user.accessToken}` },
    transports: ['websocket', 'polling'],
    reconnection: false,
  });
  return socket;
}

function waitForSocket(socket, event, predicate, label, ms = 15000) {
  return Promise.race([
    new Promise((resolve) => {
      socket.on(event, (payload) => {
        if (!predicate || predicate(payload)) resolve(payload);
      });
    }),
    timeout(ms, label),
  ]);
}

async function main() {
  console.log(`[smoke] baseUrl=${baseUrl}`);
  const [userA, userB] = await Promise.all([
    registerAndLogin('a'),
    registerAndLogin('b'),
  ]);
  console.log(`[smoke] users=${userA.userId},${userB.userId}`);

  const socketA = connectSocket(userA);
  const socketB = connectSocket(userB);

  try {
    await Promise.all([
      waitForSocket(socketA, 'connect', null, 'socket A connect'),
      waitForSocket(socketB, 'connect', null, 'socket B connect'),
    ]);
    console.log('[smoke] sockets connected');

    socketA.emit('requestOnlineUsers');
    const onlineUsers = await waitForSocket(
      socketA,
      'getOnlineUsers',
      (ids) => Array.isArray(ids) && ids.includes(userA.userId) && ids.includes(userB.userId),
      'online users include both smoke users',
    );
    console.log(`[smoke] online users includes both=${onlineUsers.includes(userA.userId) && onlineUsers.includes(userB.userId)}`);

    const room = await request('/api/chatrooms', {
      method: 'POST',
      headers: { Authorization: `Bearer ${userA.accessToken}` },
      body: JSON.stringify({ userId: userB.userId }),
    });
    const roomId = room.roomId || room._id || room.id;
    assert.ok(roomId, 'roomId should be returned');
    console.log(`[smoke] roomId=${roomId}`);

    socketA.emit('joinChatRoom', { roomId });
    socketB.emit('joinChatRoom', { roomId });
    await new Promise((resolve) => setTimeout(resolve, 1000));

    const text = `realtime smoke ${Date.now()}`;
    const messagePromise = waitForSocket(
      socketB,
      'messageCreated',
      (message) =>
        message &&
        (message.roomId === roomId || message.conversationId === roomId) &&
        message.senderId === userA.userId &&
        message.text === text,
      'recipient messageCreated',
    );

    const sent = await request('/api/messages', {
      method: 'POST',
      headers: { Authorization: `Bearer ${userA.accessToken}` },
      body: JSON.stringify({ roomId, text }),
    });
    const realtimeMessage = await messagePromise;
    assert.equal(realtimeMessage._id || realtimeMessage.id, sent._id || sent.id);
    console.log(`[smoke] recipient received messageCreated id=${sent._id || sent.id}`);

    const offlinePromise = waitForSocket(
      socketA,
      'userStatusChanged',
      (event) => event && event.userId === userB.userId && event.isOnline === false,
      'user B offline event',
    );
    socketB.emit('userOffline');
    const offlineEvent = await offlinePromise;
    console.log(`[smoke] offline event userId=${offlineEvent.userId} isOnline=${offlineEvent.isOnline}`);

    console.log('[smoke] PASS realtime messaging and presence verified');
  } finally {
    socketA.disconnect();
    socketB.disconnect();
  }
}

main().catch((error) => {
  console.error(`[smoke] FAIL ${error.stack || error.message}`);
  process.exitCode = 1;
});
