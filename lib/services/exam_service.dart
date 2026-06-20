// lib/services/exam_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExamService {
  static final ExamService _instance = ExamService._internal();
  factory ExamService() => _instance;
  ExamService._internal();

  // List of all available exams (all free - no premium flags)
  final List<Map<String, dynamic>> _availableExams = [
    {
      'id': 'exam_beginner_001',
      'title': 'CS Exit Exam - Beginner Level',
      'description': 'Foundation assessment covering core concepts',
      'level': 'Beginner',
      'timeLimit': 180,
      'totalQuestions': 100,
      'file': 'assets/exams/exam_1_beginner.json',
      'icon': Icons.eco,
      'color': Colors.green,
    },
    {
      'id': 'exam_intermediate_001',
      'title': 'CS Exit Exam - Intermediate Level',
      'description': 'Comprehensive mid-level assessment',
      'level': 'Intermediate',
      'timeLimit': 180,
      'totalQuestions': 100,
      'file': 'assets/exams/exam_2_intermediate.json',
      'icon': Icons.trending_up,
      'color': Colors.orange,
    },
    {
      'id': 'exam_advanced_001',
      'title': 'CS Exit Exam - Advanced Level',
      'description': '100 advanced questions covering all CS domains',
      'level': 'Advanced',
      'timeLimit': 180,
      'totalQuestions': 100,
      'file': 'assets/exams/exam_3_advanced.json',
      'icon': Icons.rocket_launch,
      'color': Colors.red,
    },
  ];

  // Get all exams (all free)
  List<Map<String, dynamic>> getAvailableExams() {
    return _availableExams;
  }

  // Load exam by ID
  Future<Map<String, dynamic>?> loadExam(String examId) async {
    try {
      final exam = _availableExams.firstWhere(
        (e) => e['id'] == examId,
        orElse: () => {},
      );
      
      if (exam.isEmpty) return null;
      
      final String jsonString = await rootBundle.loadString(exam['file']);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // Map your JSON structure to the expected format
      return {
        'id': examId,
        'title': jsonData['subject'] ?? 'CS Exit Exam',
        'description': jsonData['description'] ?? 'Full-length exam',
        'level': exam['level'],
        'timeLimit': jsonData['timeLimit'] ?? 180,
        'totalQuestions': jsonData['totalQuestions'] ?? (jsonData['questions'] as List).length,
        'questions': jsonData['questions'],
      };
    } catch (e) {
      debugPrint('Error loading exam $examId: $e');
      return null;
    }
  }

  // Save exam progress
  Future<void> saveExamProgress(String examId, Map<String, dynamic> progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('exam_progress_$examId', json.encode(progress));
  }

  // Load exam progress
  Future<Map<String, dynamic>?> loadExamProgress(String examId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('exam_progress_$examId');
    if (data != null) {
      return json.decode(data);
    }
    return null;
  }

  // Clear exam progress
  Future<void> clearExamProgress(String examId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('exam_progress_$examId');
  }

  // Generate answer key
  Map<int, String> generateAnswerKey(Map<String, dynamic> exam) {
    final Map<int, String> answerKey = {};
    final questions = exam['questions'] as List;
    
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final answerIndex = q['correctAnswerIndex'] as int;
      answerKey[i + 1] = String.fromCharCode(65 + answerIndex); // A, B, C, D
    }
    
    return answerKey;
  }

  // Calculate score
  Map<String, dynamic> calculateScore(List<int?> userAnswers, List<dynamic> questions) {
    int correct = 0;
    int incorrect = 0;
    int unanswered = 0;
    
    for (int i = 0; i < questions.length; i++) {
      final answer = userAnswers[i];
      if (answer == null) {
        unanswered++;
      } else if (answer == questions[i]['correctAnswerIndex']) {
        correct++;
      } else {
        incorrect++;
      }
    }
    
    final total = questions.length;
    final percentage = total > 0 ? (correct / total * 100).round() : 0;
    
    return {
      'correct': correct,
      'incorrect': incorrect,
      'unanswered': unanswered,
      'total': total,
      'percentage': percentage,
      'passed': percentage >= 60,
    };
  }
}