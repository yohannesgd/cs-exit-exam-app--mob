// lib/screens/performance_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/performance_model.dart';

class PerformanceDetailScreen extends StatelessWidget {
  final SubjectPerformance subjectPerformance;

  const PerformanceDetailScreen({
    super.key,
    required this.subjectPerformance,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subjectPerformance.subjectName),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(context),
            const SizedBox(height: 20),
            _buildStatsGrid(),
            const SizedBox(height: 20),
            _buildScoreHistoryCard(),
            const SizedBox(height: 20),
            _buildAttemptsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    final trend = subjectPerformance.scoreHistory.isEmpty
        ? 0.0
        : subjectPerformance.scoreHistory.first - 
          (subjectPerformance.scoreHistory.lastOrNull ?? 0);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade700,
              Colors.deepPurple.shade400,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Average Score',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        trend >= 0 ? Icons.trending_up : Icons.trending_down,
                        color: trend >= 0 ? Colors.green[300] : Colors.red[300],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${trend.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: trend >= 0 ? Colors.green[300] : Colors.red[300],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${subjectPerformance.averageScore.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${subjectPerformance.attempts} ${subjectPerformance.attempts == 1 ? 'attempt' : 'attempts'}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

 // In performance_detail_screen.dart, update _buildStatsGrid method

Widget _buildStatsGrid() {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Statistics',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.8, // Changed from 1.5 to 1.8
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _buildCompactStatCard(
                'Best Score',
                '${subjectPerformance.bestScore.toStringAsFixed(1)}%',
                Icons.emoji_events,
                Colors.amber,
              ),
              _buildCompactStatCard(
                'Worst Score',
                '${subjectPerformance.worstScore.toStringAsFixed(1)}%',
                Icons.warning,
                Colors.red,
              ),
              _buildCompactStatCard(
                'Accuracy',
                '${subjectPerformance.accuracyRate.toStringAsFixed(1)}%',
                Icons.check_circle,
                Colors.green,
              ),
              _buildCompactStatCard(
                'Total Time',
                subjectPerformance.formattedTotalTime,
                Icons.timer,
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// Add this helper method for compact stat cards
Widget _buildCompactStatCard(String label, String value, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}
Widget _buildScoreHistoryCard() {
  if (subjectPerformance.scoreHistory.isEmpty) {
    return const SizedBox.shrink();
  }

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Score Progression',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: subjectPerformance.scoreHistory.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final score = subjectPerformance.scoreHistory[index];
                final date = subjectPerformance.attemptDates[index];
                final isBest = score == subjectPerformance.bestScore;
                final isWorst = score == subjectPerformance.worstScore;
                  
                return Container(
                  width: 80,
                    decoration: BoxDecoration(
                      color: _getScoreColor(score).withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12),
                      border: isBest || isWorst
                          ? Border.all(
                              color: isBest ? Colors.amber : Colors.red,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isBest)
                          const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                        if (isWorst)
                          const Icon(Icons.warning, color: Colors.red, size: 16),
                        Text(
                          '${score.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(score),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d').format(date),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
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
    );
  }

  Widget _buildAttemptsList() {
    if (subjectPerformance.attempts == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Attempts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              subjectPerformance.attempts > 5 ? 5 : subjectPerformance.attempts,
              (index) {
                final scoreIndex = subjectPerformance.scoreHistory.length - 1 - index;
                final score = subjectPerformance.scoreHistory[scoreIndex];
                final date = subjectPerformance.attemptDates[scoreIndex];
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getScoreColor(score).withValues(alpha: .1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${scoreIndex + 1}',
                            style: TextStyle(
                              color: _getScoreColor(score),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, MMMM d, y').format(date),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'at ${DateFormat('h:mm a').format(date)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getScoreColor(score),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${score.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

extension ListExtension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}