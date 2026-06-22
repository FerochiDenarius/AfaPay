import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/dashboard_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/wallet_provider.dart';
import '../widgets/activity_preview.dart';
import '../widgets/balance_card.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/dashboard_grid.dart';

const _gold = Color(0xFFF5B81F);
const _muted = Color(0xFFA9ABB2);

class MainActivityScreen extends ConsumerStatefulWidget {
  const MainActivityScreen({super.key});

  @override
  ConsumerState<MainActivityScreen> createState() => _MainActivityScreenState();
}

class _MainActivityScreenState extends ConsumerState<MainActivityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboard());
  }

  Future<void> _loadDashboard() async {
    await Future.wait([
      ref.read(dashboardProvider.notifier).load(),
      ref.read(walletProvider.notifier).load(),
      ref.read(notificationProvider.notifier).load(),
    ]);
  }

  void _redirectIfAuthExpired() {
    final dashboardExpired = ref.read(dashboardProvider).authExpired;
    final walletExpired = ref.read(walletProvider).authExpired;
    final notificationExpired = ref.read(notificationProvider).authExpired;
    if (dashboardExpired || walletExpired || notificationExpired) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dashboardProvider, (_, __) => _redirectIfAuthExpired());
    ref.listen(walletProvider, (_, __) => _redirectIfAuthExpired());
    ref.listen(notificationProvider, (_, __) => _redirectIfAuthExpired());

    final dashboard = ref.watch(dashboardProvider);
    final wallet = ref.watch(walletProvider);
    final notifications = ref.watch(notificationProvider);
    final profile = dashboard.summary?.profile;

    return Scaffold(
      bottomNavigationBar: AfaBottomNavigation(
        currentRoute: '/dashboard',
        onSelected: (route) => context.go(route),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.55),
            radius: 1.24,
            colors: [Color(0xFF09234D), Color(0xFF020712), Color(0xFF01040B)],
            stops: [0, 0.45, 1],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadDashboard,
            color: _gold,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DashboardHeader(
                          firstName: profile?.firstName,
                          isLoading: dashboard.isLoading && profile == null,
                          unreadCount: notifications.unreadCount,
                          onNotifications: () => context.go('/notifications'),
                          onQrScanner: () => context.go('/pay'),
                        ),
                        const SizedBox(height: 20),
                        BalanceCard(
                          balance: wallet.balance,
                          isLoading: wallet.isLoading,
                          isBalanceVisible: wallet.isBalanceVisible,
                          errorMessage: wallet.errorMessage,
                          onToggleVisibility: ref
                              .read(walletProvider.notifier)
                              .toggleBalanceVisibility,
                          onFundWallet: () => context.go('/wallet/fund'),
                          onRetry: ref.read(walletProvider.notifier).load,
                        ),
                        const SizedBox(height: 18),
                        _PromoBanner(onLearnMore: () => context.go('/about')),
                        const SizedBox(height: 24),
                        const Text(
                          'All Features',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        DashboardGrid(
                          onSelected: (feature) => context.go(feature.route),
                        ),
                        const SizedBox(height: 24),
                        ActivityPreview(
                          transactions:
                              dashboard.summary?.recentTransactions ?? const [],
                          isLoading:
                              dashboard.isLoading && dashboard.summary == null,
                          errorMessage: dashboard.errorMessage,
                          onRetry: ref.read(dashboardProvider.notifier).load,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.firstName,
    required this.isLoading,
    required this.unreadCount,
    required this.onNotifications,
    required this.onQrScanner,
  });

  final String? firstName;
  final bool isLoading;
  final int unreadCount;
  final VoidCallback onNotifications;
  final VoidCallback onQrScanner;

  @override
  Widget build(BuildContext context) {
    final displayName = firstName == null || firstName!.trim().isEmpty
        ? 'there'
        : firstName!;

    return Row(
      children: [
        CircleAvatar(
          radius: 27,
          backgroundColor: _gold.withValues(alpha: 0.18),
          child: isLoading
              ? const _HeaderSkeleton(size: 28)
              : Text(
                  displayName[0].toUpperCase(),
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: isLoading
              ? const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderSkeleton(width: 140, height: 18),
                    SizedBox(height: 8),
                    _HeaderSkeleton(width: 96, height: 14),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $displayName 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Welcome back',
                      style: TextStyle(color: _muted, fontSize: 15),
                    ),
                  ],
                ),
        ),
        _NotificationButton(
          unreadCount: unreadCount,
          onPressed: onNotifications,
        ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          tooltip: 'QR Scanner',
          onPressed: onQrScanner,
          icon: const Icon(Icons.qr_code_scanner_rounded),
        ),
      ],
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton.filledTonal(
          tooltip: 'Notifications',
          onPressed: onPressed,
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 4,
            top: 2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D5E),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.onLearnMore});

  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _gold.withValues(alpha: 0.35)),
        gradient: LinearGradient(
          colors: [_gold.withValues(alpha: 0.18), const Color(0xFF07101D)],
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure. Fast. Reliable.',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 6),
                Text(
                  'Your all-in-one financial super app.',
                  style: TextStyle(color: _muted, fontSize: 14.5),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onLearnMore,
            style: FilledButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Learn More'),
          ),
        ],
      ),
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton({this.width, this.height, this.size});

  final double? width;
  final double? height;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size ?? width,
      height: size ?? height,
      decoration: BoxDecoration(
        color: const Color(0xFF172334),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
