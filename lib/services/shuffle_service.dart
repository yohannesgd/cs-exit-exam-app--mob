// lib/services/shuffle_service.dart - UPDATED

import 'dart:math';
import '../models/question.dart';
import '../models/subject.dart';

class ShuffleService {
  static final Random _random = Random();

  // Special patterns that should remain at the end
  static const List<String> _specialPatterns = [
    'all of the above',
    'none of the above',
    'both a and b',
    'both b and c',
    'a and b only',
    'b and c only',
  ];

  static Question _shuffleQuestionOptions(Question question) {
    // Create list of (option, isCorrect) pairs
    final List<MapEntry<String, bool>> optionsWithCorrectness = [];
    
    // Track special options
    final List<int> specialIndices = [];
    
    for (int i = 0; i < question.options.length; i++) {
      final option = question.options[i];
      final isSpecial = _specialPatterns.any(
        (pattern) => option.toLowerCase().contains(pattern)
      );
      
      if (isSpecial) {
        specialIndices.add(i);
      }
      
      optionsWithCorrectness.add(
        MapEntry(option, i == question.correctAnswerIndex)
      );
    }
    
    // Separate special and normal options
    final List<MapEntry<String, bool>> normalOptions = [];
    final List<MapEntry<String, bool>> specialOptions = [];
    
    for (int i = 0; i < optionsWithCorrectness.length; i++) {
      if (specialIndices.contains(i)) {
        specialOptions.add(optionsWithCorrectness[i]);
      } else {
        normalOptions.add(optionsWithCorrectness[i]);
      }
    }
    
    // Shuffle normal options only
    normalOptions.shuffle(_random);
    
    // Combine: normal options first, then special options (preserving order)
    final combined = [...normalOptions, ...specialOptions];
    
    // Extract shuffled options and find new correct index
    final List<String> shuffledOptions = [];
    int newCorrectIndex = -1;
    
    for (int i = 0; i < combined.length; i++) {
      shuffledOptions.add(combined[i].key);
      if (combined[i].value) {
        newCorrectIndex = i;
      }
    }
    
    return Question(
      id: question.id,
      text: question.text,
      options: shuffledOptions,
      correctAnswerIndex: newCorrectIndex,
      explanation: question.explanation,
      topic: question.topic,
      difficulty: question.difficulty,
    );
  }

  // Get shuffled subject with smart option handling
  static Subject getShuffledSubject({
    required Subject subject,
    required bool shuffleQuestions,
    required bool shuffleOptions,
  }) {
    if (!shuffleQuestions && !shuffleOptions) {
      return subject;
    }
    
    Subject result = subject;
    
    if (shuffleQuestions) {
      // Shuffle questions order
      List<Question> shuffledQuestions = List.from(result.questions);
      shuffledQuestions.shuffle(_random);
      result = Subject(
        id: result.id,
        name: result.name,
        description: result.description,
        questions: shuffledQuestions,
        icon: result.icon,
        timeLimit: result.timeLimit,
      );
    }
    
    if (shuffleOptions) {
      // Shuffle options with special handling
      final shuffledWithOptions = result.questions.map((q) => 
        _shuffleQuestionOptions(q)
      ).toList();
      
      result = Subject(
        id: result.id,
        name: result.name,
        description: result.description,
        questions: shuffledWithOptions,
        icon: result.icon,
        timeLimit: result.timeLimit,
      );
    }
    
    return result;
  }
}