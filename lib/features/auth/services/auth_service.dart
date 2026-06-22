import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/security/auth_token_storage.dart';
import '../models/register_request.dart';

class RegisterResult {
  const RegisterResult({
    required this.success,
    required this.verificationRequired,
    required this.userId,
    required this.nextStep,
  });

  final bool success;
  final bool verificationRequired;
  final String userId;
  final String nextStep;
}

class LoginResult {
  const LoginResult({
    required this.success,
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
  });

  final bool success;
  final String accessToken;
  final String refreshToken;
  final String userId;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({
    http.Client? client,
    String? baseUrl,
    AuthTokenStorage? tokenStorage,
  }) : _client = client ?? http.Client(),
       _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), ''),
       _tokenStorage = tokenStorage ?? AuthTokenStorage();

  final http.Client _client;
  final String _baseUrl;
  final AuthTokenStorage _tokenStorage;

  Future<RegisterResult> register(RegisterRequest request) async {
    if (ApiConfig.useMockAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      return const RegisterResult(
        success: true,
        verificationRequired: true,
        userId: 'uuid',
        nextStep: 'pin_setup',
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
      nextStep: body['nextStep'] as String? ?? 'pin_setup',
    );
  }

  Future<LoginResult> login({
    required String identifier,
    required String password,
  }) async {
    if (ApiConfig.useMockAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      await _tokenStorage.saveTokens(
        const AuthTokens(
          accessToken: 'mock-access-token',
          refreshToken: 'mock-refresh-token',
        ),
      );
      return const LoginResult(
        success: true,
        accessToken: 'mock-access-token',
        refreshToken: 'mock-refresh-token',
        userId: 'uuid',
      );
    }

    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/afapay/auth/login'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'identifier': identifier.trim(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 20));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] != true) {
      throw AuthException(
        body['message'] as String? ?? 'Login could not be completed.',
      );
    }
    final user = body['user'] as Map<String, dynamic>? ?? const {};
    final result = LoginResult(
      success: true,
      accessToken: body['accessToken'] as String? ?? '',
      refreshToken: body['refreshToken'] as String? ?? '',
      userId: user['id'] as String? ?? '',
    );
    await _tokenStorage.saveTokens(
      AuthTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      ),
    );
    return result;
  }
}
