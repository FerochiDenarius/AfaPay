import 'package:afa_pay/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the AfaPay registration form', (tester) async {
    await tester.pumpWidget(const AfaPayApp());

    expect(find.text('Create Your Account'), findsOneWidget);
    expect(find.text('First Name'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password must contain:'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
