import 'package:afa_pay/features/dashboard/models/wallet_balance.dart';
import 'package:afa_pay/features/dashboard/providers/wallet_provider.dart';
import 'package:afa_pay/features/dashboard/repositories/wallet_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads wallet balance and toggles visibility', () async {
    final container = ProviderContainer(
      overrides: [
        walletRepositoryProvider.overrideWithValue(
          const _FakeWalletRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(walletProvider.notifier).load();
    expect(container.read(walletProvider).balance?.balance, 250000);
    expect(container.read(walletProvider).isBalanceVisible, isTrue);

    container.read(walletProvider.notifier).toggleBalanceVisibility();
    expect(container.read(walletProvider).isBalanceVisible, isFalse);
  });
}

class _FakeWalletRepository implements WalletRepository {
  const _FakeWalletRepository();

  @override
  Future<WalletBalance> getBalance() async {
    return const WalletBalance(balance: 250000, currency: 'NGN');
  }
}
