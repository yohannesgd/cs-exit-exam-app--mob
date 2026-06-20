// lib/services/question_bank_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
//import '../models/question.dart';

class QuestionBankService {
  static final QuestionBankService _instance = QuestionBankService._internal();
  factory QuestionBankService() => _instance;
  QuestionBankService._internal();

  static const String _usageKey = 'question_usage';

  // Track when a question is used
  Future<void> trackQuestionUsage(int questionId, String subject) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_usageKey);
    Map<String, dynamic> usage = {};
    
    if (data != null) {
      usage = json.decode(data);
    }
    
    final String key = '${subject}_$questionId';
    final now = DateTime.now().toIso8601String();
    
    if (usage.containsKey(key)) {
      usage[key]['count'] = (usage[key]['count'] as int) + 1;
      usage[key]['lastUsed'] = now;
    } else {
      usage[key] = {
        'count': 1,
        'lastUsed': now,
      };
    }
    
    await prefs.setString(_usageKey, json.encode(usage));
  }

  // Get least used questions
  Future<List<int>> getLeastUsedQuestions(String subject, int limit) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_usageKey);
    
    if (data == null) return [];
    
    final Map<String, dynamic> usage = json.decode(data);
    final List<MapEntry<String, dynamic>> filtered = [];
    
    for (var entry in usage.entries) {
      if (entry.key.startsWith('${subject}_')) {
        filtered.add(entry);
      }
    }
    
    // Sort by usage count (ascending)
    filtered.sort((a, b) => 
      (a.value['count'] as int).compareTo(b.value['count'] as int)
    );
    
    return filtered.take(limit).map((e) {
      return int.parse(e.key.split('_').last);
    }).toList();
  }

  // Reset usage statistics
  Future<void> resetUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usageKey);
  }
}