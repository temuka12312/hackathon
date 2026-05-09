import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/app.dart';

void main() {
  testWidgets('renders login page', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
