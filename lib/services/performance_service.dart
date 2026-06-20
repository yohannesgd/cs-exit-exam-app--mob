// lib/services/performance_service.dart
import 'package:flutter/material.dart';

import '../services/database_helper.dart';
import '../models/performance_model.dart';
import '../utils/json_loader.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  // Get overall performance statistics
  Future<OverallPerformance> getOverallPerformance() async {
    try {
      final results = await DatabaseHelper.getAllResults();
      
      if (results.isEmpty) {
        return OverallPerformance(
          totalExams: 0,
          totalQuestions: 0,
          totalCorrect: 0,
          totalIncorrect: 0,
          overallAverage: 0,
          highestScore: 0,
          lowestScore: 0,
          totalTimeSpent: 0,
          subjectPerformances: [],
          strengthAreas: {},
          improvementAreas: {},
        );
      }

      // Calculate overall metrics
      int totalQuestions = 0;
      int totalCorrect = 0;
      int totalIncorrect = 0;
      double totalScore = 0;
      double highestScore = 0;
      double lowestScore = 100;
      int totalTimeSpent = 0;
      
      final Map<int, List<Map<String, dynamic>>> subjectResults = {};

      for (final result in results) {
        final score = result['score'] as double;
        final subjectId = result['subject_id'] as int;
        
        totalScore += score;
        totalQuestions += result['total_questions'] as int;
        totalCorrect += result['correct_count'] as int;
        totalIncorrect += result['incorrect_count'] as int;
        totalTimeSpent += result['time_spent'] as int;
        
        if (score > highestScore) highestScore = score;
        if (score < lowestScore) lowestScore = score;
        
        if (!subjectResults.containsKey(subjectId)) {
          subjectResults[subjectId] = [];
        }
        subjectResults[subjectId]!.add(result);
      }

      // Calculate subject performances
      final subjectPerformances = await _calculateSubjectPerformances(subjectResults);
      
      // Identify strengths and weaknesses
      final strengthAreas = _identifyStrengths(subjectPerformances);
      final improvementAreas = _identifyWeaknesses(subjectPerformances);

      return OverallPerformance(
        totalExams: results.length,
        totalQuestions: totalQuestions,
        totalCorrect: totalCorrect,
        totalIncorrect: totalIncorrect,
        overallAverage: totalScore / results.length,
        highestScore: highestScore,
        lowestScore: lowestScore,
        totalTimeSpent: totalTimeSpent,
        subjectPerformances: subjectPerformances,
        strengthAreas: strengthAreas,
        improvementAreas: improvementAreas,
      );
    } catch (e) {
      debugPrint('❌ Error getting overall performance: $e');
      rethrow;
    }
  }

  // Calculate performance for each subject
  Future<List<SubjectPerformance>> _calculateSubjectPerformances(
    Map<int, List<Map<String, dynamic>>> subjectResults
  ) async {
    final List<SubjectPerformance> performances = [];
    
    try {
      final subjects = await JsonLoader.loadSubjects();
      
      for (final subject in subjects) {
        final results = subjectResults[subject.id] ?? [];
        
        if (results.isEmpty) {
          performances.add(SubjectPerformance(
            subjectId: subject.id,
            subjectName: subject.name,
            attempts: 0,
            averageScore: 0,
            bestScore: 0,
            worstScore: 0,
            totalQuestions: 0,
            totalCorrect: 0,
            totalTimeSpent: 0,
            scoreHistory: [],
            attemptDates: [],
          ));
          continue;
        }

        double totalScore = 0;
        double bestScore = 0;
        double worstScore = 100;
        int totalQuestions = 0;
        int totalCorrect = 0;
        int totalTimeSpent = 0;
        final List<double> scoreHistory = [];
        final List<DateTime> attemptDates = [];

        for (final result in results) {
          final score = result['score'] as double;
          totalScore += score;
          scoreHistory.add(score);
          
          final date = DateTime.parse(result['completed_at']);
          attemptDates.add(date);
          
          if (score > bestScore) bestScore = score;
          if (score < worstScore) worstScore = score;
          
          totalQuestions += result['total_questions'] as int;
          totalCorrect += result['correct_count'] as int;
          totalTimeSpent += result['time_spent'] as int;
        }

        performances.add(SubjectPerformance(
          subjectId: subject.id,
          subjectName: subject.name,
          attempts: results.length,
          averageScore: totalScore / results.length,
          bestScore: bestScore,
          worstScore: worstScore,
          totalQuestions: totalQuestions,
          totalCorrect: totalCorrect,
          totalTimeSpent: totalTimeSpent,
          scoreHistory: scoreHistory,
          attemptDates: attemptDates,
        ));
      }
    } catch (e) {
      debugPrint('❌ Error calculating subject performances: $e');
    }
    
    return performances;
  }

  // Identify strengths (subjects with average > 70%)
  Map<String, double> _identifyStrengths(List<SubjectPerformance> performances) {
    final strengths = <String, double>{};
    for (final perf in performances) {
      if (perf.attempts > 0 && perf.averageScore >= 70) {
        strengths[perf.subjectName] = perf.averageScore;
      }
    }
    // ✅ FIXED: Use toList() first, then sort, then take
    final sortedList = strengths.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
    return Map.fromEntries(sortedList.take(3));
  }

  // Identify weaknesses (subjects with average < 60% or never attempted)
  Map<String, double> _identifyWeaknesses(List<SubjectPerformance> performances) {
    final weaknesses = <String, double>{};
    for (final perf in performances) {
      if (perf.attempts == 0) {
        weaknesses[perf.subjectName] = 0;
      } else if (perf.averageScore < 60) {
        weaknesses[perf.subjectName] = perf.averageScore;
      }
    }
    // ✅ FIXED: Use toList() first, then sort, then take
    final sortedList = weaknesses.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  
    return Map.fromEntries(sortedList.take(3));
  }
  // Get weekly progress for the last 6 weeks
  Future<List<WeeklyProgress>> getWeeklyProgress() async {
    try {
      final results = await DatabaseHelper.getAllResults();
      final now = DateTime.now();
      final weeklyData = <WeeklyProgress>[];
      
      for (int i = 5; i >= 0; i--) {
        final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1) - (i * 7));
        final weekEnd = DateTime(weekStart.year, weekStart.month, weekStart.day + 7);
        
        final weekResults = results.where((r) {
          final date = DateTime.parse(r['completed_at']);
          return date.isAfter(weekStart) && date.isBefore(weekEnd);
        }).toList();
        
        final dailyScores = List<double>.filled(7, 0);
        final dailyCounts = List<int>.filled(7, 0);
        
        for (final result in weekResults) {
          final date = DateTime.parse(result['completed_at']);
          final dayIndex = date.weekday - 1; // 0 = Monday
          final score = result['score'] as double;
          
          dailyScores[dayIndex] += score;
          dailyCounts[dayIndex]++;
        }
        
        // Calculate average per day
        for (int j = 0; j < 7; j++) {
          if (dailyCounts[j] > 0) {
            dailyScores[j] = dailyScores[j] / dailyCounts[j];
          }
        }
        
        final avgScore = weekResults.isEmpty 
            ? 0.0 
            : weekResults.fold(0.0, (sum, r) => sum + (r['score'] as double)) / weekResults.length;
        
        final totalTime = weekResults.fold(0, (sum, r) => sum + (r['time_spent'] as int));
        
        weeklyData.add(WeeklyProgress(
          weekStart: weekStart,
          examsTaken: weekResults.length,
          averageScore: avgScore,
          totalTime: totalTime,
          dailyScores: dailyScores,
        ));
      }
      
      return weeklyData;
    } catch (e) {
      debugPrint('❌ Error getting weekly progress: $e');
      return [];
    }
  }

  // Get improvement trend
  Future<Map<String, double>> getImprovementTrend(int subjectId) async {
    try {
      final results = await DatabaseHelper.getResultsBySubject(subjectId);
      if (results.length < 2) return {'trend': 0};
      
      final firstScore = results.last['score'] as double;
      final lastScore = results.first['score'] as double;
      final improvement = lastScore - firstScore;
      
      return {
        'first': firstScore,
        'last': lastScore,
        'trend': improvement,
        'percentage': results.length > 1 
            ? ((lastScore - firstScore) / firstScore * 100) 
            : 0
      };
    } catch (e) {
      debugPrint('❌ Error getting improvement trend: $e');
      return {'trend': 0};
    }
  }
}