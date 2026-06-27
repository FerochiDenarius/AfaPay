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
      context.go('/enter-pin');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dashboardProvider, (_, __) => _redirectIfAuthExpired());

    final dashboard = ref.watch(dashboardProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      bottomNavigationBar: AfaBottomNavigation(
        currentRoute: '/dashboard',
        onSelected: (route) => context.go(route),
      ),
      body: Container(
        color: isLight ? const Color(0xFFF8FAFD) : _navy,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadDashboard,
            color: _gold,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    isLight ? 36 : 18,
                    isLight ? 30 : 12,
                    isLight ? 36 : 18,
                    24,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AfaLogoHeader(isLight: isLight),
                        SizedBox(height: isLight ? 32 : 18),
                        DashboardGrid(
                          onSelected: (feature) => context.go(feature.route),
                        ),
                        if (!isLight) ...[
                          const SizedBox(height: 22),
                          ActivityPreview(
                            transactions:
                                dashboard.summary?.recentTransactions ??
                                const [],
                            isLoading:
                                dashboard.isLoading &&
                                dashboard.summary == null,
                            errorMessage: dashboard.errorMessage,
                            onRetry: ref.read(dashboardProvider.notifier).load,
                          ),
                        ],
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
  const _AfaLogoHeader({required this.isLight});

  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isLight) {
          final cardWidth = constraints.maxWidth;
          final fullImageWidth = cardWidth / 0.82;
          final scale = fullImageWidth / 853;
          final topCrop = 134 * scale;
          final cardHeight = 520 * scale;

          return Container(
            height: cardHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEFF2F6)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 22,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: ClipRect(
              child: OverflowBox(
                maxWidth: fullImageWidth,
                minWidth: fullImageWidth,
                alignment: Alignment.topCenter,
                child: Transform.translate(
                  offset: Offset(0, -topCrop),
                  child: Image.asset(
                    'UIdesignImages/mainPageLightTheme.png',
                    width: fullImageWidth,
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
          );
        }

        final logoWidth = (constraints.maxWidth * 0.64).clamp(168.0, 250.0);
        return Center(
          child: Image.asset(
            'UIdesignImages/logo.png',
            width: logoWidth,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        );
      },
    );
  }
}
