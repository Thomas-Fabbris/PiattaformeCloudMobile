// lib/screens/exercise_screen.dart
// Versione completa e aggiornata

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

// Assicurati che questi percorsi siano corretti per il tuo progetto
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
  // Controller e stato per il Video Player
  VideoPlayerController? _controller;
  late Future<void> _initializeVideoPlayerFuture;

  // Stato per la sezione "Watch Next"
  List<Talk>? _watchNextTalks;
  bool _isLoadingWatchNext = true;

  // Stato per gli esercizi del Quiz
  late Future<List<Exercise>> _exercisesFuture;
  List<Exercise> _exercises = [];
  int _currentQuestionIndex = 0;
  String? _selectedOption;
  bool _answerChecked = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    // Inizializza tutto all'avvio dello schermo
    _initializeVideoPlayerFuture = _extractAndInitializeVideoPlayer();
    _fetchWatchNext();
    _exercisesFuture = ApiService().getOrGenerateExercises(widget.talk.id);
  }

  // --- LOGICA DI CONTROLLO DEL QUIZ ---

  void _checkAnswer() {
    if (_selectedOption == null) return;
    setState(() {
      _answerChecked = true;
      if (_selectedOption == _exercises[_currentQuestionIndex].correctAnswer) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_currentQuestionIndex < _exercises.length - 1) {
        _currentQuestionIndex++;
        _selectedOption = null;
        _answerChecked = false;
      } else {
        // L'utente ha finito le domande, l'AnimatedSwitcher mostrerà i risultati
        _currentQuestionIndex++;
      }
    });
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedOption = null;
      _answerChecked = false;
      _score = 0;
      // Ricarica gli esercizi per un nuovo tentativo
      _exercisesFuture = ApiService().getOrGenerateExercises(widget.talk.id);
    });
  }

  // --- LOGICA DI RETE E DI STATO ---

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
      if (playerData['resources']?['h264'] != null &&
          (playerData['resources']['h264'] as List).isNotEmpty) {
        var video480p = (playerData['resources']['h264'] as List)
            .firstWhere((v) => v['name'] == '480p', orElse: () => null);
        videoUrl = video480p?['file'] ?? playerData['resources']['h264'][0]['file'];
      }
      if (videoUrl == null || !videoUrl.endsWith('.mp4')) throw Exception('URL .mp4 non trovato.');
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _controller!.initialize();
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
      if (mounted) {
        setState(() {
          _watchNextTalks = talks;
          _isLoadingWatchNext = false;
        });
      }
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

  // --- METODO BUILD PRINCIPALE ---

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
              child: Text("Potrebbe interessarti anche",
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            _buildWatchNextSection(),
          ],
        ),
      ),
    );
  }

  //############################################################################
  // WIDGET BUILDERS
  //############################################################################

  Widget _buildExerciseSection() {
    return FutureBuilder<List<Exercise>>(
      future: _exercisesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.amber, size: 48),
                const SizedBox(height: 16),
                const Text(
                  "Impossibile caricare gli esercizi.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Riprova"),
                  onPressed: _restartQuiz,
                ),
              ],
            ),
          );
        }

        _exercises = snapshot.data!;
        
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            final slideAnimation = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation);

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slideAnimation, child: child),
            );
          },
          child: _currentQuestionIndex >= _exercises.length
              ? _buildResultsWidget()
              : _buildQuestionWidget(),
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
        Text(
          'DOMANDA ${_currentQuestionIndex + 1} DI ${_exercises.length}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white70,
                letterSpacing: 1.5,
              ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _exercises.length,
            minHeight: 8,
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade400),
          ),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            exercise.masked_question.replaceAll('[MASK]', '______'),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w500, height: 1.4),
          ),
        ),
        const SizedBox(height: 24),

        ...exercise.options.map((option) {
          return _buildOptionButton(option, exercise.correctAnswer);
        }).toList(),
        const SizedBox(height: 24),
        
        // ULTIMA MODIFICA: EVIDENZIA LA RISPOSTA CORRETTA
        if (_answerChecked)
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.green.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Builder(builder: (context) {
                final originalQuestion = exercise.original_question;
                final correctAnswer = exercise.correctAnswer;
                final startIndex = originalQuestion.indexOf(correctAnswer);

                final highlightStyle = const TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.normal,
                );

                if (startIndex == -1) {
                  return Text(
                    'Frase completa: "${exercise.original_question}"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, height: 1.5),
                  );
                }

                final part1 = originalQuestion.substring(0, startIndex);
                final highlightedPart = correctAnswer;
                final part2 = originalQuestion.substring(startIndex + correctAnswer.length);

                return RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, height: 1.5, fontSize: 15),
                    children: [
                      const TextSpan(text: 'Frase completa: "'),
                      TextSpan(text: part1),
                      TextSpan(text: highlightedPart, style: highlightStyle),
                      TextSpan(text: part2),
                      const TextSpan(text: '"'),
                    ],
                  ),
                );
              }),
            ),
          ),
          
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: _selectedOption == null
              ? null
              : (_answerChecked ? _nextQuestion : _checkAnswer),
          child: Text(
            _answerChecked
                ? (_currentQuestionIndex == _exercises.length - 1
                    ? 'VEDI RISULTATI'
                    : 'PROSSIMA DOMANDA')
                : 'CONFERMA RISPOSTA',
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton(String option, String correctAnswer) {
    final isSelected = _selectedOption == option;
    Color backgroundColor = Theme.of(context).cardColor;
    Color borderColor = Colors.white24;
    Widget? icon;

    if (_answerChecked) {
      if (option == correctAnswer) {
        backgroundColor = Colors.green.withOpacity(0.3);
        borderColor = Colors.green;
        icon = const Icon(Icons.check_circle, color: Colors.green);
      } else if (isSelected) {
        backgroundColor = Colors.red.withOpacity(0.3);
        borderColor = Colors.red;
        icon = const Icon(Icons.cancel, color: Colors.red);
      }
    } else if (isSelected) {
      backgroundColor = Colors.red.withOpacity(0.2);
      borderColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: OutlinedButton(
        onPressed: _answerChecked ? null : () => setState(() => _selectedOption = option),
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          alignment: Alignment.centerLeft,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            if (icon != null) const SizedBox(width: 12),
            if (icon != null) icon,
          ],
        ),
      ),
    );
  }

  Widget _buildResultsWidget() {
    final double scoreRatio = _exercises.isEmpty ? 0 : _score / _exercises.length;
    String message;
    IconData resultIcon;
    Color iconColor;

    if (scoreRatio == 1.0) {
      message = "Perfetto! Conosci questo talk alla grande!";
      resultIcon = Icons.military_tech;
      iconColor = Colors.amber;
    } else if (scoreRatio >= 0.7) {
      message = "Ottimo lavoro! Sei sulla strada giusta.";
      resultIcon = Icons.star;
      iconColor = Colors.lightGreenAccent;
    } else {
      message = "Continua a provare! La prossima volta andrà meglio.";
      resultIcon = Icons.school;
      iconColor = Colors.white70;
    }

    return Container(
      key: const ValueKey<String>('results'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(resultIcon, color: iconColor, size: 80),
          const SizedBox(height: 16),
          Text(
            'Quiz Completato!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 32),
          Text(
            'Il tuo punteggio',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            '$_score / ${_exercises.length}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('RIPROVA IL QUIZ'),
            onPressed: _restartQuiz,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return FutureBuilder<void>(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
            ),
          );
        }
        if (snapshot.hasError) {
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text('Errore nel caricamento del video.', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white))),
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
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 80),
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

  Widget _buildWatchNextSection() {
    if (_isLoadingWatchNext) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    if (_watchNextTalks == null || _watchNextTalks!.isEmpty) {
      return Center(
        child: Text(
          'Nessun talk correlato trovato.',
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
      );
    }
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _watchNextTalks!.length,
        itemBuilder: (context, index) {
          final talk = _watchNextTalks![index];
          return Padding(
            padding: EdgeInsets.only(right: (index == _watchNextTalks!.length - 1) ? 0 : 12.0),
            child: SizedBox(
              width: 280,
              child: TalkCard(talk: talk),
            ),
          );
        },
      ),
    );
  }
}