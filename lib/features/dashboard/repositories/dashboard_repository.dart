import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/security/auth_token_storage.dart';
import '../models/dashboard_summary.dart';
import '../models/transaction_preview.dart';
import '../models/user_profile.dart';

class AuthenticationExpiredException implements Exception {
  const AuthenticationExpiredException();
}

abstract interface class DashboardRepository {
  Future<DashboardSummary> getSummary();

  Future<int> getUnreadNotificationCount();
}

class FrontendDashboardRepository implements DashboardRepository {
  const FrontendDashboardRepository();

  @override
  Future<DashboardSummary> getSummary() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    return DashboardSummary(
      profile: const UserProfile(
        id: 'uuid',
        firstName: 'Bright',
        lastName: 'Menya',
        email: 'bright@example.com',
        phoneNumber: '+233241234567',
      ),
      recentTransactions: [
        TransactionPreview(
          type: 'transfer',
          amount: 500,
          status: 'success',
          time: DateTime.now().subtract(const Duration(minutes: 12)),
        ),
        TransactionPreview(
          type: 'airtime',
          amount: 50,
          status: 'success',
          time: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        TransactionPreview(
          type: 'bill payment',
          amount: 1200,
          status: 'pending',
          time: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    );
  }

  @override
  Future<int> getUnreadNotificationCount() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return 5;
  }
}

class HttpDashboardRepository implements DashboardRepository {
  HttpDashboardRepository({
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
  Future<DashboardSummary> getSummary() async {
    final responses = await Future.wait([
      _getJson('/api/user/profile'),
      _getJson('/api/transactions/recent'),
    ]);

    final transactionsJson = responses[1];
    final transactions = transactionsJson is List
        ? transactionsJson
              .whereType<Map<String, dynamic>>()
              .map(TransactionPreview.fromJson)
              .toList()
        : <TransactionPreview>[];

    return DashboardSummary(
      profile: UserProfile.fromJson(responses[0] as Map<String, dynamic>),
      recentTransactions: transactions,
    );
  }

  @override
  Future<int> getUnreadNotificationCount() async {
    final response = await _getJson('/api/notifications/unread-count');
    return (response as Map<String, dynamic>)['count'] as int? ?? 0;
  }

  Future<Object?> _getJson(String path) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthenticationExpiredException();
    }

    final response = await _client
        .get(
          Uri.parse('$_baseUrl$path'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 401 || response.statusCode == 403) {
      await _tokenStorage.clear();
      throw const AuthenticationExpiredException();
    }

    Object? json;
    try {
      json = jsonDecode(response.body);
    } on FormatException {
      throw const DashboardApiException('The server returned invalid JSON.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = json is Map<String, dynamic>
          ? json['message'] as String?
          : null;
      throw DashboardApiException(message ?? 'Dashboard request failed.');
    }
    return json;
  }
}

class DashboardApiException implements Exception {
  const DashboardApiException(this.message);

  final String message;
}
