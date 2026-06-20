// utils/subject_loader.dart
import 'package:flutter/material.dart';
import 'json_loader.dart';
import '../models/subject.dart';

class SubjectLoader {
  /// Load all university subjects
  static Future<List<Subject>> loadAllSubjects() async {
    try {
      return await JsonLoader.loadSubjects();
    } catch (e) {
      debugPrint('Error loading subjects: $e');
      return [];
    }
  }

  /// Load a specific subject by ID
  static Future<Subject?> loadSubjectById(int subjectId) async {
    try {
      final subjects = await loadAllSubjects();
      return subjects.firstWhere(
        (subject) => subject.id == subjectId,
        orElse: () => throw Exception('Subject $subjectId not found'),
      );
    } catch (e) {
      debugPrint('Error loading subject $subjectId: $e');
      return null;
    }
  }

  /// Load subjects for a specific exam
  static Future<List<Subject>> loadSubjectsForExam(String examPath) async {
    try {
      // For now, we only have university.json
      // If you have multiple exam files, modify this
      if (examPath.contains('university')) {
        return await JsonLoader.loadSubjects();
      }
      return [];
    } catch (e) {
      debugPrint('Error loading subjects for exam $examPath: $e');
      return [];
    }
  }
}