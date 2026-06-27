import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/security/auth_token_storage.dart';
import '../../auth/services/auth_service.dart';
import '../models/wallet_balance.dart';
import 'dashboard_repository.dart';

abstract interface class WalletRepository {
  Future<WalletBalance> getBalance();
}

class FrontendWalletRepository implements WalletRepository {
  const FrontendWalletRepository();

  @override
  Future<WalletBalance> getBalance() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const WalletBalance(balance: 250000, currency: 'NGN');
  }
}

class HttpWalletRepository implements WalletRepository {
  HttpWalletRepository({
    http.Client? client,
    String? baseUrl,
    AuthTokenStorage? tokenStorage,
  }) : _client = client ?? http.Client(),
       _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), ''),
       _tokenStorage = tokenStorage ?? AuthTokenStorage();

  final http.Client _client;
  final String _baseUrl;
  final AuthTokenStorage _tokenStorage;

  @override
  Future<WalletBalance> getBalance() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthenticationExpiredException();
    }

    var response = await _sendBalanceRequest(token);

    if (response.statusCode == 401 || response.statusCode == 403) {
      final refreshed = await AuthService(
        client: _client,
        baseUrl: _baseUrl,
        tokenStorage: _tokenStorage,
      ).refreshSession();
      if (refreshed == null) {
        throw const AuthenticationExpiredException();
      }
      response = await _sendBalanceRequest(refreshed.accessToken);
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const AuthenticationExpiredException();
      }
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw const DashboardApiException('The server returned invalid JSON.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DashboardApiException(
        json['message'] as String? ?? 'Wallet balance request failed.',
      );
    }
    return WalletBalance.fromJson(json);
  }

  Future<http.Response> _sendBalanceRequest(String token) {
    return _client
        .get(
          Uri.parse('$_baseUrl/api/wallet/balance'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));
  }
}
