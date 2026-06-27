import 'package:afa_pay/main.dart';
import 'package:afa_pay/features/auth/screens/get_started_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the dark get started screen first', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const AfaPayApp());

    expect(find.byType(GetStartedScreen), findsOneWidget);
    expect(find.textContaining('Welcome to'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('sign in opens the light login signup section', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const AfaPayApp());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text("Don’t have an account?"), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Sign Up'), findsOneWidget);
  });
}
