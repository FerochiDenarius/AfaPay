import 'package:flutter/material.dart';

const _gold = Color(0xFFF5B81F);

class DashboardFeature {
  const DashboardFeature({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

const dashboardFeatures = <DashboardFeature>[
  DashboardFeature(
    label: 'Wallet',
    icon: Icons.account_balance_wallet_outlined,
    route: '/wallet',
  ),
  DashboardFeature(
    label: 'Airtime & Data',
    icon: Icons.phone_android_rounded,
    route: '/airtime',
  ),
  DashboardFeature(
    label: 'Bill Payment',
    icon: Icons.receipt_long_rounded,
    route: '/bills',
  ),
  DashboardFeature(
    label: 'Transfer',
    icon: Icons.swap_horiz_rounded,
    route: '/transfer',
  ),
  DashboardFeature(
    label: 'Cards',
    icon: Icons.credit_card_rounded,
    route: '/cards',
  ),
  DashboardFeature(
    label: 'Savings',
    icon: Icons.savings_outlined,
    route: '/savings',
  ),
  DashboardFeature(
    label: 'Group Chat',
    icon: Icons.groups_2_outlined,
    route: '/group-chat',
  ),
  DashboardFeature(
    label: 'Voice Call',
    icon: Icons.call_outlined,
    route: '/voice-call',
  ),
  DashboardFeature(
    label: 'Video Call',
    icon: Icons.videocam_outlined,
    route: '/video-call',
  ),
  DashboardFeature(
    label: 'TV Subscription',
    icon: Icons.live_tv_outlined,
    route: '/tv-subscription',
  ),
  DashboardFeature(
    label: 'Loans',
    icon: Icons.payments_outlined,
    route: '/loans',
  ),
  DashboardFeature(
    label: 'Insurance',
    icon: Icons.verified_user_outlined,
    route: '/insurance',
  ),
];

class DashboardGrid extends StatelessWidget {
  const DashboardGrid({super.key, required this.onSelected});

  final ValueChanged<DashboardFeature> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dashboardFeatures.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: isCompact ? 10 : 12,
            crossAxisSpacing: isCompact ? 10 : 12,
            childAspectRatio: isCompact ? 0.96 : 1.02,
          ),
          itemBuilder: (context, index) {
            final feature = dashboardFeatures[index];
            return _FeatureCard(
              feature: feature,
              isCompact: isCompact,
              onTap: () => onSelected(feature),
            );
          },
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.feature,
    required this.isCompact,
    required this.onTap,
  });

  final DashboardFeature feature;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF08111E).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF22334A)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 6 : 8,
              vertical: isCompact ? 8 : 10,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Icon(feature.icon, color: _gold, size: 34),
                  ),
                ),
                SizedBox(height: isCompact ? 7 : 9),
                Flexible(
                  child: Text(
                    feature.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: isCompact ? 12.5 : 13.5,
                      height: 1.08,
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
