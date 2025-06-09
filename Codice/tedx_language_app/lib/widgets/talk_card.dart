// lib/widgets/talk_card.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/talk_model.dart';
import '../screens/exercise_screen.dart';

class TalkCard extends StatefulWidget {
  final Talk talk;
  const TalkCard({super.key, required this.talk});

  @override
  State<TalkCard> createState() => _TalkCardState();
}

class _TalkCardState extends State<TalkCard> {
  late Future<String?> _imageUrlFuture;

  @override
  void initState() {
    super.initState();
    _imageUrlFuture = _fetchImageUrl();
  }

  Future<String?> _fetchImageUrl() async {
    try {
      final response = await http.get(Uri.parse(widget.talk.url));
      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        var imageElement = document.querySelector('meta[property="og:image"]');
        if (imageElement != null) {
          return imageElement.attributes['content'];
        }
      }
      return null;
    } catch (e) {
      print("Errore scraping immagine per ${widget.talk.title}: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ora puoi prendere il colore del testo direttamente dal textTheme del contesto
    // È preferibile usare colorScheme.onSurface se vuoi un colore che si adatti
    // al colore della superficie (come la Card)
    final Color? titleColor = Theme.of(context).textTheme.titleLarge?.color; // Usa lo stile definito nel ThemeProvider
    // Oppure potresti usare:
    // final Color? titleColor = Theme.of(context).colorScheme.onSurface; // Questo si adatta alla superficie della Card

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ExerciseScreen(talk: widget.talk),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: FutureBuilder<String?>(
                  future: _imageUrlFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(color: Colors.black26, child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0)));
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                      return Container(color: Colors.black26, child: Center(child: Icon(Icons.image_not_supported, color: Colors.white38, size: 40)));
                    }
                    final imageUrl = snapshot.data!;
                    return Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: Colors.black26, child: Center(child: Icon(Icons.image_not_supported, color: Colors.white38, size: 40)));
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.talk.speakers.toUpperCase(),
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.talk.title,
                      // --- MODIFICA CHIAVE QUI: USA IL COLORE DEL TESTO DAL TEMA ---
                      style: TextStyle(color: titleColor, fontWeight: FontWeight.bold, fontSize: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}