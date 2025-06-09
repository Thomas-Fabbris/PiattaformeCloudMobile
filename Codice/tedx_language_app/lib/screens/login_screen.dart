// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:tedx_language_app/services/cognito_service.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cognitoService = CognitoService();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final success = await _cognitoService.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    } else {
      // Ottieni colori dal tema per la SnackBar di errore
      final Color snackBarBg = Theme.of(context).colorScheme.error;
      final Color snackBarText = Theme.of(context).colorScheme.onError;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login fallito. Controlla le credenziali.', style: TextStyle(color: snackBarText)),
          backgroundColor: snackBarBg,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ottieni i colori dinamici dal tema
    final Color primaryTextColor = Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black; // Per il titolo "TEDx Language"
    final Color secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54; // Per il sottotitolo e le icone/hintText
    final Color inputTextColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black; // Per il testo digitato nell'input
    final Color inputFillColor = Theme.of(context).inputDecorationTheme.fillColor ?? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey[100]!); // Colore di riempimento per TextFormField
    final Color inputHintColor = Theme.of(context).inputDecorationTheme.hintStyle?.color ?? secondaryTextColor; // Colore del hint
    final Color inputPrefixIconColor = secondaryTextColor; // Colore delle icone all'interno dei TextFormField

    return Scaffold(
      // Scaffold background color è già gestito dal ThemeProvider
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Logo TEDx Language
                Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Image.asset(
                    'assets/images/logo4.1-2.png',
                    fit: BoxFit.contain,
                  ),
                ),
                Text(
                  'TEDx Language',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor, // Colore dinamico
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Impara le lingue, una grande idea alla volta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: secondaryTextColor, // Colore dinamico
                  ),
                ),
                const SizedBox(height: 48.0),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined, color: inputPrefixIconColor), // Colore dinamico
                    // Colori di riempimento e bordo gestiti dal tema
                    fillColor: inputFillColor,
                    filled: true,
                    border: Theme.of(context).inputDecorationTheme.border, // Prendi il bordo dal tema
                    hintStyle: TextStyle(color: inputHintColor), // Colore dinamico per il hint
                  ),
                  style: TextStyle(color: inputTextColor), // Colore dinamico per il testo digitato
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline, color: inputPrefixIconColor), // Colore dinamico
                    // Colori di riempimento e bordo gestiti dal tema
                    fillColor: inputFillColor,
                    filled: true,
                    border: Theme.of(context).inputDecorationTheme.border, // Prendi il bordo dal tema
                    hintStyle: TextStyle(color: inputHintColor), // Colore dinamico per il hint
                  ),
                  style: TextStyle(color: inputTextColor), // Colore dinamico per il testo digitato
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary, // Colore dinamico (rosso TEDx)
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _login,
                        // Lo stile del bottone è già gestito globalmente dal ThemeProvider
                        // child: const Text('ACCEDI', style: TextStyle(fontWeight: FontWeight.bold)), // Il colore del testo è gestito dal ThemeProvider
                      child: const Text('ACCEDI', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}