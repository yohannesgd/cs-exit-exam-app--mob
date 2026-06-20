import 'package:cs_exit_exam_app/models/subject.dart';

class Exam {
  final int id;
  final String title;
  final String description;
  final String jsonPath;
  final List<Subject> subjects;

  Exam({
    required this.id,
    required this.title,
    required this.description,
    required this.jsonPath,
    required this.subjects,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      jsonPath: json['jsonPath'] ?? '',
      subjects: (json['subjects'] as List<dynamic>?)
              ?.map((s) => Subject(
                    id: s['id'] ?? 0,
                    name: s['name'] ?? '',
                    description: s['description'] ?? '',
                    questions: [], // Questions loaded separately
                  ))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'jsonPath': jsonPath,
        'subjects': subjects.map((s) => {
              'id': s.id,
              'name': s.name,
              'description': s.description,
            }).toList(),
      };
}