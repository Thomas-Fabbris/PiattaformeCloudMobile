// lib/screens/exercise_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/talk_model.dart';
import '../services/api_service.dart';
import '../widgets/talk_card.dart';
import '../widgets/custom_app_bar.dart'; // Assicurati che custom_app_bar gestisca i colori del tema

class ExerciseScreen extends StatefulWidget {
  final Talk talk;
  const ExerciseScreen({super.key, required this.talk});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  VideoPlayerController? _controller;
  late Future<void> _initializeVideoPlayerFuture;

  List<Talk>? _watchNextTalks;
  bool _isLoadingWatchNext = true;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayerFuture = _extractAndInitializeVideoPlayer();
    _fetchWatchNext();
  }

  Future<void> _extractAndInitializeVideoPlayer() async {
    try {
      final response = await http.get(Uri.parse(widget.talk.url));
      if (response.statusCode != 200) throw Exception('Impossibile caricare la pagina del talk');
      var document = parser.parse(response.body);
      var scriptElement = document.getElementById('__NEXT_DATA__');
      if (scriptElement == null) throw Exception('Script dati video non trovato.');
      var jsonData = json.decode(scriptElement.text);
      var playerDataString = jsonData['props']['pageProps']['videoData']['playerData'];
      if (playerDataString == null) throw Exception('Dati player non trovati.');
      var playerData = json.decode(playerDataString);
      String? videoUrl;
      if (playerData['resources']?['h264'] != null && (playerData['resources']['h264'] as List).isNotEmpty) {
        var video480p = (playerData['resources']['h264'] as List).firstWhere((v) => v['name'] == '480p', orElse: () => null);
        videoUrl = video480p?['file'] ?? playerData['resources']['h264'][0]['file'];
      }
      if (videoUrl == null || !videoUrl.endsWith('.mp4')) throw Exception('URL .mp4 non trovato.');
      
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _controller!.initialize();
      
      // Il listener aggiorna la UI quando lo stato del player cambia (play/pausa)
      _controller!.addListener(() {
        if (mounted) setState(() {});
      });
      
    } catch (e) {
      print("Errore estrazione video: $e");
      throw Exception('Errore caricamento video.');
    }
  }

  Future<void> _fetchWatchNext() async {
    final apiService = ApiService(); 
    try {
      final talks = await apiService.getWatchNext(widget.talk.id);
      if (mounted) setState(() {
        _watchNextTalks = talks;
        _isLoadingWatchNext = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingWatchNext = false);
      print("Errore caricamento watch next: $e");
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(() {}); 
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ottieni il colore del testo per il tema corrente
    final Color? sectionTitleColor = Theme.of(context).textTheme.titleLarge?.color;
    // Assicurati che lo "Spazio per gli esercizi..." abbia un colore dinamico
    final Color? bodyTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.talk.title,
        showSearchAction: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVideoPlayer(),
            
            const SizedBox(height: 24),
            Text(
              "Spazio per gli esercizi...",
              style: TextStyle(color: bodyTextColor), // Colore dinamico
            ),
            Divider(
              height: 40, 
              thickness: 1, 
              indent: 20, 
              endIndent: 20,
              color: Theme.of(context).dividerColor, // Colore del Divider dinamico
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                "Potrebbe interessarti anche", 
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  // --- MODIFICA QUI: Usa la variabile sectionTitleColor ---
                  color: sectionTitleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildWatchNextSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return FutureBuilder<void>(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        // Ottieni i colori dinamici per il player
        final Color containerBgColor = Theme.of(context).cardColor; // Un colore scuro per il tema scuro, chiaro per il tema chiaro
        final Color indicatorColor = Theme.of(context).colorScheme.primary; // O un altro colore appropriato
        final Color errorTextColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white; // Colore del testo di errore dinamico

        if (snapshot.connectionState == ConnectionState.waiting) {
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                // Colore del container dinamico
                color: containerBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: CircularProgressIndicator(color: indicatorColor)), // Colore dinamico
            ),
          );
        }
        if (snapshot.hasError) {
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                // Colore del container dinamico
                color: containerBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text('Errore nel caricamento del video.', style: TextStyle(color: errorTextColor))), // Colore dinamico
            ),
          );
        }
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                VideoPlayer(_controller!),
                
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                    });
                  },
                ),

                AnimatedOpacity(
                  opacity: _controller!.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5), // L'overlay nero può rimanere fisso
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 80), // Icona play bianca va bene
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Widget per la sezione "Watch Next"
  Widget _buildWatchNextSection() {
    if (_isLoadingWatchNext) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary, // Colore dinamico
        ),
      );
    }
    if (_watchNextTalks == null || _watchNextTalks!.isEmpty) {
      return Center( // Centra il messaggio se non ci sono talk
        child: Text(
          'Nessun talk correlato trovato.',
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color), // Colore dinamico
        ),
      );
    }
    return SizedBox(
      height: 250, // Altezza desiderata per la riga dei "Watch Next"
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        // Aggiungi un padding alla ListView per il margine iniziale a sinistra
        padding: const EdgeInsets.symmetric(horizontal: 0), // Modifica: Rimosso padding orizzontale dal container
        itemCount: _watchNextTalks!.length,
        itemBuilder: (context, index) {
          final talk = _watchNextTalks![index];
          return Padding(
            // --- MODIFICA QUI: Regola il padding tra le card ---
            padding: EdgeInsets.only(
              right: (index == _watchNextTalks!.length - 1) ? 0 : 12.0, // Solo spazio tra le card, non alla fine
              left: (index == 0) ? 16.0 : 0, // Margine a sinistra solo per la prima card
            ),
            child: SizedBox(
              // --- MODIFICA QUI: Aumenta la larghezza della card ---
              width: 280, // Larghezza desiderata per ogni TalkCard (era 200)
              child: TalkCard(talk: talk),
            ),
          );
        },
      ),
    );
  }
}