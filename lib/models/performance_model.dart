// lib/models/performance_model.dart
class SubjectPerformance {
  final int subjectId;
  final String subjectName;
  final int attempts;
  final double averageScore;
  final double bestScore;
  final double worstScore;
  final int totalQuestions;
  final int totalCorrect;
  final int totalTimeSpent;
  final List<double> scoreHistory;
  final List<DateTime> attemptDates;

  SubjectPerformance({
    required this.subjectId,
    required this.subjectName,
    required this.attempts,
    required this.averageScore,
    required this.bestScore,
    required this.worstScore,
    required this.totalQuestions,
    required this.totalCorrect,
    required this.totalTimeSpent,
    required this.scoreHistory,
    required this.attemptDates,
  });

  double get accuracyRate => 
      totalQuestions > 0 ? (totalCorrect / totalQuestions * 100) : 0;
  
  String get formattedTotalTime {
    final hours = totalTimeSpent ~/ 3600;
    final minutes = (totalTimeSpent % 3600) ~/ 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }
}

class OverallPerformance {
  final int totalExams;
  final int totalQuestions;
  final int totalCorrect;
  final int totalIncorrect;
  final double overallAverage;
  final double highestScore;
  final double lowestScore;
  final int totalTimeSpent;
  final List<SubjectPerformance> subjectPerformances;
  final Map<String, double> strengthAreas;
  final Map<String, double> improvementAreas;

  OverallPerformance({
    required this.totalExams,
    required this.totalQuestions,
    required this.totalCorrect,
    required this.totalIncorrect,
    required this.overallAverage,
    required this.highestScore,
    required this.lowestScore,
    required this.totalTimeSpent,
    required this.subjectPerformances,
    required this.strengthAreas,
    required this.improvementAreas,
  });

  double get accuracyRate => 
      totalQuestions > 0 ? (totalCorrect / totalQuestions * 100) : 0;
  
  String get formattedTotalTime {
    final hours = totalTimeSpent ~/ 3600;
    final minutes = (totalTimeSpent % 3600) ~/ 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }
}

class WeeklyProgress {
  final DateTime weekStart;
  final int examsTaken;
  final double averageScore;
  final int totalTime;
  final List<double> dailyScores;

  WeeklyProgress({
    required this.weekStart,
    required this.examsTaken,
    required this.averageScore,
    required this.totalTime,
    required this.dailyScores,
  });
}