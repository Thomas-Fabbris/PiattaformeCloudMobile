// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:tedx_language_app/main.dart'; // Assicurati che il percorso sia corretto
import 'package:tedx_language_app/screens/login_screen.dart'; // Importa la schermata di login

void main() {
  testWidgets('App starts and shows the login screen', (WidgetTester tester) async {
    // 1. Costruisci l'app. Il widget principale si chiama MyApp.
    await tester.pumpWidget(const MyApp());

    // 2. Verifica che la schermata di Login sia visualizzata per prima.
    //    Cerchiamo un widget di testo che sappiamo essere presente solo nella LoginScreen.
    expect(find.text('CREATE AN ACCOUNT'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);

    // 3. Verifica che il titolo 'TEDx Talks' (della HomeScreen) NON sia presente.
    expect(find.text('TEDx Talks'), findsNothing);
  });
}