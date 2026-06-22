import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/api_config.dart';
import '../../features/auth/pages/phone_verification_screen.dart';
import '../../features/auth/pages/pin_setup_screen.dart';
import '../../features/auth/pages/registration_page.dart';
import '../../features/auth/screens/email_otp_verification_screen.dart';
import '../../features/auth/screens/email_verification_entry_screen.dart';
import '../../features/auth/screens/onboarding_complete_screen.dart';
import '../../features/dashboard/presentation/screens/main_activity_screen.dart';
import '../../screens/login_screen.dart';

final appRouter = GoRouter(
  initialLocation: ApiConfig.initialRoute,
  routes: [
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const MainActivityScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegistrationPage(),
    ),
    GoRoute(
      path: '/verify-phone',
      name: 'verify-phone',
      builder: (context, state) {
        final data = state.extra as Map<String, String>?;
        return PhoneVerificationScreen(
          userId: data?['userId'] ?? 'uuid',
          phoneNumber: data?['phoneNumber'] ?? '+233 24 812 3456',
          email: data?['email'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/pin-setup',
      name: 'pin-setup',
      builder: (context, state) {
        final data = state.extra as Map<String, String>?;
        return PinSetupScreen(
          userId: data?['userId'] ?? 'uuid',
          email: data?['email'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/email-verification',
      name: 'email-verification',
      builder: (context, state) {
        final data = state.extra as Map<String, String>?;
        return EmailVerificationEntryScreen(
          userId: data?['userId'] ?? 'uuid',
          initialEmail: data?['email'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/email-verification-code',
      name: 'email-verification-code',
      builder: (context, state) {
        final data = state.extra as Map<String, String>?;
        return EmailOtpVerificationScreen(
          userId: data?['userId'] ?? 'uuid',
          email: data?['email'] ?? 'john.doe@gmail.com',
        );
      },
    ),
    GoRoute(
      path: '/onboarding-complete',
      name: 'onboarding-complete',
      builder: (context, state) => const OnboardingCompleteScreen(),
    ),
    ..._placeholderRoutes,
  ],
);

final _placeholderRoutes = <GoRoute>[
  _placeholderRoute('/wallet', 'Wallet'),
  _placeholderRoute('/wallet/fund', 'Fund Wallet'),
  _placeholderRoute('/airtime', 'Airtime & Data'),
  _placeholderRoute('/bills', 'Bill Payment'),
  _placeholderRoute('/transfer', 'Transfer'),
  _placeholderRoute('/cards', 'Cards'),
  _placeholderRoute('/savings', 'Savings'),
  _placeholderRoute('/group-chat', 'Group Chat'),
  _placeholderRoute('/voice-call', 'Voice Call'),
  _placeholderRoute('/video-call', 'Video Call'),
  _placeholderRoute('/tv-subscription', 'TV Subscription'),
  _placeholderRoute('/loans', 'Loans'),
  _placeholderRoute('/insurance', 'Insurance'),
  _placeholderRoute('/about', 'About AfaPay'),
  _placeholderRoute('/activity', 'Activity'),
  _placeholderRoute('/pay', 'Pay'),
  _placeholderRoute('/contacts', 'Contacts'),
  _placeholderRoute('/settings', 'Settings'),
  _placeholderRoute('/notifications', 'Notifications'),
];

GoRoute _placeholderRoute(String path, String title) {
  return GoRoute(
    path: path,
    builder: (context, state) => _ComingSoonScreen(title: title),
  );
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.construction_rounded,
                color: Color(0xFFF5B81F),
                size: 56,
              ),
              const SizedBox(height: 18),
              Text(
                '$title is coming soon.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
