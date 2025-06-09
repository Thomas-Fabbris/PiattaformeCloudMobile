// lib/screens/language_selection_screen.dart

import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLanguage = 'Italiano'; // Lingua di default, puoi renderla persistente con SharedPreferences

  final List<Map<String, String>> _languages = [
    {'name': 'Italiano', 'code': 'it', 'flag': '🇮🇹'},
    {'name': 'English', 'code': 'en', 'flag': '🇬🇧'},
    {'name': 'Español', 'code': 'es', 'flag': '🇪🇸'},
    {'name': 'Français', 'code': 'fr', 'flag': '🇫🇷'},
    {'name': 'Deutsch', 'code': 'de', 'flag': '🇩🇪'},
    {'name': '中文', 'code': 'zh', 'flag': '🇨🇳'},
    {'name': '日本語', 'code': 'ja', 'flag': '🇯🇵'},
    {'name': 'Русский', 'code': 'ru', 'flag': '🇷🇺'},
  ];

  @override
  Widget build(BuildContext context) {
    // Ottieni i colori del testo dal tema corrente
    final Color? titleColor = Theme.of(context).textTheme.headlineSmall?.color; // Per "Scegli la tua lingua..."
    final Color? subtitleColor = Theme.of(context).textTheme.bodyMedium?.color; // Per "Questa impostazione..."
    final Color? unselectedCardColor = Theme.of(context).cardColor; // Colore delle card non selezionate
    final Color? unselectedTextColor = Theme.of(context).textTheme.bodyLarge?.color; // Colore del testo delle card non selezionate

    return Scaffold(
      appBar: CustomAppBar(title: 'Selezione Lingua'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scegli la tua lingua preferita',
              style: TextStyle(
                color: titleColor, // Colore dinamico
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Questa impostazione influenzerà l\'interfaccia dell\'app',
              style: TextStyle(
                color: subtitleColor, // Colore dinamico
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: ListView.builder(
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  final language = _languages[index];
                  final isSelected = language['name'] == _selectedLanguage;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedLanguage = language['name']!;
                        });
                        _changeLanguage(language['code']!);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          // --- MODIFICA 1: Sfondo rosso pieno per la selezione ---
                          color: isSelected ? Colors.red : unselectedCardColor, // Dinamico
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.red : Colors.transparent, // Bordo rosso se selezionato
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              language['flag']!,
                              style: const TextStyle(fontSize: 24), // Le emoji bandiera hanno colore fisso
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                language['name']!,
                                style: TextStyle(
                                  // --- MODIFICA 2: Colore del testo dinamico ---
                                  color: isSelected ? Colors.white : unselectedTextColor, // Bianco se selezionato, dinamico altrimenti
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white, // L'icona diventa bianca su sfondo rosso
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Pulsante di conferma (usa il tema elevato del bottone)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lingua cambiata in: $_selectedLanguage'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                // Usa lo stile predefinito dell'elevatedButtonTheme del tema
                // style: ElevatedButton.styleFrom(
                //   backgroundColor: Colors.red,
                //   padding: const EdgeInsets.symmetric(vertical: 12),
                // ),
                child: const Text(
                  'CONFERMA',
                  // Il colore del testo del bottone elevato è già definito nel tema come white
                  // style: TextStyle(
                  //   color: Colors.white,
                  //   fontWeight: FontWeight.bold,
                  // ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeLanguage(String languageCode) {
    print('Changing language to: $languageCode');
    // Implementa qui la logica di localizzazione (es. con un provider o un pacchetto di localizzazione)
  }
}