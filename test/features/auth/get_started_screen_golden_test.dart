import 'package:afa_pay/core/theme/app_theme.dart';
import 'package:afa_pay/features/auth/screens/get_started_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> renderScreen(
    WidgetTester tester, {
    required Brightness brightness,
  }) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAfaPayTheme(brightness),
        home: const GetStartedScreen(),
      ),
    );
    final illustration = brightness == Brightness.dark
        ? 'UIdesignImages/afa_onboarding_africa_dark.png'
        : 'UIdesignImages/afa_onboarding_africa_light.png';
    final logo = brightness == Brightness.dark
        ? 'UIdesignImages/logo.png'
        : 'UIdesignImages/appIcon.png';
    for (final asset in [illustration, logo]) {
      await tester.runAsync(
        () => precacheImage(
          AssetImage(asset),
          tester.element(find.byType(GetStartedScreen)),
        ),
      );
    }
    await tester.pumpAndSettle();
  }

  testWidgets('dark theme', (tester) async {
    await renderScreen(tester, brightness: Brightness.dark);

    await expectLater(
      find.byType(GetStartedScreen),
      matchesGoldenFile('goldens/get_started_dark.png'),
    );
  });

  testWidgets('light theme', (tester) async {
    await renderScreen(tester, brightness: Brightness.light);

    await expectLater(
      find.byType(GetStartedScreen),
      matchesGoldenFile('goldens/get_started_light.png'),
    );
  });
}
