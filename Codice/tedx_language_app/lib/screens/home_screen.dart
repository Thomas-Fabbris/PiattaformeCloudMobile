// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/talk_provider.dart';
import '../widgets/talk_card.dart';
import '../widgets/custom_app_bar.dart';

String _capitalizeFirstLetter(String text) {
  if (text.isEmpty) {
    return text;
  }

  return text[0].toUpperCase() + text.substring(1);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _tags = [
    'Tutti',
    'technology',
    'science',
    'creativity',
    'design',
    'business',
  ];
  String _selectedTag = 'Tutti';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<TalkProvider>(
        context,
        listen: false,
      ).fetchTalks(_getFilterValue(_selectedTag)),
    );
  }

  String _getFilterValue(String tag) {
    if (tag == 'Tutti') {
      return 'all';
    }
    return tag.toLowerCase();
  }

  Widget _buildFilterChips() {
    final Color? sectionTitleColor =
        Theme.of(context).textTheme.headlineSmall?.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text(
            "Esplora per Categoria",
            style: TextStyle(
              color: sectionTitleColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: _tags.length,
            itemBuilder: (context, index) {
              final tag = _tags[index];
              final isSelected = tag == _selectedTag;

              final Color chipTextColor =
                  isSelected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium!.color!;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: InkWell(
                  onTap: () {
                    if (!isSelected) {
                      setState(() {
                        _selectedTag = tag;
                      });
                      Provider.of<TalkProvider>(
                        context,
                        listen: false,
                      ).fetchTalks(_getFilterValue(_selectedTag));
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? Colors.red : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected
                                ? Colors.red
                                : Theme.of(context).dividerColor,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _capitalizeFirstLetter(tag),
                        style: TextStyle(
                          color: chipTextColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
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
      appBar: CustomAppBar(title: 'TEDx Language'),
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
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  );
                }

                if (talkProvider.talks.isEmpty) {
                  return Center(
                    child: Text(
                      'Nessun talk trovato.',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 10),
                  itemCount: talkProvider.talks.length,
                  itemBuilder:
                      (context, index) =>
                          TalkCard(talk: talkProvider.talks[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
