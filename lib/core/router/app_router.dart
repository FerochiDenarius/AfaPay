import 'package:go_router/go_router.dart';

import '../config/api_config.dart';
import '../../features/auth/pages/phone_verification_screen.dart';
import '../../features/auth/pages/pin_setup_screen.dart';
import '../../features/auth/pages/registration_page.dart';
import '../../features/auth/screens/email_otp_verification_screen.dart';
import '../../features/auth/screens/email_verification_entry_screen.dart';
import '../../features/auth/screens/onboarding_complete_screen.dart';
import '../../screens/login_screen.dart';

final appRouter = GoRouter(
  initialLocation: ApiConfig.initialRoute,
  routes: [
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
        );
      },
    ),
    GoRoute(
      path: '/pin-setup',
      name: 'pin-setup',
      builder: (context, state) {
        final data = state.extra as Map<String, String>?;
        return PinSetupScreen(userId: data?['userId'] ?? 'uuid');
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
  ],
);
