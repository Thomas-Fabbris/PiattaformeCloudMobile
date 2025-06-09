// lib/screens/main_navigation_screen.dart

import 'package:flutter/material.dart';
// Non è più necessario importare il ThemeProvider qui, in quanto usiamo Theme.of(context)
// import 'package:provider/provider.dart'; // Rimuovi se non usato altrove in questo file
import 'home_screen.dart';
import 'account_screen.dart';
import 'language_selection_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  // Lista delle pagine
  final List<Widget> _pages = [
    const HomeScreen(),
    const AccountScreen(),
    const LanguageSelectionScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Ottieni il tema corrente per determinare i colori della BottomNavigationBar
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    // Colori dinamici per la BottomNavigationBar
    // Sfondo della navbar: nero nel tema scuro, bianco nel tema chiaro
    final Color navBarBackgroundColor = isDarkMode ? Colors.black : Colors.white;
    // Colore degli elementi selezionati (rosso TEDx, già definito nel tuo primaryColor)
    final Color selectedItemColor = theme.primaryColor;
    // Colore degli elementi non selezionati: bianco semi-trasparente nel tema scuro, nero semi-trasparente nel tema chiaro
    final Color unselectedItemColor = isDarkMode ? Colors.white54 : Colors.black54;

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          // --- MODIFICA QUI: Colore di sfondo del Container dinamico ---
          color: navBarBackgroundColor,
          boxShadow: [
            // L'ombra può essere più o meno visibile a seconda del tema
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.6 : 0.2), // Ombra più o meno intensa a seconda del tema
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          // --- MODIFICHE QUI: Colori della BottomNavigationBar dinamici ---
          backgroundColor: navBarBackgroundColor, // Usa il colore dinamico
          selectedItemColor: selectedItemColor,     // Usa il colore dinamico
          unselectedItemColor: unselectedItemColor, // Usa il colore dinamico
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0, // L'elevation è già gestita dal BoxDecoration del Container
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              activeIcon: Icon(Icons.account_circle),
              label: 'Account',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.language_outlined),
              activeIcon: Icon(Icons.language),
              label: 'Lingua',
            ),
          ],
        ),
      ),
    );
  }
}