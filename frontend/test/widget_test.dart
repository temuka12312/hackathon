import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app.dart';

void main() {
  testWidgets('renders onboarding screen', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Саад мэдээлэх'), findsOneWidget);
    expect(find.text('Report road obstacles'), findsOneWidget);
    expect(find.text('Үргэлжлүүлэх'), findsOneWidget);
  });
}
