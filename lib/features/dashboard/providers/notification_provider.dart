import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/dashboard_repository.dart';
import 'dashboard_provider.dart';

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
      NotificationNotifier.new,
    );

class NotificationState {
  const NotificationState({
    this.unreadCount = 0,
    this.isLoading = false,
    this.errorMessage,
    this.authExpired = false,
  });

  final int unreadCount;
  final bool isLoading;
  final String? errorMessage;
  final bool authExpired;

  NotificationState copyWith({
    int? unreadCount,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? authExpired,
  }) {
    return NotificationState(
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      authExpired: authExpired ?? this.authExpired,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() => const NotificationState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final count = await ref
          .read(dashboardRepositoryProvider)
          .getUnreadNotificationCount();
      state = state.copyWith(
        unreadCount: count,
        isLoading: false,
        authExpired: false,
      );
    } on AuthenticationExpiredException {
      state = state.copyWith(isLoading: false, authExpired: true);
    } on DashboardApiException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load notifications.',
      );
    }
  }
}
