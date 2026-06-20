// lib/services/previous_exam_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cs_exit_exam_app/models/previous_exam.dart';

class PreviousExamService {
  static final PreviousExamService _instance = PreviousExamService._internal();
  factory PreviousExamService() => _instance;
  PreviousExamService._internal();

  /// Returns the list of known previous exams (sample data defined in the model).
  List<PreviousExam> getPreviousExams() {
    return PreviousExam.getSampleExams();
  }

  /// Attempt to load the full exam data for a given previous-exam id.
  ///
  /// The returned map uses the same shape as `ExamService.loadExam` so that
  /// the existing exam screen and navigation logic can be reused.
  ///
  /// If a corresponding JSON asset cannot be found the map will still be
  /// returned with an empty question list (calling code may choose to handle
  /// that case gracefully).
  Future<Map<String, dynamic>?> loadPreviousExam(String id) async {
    try {
      final exam = getPreviousExams().firstWhere((e) => e.id == id);
      // basic structure populated from the metadata
      final Map<String, dynamic> base = {
        'id': exam.id,
        'title': exam.title,
        'description': '${exam.university} previous year paper',
        'timeLimit': exam.timeLimitMinutes,
        'totalQuestions': exam.questionCount,
        'questions': <dynamic>[],
      };

      // try to load a JSON file that matches the id (if one exists);
      // this allows us to ship real question sets later without changing
      // the consuming code. the file is expected to live under
      // `assets/exams/<id>.json`.
      final String assetPath = 'assets/exams/$id.json';
      try {
        final jsonString = await rootBundle.loadString(assetPath);
        final Map<String, dynamic> jsonData = json.decode(jsonString);
        base['questions'] = jsonData['questions'] ?? [];
        base['totalQuestions'] = (base['questions'] as List).length;
      } catch (e) {
        // not all previous exams have question files yet; this is okay
        debugPrint('PreviousExamService: could not read $assetPath – $e');
      }

      return base;
    } catch (e) {
      debugPrint('PreviousExamService.loadPreviousExam error: $e');
      return null;
    }
  }
}
