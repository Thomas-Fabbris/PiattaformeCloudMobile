// lib/screens/language_selection_screen.dart

import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLanguage = 'Italiano';

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
    final Color? titleColor = Theme.of(context).textTheme.headlineSmall?.color;
    final Color? subtitleColor = Theme.of(context).textTheme.bodyMedium?.color;
    final Color? unselectedCardColor = Theme.of(context).cardColor;
    final Color? unselectedTextColor =
        Theme.of(context).textTheme.bodyLarge?.color;

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
                color: titleColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Questa impostazione influenzerà l\'interfaccia dell\'app',
              style: TextStyle(color: subtitleColor, fontSize: 14),
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
                          color: isSelected ? Colors.red : unselectedCardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.red : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              language['flag']!,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                language['name']!,
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : unselectedTextColor,
                                  fontSize: 16,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

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

                child: const Text('CONFERMA'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeLanguage(String languageCode) {
    print('Changing language to: $languageCode');
  }
}
