import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../models/email_verification_request.dart';
import '../models/email_verification_response.dart';
import '../models/otp_verification_request.dart';
import '../models/otp_verification_response.dart';
import 'auth_repository.dart';

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;

  @override
  Future<EmailVerificationResponse> sendEmailVerification(
    EmailVerificationRequest request,
  ) async {
    final response = await _post(
      '/api/afapay/auth/send-email-verification',
      request.toJson(),
    );
    return EmailVerificationResponse.fromJson(response);
  }

  @override
  Future<OtpVerificationResponse> verifyEmailOtp({
    required String userId,
    required String email,
    required String otp,
  }) async {
    final response = await _post('/api/afapay/auth/verify-email', {
      'userId': userId,
      'email': email,
      'otp': otp,
    });
    return OtpVerificationResponse.fromJson(response);
  }

  @override
  Future<void> resendEmailVerification({
    required String userId,
    required String email,
  }) async {
    await _post('/api/afapay/auth/send-email-verification', {
      'userId': userId,
      'email': email,
    });
  }

  @override
  Future<OtpVerificationResponse> verifyPhoneOtp(
    OtpVerificationRequest request,
  ) async {
    final response = await _post(
      '/api/afapay/auth/verify-phone',
      request.toJson(),
    );
    return OtpVerificationResponse.fromJson(response);
  }

  @override
  Future<void> resendOtp({required String userId}) async {
    await _post('/api/afapay/auth/resend-phone-otp', {'userId': userId});
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw const AuthApiException('The server returned an invalid response.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        json['message'] as String? ?? 'The request could not be completed.',
      );
    }
    return json;
  }
}

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
