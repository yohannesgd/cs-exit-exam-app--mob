import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DatabaseHelper {
  static const String _resultsBoxName = 'results_box';
  static const String _progressBoxName = 'progress_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_resultsBoxName);
    await Hive.openBox(_progressBoxName);
    debugPrint('✅ Hive Initialized for ${kIsWeb ? "Web" : "Native"}');
  }

  // --- RESULTS METHODS ---

  static Future<int> insertResult(Map<String, dynamic> result) async {
    final box = Hive.box(_resultsBoxName);
    // Add a unique ID and timestamp if not present
    final id = await box.add(result); 
    return id;
  }

  static Future<List<Map<String, dynamic>>> getAllResults() async {
    final box = Hive.box(_resultsBoxName);
    // Hive returns data as Map<dynamic, dynamic>, we cast it to String/dynamic
    final results = box.values.map((item) => Map<String, dynamic>.from(item)).toList();
    // Sort by date (descending) to mimic your SQL query
    results.sort((a, b) => b['completed_at'].compareTo(a['completed_at']));
    return results;
  }

  static Future<List<Map<String, dynamic>>> getResultsBySubject(int subjectId) async {
    final box = Hive.box(_resultsBoxName);
    final results = box.values.map((item) => Map<String, dynamic>.from(item)).toList();
    // Filter by subject_id
    final filteredResults = results.where((result) => result['subject_id'] == subjectId).toList();
    // Sort by date (descending)
    filteredResults.sort((a, b) => b['completed_at'].compareTo(a['completed_at']));
    return filteredResults;
  }

  static Future<void> clearAllResults() async {
    await Hive.box(_resultsBoxName).clear();
    await Hive.box(_progressBoxName).clear();
  }

  // --- PROGRESS METHODS ---

  static Future<Map<String, dynamic>?> getUserProgress(int subjectId) async {
    final box = Hive.box(_progressBoxName);
    final data = box.get(subjectId); // Use subjectId as the Key
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  static Future<void> updateUserProgress(Map<String, dynamic> progress) async {
    final box = Hive.box(_progressBoxName);
    final subjectId = progress['subject_id'];
    await box.put(subjectId, progress); // put() automatically handles insert or update
  }

  // --- STUBS FOR COMPATIBILITY ---
  // These keep your existing code from breaking
  static Future<void> debugDatabase() async {
    debugPrint('Results Count: ${Hive.box(_resultsBoxName).length}');
  }
}