// lib/models/exam_simulator.dart

class ExamSimulator {
  final String id;
  final String title;
  final String description;
  final int questionCount;
  final int timeLimitMinutes;
  final String level; // Beginner, Intermediate, Advanced
  final List<String> subjects; // Subjects covered
  final bool hasAnswerSheet;
  final bool hasExplanations;

  ExamSimulator({
    required this.id,
    required this.title,
    required this.description,
    required this.questionCount,
    required this.timeLimitMinutes,
    required this.level,
    required this.subjects,
    this.hasAnswerSheet = true,
    this.hasExplanations = true,
  });

  static List<ExamSimulator> getSampleExams() {
    return [
      ExamSimulator(
        id: 'exam_beginner_001',
        title: 'CS Exit Exam - Beginner Level',
        description: 'Foundation assessment covering core concepts',
        questionCount: 100,
        timeLimitMinutes: 180,
        level: 'Beginner',
        subjects: ['Programming', 'Database', 'Networking', 'OS', 'Web'],
      ),
      ExamSimulator(
        id: 'exam_intermediate_001',
        title: 'CS Exit Exam - Intermediate Level',
        description: 'Comprehensive mid-level assessment',
        questionCount: 100,
        timeLimitMinutes: 180,
        level: 'Intermediate',
        subjects: ['Programming', 'Database', 'Networking', 'OS', 'AI', 'Security'],
      ),
      ExamSimulator(
        id: 'exam_advanced_001',
        title: 'CS Exit Exam - Advanced Level',
        description: 'Advanced topics and problem-solving',
        questionCount: 100,
        timeLimitMinutes: 180,
        level: 'Advanced',
        subjects: ['Algorithms', 'System Design', 'ML', 'Cloud', 'IoT', 'Blockchain'],
      ),
    ];
  }
}