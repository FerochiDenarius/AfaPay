import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
    required this.deviceId,
    required this.pinConfigured,
    required this.biometricEnabled,
  });

  final bool success;
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String deviceId;
  final bool pinConfigured;
  final bool biometricEnabled;
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
    bool? useMockAuth,
  }) : _client = client ?? http.Client(),
       _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), ''),
       _tokenStorage = tokenStorage ?? AuthTokenStorage(),
       _useMockAuth = useMockAuth ?? ApiConfig.useMockAuth;

  final http.Client _client;
  final String _baseUrl;
  final AuthTokenStorage _tokenStorage;
  final bool _useMockAuth;

  Future<RegisterResult> register(RegisterRequest request) async {
    if (_useMockAuth) {
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
    if (_useMockAuth) {
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
        deviceId: 'mock-device',
        pinConfigured: false,
        biometricEnabled: false,
      );
    }

    final deviceId = await _getOrCreateDeviceId();

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
            'deviceId': deviceId,
            'deviceName': Platform.operatingSystem,
            'platform': Platform.operatingSystem,
            'osVersion': Platform.operatingSystemVersion,
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
      deviceId: body['deviceId'] as String? ?? deviceId,
      pinConfigured: body['pinConfigured'] == true,
      biometricEnabled: body['biometricEnabled'] == true,
    );
    await _tokenStorage.saveTokens(
      AuthTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      ),
    );
    await _tokenStorage.saveDeviceId(result.deviceId);
    return result;
  }

  Future<String> _getOrCreateDeviceId() async {
    final existing = await _tokenStorage.readDeviceId();
    if (existing != null && existing.isNotEmpty) return existing;
    final generated =
        'afapay-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
    await _tokenStorage.saveDeviceId(generated);
    return generated;
  }
}
