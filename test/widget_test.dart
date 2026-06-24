import 'package:afa_pay/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the AfaPay login form first', (tester) async {
    await tester.pumpWidget(const AfaPayApp());

    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Login to your AFA account'), findsOneWidget);
    expect(find.text('Email or Phone Number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('shows the light login signup section', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const AfaPayApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text("Don’t have an account?"), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Sign Up'), findsOneWidget);
  });
}
