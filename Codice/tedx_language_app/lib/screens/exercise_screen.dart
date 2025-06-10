// lib/screens/exercise_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/talk_model.dart';
import '../models/exercise_model.dart';
import '../services/api_service.dart';
import '../widgets/talk_card.dart';
import '../widgets/custom_app_bar.dart';

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

  late Future<List<Exercise>> _exercisesFuture;
  List<Exercise> _exercises = [];
  int _currentQuestionIndex = 0;
  String? _selectedOption;
  bool _answerChecked = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayerFuture = _extractAndInitializeVideoPlayer();
    _fetchWatchNext();
    _exercisesFuture = ApiService().getOrGenerateExercises(widget.talk.id);
  }

  // --- LOGICA DI CONTROLLO SEMPLIFICATA E CORRETTA ---
  void _checkAnswer() {
    if (_selectedOption == null) return;
    setState(() {
      _answerChecked = true;
      if (_selectedOption == _exercises[_currentQuestionIndex].correctAnswer) {
        _score++;
      }
    });
  }

  Future<void> _extractAndInitializeVideoPlayer() async { try { final response = await http.get(Uri.parse(widget.talk.url)); if (response.statusCode != 200) throw Exception('Impossibile caricare la pagina del talk'); var document = parser.parse(response.body); var scriptElement = document.getElementById('__NEXT_DATA__'); if (scriptElement == null) throw Exception('Script dati video non trovato.'); var jsonData = json.decode(scriptElement.text); var playerDataString = jsonData['props']['pageProps']['videoData']['playerData']; if (playerDataString == null) throw Exception('Dati player non trovati.'); var playerData = json.decode(playerDataString); String? videoUrl; if (playerData['resources']?['h264'] != null && (playerData['resources']['h264'] as List).isNotEmpty) { var video480p = (playerData['resources']['h264'] as List).firstWhere((v) => v['name'] == '480p', orElse: () => null); videoUrl = video480p?['file'] ?? playerData['resources']['h264'][0]['file']; } if (videoUrl == null || !videoUrl.endsWith('.mp4')) throw Exception('URL .mp4 non trovato.'); _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl)); await _controller!.initialize(); _controller!.addListener(() { if (mounted) setState(() {}); }); } catch (e) { print("Errore estrazione video: $e"); throw Exception('Errore caricamento video.'); } }
  Future<void> _fetchWatchNext() async { final apiService = ApiService(); try { final talks = await apiService.getWatchNext(widget.talk.id); if (mounted) setState(() { _watchNextTalks = talks; _isLoadingWatchNext = false; }); } catch (e) { if (mounted) setState(() => _isLoadingWatchNext = false); print("Errore caricamento watch next: $e"); } }
  void _nextQuestion() { setState(() { if (_currentQuestionIndex < _exercises.length - 1) { _currentQuestionIndex++; _selectedOption = null; _answerChecked = false; } else { _currentQuestionIndex++; } }); }
  void _restartQuiz() { setState(() { _currentQuestionIndex = 0; _selectedOption = null; _answerChecked = false; _score = 0; _exercisesFuture = ApiService().getOrGenerateExercises(widget.talk.id); }); }
  @override
  void dispose() { _controller?.removeListener(() {});  _controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: widget.talk.title, showSearchAction: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVideoPlayer(),
            const SizedBox(height: 24),
            _buildExerciseSection(),
            Divider(height: 40, thickness: 1, indent: 20, endIndent: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text("Potrebbe interessarti anche", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            _buildWatchNextSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseSection() {
    return FutureBuilder<List<Exercise>>(
      future: _exercisesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Impossibile caricare gli esercizi."));
        _exercises = snapshot.data!;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (Widget child, Animation<double> animation) => FadeTransition(opacity: animation, child: child),
          child: _currentQuestionIndex >= _exercises.length ? _buildResultsWidget() : _buildQuestionWidget(),
        );
      },
    );
  }

  Widget _buildQuestionWidget() {
    final exercise = _exercises[_currentQuestionIndex];
    return Column(
      key: ValueKey<int>(_currentQuestionIndex),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('DOMANDA ${_currentQuestionIndex + 1} / ${_exercises.length}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(exercise.masked_question, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        ...exercise.options.map((option) {
          return _buildOptionButton(option, exercise.correctAnswer);
        }).toList(),
        const SizedBox(height: 24),
        if (_answerChecked)
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Theme.of(context).cardColor.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
              child: Text('Frase corretta: "${exercise.original_question}"', style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
            ),
          ),
        ElevatedButton(
          onPressed: _selectedOption == null ? null : (_answerChecked ? _nextQuestion : _checkAnswer),
          child: Text(_answerChecked ? (_currentQuestionIndex == _exercises.length - 1 ? 'VEDI RISULTATI' : 'PROSSIMA') : 'CONFERMA'),
        ),
      ],
    );
  }

  // --- LOGICA PULSANTI RIPRISTINATA ALLA VERSIONE SEMPLICE ---
  Widget _buildOptionButton(String option, String correctAnswer) {
    bool isSelected = _selectedOption == option;
    Color color = Theme.of(context).cardColor;
    Color borderColor = Colors.white54;

    if (_answerChecked) {
      if (option == correctAnswer) {
        color = Colors.green.withOpacity(0.4);
        borderColor = Colors.green;
      } else if (isSelected) {
        color = Colors.red.withOpacity(0.4);
        borderColor = Colors.red;
      }
    } else if (isSelected) {
      borderColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: OutlinedButton(
        onPressed: _answerChecked ? null : () => setState(() => _selectedOption = option),
        style: OutlinedButton.styleFrom(
          backgroundColor: color,
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          alignment: Alignment.centerLeft,
        ),
        child: Text(option, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }

  Widget _buildResultsWidget() {
    return Column(
      key: const ValueKey<String>('results'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Quiz Completato!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Text('Il tuo punteggio:', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('$_score / ${_exercises.length}', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red), textAlign: TextAlign.center),
        const SizedBox(height: 48),
        ElevatedButton(onPressed: _restartQuiz, child: const Text('RIPROVA IL QUIZ')),
      ],
    );
  }
  
  Widget _buildVideoPlayer() { return FutureBuilder<void>( future: _initializeVideoPlayerFuture, builder: (context, snapshot) { if (snapshot.connectionState == ConnectionState.waiting) { return AspectRatio( aspectRatio: 16 / 9, child: Container( clipBehavior: Clip.antiAlias, decoration: BoxDecoration( color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), ), child: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)), ), ); } if (snapshot.hasError) { return AspectRatio( aspectRatio: 16 / 9, child: Container( clipBehavior: Clip.antiAlias, decoration: BoxDecoration( color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), ), child: Center(child: Text('Errore nel caricamento del video.', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white))), ), ); } return ClipRRect( borderRadius: BorderRadius.circular(12), child: AspectRatio( aspectRatio: _controller!.value.aspectRatio, child: Stack( alignment: Alignment.center, children: <Widget>[ VideoPlayer(_controller!), GestureDetector( onTap: () { setState(() { _controller!.value.isPlaying ? _controller!.pause() : _controller!.play(); }); }, ), AnimatedOpacity( opacity: _controller!.value.isPlaying ? 0.0 : 1.0, duration: const Duration(milliseconds: 300), child: IgnorePointer( child: Container( decoration: BoxDecoration( color: Colors.black.withOpacity(0.5), shape: BoxShape.circle, ), child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 80), ), ), ), ], ), ), ); }, ); }
  Widget _buildWatchNextSection() { if (_isLoadingWatchNext) { return Center( child: CircularProgressIndicator( color: Theme.of(context).colorScheme.primary, ), ); } if (_watchNextTalks == null || _watchNextTalks!.isEmpty) { return Center( child: Text( 'Nessun talk correlato trovato.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color), ), ); } return SizedBox( height: 250, child: ListView.builder( scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 0), itemCount: _watchNextTalks!.length, itemBuilder: (context, index) { final talk = _watchNextTalks![index]; return Padding( padding: EdgeInsets.only( right: (index == _watchNextTalks!.length - 1) ? 0 : 12.0, left: (index == 0) ? 16.0 : 0, ), child: SizedBox( width: 280, child: TalkCard(talk: talk), ), ); }, ), ); }
}