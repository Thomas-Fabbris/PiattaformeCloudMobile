// lib/screens/account_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_app_bar.dart';
import '../services/cognito_service.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _cognitoService = CognitoService();
  String? _userEmail;
  String? _userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final email = await _cognitoService.getCurrentUserEmail();
    final name = await _cognitoService.getCurrentUserName();

    if (mounted) {
      setState(() {
        _userEmail = email;
        _userName = name ?? 'Utente';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final Color dialogBgColor = Theme.of(context).cardColor;
    final Color dialogTitleColor =
        Theme.of(context).textTheme.titleLarge?.color ?? Colors.black;
    final Color dialogContentColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;
    final Color dialogButtonColor = Theme.of(context).colorScheme.primary;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: dialogBgColor,
            title: Text(
              'Conferma Logout',
              style: TextStyle(color: dialogTitleColor),
            ),
            content: Text(
              'Sei sicuro di voler uscire dall\'app?',
              style: TextStyle(color: dialogContentColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Annulla',
                  style: TextStyle(color: dialogContentColor),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Logout',
                  style: TextStyle(color: dialogButtonColor),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final success = await _cognitoService.signOut();
      if (success && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Errore durante il logout',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showNotImplemented(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature: funzione non ancora disponibile',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final Color cardBackgroundColor = Theme.of(context).cardColor;
    final Color primaryTextColor =
        Theme.of(context).textTheme.titleLarge?.color ?? Colors.black;
    final Color secondaryTextColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Account'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Image.asset(
                      'assets/images/logo4.1-2.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLoading ? 'Caricamento...' : _userName ?? 'Utente',
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isLoading
                              ? 'Caricamento...'
                              : _userEmail ?? 'Email non disponibile',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildThemeToggle(
              themeProvider,
              cardBackgroundColor,
              primaryTextColor,
              secondaryTextColor,
            ),
            _buildMenuItem(
              icon: Icons.settings_outlined,
              title: 'Impostazioni',
              onTap: () => _showNotImplemented('Impostazioni'),
              cardBackgroundColor: cardBackgroundColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            _buildMenuItem(
              icon: Icons.help_outline,
              title: 'Aiuto',
              onTap: () => _showNotImplemented('Aiuto'),
              cardBackgroundColor: cardBackgroundColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            _buildMenuItem(
              icon: Icons.info_outline,
              title: 'Informazioni',
              onTap: () => _showNotImplemented('Informazioni'),
              cardBackgroundColor: cardBackgroundColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,

                child: const Text('LOGOUT'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(
    ThemeProvider themeProvider,
    Color cardBackgroundColor,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,

              color: secondaryTextColor,
            ),
            const SizedBox(width: 16),
            Text(
              'Tema scuro',
              style: TextStyle(color: primaryTextColor, fontSize: 16),
            ),
            const Spacer(),
            Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(),
              activeColor: Colors.red,
              inactiveThumbColor: secondaryTextColor,
              inactiveTrackColor: secondaryTextColor.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color cardBackgroundColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: secondaryTextColor),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(color: primaryTextColor, fontSize: 16),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                color: secondaryTextColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
