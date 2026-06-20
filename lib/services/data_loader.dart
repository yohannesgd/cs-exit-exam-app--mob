// lib/services/data_loader.dart
/*import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/exam.dart';
import '../models/subject.dart';
import '../models/question.dart';

class DataLoader {
  // Load exams list
  static Future<List<Exam>> loadExams() async {
    final data = await rootBundle.loadString('assets/data/exams.json');
    final List<dynamic> jsonResult = json.decode(data);
    return jsonResult.map((e) => Exam.fromJson(e)).toList();
  }

  // ✅ New method
  static Future<List<Subject>> loadExamSubjects(String examTitle, String jsonPath) async {
    final data = await rootBundle.loadString(jsonPath);
    final List<dynamic> jsonResult = json.decode(data);

    return jsonResult.map((s) {
      return Subject(
        id: s['id'] ?? 0,
        name: s['name'] ?? 'Unknown',
        jsonPath: jsonPath,
        questions: (s['questions'] as List<dynamic>?)
                ?.map((q) => Question.fromJson(q))
                .toList() ??
            [],
      );
    }).toList();
  }
}*/
