import 'package:afa_pay/features/dashboard/models/dashboard_summary.dart';
import 'package:afa_pay/features/dashboard/models/transaction_preview.dart';
import 'package:afa_pay/features/dashboard/models/user_profile.dart';
import 'package:afa_pay/features/dashboard/providers/dashboard_provider.dart';
import 'package:afa_pay/features/dashboard/repositories/dashboard_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads dashboard summary from repository', () async {
    final container = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(
          const _FakeDashboardRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(dashboardProvider.notifier).load();

    final state = container.read(dashboardProvider);
    expect(state.isLoading, isFalse);
    expect(state.errorMessage, isNull);
    expect(state.summary?.profile.firstName, 'Bright');
    expect(state.summary?.recentTransactions, hasLength(1));
  });

  test('marks auth as expired when repository rejects the token', () async {
    final container = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(
          const _ExpiredDashboardRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(dashboardProvider.notifier).load();

    final state = container.read(dashboardProvider);
    expect(state.authExpired, isTrue);
    expect(state.isLoading, isFalse);
  });
}

class _FakeDashboardRepository implements DashboardRepository {
  const _FakeDashboardRepository();

  @override
  Future<DashboardSummary> getSummary() async {
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
          time: DateTime(2026),
        ),
      ],
    );
  }

  @override
  Future<int> getUnreadNotificationCount() async => 5;
}

class _ExpiredDashboardRepository implements DashboardRepository {
  const _ExpiredDashboardRepository();

  @override
  Future<DashboardSummary> getSummary() async {
    throw const AuthenticationExpiredException();
  }

  @override
  Future<int> getUnreadNotificationCount() async {
    throw const AuthenticationExpiredException();
  }
}
