import 'question.dart';

class Subject {
  final int id;
  final String name;
  final String description;
  final List<Question> questions;
  final String? icon;
  final int? timeLimit; // in minutes

  Subject({
    required this.id,
    required this.name,
    required this.description,
    required this.questions,
    this.icon,
    this.timeLimit,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      questions: (json['questions'] as List)
          .map((q) => Question.fromJson(q))
          .toList(),
      icon: json['icon'] as String?,
      timeLimit: json['timeLimit'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
      'icon': icon,
      'timeLimit': timeLimit,
    };
  }
}