import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/security/auth_token_storage.dart';
import '../models/chat_models.dart';
import '../models/chat_room_settings.dart';

class ChatAuthExpiredException implements Exception {
  const ChatAuthExpiredException();
}

class ChatApiException implements Exception {
  const ChatApiException(this.message);

  final String message;
}

class ChatRepository {
  ChatRepository({
    http.Client? client,
    String? baseUrl,
    AuthTokenStorage? tokenStorage,
  }) : _client = client ?? http.Client(),
       _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), ''),
       _tokenStorage = tokenStorage ?? AuthTokenStorage();

  final http.Client _client;
  final String _baseUrl;
  final AuthTokenStorage _tokenStorage;

  Future<String?> currentUserId() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final json = jsonDecode(payload);
      if (json is! Map<String, dynamic>) return null;
      return (json['id'] ?? json['_id'] ?? json['userId'] ?? json['sub'])
          ?.toString();
    } on FormatException {
      return null;
    }
  }

  Future<List<ChatConversation>> fetchPrivateChats() async {
    final json = await _getJson('/api/chatrooms');
    final items = json is List ? json : const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ChatConversation.privateFromJson)
        .where((chat) => chat.id.isNotEmpty)
        .toList();
  }

  Future<List<ChatConversation>> fetchGroups() async {
    final json = await _getJson('/api/groups');
    final groups = json is Map<String, dynamic> ? json['groups'] : null;
    final items = groups is List ? groups : const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ChatConversation.groupFromJson)
        .where((chat) => chat.id.isNotEmpty)
        .toList();
  }

  Future<List<ChatParticipant>> fetchContacts() async {
    final json = await _getJson('/api/contacts');
    final items = json is List ? json : const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ChatParticipant.fromJson)
        .where((contact) => contact.id.isNotEmpty)
        .toList();
  }

  Future<List<ChatParticipant>> searchUsers(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];
    final json = await _getJson(
      '/api/users/search?query=${Uri.encodeQueryComponent(trimmed)}',
    );
    final items = json is List ? json : const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ChatParticipant.fromJson)
        .where((user) => user.id.isNotEmpty)
        .toList();
  }

  Future<ChatConversation> startPrivateChat({
    String? username,
    String? userId,
  }) async {
    final json = await _sendJson('/api/chatrooms', {
      if (username != null) 'username': username,
      if (userId != null) 'userId': userId,
    });
    if (json is! Map<String, dynamic>) {
      throw const ChatApiException('Unable to start chat.');
    }
    final participant = json['participant'];
    return ChatConversation(
      id: json['roomId']?.toString() ?? '',
      title: participant is Map<String, dynamic>
          ? ChatParticipant.fromJson(participant).username
          : username ?? 'Private Chat',
      isGroup: false,
      subtitle: 'Start a secure conversation',
      imageUrl: participant is Map<String, dynamic>
          ? ChatParticipant.fromJson(participant).profileImage
          : null,
      participant: participant is Map<String, dynamic>
          ? ChatParticipant.fromJson(participant)
          : null,
    );
  }

  Future<ChatConversation> createGroup({
    required String groupName,
    required List<String> memberIds,
  }) async {
    final json = await _sendJson('/api/groups/create', {
      'groupName': groupName,
      'memberIds': memberIds,
    });
    if (json is! Map<String, dynamic> ||
        json['group'] is! Map<String, dynamic>) {
      throw const ChatApiException('Unable to create group.');
    }
    return ChatConversation.groupFromJson(
      json['group'] as Map<String, dynamic>,
    );
  }

  Future<List<ChatMessage>> fetchMessages(String roomId) async {
    final json = await _getJson('/api/messages/$roomId');
    final items = json is List ? json : const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList();
  }

  Future<ChatMessage> sendMessage({
    required String roomId,
    required String text,
    String? repliedToMessageId,
  }) async {
    final json = await _sendJson('/api/messages', {
      'roomId': roomId,
      'text': text,
      if (repliedToMessageId != null && repliedToMessageId.isNotEmpty)
        'repliedTo': repliedToMessageId,
    });
    if (json is! Map<String, dynamic>) {
      throw const ChatApiException('Unable to send message.');
    }
    return ChatMessage.fromJson(json);
  }

  Future<void> markAsRead(String roomId) async {
    await _sendJson('/api/messages/$roomId/mark-as-read', const {});
  }

  Future<ChatRoomSettings> fetchRoomSettings(String roomId) async {
    final json = await _getJson('/api/chatrooms/$roomId/settings');
    final settings = json is Map<String, dynamic> ? json['settings'] : null;
    if (settings is Map<String, dynamic>) {
      return ChatRoomSettings.fromJson(settings);
    }
    return ChatRoomSettings.defaults;
  }

  Future<ChatRoomSettings> saveRoomSettings({
    required String roomId,
    required ChatRoomSettings settings,
  }) async {
    final json = await _sendJson(
      '/api/chatrooms/$roomId/settings',
      settings.toJson(),
    );
    final savedSettings = json is Map<String, dynamic>
        ? json['settings']
        : null;
    if (savedSettings is Map<String, dynamic>) {
      return ChatRoomSettings.fromJson(savedSettings);
    }
    return settings;
  }

  Future<ChatRoomSettings> clearChat(String roomId) async {
    final json = await _sendJson('/api/chatrooms/$roomId/clear', const {});
    final settings = json is Map<String, dynamic> ? json['settings'] : null;
    if (settings is Map<String, dynamic>) {
      return ChatRoomSettings.fromJson(settings);
    }
    return ChatRoomSettings.defaults.copyWith(clearedBefore: DateTime.now());
  }

  Future<void> blockContact(String userId) async {
    await _sendJson('/api/users/$userId/block', const {});
  }

  Future<void> reportContact({
    required String userId,
    required String roomId,
    required String reason,
  }) async {
    await _sendJson('/api/users/$userId/report', {
      'roomId': roomId,
      'reason': reason,
    });
  }

  Future<Object?> _getJson(String path) async {
    return _requestJson('GET', path);
  }

  Future<Object?> _sendJson(String path, Map<String, Object?> body) async {
    return _requestJson('POST', path, body: body);
  }

  Future<Object?> _requestJson(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const ChatAuthExpiredException();
    }

    var response = await _sendRequest(method, path, token: token, body: body);

    if (response.statusCode == 401 || response.statusCode == 403) {
      final refreshed = await _refreshTokens();
      if (refreshed == null) {
        await _tokenStorage.clear();
        throw const ChatAuthExpiredException();
      }
      response = await _sendRequest(
        method,
        path,
        token: refreshed.accessToken,
        body: body,
      );
      if (response.statusCode == 401 || response.statusCode == 403) {
        await _tokenStorage.clear();
        throw const ChatAuthExpiredException();
      }
    }

    return _decodeResponse(response);
  }

  Future<http.Response> _sendRequest(
    String method,
    String path, {
    required String token,
    Map<String, Object?>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    return method == 'GET'
        ? _client
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 20))
        : _client
              .post(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 20));
  }

  Future<AuthTokens?> _refreshTokens() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    final deviceId = await _tokenStorage.readDeviceId();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/afapay/auth/refresh'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'refreshToken': refreshToken,
            if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    Object? json;
    try {
      json = jsonDecode(response.body);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, dynamic> || json['success'] != true) return null;

    final tokens = AuthTokens(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
    );
    if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) return null;
    await _tokenStorage.saveTokens(tokens);
    final refreshedDeviceId = json['deviceId']?.toString();
    if (refreshedDeviceId != null && refreshedDeviceId.isNotEmpty) {
      await _tokenStorage.saveDeviceId(refreshedDeviceId);
    }
    return tokens;
  }

  Object? _decodeResponse(http.Response response) {
    Object? json;
    try {
      json = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      throw const ChatApiException('The server returned invalid JSON.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = json is Map<String, dynamic>
          ? (json['message'] ?? json['error'])?.toString()
          : null;
      throw ChatApiException(message ?? 'Chat request failed.');
    }
    return json;
  }
}
