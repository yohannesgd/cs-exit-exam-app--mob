import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/subject.dart';
import '../models/question.dart';

class JsonLoader {
  /// Main method to load all subjects with their questions
  static Future<List<Subject>> loadSubjects() async {
    try {
      // Load SINGLE configuration file
      final jsonString = await rootBundle.loadString('assets/config/exam_config.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final List<dynamic> subjectsJson = jsonData['subjects'] ?? [];
      final List<Subject> subjects = [];
      
      for (final subjectJson in subjectsJson) {
        try {
          // Extract file path from the 'file' field
          final String filePath = subjectJson['file'] ?? '';
          
          if (filePath.isEmpty) {
            debugPrint('⚠️ No file path specified for subject: ${subjectJson['name']}');
            continue;
          }
          
          // Extract filename from full path or use as is
          final String fileName = filePath.contains('/') 
              ? filePath.split('/').last 
              : filePath;
          
          // Load questions from the referenced file
          final questions = await _loadQuestionsFromFile(fileName);
          
          // Handle missing fields with null safety
          subjects.add(Subject(
            id: subjectJson['id'] ?? 0,
            name: subjectJson['name'] ?? 'Unknown Subject',
            description: subjectJson['description'] ?? '',
            questions: questions,
            icon: subjectJson['icon'] as String?,
            timeLimit: subjectJson['timeLimit'] as int?,
          ));
          
          debugPrint('✅ Loaded subject: ${subjectJson['name']} (${questions.length} questions)');
        } catch (e) {
          debugPrint('❌ Failed to load subject ${subjectJson['name']}: $e');
          // Continue loading other subjects even if one fails
          continue;
        }
      }
      
      return subjects;
    } catch (e) {
      debugPrint("❌ Error loading subjects from config: $e");
      rethrow;
    }
  }

  /// Load questions from a separate JSON file
  static Future<List<Question>> _loadQuestionsFromFile(String fileName) async {
    try {
      // Ensure fileName has .json extension
      final String fullFileName = fileName.endsWith('.json') 
          ? fileName 
          : '$fileName.json';
      
      final String filePath = 'assets/questions/$fullFileName';
      final jsonString = await rootBundle.loadString(filePath);
      final dynamic jsonData = json.decode(jsonString); // Changed to dynamic
      
      // Handle different JSON structures
      List<dynamic> questionsJson = [];
      
      // ✅ FIXED: Check if jsonData is Map first, then extract questions
      if (jsonData is Map<String, dynamic>) {
        if (jsonData.containsKey('questions')) {
          questionsJson = jsonData['questions'] ?? [];
        } else if (jsonData.containsKey('subject') && jsonData.containsKey('questions')) {
          questionsJson = jsonData['questions'] ?? [];
        }
      } 
      // ✅ FIXED: Check if jsonData is List (direct array of questions)
      else if (jsonData is List) {
        questionsJson = jsonData;
      }
      
      if (questionsJson.isEmpty) {
        debugPrint('⚠️ No questions found in $fullFileName');
        return [];
      }
      
      return questionsJson.map((q) {
        try {
          return Question.fromJson(q);
        } catch (e) {
          debugPrint('❌ Error parsing question in $fullFileName: $e');
          return null;
        }
      }).whereType<Question>().toList();
      
    } catch (e) {
      debugPrint("❌ Error loading questions from $fileName: $e");
      return [];
    }
  }

  /// Load a single subject by ID
  static Future<Subject?> loadSubjectById(int subjectId) async {
    try {
      final subjects = await loadSubjects();
      return subjects.firstWhere(
        (subject) => subject.id == subjectId,
        orElse: () => throw Exception("Subject with ID $subjectId not found"),
      );
    } catch (e) {
      debugPrint("❌ Error loading subject $subjectId: $e");
      return null;
    }
  }

  /// Load a single subject by name
  static Future<Subject?> loadSubjectByName(String subjectName) async {
    try {
      final subjects = await loadSubjects();
      return subjects.firstWhere(
        (subject) => subject.name.toLowerCase() == subjectName.toLowerCase(),
        orElse: () => throw Exception("Subject '$subjectName' not found"),
      );
    } catch (e) {
      debugPrint("❌ Error loading subject $subjectName: $e");
      return null;
    }
  }

  /// Load a single question file directly (for debugging/testing)
  static Future<List<Question>> loadQuestionsFile(String fileName) async {
    return await _loadQuestionsFromFile(fileName);
  }

  /// Get all available subjects
  static Future<List<String>> getAvailableSubjects() async {
    try {
      final subjects = await loadSubjects();
      return subjects.map((s) => s.name).toList();
    } catch (e) {
      debugPrint('❌ Error getting available subjects: $e');
      return [];
    }
  }

  /// Get exam configuration metadata
  static Future<Map<String, dynamic>> getExamConfig() async {
    try {
      final jsonString = await rootBundle.loadString('assets/config/exam_config.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      return jsonData['exam'] ?? {};
    } catch (e) {
      debugPrint('❌ Error loading exam config: $e');
      return {};
    }
  }

  /// Reload a specific subject (useful for refresh)
  static Future<Subject?> reloadSubject(int subjectId) async {
    try {
      final subjects = await loadSubjects();
      return subjects.firstWhere(
        (subject) => subject.id == subjectId,
        orElse: () => throw Exception("Subject $subjectId not found"),
      );
    } catch (e) {
      debugPrint('❌ Error reloading subject $subjectId: $e');
      return null;
    }
  }
}