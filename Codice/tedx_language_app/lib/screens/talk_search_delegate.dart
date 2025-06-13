// lib/screens/talk_search_delegate.dart

import 'package:flutter/material.dart';
import '../models/talk_model.dart';
import '../services/api_service.dart';
import '../widgets/talk_card.dart';

class TalkSearchDelegate extends SearchDelegate<Talk?> {
  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final Color appBarBgColor = isDarkMode ? Colors.black : Colors.white;
    final Color iconColor = isDarkMode ? Colors.white : Colors.black;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color hintTextColor = isDarkMode ? Colors.white60 : Colors.black54;

    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBgColor,
        elevation: theme.appBarTheme.elevation,
        foregroundColor: iconColor,
      ),
      primaryColor: appBarBgColor,
      primaryIconTheme: theme.primaryIconTheme.copyWith(color: iconColor),
      textTheme: theme.textTheme.copyWith(
        titleLarge: TextStyle(color: textColor, fontSize: 18),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: hintTextColor),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final Color? bodyTextColor = Theme.of(context).textTheme.bodyMedium?.color;
    final Color? indicatorColor = Theme.of(context).colorScheme.primary;

    if (query.isEmpty) {
      return Center(
        child: Text(
          "Inizia a scrivere per cercare.",
          style: TextStyle(color: bodyTextColor),
        ),
      );
    }

    return FutureBuilder<List<Talk>>(
      future: ApiService().getTalksByTitle(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: indicatorColor),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              "Nessun talk trovato per questa ricerca.",
              style: TextStyle(color: bodyTextColor),
            ),
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

  @override
  Widget buildSuggestions(BuildContext context) {
    final Color? iconColor = Theme.of(context).textTheme.bodyMedium?.color;
    final Color? suggestionTextColor =
        Theme.of(context).textTheme.bodyMedium?.color;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: iconColor?.withOpacity(0.3) ?? Colors.white38,
          ),
          const SizedBox(height: 16),
          Text(
            "Cerca un talk per titolo...",
            style: TextStyle(color: suggestionTextColor, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
