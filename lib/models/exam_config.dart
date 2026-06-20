// lib/models/exam_config.dart

class ExamConfig {
  final String name;
  final int totalQuestions;
  final int timeLimitMinutes;
  final Map<String, double> subjectPercentages; // subjectName -> percentage
  final Map<String, Map<String, double>> topicPercentages; // subject -> topic -> percentage

  ExamConfig({
    required this.name,
    required this.totalQuestions,
    required this.timeLimitMinutes,
    required this.subjectPercentages,
    required this.topicPercentages,
  });

  // Ethiopian CS Exit Exam configuration
  static final ExamConfig ethiopianExitExam = ExamConfig(
    name: "Ethiopian CS Exit Exam (Simulated)",
    totalQuestions: 100,
    timeLimitMinutes: 180,
    subjectPercentages: {
      "Programming and Algorithms": 20,
      "Database and Software Engineering": 20,
      "Networking and System Administration": 15,
      "Computer Architecture and OS": 15,
      "Intelligent Systems and Theory": 15,
      "Project Management": 15,
    },
    topicPercentages: {
      "Programming and Algorithms": {
        "Programming Fundamentals": 30,
        "Object-Oriented Programming": 25,
        "Data Structures": 25,
        "Algorithms": 20,
      },
      "Database and Software Engineering": {
        "Database Systems": 40,
        "Software Engineering": 30,
        "Web Programming": 30,
      },
      "Networking and System Administration": {
        "dataCommunicationNetworking": 40,
        "computerSecurity": 30,
        "networkSystemAdministration": 30
      },
      "Computer Architecture and OS": {
        "computerOrganizationArchitecture": 50,
        "operatingSystems": 30,
        "digitalLogicDesign": 20
      },
      "Intelligent Systems and Theory": {
        "artificialIntelligence": 40,
        "theoryOfComputation": 30,
        "machineLearning": 30
      },
      "Project Management": {
        "projectPlanning": 40,
        "softwareProjectManagement": 30,
        "agileMethodologies": 30
      },
      // ... other subjects
    },
  );
}