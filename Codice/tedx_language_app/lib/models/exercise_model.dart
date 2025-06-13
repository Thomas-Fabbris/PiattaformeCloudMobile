// lib/models/exercise_model.dart

class Exercise {
  final String masked_question;
  final String original_question;
  final List<String> options;
  final String correctAnswer;

  Exercise({
    required this.masked_question,
    required this.original_question,
    required this.options,
    required this.correctAnswer,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      masked_question: json['masked_question'] ?? 'Domanda non disponibile.',
      original_question:
          json['original_question'] ?? 'Frase corretta non disponibile.',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? '',
    );
  }
}
