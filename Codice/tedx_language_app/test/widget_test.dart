// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:tedx_language_app/main.dart'; 

void main() {
  testWidgets('App starts and shows the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    expect(find.text('CREATE AN ACCOUNT'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('TEDx Talks'), findsNothing);
  });
}