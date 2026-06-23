import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/dashboard_provider.dart';
import '../widgets/activity_preview.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/dashboard_grid.dart';

const _gold = Color(0xFFF5B81F);
const _navy = Color(0xFF020712);

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
    await ref.read(dashboardProvider.notifier).load();
  }

  void _redirectIfAuthExpired() {
    if (ref.read(dashboardProvider).authExpired) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dashboardProvider, (_, __) => _redirectIfAuthExpired());

    final dashboard = ref.watch(dashboardProvider);

    return Scaffold(
      bottomNavigationBar: AfaBottomNavigation(
        currentRoute: '/dashboard',
        onSelected: (route) => context.go(route),
      ),
      body: Container(
        color: _navy,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadDashboard,
            color: _gold,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _AfaLogoHeader(),
                        const SizedBox(height: 18),
                        DashboardGrid(
                          onSelected: (feature) => context.go(feature.route),
                        ),
                        const SizedBox(height: 22),
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

class _AfaLogoHeader extends StatelessWidget {
  const _AfaLogoHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final logoWidth = (constraints.maxWidth * 0.64).clamp(168.0, 250.0);
        return Center(
          child: Image.asset(
            'UIdesignImages/logoEmblem.png',
            width: logoWidth,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        );
      },
    );
  }
}
