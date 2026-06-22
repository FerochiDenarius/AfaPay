import 'package:afa_pay/features/dashboard/presentation/widgets/dashboard_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders feature grid and reports selected route', (
    tester,
  ) async {
    DashboardFeature? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardGrid(onSelected: (feature) => selected = feature),
        ),
      ),
    );

    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Airtime & Data'), findsOneWidget);
    expect(
      dashboardFeatures.map((feature) => feature.label),
      contains('Insurance'),
    );

    await tester.tap(find.text('Wallet'));
    expect(selected?.route, '/wallet');
  });
}
