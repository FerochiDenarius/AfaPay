import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/config/api_config.dart';
import '../../../core/security/auth_token_storage.dart';

class ChatRealtimeService {
  ChatRealtimeService({
    AuthTokenStorage? tokenStorage,
    String? baseUrl,
  }) : _tokenStorage = tokenStorage ?? AuthTokenStorage(),
       _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), '');

  final AuthTokenStorage _tokenStorage;
  final String _baseUrl;
  io.Socket? _socket;

  bool get isConnected => _socket?.connected == true;

  Future<void> connect({
    required String roomId,
    required void Function(Map<String, dynamic>) onMessageCreated,
    required void Function(Map<String, dynamic>) onMessageEdited,
    required void Function(String messageId) onMessageDeleted,
    required void Function(Map<String, dynamic>) onTyping,
    required void Function(Map<String, dynamic>) onRead,
    required void Function(String event, Map<String, dynamic> payload)
    onCallSignal,
  }) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty || roomId.isEmpty) return;

    final socket = io.io(
      _baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );
    _socket = socket;

    socket
      ..onConnect((_) => socket.emit('joinChatRoom', {'roomId': roomId}))
      ..on('messageCreated', (payload) {
        final data = _asMap(payload);
        if (data != null && data['roomId']?.toString() == roomId) {
          onMessageCreated(data);
        }
      })
      ..on('messageEdited', (payload) {
        final data = _asMap(payload);
        if (data != null && data['roomId']?.toString() == roomId) {
          onMessageEdited(data);
        }
      })
      ..on('messageDeleted', (payload) {
        final data = _asMap(payload);
        if (data != null && data['roomId']?.toString() == roomId) {
          onMessageDeleted(data['messageId']?.toString() ?? '');
        }
      })
      ..on('chatTyping', (payload) {
        final data = _asMap(payload);
        if (data != null && data['roomId']?.toString() == roomId) {
          onTyping(data);
        }
      })
      ..on('chatRoomRead', (payload) {
        final data = _asMap(payload);
        if (data != null && data['roomId']?.toString() == roomId) {
          onRead(data);
        }
      });

    for (final event in [
      'callOffer',
      'callAnswer',
      'callIceCandidate',
      'callEnded',
    ]) {
      socket.on(event, (payload) {
        final data = _asMap(payload);
        if (data != null && data['roomId']?.toString() == roomId) {
          onCallSignal(event, data);
        }
      });
    }

    socket.connect();
  }

  void sendTyping({required String roomId, required bool isTyping}) {
    _socket?.emit('chatTyping', {'roomId': roomId, 'isTyping': isTyping});
  }

  void sendCallSignal(String event, Map<String, Object?> payload) {
    _socket?.emit(event, payload);
  }

  void disconnect(String roomId) {
    _socket?.emit('leaveChatRoom', {'roomId': roomId});
    _socket?.dispose();
    _socket = null;
  }
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}
