class Question {
  final int id;
  final String text;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;
  final String? topic;
  final int? difficulty; // 1-5 scale

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
    this.topic = "General",
    this.difficulty,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int,
      text: json['text'] as String,
      options: List<String>.from(json['options']),
      correctAnswerIndex: json['correctAnswerIndex'] as int,
      explanation: json['explanation'] as String?,
      topic: json['topic'] as String?,
      difficulty: json['difficulty'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
      'topic': topic,
      'difficulty': difficulty,
    };
  }
}