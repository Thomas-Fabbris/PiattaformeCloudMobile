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
      final Color snackBarBg = Theme.of(context).colorScheme.error;
      final Color snackBarText = Theme.of(context).colorScheme.onError;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Login fallito. Controlla le credenziali.',
            style: TextStyle(color: snackBarText),
          ),
          backgroundColor: snackBarBg,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color mainTitleColor =
        Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black;
    final Color subtitleColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;
    final Color inputContentColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
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
                    color: mainTitleColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Impara le lingue, una grande idea alla volta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: subtitleColor),
                ),
                const SizedBox(height: 48.0),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: inputContentColor),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: inputContentColor.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: TextStyle(color: inputContentColor),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: inputContentColor.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                    : ElevatedButton(
                      onPressed: _login,
                      child: const Text(
                        'ACCEDI',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
