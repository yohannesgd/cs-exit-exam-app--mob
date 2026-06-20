import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/subject.dart';
import '../models/question.dart';

class JsonLoader {
  /// Loads all subjects from a JSON file in assets.
  /// Each subject must include its questions list.
  static Future<List<Subject>> loadSubjects(String jsonPath) async {
  try {
    final jsonString = await rootBundle.loadString(jsonPath);
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    
    final List<dynamic> subjectsJson = jsonData['subjects'] ?? [];
    final List<Subject> subjects = [];
    
    for (final subjectJson in subjectsJson) {
      List<Question> questions = [];
      
      // Check if questions are inline or in separate file
      if (subjectJson['questions'] != null) {
        // Questions are inline
        final List<dynamic> questionList = subjectJson['questions'] ?? [];
        questions = questionList.map((q) => Question.fromJson(q)).toList();
      } else if (subjectJson['questionsFile'] != null) {
        // Load questions from separate file
        final questionsFile = subjectJson['questionsFile'] as String;
        questions = await loadQuestionsFromFile('assets/questions/$questionsFile');
      }
      
      subjects.add(Subject(
        id: subjectJson['id'] ?? 0,
        name: subjectJson['name'] ?? 'Unknown',
        description: subjectJson['description'] ?? '',
        questions: questions,
        icon: subjectJson['icon'] as String?,
        timeLimit: subjectJson['timeLimit'] as int?,
      ));
    }
    
    return subjects;
  } catch (e) {
    debugPrint("❌ Error loading subjects from $jsonPath: $e");
    rethrow;
  }
}

static Future<List<Question>> loadQuestionsFromFile(String filePath) async {
  try {
    final jsonString = await rootBundle.loadString(filePath);
    final jsonData = json.decode(jsonString);
    
    final List<dynamic> questionsJson = jsonData['questions'] ?? [];
    return questionsJson.map((q) => Question.fromJson(q)).toList();
  } catch (e) {
    debugPrint("❌ Error loading questions from $filePath: $e");
    return [];
  }
}
}