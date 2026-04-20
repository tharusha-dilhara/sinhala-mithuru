class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    // Backend sends `correct_answer` as a 0-based index.
    // e.g., correct_answer: 1  →  options[1] is the correct answer.
    final int correctAnswerIndex =
        (json['correct_answer'] ?? json['correct_answer_index'] ?? 0) as int;

    return QuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswerIndex: correctAnswerIndex,
    );
  }
}

