import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_config.dart';
import '../models/dashboard_summary.dart';
import '../repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => ApiConfig.useMockAuth
      ? const FrontendDashboardRepository()
      : HttpDashboardRepository(),
);

final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);

class DashboardState {
  const DashboardState({
    this.summary,
    this.isLoading = false,
    this.errorMessage,
    this.authExpired = false,
  });

  final DashboardSummary? summary;
  final bool isLoading;
  final String? errorMessage;
  final bool authExpired;

  DashboardState copyWith({
    DashboardSummary? summary,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? authExpired,
  }) {
    return DashboardState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      authExpired: authExpired ?? this.authExpired,
    );
  }
}

class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() => const DashboardState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final summary = await ref.read(dashboardRepositoryProvider).getSummary();
      state = state.copyWith(
        summary: summary,
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
        errorMessage: 'Unable to load your dashboard.',
      );
    }
  }
}
