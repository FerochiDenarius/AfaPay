import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/security/auth_token_storage.dart';
import '../models/device_session.dart';

class SecurityException implements Exception {
  const SecurityException(this.message);

  final String message;
}

class PinVerificationResult {
  const PinVerificationResult({
    required this.success,
    this.failedCount = 0,
    this.lockedUntil,
  });

  final bool success;
  final int failedCount;
  final DateTime? lockedUntil;
}

class SecurityRepository {
  SecurityRepository({
    http.Client? client,
    String? baseUrl,
    AuthTokenStorage? tokenStorage,
  }) : _client = client ?? http.Client(),
       _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), ''),
       _tokenStorage = tokenStorage ?? AuthTokenStorage();

  final http.Client _client;
  final String _baseUrl;
  final AuthTokenStorage _tokenStorage;

  Future<void> setupPin(String pin) async {
    await _request('POST', '/api/security/pin/setup', body: {'pin': pin});
  }

  Future<PinVerificationResult> verifyPin(String pin) async {
    final json = await _request(
      'POST',
      '/api/security/pin/verify',
      body: {'pin': pin},
      allowSecurityFailure: true,
    );
    return PinVerificationResult(
      success: json['success'] == true,
      failedCount: int.tryParse(json['failedCount']?.toString() ?? '') ?? 0,
      lockedUntil: DateTime.tryParse(json['lockedUntil']?.toString() ?? ''),
    );
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _request(
      'POST',
      '/api/security/biometrics',
      body: {'enabled': enabled},
    );
  }

  Future<List<DeviceSession>> fetchDevices() async {
    final json = await _request('GET', '/api/security/devices');
    final items = json['devices'];
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(DeviceSession.fromJson)
        .where((device) => device.deviceId.isNotEmpty)
        .toList();
  }

  Future<void> removeDevice(String deviceId) async {
    await _request('DELETE', '/api/security/devices/$deviceId');
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
    bool allowSecurityFailure = false,
  }) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const SecurityException('Please login before continuing.');
    }
    final uri = Uri.parse('$_baseUrl$path');
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final response = switch (method) {
      'GET' => await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 20)),
      'DELETE' => await _client
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 20)),
      _ => await _client
          .post(uri, headers: headers, body: jsonEncode(body ?? const {}))
          .timeout(const Duration(seconds: 20)),
    };

    Object? decoded;
    try {
      decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    } on FormatException {
      throw const SecurityException('The server returned invalid JSON.');
    }
    final json = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (allowSecurityFailure &&
          (response.statusCode == 401 || response.statusCode == 423)) {
        return json;
      }
      throw SecurityException(
        json['message']?.toString() ?? 'Security request failed.',
      );
    }
    return json;
  }
}
