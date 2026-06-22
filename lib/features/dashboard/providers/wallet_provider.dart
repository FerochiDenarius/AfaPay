import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_config.dart';
import '../models/wallet_balance.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => ApiConfig.useMockAuth
      ? const FrontendWalletRepository()
      : HttpWalletRepository(),
);

final walletProvider = NotifierProvider<WalletNotifier, WalletState>(
  WalletNotifier.new,
);

class WalletState {
  const WalletState({
    this.balance,
    this.isLoading = false,
    this.isBalanceVisible = true,
    this.errorMessage,
    this.authExpired = false,
  });

  final WalletBalance? balance;
  final bool isLoading;
  final bool isBalanceVisible;
  final String? errorMessage;
  final bool authExpired;

  WalletState copyWith({
    WalletBalance? balance,
    bool? isLoading,
    bool? isBalanceVisible,
    String? errorMessage,
    bool clearError = false,
    bool? authExpired,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
      isBalanceVisible: isBalanceVisible ?? this.isBalanceVisible,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      authExpired: authExpired ?? this.authExpired,
    );
  }
}

class WalletNotifier extends Notifier<WalletState> {
  @override
  WalletState build() => const WalletState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final balance = await ref.read(walletRepositoryProvider).getBalance();
      state = state.copyWith(
        balance: balance,
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
        errorMessage: 'Unable to load wallet balance.',
      );
    }
  }

  void toggleBalanceVisibility() {
    state = state.copyWith(isBalanceVisible: !state.isBalanceVisible);
  }
}
