// services/achievement_service.dart - FIXED

import 'dart:convert';
import 'package:cs_exit_exam_app/services/database_helper.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement_model.dart';
import '../models/performance_model.dart';

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  // Remove unused _badgesKey or comment it out
  // static const String _badgesKey = 'achievement_badges'; // ❌ Not used
  static const String _userAchievementsKey = 'user_achievements';
  
  List<AchievementBadge> _allBadges = [];
  Map<String, UserAchievement> _userAchievements = {};

  // Load all badge definitions
  Future<List<AchievementBadge>> loadBadgeDefinitions() async {
    try {
      final String response = await rootBundle.loadString('assets/config/badges.json');
      final List<dynamic> data = json.decode(response);
      
      _allBadges = data.map((json) => AchievementBadge.fromJson(json)).toList();
      return _allBadges;
    } catch (e) {
      debugPrint('❌ Error loading badge definitions: $e');
      // Return default badges if file not found
      _allBadges = _getDefaultBadges();
      return _allBadges;
    }
  }

  // Get all badges with user progress
  Future<List<AchievementBadge>> getAllBadgesWithProgress() async {
    if (_allBadges.isEmpty) {
      await loadBadgeDefinitions();
    }
    
    await _loadUserAchievements();
    
    return _allBadges.map((badge) {
      final userAchievement = _userAchievements[badge.id];
      if (userAchievement != null) {
        return AchievementBadge(
          id: badge.id,
          name: badge.name,
          description: badge.description,
          category: badge.category,
          rarity: badge.rarity,
          icon: badge.icon,
          threshold: badge.threshold,
          metric: badge.metric,
          isSecret: badge.isSecret,
          unlockedAt: userAchievement.unlockedAt,
          maxProgress: badge.maxProgress,
          currentProgress: userAchievement.progress.toInt(),
        );
      }
      return badge;
    }).toList();
  }

  // Get only unlocked badges
  Future<List<AchievementBadge>> getUnlockedBadges() async {
    await _loadUserAchievements();
    
    return _allBadges.where((badge) {
      return _userAchievements.containsKey(badge.id);
    }).map((badge) {
      final userAchievement = _userAchievements[badge.id]!;
      return AchievementBadge(
        id: badge.id,
        name: badge.name,
        description: badge.description,
        category: badge.category,
        rarity: badge.rarity,
        icon: badge.icon,
        threshold: badge.threshold,
        metric: badge.metric,
        isSecret: badge.isSecret,
        unlockedAt: userAchievement.unlockedAt,
        maxProgress: badge.maxProgress,
        currentProgress: userAchievement.progress.toInt(),
      );
    }).toList();
  }

  // Get achievement statistics
  Future<AchievementStats> getAchievementStats() async {
    await _loadUserAchievements();
    
    if (_allBadges.isEmpty) {
      await loadBadgeDefinitions();
    }
    
    final unlocked = _userAchievements.length;
    final badgesByRarity = _getBadgesByRarity();
    
    DateTime? lastUnlock;
    if (_userAchievements.isNotEmpty) {
      lastUnlock = _userAchievements.values
          .map((a) => a.unlockedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }
    
    return AchievementStats(
      totalBadges: _allBadges.length,
      unlockedBadges: unlocked,
      bronzeBadges: badgesByRarity[BadgeRarity.bronze] ?? 0,
      silverBadges: badgesByRarity[BadgeRarity.silver] ?? 0,
      goldBadges: badgesByRarity[BadgeRarity.gold] ?? 0,
      platinumBadges: badgesByRarity[BadgeRarity.platinum] ?? 0,
      diamondBadges: badgesByRarity[BadgeRarity.diamond] ?? 0,
      lastUnlock: lastUnlock,
    );
  }

  // Check and update achievements based on exam results
  Future<List<AchievementBadge>> checkAchievements(
    Map<String, dynamic> examResult,
    OverallPerformance performance
  ) async {
    await _loadUserAchievements();
    final newlyUnlocked = <AchievementBadge>[];
    
    for (final badge in _allBadges) {
      if (_userAchievements.containsKey(badge.id)) continue;
      
      bool unlocked = false;
      int progress = 0;
      
      switch (badge.id) {
        // Excellence Badges
        case 'perfect_score':
          unlocked = examResult['score'] == 100;
          progress = examResult['score'] == 100 ? 1 : 0;
          break;
        case 'first_perfect':
          unlocked = examResult['score'] == 100 && 
                    performance.totalExams == 1;
          progress = examResult['score'] == 100 ? 1 : 0;
          break;
        case 'excellent_80':
          final score = examResult['score'] as double;
          unlocked = score >= 80;
          progress = score >= 80 ? 1 : 0;
          break;
        case 'excellent_90':
          final score = examResult['score'] as double;
          unlocked = score >= 90;
          progress = score >= 90 ? 1 : 0;
          break;
          
        // Consistency Badges
        case 'three_in_row':
          final subjectId = examResult['subject_id'] as int;
          final results = await DatabaseHelper.getResultsBySubject(subjectId);
          if (results.length >= 3) {
            bool allAbove70 = true;
            for (int i = 0; i < 3; i++) {
              if ((results[i]['score'] as double) < 70) {
                allAbove70 = false;
                break;
              }
            }
            unlocked = allAbove70;
            progress = allAbove70 ? 3 : results.length;
          }
          break;
        case 'weekly_warrior':
          final weeklyProgress = await getWeeklyExamCount();
          unlocked = weeklyProgress >= 5;
          progress = weeklyProgress;
          break;
        case 'monthly_dedication':
          final monthlyProgress = await getMonthlyExamCount();
          unlocked = monthlyProgress >= 15;
          progress = monthlyProgress;
          break;
          
        // Speed Badges - FIXED calendar_week
        case 'speed_demon':
          final timeSpent = examResult['time_spent'] as int;
          final totalQuestions = examResult['total_questions'] as int;
          final secondsPerQuestion = timeSpent / totalQuestions;
          unlocked = secondsPerQuestion < 30 && (examResult['score'] as double) >= 70;
          progress = secondsPerQuestion < 30 ? 1 : 0;
          break;
        case 'lightning_fast':
          final timeSpent = examResult['time_spent'] as int;
          final totalQuestions = examResult['total_questions'] as int;
          final secondsPerQuestion = timeSpent / totalQuestions;
          unlocked = secondsPerQuestion < 20 && (examResult['score'] as double) >= 80;
          progress = secondsPerQuestion < 20 ? 1 : 0;
          break;
          
        // Mastery Badges
        case 'subject_master':
          final subjectId = examResult['subject_id'] as int;
          final results = await DatabaseHelper.getResultsBySubject(subjectId);
          if (results.length >= 5) {
            double avgScore = results.fold(0.0, (sum, r) => 
                sum + (r['score'] as double)) / results.length;
            unlocked = avgScore >= 85;
            progress = results.length;
          }
          break;
        case 'all_rounder':
          final subjects = await DatabaseHelper.getAllResults();
          final uniqueSubjects = subjects.map((r) => r['subject_id']).toSet().length;
          unlocked = uniqueSubjects >= 6;
          progress = uniqueSubjects;
          break;
          
        // Dedication Badges
        case 'first_step':
          unlocked = performance.totalExams >= 1;
          progress = performance.totalExams;
          break;
        case 'dedicated_learner':
          unlocked = performance.totalExams >= 10;
          progress = performance.totalExams;
          break;
        case 'exam_master':
          unlocked = performance.totalExams >= 25;
          progress = performance.totalExams;
          break;
        case 'quiz_legend':
          unlocked = performance.totalExams >= 50;
          progress = performance.totalExams;
          break;
          
        // Milestone Badges
        case 'time_investor':
          final totalTime = performance.totalTimeSpent;
          unlocked = totalTime >= 3600; // 1 hour
          progress = totalTime ~/ 60; // minutes
          break;
        case 'time_master':
          final totalTime = performance.totalTimeSpent;
          unlocked = totalTime >= 7200; // 2 hours
          progress = totalTime ~/ 60;
          break;
        case 'perfect_accuracy':
          final totalCorrect = performance.totalCorrect;
          final totalQuestions = performance.totalQuestions;
          final accuracy = totalQuestions > 0 
              ? (totalCorrect / totalQuestions * 100) 
              : 0.0;
          unlocked = accuracy >= 95 && totalQuestions >= 50;
          progress = accuracy.toInt();
          break;
      }
      
      if (unlocked) {
        final userAchievement = UserAchievement(
          badgeId: badge.id,
          unlockedAt: DateTime.now(),
          progress: progress.toDouble(),
          metadata: {
            'score': examResult['score'],
            'subject': examResult['subject_name'],
          },
        );
        
        _userAchievements[badge.id] = userAchievement;
        await _saveUserAchievements();
        
        final unlockedBadge = AchievementBadge(
          id: badge.id,
          name: badge.name,
          description: badge.description,
          category: badge.category,
          rarity: badge.rarity,
          icon: badge.icon,
          threshold: badge.threshold,
          metric: badge.metric,
          isSecret: badge.isSecret,
          unlockedAt: userAchievement.unlockedAt,
          maxProgress: badge.maxProgress,
          currentProgress: progress,
        );
        
        newlyUnlocked.add(unlockedBadge);
      } else if (_userAchievements.containsKey(badge.id)) {
        // Update progress for already unlocked badges
        final existing = _userAchievements[badge.id]!;
        if (progress > existing.progress) {
          _userAchievements[badge.id] = UserAchievement(
            badgeId: badge.id,
            unlockedAt: existing.unlockedAt,
            progress: progress.toDouble(),
            metadata: existing.metadata,
          );
          await _saveUserAchievements();
        }
      }
    }
    
    return newlyUnlocked;
  }

  // Helper methods
  Future<void> _loadUserAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_userAchievementsKey);
    
    if (data != null) {
      try {
        final Map<String, dynamic> jsonMap = json.decode(data); // ✅ FIXED: renamed to jsonMap
        _userAchievements = jsonMap.map((key, value) => 
            MapEntry(key, UserAchievement.fromJson(value)));
      } catch (e) {
        debugPrint('❌ Error loading user achievements: $e');
        _userAchievements = {};
      }
    } else {
      _userAchievements = {};
    }
  }

  Future<void> _saveUserAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> jsonMap = _userAchievements.map((key, value) => // ✅ FIXED: renamed to jsonMap
        MapEntry(key, value.toJson()));
    await prefs.setString(_userAchievementsKey, jsonEncode(jsonMap));
  }

  Map<BadgeRarity, int> _getBadgesByRarity() {
    final Map<BadgeRarity, int> counts = {};
    
    for (final badgeId in _userAchievements.keys) {
      final badge = _allBadges.firstWhere((b) => b.id == badgeId);
      counts[badge.rarity] = (counts[badge.rarity] ?? 0) + 1;
    }
    
    return counts;
  }

  Future<int> getWeeklyExamCount() async {
    final results = await DatabaseHelper.getAllResults();
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    return results.where((r) {
      final date = DateTime.parse(r['completed_at']);
      return date.isAfter(weekAgo);
    }).length;
  }

  Future<int> getMonthlyExamCount() async {
    final results = await DatabaseHelper.getAllResults();
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    
    return results.where((r) {
      final date = DateTime.parse(r['completed_at']);
      return date.isAfter(monthAgo);
    }).length;
  }

  // Default badges if JSON file not found
  List<AchievementBadge> _getDefaultBadges() {
    return [
      // Excellence Badges
      AchievementBadge(
        id: 'first_step',
        name: 'First Step',
        description: 'Complete your first exam',
        category: BadgeCategory.milestone,
        rarity: BadgeRarity.bronze,
        icon: BadgeCategory.milestone.icon,
        threshold: 1,
        metric: 'exams',
        maxProgress: 1,
      ),
      AchievementBadge(
        id: 'perfect_score',
        name: 'Perfect Score',
        description: 'Achieve 100% on any exam',
        category: BadgeCategory.excellence,
        rarity: BadgeRarity.gold,
        icon: BadgeCategory.excellence.icon,
        threshold: 100,
        metric: 'score',
        maxProgress: 1,
      ),
      AchievementBadge(
        id: 'excellent_80',
        name: 'Excellence Award',
        description: 'Score 80% or higher',
        category: BadgeCategory.excellence,
        rarity: BadgeRarity.silver,
        icon: BadgeCategory.excellence.icon,
        threshold: 80,
        metric: 'score',
        maxProgress: 1,
      ),
      AchievementBadge(
        id: 'excellent_90',
        name: 'Outstanding Achievement',
        description: 'Score 90% or higher',
        category: BadgeCategory.excellence,
        rarity: BadgeRarity.gold,
        icon: BadgeCategory.excellence.icon,
        threshold: 90,
        metric: 'score',
        maxProgress: 1,
      ),
      AchievementBadge(
        id: 'first_perfect',
        name: 'Debut Perfection',
        description: 'Score 100% on your first attempt',
        category: BadgeCategory.excellence,
        rarity: BadgeRarity.platinum,
        icon: BadgeCategory.excellence.icon,
        threshold: 100,
        metric: 'first_try',
        maxProgress: 1,
        isSecret: true,
      ),

      // Consistency Badges
      AchievementBadge(
        id: 'three_in_row',
        name: 'Three in a Row',
        description: 'Score 70%+ on 3 consecutive attempts in the same subject',
        category: BadgeCategory.consistency,
        rarity: BadgeRarity.silver,
        icon: BadgeCategory.consistency.icon,
        threshold: 3,
        metric: 'consecutive',
        maxProgress: 3,
      ),
      AchievementBadge(
        id: 'weekly_warrior',
        name: 'Weekly Warrior',
        description: 'Complete 5 exams in one week',
        category: BadgeCategory.dedication,
        rarity: BadgeRarity.silver,
        icon: BadgeCategory.dedication.icon,
        threshold: 5,
        metric: 'weekly_exams',
        maxProgress: 5,
      ),
      AchievementBadge(
        id: 'monthly_dedication',
        name: 'Monthly Dedication',
        description: 'Complete 15 exams in one month',
        category: BadgeCategory.dedication,
        rarity: BadgeRarity.gold,
        icon: BadgeCategory.dedication.icon,
        threshold: 15,
        metric: 'monthly_exams',
        maxProgress: 15,
      ),

      // Speed Badges
      AchievementBadge(
        id: 'speed_demon',
        name: 'Speed Demon',
        description: 'Complete an exam in under 30 seconds per question with 70%+ score',
        category: BadgeCategory.speed,
        rarity: BadgeRarity.silver,
        icon: BadgeCategory.speed.icon,
        threshold: 30,
        metric: 'seconds_per_question',
        maxProgress: 1,
      ),
      AchievementBadge(
        id: 'lightning_fast',
        name: 'Lightning Fast',
        description: 'Complete an exam in under 20 seconds per question with 80%+ score',
        category: BadgeCategory.speed,
        rarity: BadgeRarity.gold,
        icon: BadgeCategory.speed.icon,
        threshold: 20,
        metric: 'seconds_per_question',
        maxProgress: 1,
      ),

      // Mastery Badges
      AchievementBadge(
        id: 'subject_master',
        name: 'Subject Master',
        description: 'Achieve 85%+ average across 5 attempts in any subject',
        category: BadgeCategory.mastery,
        rarity: BadgeRarity.gold,
        icon: BadgeCategory.mastery.icon,
        threshold: 85,
        metric: 'subject_average',
        maxProgress: 5,
      ),
      AchievementBadge(
        id: 'all_rounder',
        name: 'All-Rounder',
        description: 'Attempt all 6 subject categories',
        category: BadgeCategory.mastery,
        rarity: BadgeRarity.platinum,
        icon: BadgeCategory.mastery.icon,
        threshold: 6,
        metric: 'subjects_attempted',
        maxProgress: 6,
      ),

      // Dedication Badges
      AchievementBadge(
        id: 'dedicated_learner',
        name: 'Dedicated Learner',
        description: 'Complete 10 exams',
        category: BadgeCategory.dedication,
        rarity: BadgeRarity.bronze,
        icon: BadgeCategory.dedication.icon,
        threshold: 10,
        metric: 'total_exams',
        maxProgress: 10,
      ),
      AchievementBadge(
        id: 'exam_master',
        name: 'Exam Master',
        description: 'Complete 25 exams',
        category: BadgeCategory.dedication,
        rarity: BadgeRarity.silver,
        icon: BadgeCategory.dedication.icon,
        threshold: 25,
        metric: 'total_exams',
        maxProgress: 25,
      ),
      AchievementBadge(
        id: 'quiz_legend',
        name: 'Quiz Legend',
        description: 'Complete 50 exams',
        category: BadgeCategory.dedication,
        rarity: BadgeRarity.gold,
        icon: BadgeCategory.dedication.icon,
        threshold: 50,
        metric: 'total_exams',
        maxProgress: 50,
      ),

      // Time Investment Badges
      AchievementBadge(
        id: 'time_investor',
        name: 'Time Investor',
        description: 'Spend 1 hour total on exams',
        category: BadgeCategory.dedication,
        rarity: BadgeRarity.bronze,
        icon: BadgeCategory.dedication.icon,
        threshold: 60,
        metric: 'minutes',
        maxProgress: 60,
      ),
      AchievementBadge(
        id: 'time_master',
        name: 'Time Master',
        description: 'Spend 2 hours total on exams',
        category: BadgeCategory.dedication,
        rarity: BadgeRarity.silver,
        icon: BadgeCategory.dedication.icon,
        threshold: 120,
        metric: 'minutes',
        maxProgress: 120,
      ),

      // Accuracy Badges
      AchievementBadge(
        id: 'perfect_accuracy',
        name: 'Perfect Accuracy',
        description: 'Maintain 95%+ accuracy across 50+ questions',
        category: BadgeCategory.excellence,
        rarity: BadgeRarity.platinum,
        icon: BadgeCategory.excellence.icon,
        threshold: 95,
        metric: 'accuracy',
        maxProgress: 100,
      ),
    ];
  }
}