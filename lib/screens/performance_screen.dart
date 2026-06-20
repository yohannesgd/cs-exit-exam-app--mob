import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  late Future<Map<String, dynamic>> _performanceFuture;

  @override
  void initState() {
    super.initState();
    _performanceFuture = _loadPerformanceData();
  }

  Future<Map<String, dynamic>> _loadPerformanceData() async {
    final results = await DatabaseHelper.getAllResults();
    
    if (results.isEmpty) {
      return {
        'totalAttempts': 0,
        'averageScore': 0.0,
        'bestScore': 0.0,
        'totalTime': 0,
        'subjectStats': {},
      };
    }

    // Calculate statistics
    double totalScore = 0;
    double bestScore = 0;
    int totalTime = 0;
    final Map<String, Map<String, dynamic>> subjectStats = {};

    for (final result in results) {
      final score = result['score'] as double;
      totalScore += score;
      
      if (score > bestScore) bestScore = score;
      
      totalTime += result['time_spent'] as int;
      
      final subjectName = result['subject_name'] as String;
      if (!subjectStats.containsKey(subjectName)) {
        subjectStats[subjectName] = {
          'attempts': 0,
          'totalScore': 0.0,
          'bestScore': 0.0,
        };
      }
      
      final stats = subjectStats[subjectName]!;
      stats['attempts'] = (stats['attempts'] as int) + 1;
      stats['totalScore'] = (stats['totalScore'] as double) + score;
      if (score > (stats['bestScore'] as double)) {
        stats['bestScore'] = score;
      }
    }

    return {
      'totalAttempts': results.length,
      'averageScore': totalScore / results.length,
      'bestScore': bestScore,
      'totalTime': totalTime,
      'subjectStats': subjectStats,
    };
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Performance Statistics"),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _performanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading statistics: ${snapshot.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }

          final data = snapshot.data!;
          final totalAttempts = data['totalAttempts'] as int;
          final averageScore = data['averageScore'] as double;
          final bestScore = data['bestScore'] as double;
          final totalTime = data['totalTime'] as int;
          final subjectStats = data['subjectStats'] as Map<String, Map<String, dynamic>>;

          if (totalAttempts == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bar_chart, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  Text(
                    'No exam data yet',
                    style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Take some exams to see your performance statistics',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview stats
                const Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildStatCard(
                      'Total Attempts',
                      '$totalAttempts',
                      Icons.assignment_turned_in,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Avg Score',
                      '${averageScore.toStringAsFixed(1)}%',
                      Icons.trending_up,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Best Score',
                      '${bestScore.toStringAsFixed(1)}%',
                      Icons.emoji_events,
                      Colors.amber,
                    ),
                    _buildStatCard(
                      'Total Time',
                      _formatTime(totalTime),
                      Icons.timer,
                      Colors.purple,
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Subject-wise stats
                const Text(
                  'Subject Performance',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                if (subjectStats.isEmpty)
                  Text(
                    'No subject data available',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  )
                else
                  ...subjectStats.entries.map((entry) {
                    final subjectName = entry.key;
                    final stats = entry.value;
                    final attempts = stats['attempts'] as int;
                    final avgScore = (stats['totalScore'] as double) / attempts;
                    final best = stats['bestScore'] as double;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subjectName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMiniStat('Attempts', '$attempts'),
                                _buildMiniStat('Average', '${avgScore.toStringAsFixed(1)}%'),
                                _buildMiniStat('Best', '${best.toStringAsFixed(1)}%'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: avgScore / 100,
                              backgroundColor: Colors.grey[200],
                              color: _getScoreColor(avgScore),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}