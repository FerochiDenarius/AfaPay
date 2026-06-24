import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../../../core/config/api_config.dart';
import '../../../core/security/auth_token_storage.dart';
import '../models/chat_models.dart';

class ChatPresenceEvent {
  const ChatPresenceEvent({
    required this.userId,
    required this.isOnline,
    this.lastSeen,
  });

  final String userId;
  final bool isOnline;
  final DateTime? lastSeen;
}

class ChatRealtimeService with WidgetsBindingObserver {
  ChatRealtimeService._({AuthTokenStorage? tokenStorage, String? baseUrl})
    : _tokenStorage = tokenStorage ?? AuthTokenStorage(),
      _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), '');

  static final ChatRealtimeService instance = ChatRealtimeService._();

  final AuthTokenStorage _tokenStorage;
  final String _baseUrl;
  final _onlineUsersController = StreamController<Set<String>>.broadcast();
  final _presenceController = StreamController<ChatPresenceEvent>.broadcast();
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _joinedRoomIds = <String>{};

  socket_io.Socket? _socket;
  String? _activeToken;
  bool _observingLifecycle = false;

  Stream<Set<String>> get onlineUsersStream => _onlineUsersController.stream;
  Stream<ChatPresenceEvent> get presenceStream => _presenceController.stream;
  Stream<ChatMessage> get messageStream => _messageController.stream;

  bool get isConnected => _socket?.connected == true;

  Future<void> connect() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) return;

    _ensureLifecycleObserver();

    final socket = _socket;
    if (socket != null && _activeToken == token) {
      if (!socket.connected) socket.connect();
      requestOnlineUsers();
      return;
    }

    disconnect(sendOffline: false);
    _activeToken = token;

    final nextSocket = socket_io.io(
      _baseUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .enableReconnection()
          .disableAutoConnect()
          .build(),
    );

    nextSocket.onConnect((_) {
      nextSocket.emit('userConnected');
      nextSocket.emit('requestOnlineUsers');
      for (final roomId in _joinedRoomIds) {
        nextSocket.emit('joinChatRoom', {'roomId': roomId});
      }
    });
    nextSocket.on('getOnlineUsers', _handleOnlineUsers);
    nextSocket.on('userStatusChanged', _handlePresenceEvent);
    nextSocket.on('messageCreated', _handleMessageCreated);
    nextSocket.on('authError', (_) {
      disconnect(sendOffline: false);
    });

    _socket = nextSocket;
    nextSocket.connect();
  }

  void requestOnlineUsers() {
    final socket = _socket;
    if (socket?.connected == true) {
      socket!.emit('requestOnlineUsers');
    }
  }

  void joinChatRoom(String roomId) {
    final normalizedRoomId = roomId.trim();
    if (normalizedRoomId.isEmpty) return;
    _joinedRoomIds.add(normalizedRoomId);
    final socket = _socket;
    if (socket?.connected == true) {
      socket!.emit('joinChatRoom', {'roomId': normalizedRoomId});
    }
  }

  void leaveChatRoom(String roomId) {
    final normalizedRoomId = roomId.trim();
    if (normalizedRoomId.isEmpty) return;
    _joinedRoomIds.remove(normalizedRoomId);
    final socket = _socket;
    if (socket?.connected == true) {
      socket!.emit('leaveChatRoom', normalizedRoomId);
    }
  }

  void markOffline() {
    final socket = _socket;
    if (socket?.connected == true) {
      socket!.emit('userOffline');
    }
  }

  void disconnect({bool sendOffline = true}) {
    final socket = _socket;
    if (socket == null) return;
    if (sendOffline && socket.connected) {
      socket.emit('userOffline');
    }
    socket
      ..off('getOnlineUsers')
      ..off('userStatusChanged')
      ..off('messageCreated')
      ..off('authError')
      ..disconnect()
      ..dispose();
    _socket = null;
    _activeToken = null;
  }

  void _handleOnlineUsers(Object? data) {
    final ids = <String>{};
    if (data is Iterable) {
      for (final value in data) {
        final id = value?.toString().trim();
        if (id != null && id.isNotEmpty) ids.add(id);
      }
    }
    _onlineUsersController.add(ids);
  }

  void _handlePresenceEvent(Object? data) {
    if (data is! Map) return;
    final userId = data['userId']?.toString().trim();
    if (userId == null || userId.isEmpty) return;
    final isOnline = data['isOnline'] == true || data['online'] == true;
    _presenceController.add(
      ChatPresenceEvent(
        userId: userId,
        isOnline: isOnline,
        lastSeen: DateTime.tryParse(data['lastSeen']?.toString() ?? ''),
      ),
    );
  }

  void _handleMessageCreated(Object? data) {
    if (data is! Map) return;
    final json = Map<String, dynamic>.from(data);
    final message = ChatMessage.fromJson(json);
    if (message.id.isEmpty || message.roomId.isEmpty) return;
    _messageController.add(message);
  }

  void _ensureLifecycleObserver() {
    if (_observingLifecycle) return;
    WidgetsBinding.instance.addObserver(this);
    _observingLifecycle = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(connect());
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      markOffline();
    }
  }
}
