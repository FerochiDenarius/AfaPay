import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../models/register_request.dart';

class RegisterResult {
  const RegisterResult({
    required this.success,
    required this.verificationRequired,
    required this.userId,
  });

  final bool success;
  final bool verificationRequired;
  final String userId;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;

  Future<RegisterResult> register(RegisterRequest request) async {
    if (ApiConfig.useMockAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      return const RegisterResult(
        success: true,
        verificationRequired: true,
        userId: 'uuid',
      );
    }

    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/afapay/auth/register'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 20));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] != true) {
      throw AuthException(
        body['message'] as String? ?? 'Registration could not be completed.',
      );
    }
    return RegisterResult(
      success: true,
      verificationRequired: body['verificationRequired'] == true,
      userId: body['userId'] as String? ?? '',
    );
  }
}
