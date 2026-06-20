// lib/models/previous_exam.dart

class PreviousExam {
  final String id;
  final String year;
  final String title;
  final String university; // e.g., "Addis Ababa University"
  final int questionCount;
  final int timeLimitMinutes;
  final bool hasAnswerKey;
  final bool hasExplanations;
  final String pdfUrl; // For answer sheet
  final DateTime releaseDate;

  PreviousExam({
    required this.id,
    required this.year,
    required this.title,
    required this.university,
    required this.questionCount,
    required this.timeLimitMinutes,
    required this.hasAnswerKey,
    required this.hasExplanations,
    required this.pdfUrl,
    required this.releaseDate,
  });

  static List<PreviousExam> getSampleExams() {
    return [
      PreviousExam(
        id: 'prev_2023_01',
        year: '2023',
        title: 'CS Exit Exam - Addis Ababa University',
        university: 'Addis Ababa University',
        questionCount: 100,
        timeLimitMinutes: 180,
        hasAnswerKey: true,
        hasExplanations: true,
        pdfUrl: 'assets/exams/2023_AAU_exit_exam.pdf',
        releaseDate: DateTime(2023, 6, 15),
      ),
      PreviousExam(
        id: 'prev_2022_01',
        year: '2022',
        title: 'CS Exit Exam - Bahir Dar University',
        university: 'Bahir Dar University',
        questionCount: 100,
        timeLimitMinutes: 180,
        hasAnswerKey: true,
        hasExplanations: false,
        pdfUrl: 'assets/exams/2022_BDU_exit_exam.pdf',
        releaseDate: DateTime(2022, 7, 10),
      ),
      PreviousExam(
        id: 'prev_2021_01',
        year: '2021',
        title: 'CS Exit Exam - Jimma University',
        university: 'Jimma University',
        questionCount: 100,
        timeLimitMinutes: 180,
        hasAnswerKey: true,
        hasExplanations: true,
        pdfUrl: 'assets/exams/2021_JU_exit_exam.pdf',
        releaseDate: DateTime(2021, 6, 20),
      ),
    ];
  }
}