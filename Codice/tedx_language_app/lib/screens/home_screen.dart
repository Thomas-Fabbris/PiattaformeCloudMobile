// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/talk_provider.dart';
import '../widgets/talk_card.dart';
import '../widgets/custom_app_bar.dart'; // Assicurati che custom_app_bar gestisca i colori del tema

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _tags = ['Tutti', 'technology', 'science', 'creativity', 'design', 'business'];
  String _selectedTag = 'Tutti';

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
      Provider.of<TalkProvider>(context, listen: false).fetchTalks(_getFilterValue(_selectedTag))
    );
  }

  // Metodo helper per convertire il tag selezionato nel valore del filtro
  String _getFilterValue(String tag) {
    if (tag == 'Tutti') {
      return 'all'; // Wildcard per "tutti"
    }
    return tag.toLowerCase();
  }

  // --- WIDGET DEI FILTRI MIGLIORATO ---
  Widget _buildFilterChips() {
    // Ottieni il colore del testo per il titolo della sezione dal tema corrente
    final Color? sectionTitleColor = Theme.of(context).textTheme.headlineSmall?.color;
    // Potresti anche usare Theme.of(context).colorScheme.onSurface per un colore che si adatta allo sfondo della superficie

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text(
            "Esplora per Categoria",
            style: TextStyle(
              // --- MODIFICA QUI: Usa il colore dinamico del tema ---
              color: sectionTitleColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox( // Usiamo SizedBox invece di Container per una migliore flessibilità
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: _tags.length,
            itemBuilder: (context, index) {
              final tag = _tags[index];
              final isSelected = tag == _selectedTag;
              
              // Determina il colore del testo per i chip in base al tema e alla selezione
              // Se il chip è selezionato, il testo è bianco (perché lo sfondo sarà rosso)
              // Se non è selezionato, il testo deve adattarsi al tema (scuro in light, bianco in dark)
              final Color chipTextColor = isSelected 
                  ? Colors.white 
                  : Theme.of(context).textTheme.bodyMedium!.color!; // Usa un colore di testo generico dal tema

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: InkWell(
                  onTap: () {
                    if (!isSelected) {
                      setState(() {
                        _selectedTag = tag;
                      });
                      Provider.of<TalkProvider>(context, listen: false).fetchTalks(_getFilterValue(_selectedTag));
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.red : Theme.of(context).cardColor, // Colore del chip non selezionato prende dal tema
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.red : Theme.of(context).dividerColor, // Colore del bordo dinamico
                        width: 1.5,
                      )
                    ),
                    child: Center(
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: chipTextColor, // Applica il colore dinamico del testo del chip
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'TEDx Language'), // L'AppBar dovrebbe già gestire il colore del titolo
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterChips(),
          const SizedBox(height: 10),
          
          Expanded(
            child: Consumer<TalkProvider>(
              builder: (context, talkProvider, child) {
                if (talkProvider.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      // Colore del CircularProgressIndicator dinamico
                      color: Theme.of(context).colorScheme.primary, 
                    ),
                  );
                }
            
                if (talkProvider.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Impossibile caricare i talk.\nDettagli: ${talkProvider.error}', 
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color), // Colore errore dinamico
                      ),
                    ),
                  );
                }
            
                if (talkProvider.talks.isEmpty) {
                  return Center(
                    child: Text(
                      'Nessun talk trovato.',
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color), // Colore testo "nessun talk" dinamico
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 10),
                  itemCount: talkProvider.talks.length,
                  itemBuilder: (context, index) => TalkCard(talk: talkProvider.talks[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}