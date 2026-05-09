import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/app.dart';
import 'package:frontend/pages/auth_page.dart';

void main() {
  testWidgets('renders auth page', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.byType(AuthPage), findsOneWidget);
    expect(find.text('UB SmartRide'), findsOneWidget);
  });
}
