import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/chat_room_settings.dart';

class ChatRoomSettingsService {
  const ChatRoomSettingsService({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  Future<ChatRoomSettings> read(String roomId) async {
    final raw = await _storage.read(key: _key(roomId));
    if (raw == null) return ChatRoomSettings.defaults;
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        return ChatRoomSettings.fromJson(json);
      }
    } on FormatException {
      await _storage.delete(key: _key(roomId));
    }
    return ChatRoomSettings.defaults;
  }

  Future<void> save(String roomId, ChatRoomSettings settings) {
    return _storage.write(
      key: _key(roomId),
      value: jsonEncode(settings.toJson()),
    );
  }

  String _key(String roomId) => 'chat_room_settings_$roomId';
}
