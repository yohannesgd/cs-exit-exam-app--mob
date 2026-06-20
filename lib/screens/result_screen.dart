// screens/result_screen.dart – dark mode fixed

import 'package:cs_exit_exam_app/home_screen.dart';
import 'package:cs_exit_exam_app/screens/review_answer_screen.dart';
import 'package:cs_exit_exam_app/services/database_helper.dart';
import 'package:cs_exit_exam_app/services/error_handler.dart';
import 'package:cs_exit_exam_app/services/haptic_service.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/subject.dart';
import '../models/achievement_model.dart';
import '../services/achievement_service.dart';
import '../services/performance_service.dart';
import 'subject_list_screen.dart';
import 'history_screen.dart';
import 'performance_dashboard_screen.dart';
import 'achievement_screen.dart';

class ResultScreen extends StatefulWidget {
  final Subject subject;
  final int score;
  final int correctCount;
  final int incorrectCount;
  final int totalQuestions;
  final int timeSpent;
  final List<int>? userAnswers;
  final List<bool>? answerStatus;
  final bool isHistorical;

  const ResultScreen({
    super.key,
    required this.subject,
    required this.score,
    required this.correctCount,
    required this.incorrectCount,
    required this.totalQuestions,
    required this.timeSpent,
    this.userAnswers,
    this.answerStatus,
    this.isHistorical = false,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  bool _isSaving = false;
  bool _saveSuccess = false;
  String? _errorMessage;
  final DateTime _completedAt = DateTime.now();
  List<AchievementBadge> _newlyUnlockedBadges = [];
  late AnimationController _celebrationController;
  late Animation<double> _celebrationAnimation;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _celebrationAnimation = CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    );
    
    if (!widget.isHistorical) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _saveResult();
      });
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  Future<void> _saveResult() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    
    try {
      final result = {
        'subject_id': widget.subject.id,
        'subject_name': widget.subject.name,
        'score': widget.score.toDouble(),
        'correct_count': widget.correctCount,
        'incorrect_count': widget.incorrectCount,
        'total_questions': widget.totalQuestions,
        'time_spent': widget.timeSpent,
        'completed_at': _completedAt.toIso8601String(),
      };
      
      debugPrint('📝 Saving result: $result');
      
      await DatabaseHelper.insertResult(result);
      
      final progress = await DatabaseHelper.getUserProgress(widget.subject.id);
      
      Map<String, dynamic> currentProgress;
      if (progress == null) {
        currentProgress = {
          'subject_id': widget.subject.id,
          'last_score': widget.score.toDouble(),
          'best_score': widget.score.toDouble(),
          'total_attempts': 1,
          'total_correct': widget.correctCount,
          'total_questions': widget.totalQuestions,
          'last_attempt': _completedAt.toIso8601String(),
        };
      } else {
        final currentBest = progress['best_score'] as double? ?? 0;
        currentProgress = {
          'subject_id': widget.subject.id,
          'last_score': widget.score.toDouble(),
          'best_score': widget.score > currentBest ? widget.score : currentBest,
          'total_attempts': (progress['total_attempts'] as int? ?? 0) + 1,
          'total_correct': (progress['total_correct'] as int? ?? 0) + widget.correctCount,
          'total_questions': (progress['total_questions'] as int? ?? 0) + widget.totalQuestions,
          'last_attempt': _completedAt.toIso8601String(),
        };
      }

      await DatabaseHelper.updateUserProgress(currentProgress);
      
      final performance = await PerformanceService().getOverallPerformance();
      final newBadges = await AchievementService().checkAchievements(result, performance);
      
      if (newBadges.isNotEmpty) {
        setState(() {
          _newlyUnlockedBadges = newBadges;
        });
        _celebrationController.forward();
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showAchievementCelebration(newBadges);
          }
        });
      }
      
      setState(() {
        _saveSuccess = true;
        _isSaving = false;
      });
      
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSaving = false;
        _saveSuccess = false;
      });
      if(!mounted) return;
      ErrorHandler.showErrorOverlay(context, "Failed to save result: $e");
      debugPrint('❌ Save error details: $e');
    }
  }

  void _shareResults() {
    final minutes = widget.timeSpent ~/ 60;
    final seconds = widget.timeSpent % 60;
    final String text = "I just finished my Computer Science Exam Prep! 🚀\n"
        "Score: ${widget.correctCount}/${widget.totalQuestions}\n"
        "Time: ${minutes}m ${seconds}s\n"
        "Join our Telegram group to study together!";

    SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'My CS Exit Exam Result',
      ),
    );
  }

  void _showAchievementCelebration(List<AchievementBadge> badges) {
    HapticService().vibrateAchievement();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Column(
          children: [
            AnimatedBuilder(
              animation: _celebrationAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1 + (_celebrationAnimation.value * 0.3),
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.deepPurple,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '🏆 Achievement Unlocked!',
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ...badges.map((badge) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: badge.rarity.color.withValues(alpha: .1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        badge.icon,
                        color: badge.rarity.color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                badge.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: badge.rarity.color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  badge.rarity.name,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: badge.rarity.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            badge.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _celebrationController.reverse();
            },
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _celebrationController.reverse();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AchievementScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.deepPurple,
            ),
            child: const Text('View All Badges'),
          ),
        ],
      ),
    );
  }

  double get percentage => widget.score.toDouble();
  String get performanceMessage {
    if (percentage >= 80) return "Excellent! 🌟";
    if (percentage >= 70) return "Great job! 👍";
    if (percentage >= 60) return "Good effort! 💪";
    if (percentage >= 50) return "Passing grade! 📚";
    return "Keep practicing! 🔄";
  }

  Color get performanceColor {
    if (percentage >= 80) return const Color(0xFF4CAF50);
    if (percentage >= 70) return const Color(0xFF2196F3);
    if (percentage >= 60) return const Color(0xFFFF9800);
    if (percentage >= 50) return const Color(0xFFFF5722);
    return const Color(0xFFF44336);
  }

  String get performanceEmoji {
    if (percentage >= 80) return "🎯";
    if (percentage >= 70) return "👍";
    if (percentage >= 60) return "💪";
    if (percentage >= 50) return "📚";
    return "🔄";
  }

  String _formatCompactTime(int seconds) {
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  Map<String, Map<String, int>> _calculateTopicBreakdown() {
  final Map<String, Map<String, int>> breakdown = {};

  // Loop through based on actual answers provided to avoid range errors
  final statusList = widget.answerStatus ?? [];
  
  for (int i = 0; i < statusList.length; i++) {
    // Safety check: Ensure the question index exists
    if (i >= widget.subject.questions.length) break;

    final question = widget.subject.questions[i];
    final isCorrect = statusList[i];
    final topic = question.topic ?? 'General';

    breakdown.putIfAbsent(topic, () => {'correct': 0, 'total': 0});
    breakdown[topic]!['total'] = breakdown[topic]!['total']! + 1;
    if (isCorrect) {
      breakdown[topic]!['correct'] = breakdown[topic]!['correct']! + 1;
    }
  }

  return breakdown;
}

  Widget _buildScoreCircle() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: performanceColor.withValues(alpha: 0.3),
          width: 6,
        ),
        gradient: RadialGradient(
          colors: [
            performanceColor.withValues(alpha: .1),
            performanceColor.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${widget.score}%',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: performanceColor,
              ),
            ),
            Text(
              '${widget.correctCount}/${widget.totalQuestions}',
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMessage() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Text(performanceEmoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                performanceMessage,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.share, size: 20),
              onPressed: _shareResults,
              tooltip: 'Share results',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveStatus() {
    if (_isSaving) {
      return const Column(
        children: [
          SizedBox(height: 8),
          CircularProgressIndicator(),
          SizedBox(height: 8),
          Text('Saving...'),
        ],
      );
    }
    
    if (_errorMessage != null) {
      return Column(
        children: [
          const SizedBox(height: 8),
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(height: 8),
          const Text('Save failed', style: TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _saveResult, child: const Text('Retry')),
        ],
      );
    }
    
    if (_saveSuccess) {
      return const Column(
        children: [
          SizedBox(height: 8),
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(height: 8),
          Text('Saved!', style: TextStyle(color: Colors.green)),
        ],
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildTopicBreakdown() {
  final breakdown = _calculateTopicBreakdown();
  
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Topic-Wise Breakdown", 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...breakdown.entries.map((entry) {
            double percent = entry.value['correct']! / entry.value['total']!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 13)),
                      Text("${entry.value['correct']}/${entry.value['total']}"),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percent,
                    backgroundColor: Colors.grey[300],
                    color: percent > 0.7 ? Colors.green : (percent > 0.4 ? Colors.orange : Colors.red),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ),
  );
}

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: [
          _buildCompactStatCard(
            Icons.check_circle, 
            'Correct', 
            '${widget.correctCount}', 
            Colors.green,
          ),
          _buildCompactStatCard(
            Icons.cancel, 
            'Incorrect', 
            '${widget.incorrectCount}', 
            Colors.red,
          ),
          _buildCompactStatCard(
            Icons.timer, 
            'Time', 
            _formatCompactTime(widget.timeSpent), 
            Colors.blue,
          ),
          _buildCompactStatCard(
            Icons.calendar_today, 
            'Date', 
            DateFormat('MM/dd').format(_completedAt), 
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard(IconData icon, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                  maxLines: 1,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewBadgesPreview() {
    if (_newlyUnlockedBadges.isEmpty) return const SizedBox.shrink();
    
    return Card(
      elevation: 4,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade300, width: 1.5),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementScreen())),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.amber.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'New Achievements!',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.amber),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _newlyUnlockedBadges.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final badge = _newlyUnlockedBadges[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badge.rarity.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              badge.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badge.rarity.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badge.rarity.name,
                              style: TextStyle(
                                fontSize: 10,
                                color: badge.rarity.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          children: [
            // Inside _buildNavigationButtons in result_screen.dart
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReviewAnswersScreen(
                        questions: widget.subject.questions,
                        userAnswers: widget.userAnswers ?? [], // Pass the answers list here
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('Review Answers', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubjectListScreen())),
                icon: const Icon(Icons.list, size: 16),
                label: const Text('Subjects', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white, // Force text to be white
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SubjectListScreen()),
                ),
                icon: const Icon(Icons.refresh, size: 14),
                label: Text('Retry', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11)),
                style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                icon: const Icon(Icons.history, size: 14),
                label: Text('History', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11)),
                style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PerformanceDashboardScreen())),
                icon: const Icon(Icons.analytics, size: 14),
                label: Text('Analytics', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementScreen())),
                icon: const Icon(Icons.emoji_events, size: 14),
                label: const Text('Badges', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: Colors.amber),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletionTime() {
    if (widget.isHistorical) return const SizedBox.shrink();
    return Text(
      DateFormat('MMM d, y').format(_completedAt),
      style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color, fontStyle: FontStyle.italic),
      textAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.isHistorical ? 'Result' : 'Complete'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.isHistorical) {
              Navigator.pop(context);
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            }
          },
        ),
        actions: [
          if (!widget.isHistorical && _isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildScoreCircle(),
              const SizedBox(height: 12),
              _buildPerformanceMessage(),
              const SizedBox(height: 12),
              if (!widget.isHistorical) _buildSaveStatus(),
              if (!widget.isHistorical && _newlyUnlockedBadges.isNotEmpty) _buildNewBadgesPreview(),
              const SizedBox(height: 12),
              _buildStatsGrid(),
              const SizedBox(height: 16),
              _buildTopicBreakdown(),
              const SizedBox(height: 16),
              _buildNavigationButtons(),
              const SizedBox(height: 12),
              _buildCompletionTime(),
            ],
          ),
        ),
      ),
    );
  }
}