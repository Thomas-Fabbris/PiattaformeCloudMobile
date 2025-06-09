// lib/screens/talk_search_delegate.dart

import 'package:flutter/material.dart';
import '../models/talk_model.dart';
import '../services/api_service.dart';
import '../widgets/talk_card.dart';

class TalkSearchDelegate extends SearchDelegate<Talk?> {
  // Stile del testo nella barra di ricerca
  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    // Colori dinamici per la SearchBar in base al tema
    final Color appBarBgColor = isDarkMode ? Colors.black : Colors.white;
    final Color iconColor = isDarkMode ? Colors.white : Colors.black;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color hintTextColor = isDarkMode ? Colors.white60 : Colors.black54;

    return theme.copyWith(
      // Sfondo della barra di ricerca (stessa logica dell'AppBar principale)
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBgColor,
        elevation: theme.appBarTheme.elevation, // Mantieni l'elevation definita nel tema
        foregroundColor: iconColor, // Colore delle icone (back, clear)
      ),
      // Colore principale (non sempre usato per la barra di ricerca, ma utile per compatibilità)
      primaryColor: appBarBgColor, 
      // Colore delle icone principali della barra (es. la freccia indietro)
      primaryIconTheme: theme.primaryIconTheme.copyWith(color: iconColor),
      // Stile del testo inserito dall'utente nella barra
      textTheme: theme.textTheme.copyWith(
        titleLarge: TextStyle(color: textColor, fontSize: 18), // Stile del testo che l'utente digita
      ),
      // Stile del "hint" (testo suggerimento) nella barra di ricerca
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: hintTextColor),
        border: InputBorder.none, // Mantieni senza bordo
      ),
    );
  }

  // Costruisce l'icona per cancellare il testo (la 'X')
  @override
  List<Widget>? buildActions(BuildContext context) {
    // Le icone prenderanno il colore da foregroundColor di appBarTheme
    return [
      IconButton(
        onPressed: () {
          query = ''; // Pulisce la query
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  // Costruisce l'icona per tornare indietro
  @override
  Widget? buildLeading(BuildContext context) {
    // Le icone prenderanno il colore da foregroundColor di appBarTheme
    return IconButton(
      onPressed: () {
        close(context, null); // Chiude la ricerca
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  // Costruisce la schermata dei risultati una volta che l'utente preme "invio"
  @override
  Widget buildResults(BuildContext context) {
    final Color? bodyTextColor = Theme.of(context).textTheme.bodyMedium?.color;
    final Color? indicatorColor = Theme.of(context).colorScheme.primary;

    if (query.isEmpty) {
      return Center(child: Text("Inizia a scrivere per cercare.", style: TextStyle(color: bodyTextColor)));
    }
    
    return FutureBuilder<List<Talk>>(
      // --- MODIFICA CHIAVE QUI: Chiama getTalksByTitle ---
      future: ApiService().getTalksByTitle(query), // Usa il nuovo metodo
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: indicatorColor));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              "Nessun talk trovato per questa ricerca.", 
              style: TextStyle(color: bodyTextColor)
            )
          );
        }

        final talks = snapshot.data!;
        
        return ListView.builder(
          itemCount: talks.length,
          itemBuilder: (context, index) {
            return TalkCard(talk: talks[index]);
          },
        );
      },
    );
  }

  // Mostra i suggerimenti mentre l'utente scrive
  @override
  Widget buildSuggestions(BuildContext context) {
    final Color? iconColor = Theme.of(context).textTheme.bodyMedium?.color;
    final Color? suggestionTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: iconColor?.withOpacity(0.3) ?? Colors.white38),
          const SizedBox(height: 16),
          Text(
            "Cerca un talk per titolo...", // <--- TESTO AGGIORNATO (senza localizzazione)
            style: TextStyle(color: suggestionTextColor, fontSize: 18)
          ),
        ],
      ),
    );
  }
}