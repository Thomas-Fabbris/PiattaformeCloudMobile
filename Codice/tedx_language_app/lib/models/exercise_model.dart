// lib/models/exercise_model.dart

class Exercise {
  final String question;
  final List<String> options;
  final String correctAnswer;

  Exercise({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      question: json['question_text'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correct_answer'] ?? '',
    );
  }
}