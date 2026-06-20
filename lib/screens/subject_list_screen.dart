import 'package:cs_exit_exam_app/home_screen.dart';
import 'package:cs_exit_exam_app/services/database_helper.dart';
import 'package:flutter/material.dart';
import '../utils/json_loader.dart';
import '../models/subject.dart';
import 'quiz_screen.dart';
import '../services/error_handler.dart';

class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  late Future<List<Subject>> _subjectsFuture;
  final Map<int, Map<String, dynamic>> _subjectProgress = {};

  @override
  void initState() {
    super.initState();
    _subjectsFuture = _loadSubjects();
    _loadProgress();
  }

  Future<List<Subject>> _loadSubjects() async {
    try {
      final subjects = await JsonLoader.loadSubjects();
      return subjects;
    } catch (e) {
      throw Exception('Failed to load subjects: $e');
    }
  }

  Future<void> _loadProgress() async {
    try {
      final results = await DatabaseHelper.getAllResults();
      if (results.isEmpty) return;
      
      final Map<int, List<Map<String, dynamic>>> subjectResults = {};
      for (final result in results) {
        final subjectId = result['subject_id'] as int;
        subjectResults.putIfAbsent(subjectId, () => []).add(result);
      }
      
      final Map<int, Map<String, dynamic>> progress = {};
      subjectResults.forEach((subjectId, list) {
        double bestScore = 0;
        int attempts = list.length;
        for (final result in list) {
          final score = result['score'] as double;
          if (score > bestScore) bestScore = score;
        }
        progress[subjectId] = {'best_score': bestScore, 'attempts': attempts};
      });
      
      setState(() {
        _subjectProgress.clear();
        _subjectProgress.addAll(progress);
      });
      debugPrint('✅ Loaded progress for ${progress.length} subjects');
    } catch (e) {
      debugPrint('❌ Error loading subject progress: $e');
    }
  }

  void _openQuiz(Subject subject) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(subject: subject)));
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {    
    return Scaffold(
      appBar: AppBar(
        title: const Text("CS Exit Exam Subjects"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
            tooltip: 'Go to Home',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _subjectsFuture = _loadSubjects();
                _loadProgress();
              });
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<Subject>>(
        future: _subjectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            ErrorHandler.showErrorOverlay(context, snapshot.error.toString());
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text("Failed to load subjects", style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() => _subjectsFuture = _loadSubjects()),
                    child: const Text("Retry"),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home),
                    label: const Text("Back to Home"),
                  ),
                ],
              ),
            );
          }

          final subjects = snapshot.data ?? [];
          
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${subjects.length} Subjects',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (subjects.isNotEmpty)
                      ElevatedButton(
                        onPressed: () => _openQuiz(subjects.first),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [Icon(Icons.play_arrow, size: 14), SizedBox(width: 4), Text('Start', style: TextStyle(fontSize: 12))],
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: subjects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.subject, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text("No subjects found.", style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            Text("Check your question files", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => setState(() => _subjectsFuture = _loadSubjects()),
                              icon: const Icon(Icons.refresh),
                              label: const Text("Refresh"),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: subjects.length,
                        itemBuilder: (context, index) => _buildSubjectCard(subjects[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSubjectCard(Subject subject) {
    final progress = _subjectProgress[subject.id];
    final hasProgress = progress != null;
    double? bestScore;
    if (hasProgress) bestScore = progress['best_score'] as double?;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openQuiz(subject),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getSubjectIcon(subject.name), size: 20, color: Colors.deepPurple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subject.description,
                      style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildInfoChip('${subject.questions.length} Q', isDark ? Colors.blue[900]! : Colors.blue[50]!, isDark),
                        const SizedBox(width: 6),
                        if (subject.timeLimit != null)
                          _buildInfoChip('${subject.timeLimit} min', isDark ? Colors.green[900]! : Colors.green[50]!, isDark),
                        if (hasProgress)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _buildInfoChip('${progress['attempts']} attempts', isDark ? Colors.amber[900]! : Colors.amber[50]!, isDark),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hasProgress && bestScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _getScoreColor(bestScore), borderRadius: BorderRadius.circular(12)),
                  child: Text('${bestScore.toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                )
              else
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color bgColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(fontSize: 9, color: isDark ? Colors.white : Colors.black87)),
    );
  }

  IconData _getSubjectIcon(String subjectName) {
    // (your existing icon mapping – unchanged)
    switch (subjectName.toLowerCase()) {
      case 'programming': case 'programming and algorithms': return Icons.code;
      case 'web design': case 'web programming': return Icons.web;
      case 'computer networking': case 'data communication and computer networking': case 'networking and system administration': return Icons.lan;
      case 'data structures': return Icons.stacked_bar_chart;
      case 'automata theory': case 'automata and complexity theory': return Icons.schema;
      case 'database systems': case 'database and software engineering': return Icons.storage;
      case 'software engineering': return Icons.engineering;
      case 'operating systems': return Icons.computer;
      case 'computer organization and architecture': case 'computer architecture and operating systems': return Icons.memory;
      case 'artificial intelligence': case 'intelligent systems and theory': return Icons.psychology;
      case 'computer security': return Icons.security;
      case 'compiler design': return Icons.code_off;
      case 'project management': return Icons.assignment;
      case 'digital logic design': return Icons.calculate;
      case 'mobile development': case 'mobile application development': return Icons.smartphone;
      case 'cloud computing': return Icons.cloud;
      case 'cyber security': return Icons.security;
      case 'machine learning': return Icons.psychology;
      case 'internet of things': case 'iot': return Icons.sensors;
      case 'data science': case 'data science & big data': return Icons.analytics;
      case 'blockchain': case 'blockchain & cryptocurrency': return Icons.link;
      case 'quantum computing': return Icons.science;
      case 'game development': return Icons.sports_esports;
      case 'devops': case 'devops & ci/cd': return Icons.cloud_sync;
      default: return Icons.menu_book;
    }
  }
}