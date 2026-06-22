import 'package:afa_pay/features/dashboard/models/dashboard_summary.dart';
import 'package:afa_pay/features/dashboard/providers/dashboard_provider.dart';
import 'package:afa_pay/features/dashboard/providers/notification_provider.dart';
import 'package:afa_pay/features/dashboard/repositories/dashboard_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads unread notification badge count', () async {
    final container = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(
          const _NotificationRepositoryFake(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(notificationProvider.notifier).load();

    final state = container.read(notificationProvider);
    expect(state.unreadCount, 5);
    expect(state.isLoading, isFalse);
    expect(state.errorMessage, isNull);
  });
}

class _NotificationRepositoryFake implements DashboardRepository {
  const _NotificationRepositoryFake();

  @override
  Future<DashboardSummary> getSummary() {
    throw UnimplementedError();
  }

  @override
  Future<int> getUnreadNotificationCount() async => 5;
}
