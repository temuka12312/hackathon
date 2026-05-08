import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('renders empty page', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.byType(EmptyPage), findsOneWidget);
  });
}
