// lib/services/exam_generator_service.dart

/*import 'dart:math';
import 'package:cs_exit_exam_app/screens/custom_exam_screen.dart';
import 'package:flutter/material.dart';

import '../models/subject.dart';
import '../models/question.dart';
import '../models/exam_config.dart';
import '../services/question_bank_service.dart';
import '../utils/json_loader.dart';

class ExamGeneratorService {
  static final ExamGeneratorService _instance = ExamGeneratorService._internal();
  factory ExamGeneratorService() => _instance;
  ExamGeneratorService._internal();

  final Random _random = Random();
  final QuestionBankService _questionBank = QuestionBankService();

  // Generate a complete exam based on configuration
  Future<Map<Subject, List<Question>>> generateExam(ExamConfig config) async {
    final allSubjects = await JsonLoader.loadSubjects();
    final examQuestions = <Subject, List<Question>>{};
    
    // Calculate questions per subject
    for (final entry in config.subjectPercentages.entries) {
      final subjectName = entry.key;
      final percentage = entry.value;
      final questionCount = (config.totalQuestions * percentage / 100).round();
      
      // Find the subject
      final subject = allSubjects.firstWhere(
        (s) => s.name == subjectName,
        orElse: () => throw Exception('Subject $subjectName not found'),
      );
      
      // Get questions for this subject with topic distribution
      final questions = await _selectQuestionsByTopic(
        subject,
        questionCount,
        config.topicPercentages[subjectName] ?? {},
      );
      
      examQuestions[subject] = questions;
    }
    
    return examQuestions;
  }

  // Select questions based on topic percentages
  Future<List<Question>> _selectQuestionsByTopic(
    Subject subject, 
    int totalCount,
    Map<String, double> topicPercentages,
  ) async {
    final List<Question> selected = [];
    final allQuestions = subject.questions;
    
    // Group questions by topic
    final Map<String, List<Question>> questionsByTopic = {};
    for (final q in allQuestions) {
      final topic = q.topic ?? 'General';
      questionsByTopic.putIfAbsent(topic, () => []).add(q);
    }
    
    // Select questions per topic based on percentages
    for (final entry in topicPercentages.entries) {
      final topic = entry.key;
      final percentage = entry.value;
      final topicCount = (totalCount * percentage / 100).round();
      
      if (questionsByTopic.containsKey(topic)) {
        final topicQuestions = questionsByTopic[topic]!;
        
        // Avoid repeated questions using QuestionBankService
        final leastUsedIds = await _questionBank.getLeastUsedQuestions(
          subject.name, 
          topicCount * 2
        );
        
        // Select questions, prioritizing least used
        final availableQuestions = topicQuestions.where((q) {
          return leastUsedIds.contains(q.id);
        }).toList();
        
        // If not enough least-used, take random from remaining
        if (availableQuestions.length < topicCount) {
          availableQuestions.addAll(topicQuestions);
        }
        
        // Shuffle and take required count
        availableQuestions.shuffle(_random);
        selected.addAll(availableQuestions.take(topicCount));
      }
    }
    
    // If we don't have enough questions, fill with random
    if (selected.length < totalCount) {
      final remaining = allQuestions
        .where((q) => !selected.contains(q))
        .toList()
        ..shuffle(_random);
      selected.addAll(remaining.take(totalCount - selected.length));
    }
    
    // Shuffle final selection
    selected.shuffle(_random);
    
    // Track usage of selected questions
    for (final q in selected) {
      await _questionBank.trackQuestionUsage(q.id, subject.name);
    }
    
    return selected.take(totalCount).toList();
  }

  // Create a custom exam screen
  Widget createExamScreen(ExamConfig config) {
    // This would return a custom exam screen with timer
    return FutureBuilder<Map<Subject, List<Question>>>(
      future: generateExam(config),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        
        final examData = snapshot.data!;
        
        // Flatten all questions with subject tracking
        final allQuestions = examData.entries.expand((entry) {
          return entry.value.map((q) => {
            'subject': entry.key,
            'question': q,
          });
        }).toList()..shuffle(_random);
        
        // Navigate to custom exam screen
        return CustomExamScreen(
          examConfig: config,
          questions: allQuestions,
        );
      },
    );
  }
}*/