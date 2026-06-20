// screens/performance_dashboard_screen.dart (FIXED)

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/performance_service.dart';
import '../models/performance_model.dart';
import 'subject_list_screen.dart';
import 'performance_detail_screen.dart';

typedef UITextDirection = ui.TextDirection;


class PerformanceDashboardScreen extends StatefulWidget {
  const PerformanceDashboardScreen({super.key});

  @override
  State<PerformanceDashboardScreen> createState() => _PerformanceDashboardScreenState();
}

class _PerformanceDashboardScreenState extends State<PerformanceDashboardScreen> 
    with SingleTickerProviderStateMixin {
  late Future<OverallPerformance> _performanceFuture;
  late Future<List<WeeklyProgress>> _weeklyProgressFuture;
  late TabController _tabController;
  
  final PerformanceService _performanceService = PerformanceService();
  

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() {
    setState(() {
      _performanceFuture = _performanceService.getOverallPerformance();
      _weeklyProgressFuture = _performanceService.getWeeklyProgress();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Performance Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.show_chart), text: 'Progress'),
            Tab(icon: Icon(Icons.psychology), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildProgressTab(),
          _buildInsightsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        backgroundColor: Colors.deepPurple,
        tooltip: 'Refresh Data',
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  // ==================== OVERVIEW TAB ====================
  Widget _buildOverviewTab() {
    return FutureBuilder<OverallPerformance>(
      future: _performanceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final performance = snapshot.data!;
        
        if (performance.totalExams == 0) {
          return _buildEmptyState();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverallStatsCard(performance),
              const SizedBox(height: 20),
              _buildProgressIndicators(performance),
              const SizedBox(height: 20),
              _buildSubjectPerformanceTable(performance.subjectPerformances),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverallStatsCard(OverallPerformance performance) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade700,
            Colors.deepPurple.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCompactOverallStat(
                '${performance.overallAverage.toStringAsFixed(1)}%',
                'Avg',
                Icons.assessment,
              ),
              _buildCompactOverallStat(
                '${performance.accuracyRate.toStringAsFixed(1)}%',
                'Acc',
                Icons.check_circle,
              ),
              _buildCompactOverallStat(
                '${performance.totalExams}',
                'Exams',
                Icons.quiz,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ✅ FIXED: Compact detail row with no overflow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCompactDetailItem(Icons.emoji_events, '${performance.highestScore.toStringAsFixed(0)}%', Colors.amber),
              _buildCompactDetailItem(Icons.trending_up, '${performance.overallAverage.toStringAsFixed(0)}%', Colors.green),
              _buildCompactDetailItem(Icons.warning, '${performance.lowestScore.toStringAsFixed(0)}%', Colors.red),
            ],
          ),
        ],
      ),
    ),
  );
}

 // Add compact overall stat
Widget _buildCompactOverallStat(String value, String label, IconData icon) {
  return Column(
    children: [
      Icon(icon, color: Colors.white, size: 20),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
        ),
      ),
    ],
  );
}

 // Add compact detail item
Widget _buildCompactDetailItem(IconData icon, String value, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildProgressIndicators(OverallPerformance performance) {
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
              'Subject Mastery',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...performance.subjectPerformances
                .where((s) => s.attempts > 0)
                .take(4)
                .map((s) => _buildMasteryIndicator(s)),
          ],
        ),
      ),
    );
  }

  Widget _buildMasteryIndicator(SubjectPerformance subject) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subject.subjectName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${subject.averageScore.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(subject.averageScore),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 8,
                width: MediaQuery.of(context).size.width * 0.7 * 
                    (subject.averageScore / 100),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getScoreColor(subject.averageScore),
                      _getScoreColor(subject.averageScore).withValues(alpha: .7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectPerformanceTable(List<SubjectPerformance> performances) {
    final activePerformances = performances.where((p) => p.attempts > 0).toList();
    
    if (activePerformances.isEmpty) {
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
              'Subject Performance Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('Subject')),
                  DataColumn(label: Text('Attempts')),
                  DataColumn(label: Text('Average')),
                  DataColumn(label: Text('Best')),
                  DataColumn(label: Text('Accuracy')),
                  DataColumn(label: Text('')),
                ],
                rows: activePerformances.map((p) {
                  return DataRow(
                    cells: [
                      DataCell(Text(p.subjectName)),
                      DataCell(Text('${p.attempts}')),
                      DataCell(
                        Text(
                          '${p.averageScore.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: _getScoreColor(p.averageScore),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${p.bestScore.toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${p.accuracyRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: _getScoreColor(p.accuracyRate),
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PerformanceDetailScreen(
                                  subjectPerformance: p,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PROGRESS TAB ====================
  Widget _buildProgressTab() {
    return FutureBuilder<List<WeeklyProgress>>(
      future: _weeklyProgressFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final weeklyProgress = snapshot.data ?? [];
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWeeklyProgressChart(weeklyProgress),
              const SizedBox(height: 24),
              _buildWeeklyStats(weeklyProgress),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeeklyProgressChart(List<WeeklyProgress> weeklyProgress) {
    final hasData = weeklyProgress.any((w) => w.examsTaken > 0);
    
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
              'Weekly Performance Trend',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Average score per week',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            if (!hasData)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No weekly data available yet'),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: CustomPaint(
                  painter: WeeklyChartPainter(weeklyProgress),
                  size: Size(MediaQuery.of(context).size.width - 64, 200),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: weeklyProgress.map((week) {
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        DateFormat('MMM d').format(week.weekStart),
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: week.examsTaken > 0 
                              ? Colors.deepPurple 
                              : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${week.examsTaken}',
                            style: TextStyle(
                              fontSize: 11,
                              color: week.examsTaken > 0 
                                  ? Colors.white 
                                  : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStats(List<WeeklyProgress> weeklyProgress) {
    final totalExams = weeklyProgress.fold(0, (sum, w) => sum + w.examsTaken);
    final avgScore = weeklyProgress.where((w) => w.examsTaken > 0).isEmpty
        ? 0.0
        : weeklyProgress
            .where((w) => w.examsTaken > 0)
            .map((w) => w.averageScore)
            .reduce((a, b) => a + b) / 
            weeklyProgress.where((w) => w.examsTaken > 0).length;
    
    final totalTime = weeklyProgress.fold(0, (sum, w) => sum + w.totalTime);
    final hours = totalTime ~/ 3600;
    final minutes = (totalTime % 3600) ~/ 60;

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
              'Last 6 Weeks Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  Icons.calendar_today,
                  '$totalExams',
                  'Exams',
                  Colors.blue,
                ),
                _buildSummaryItem(
                  Icons.trending_up,
                  '${avgScore.toStringAsFixed(1)}%',
                  'Avg Score',
                  Colors.green,
                ),
                _buildSummaryItem(
                  Icons.timer,
                  '${hours}h ${minutes}m',
                  'Study Time',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== INSIGHTS TAB ====================
 Widget _buildInsightsTab() {
  return FutureBuilder<OverallPerformance>(
    future: _performanceFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError || snapshot.data!.totalExams == 0) {
        return _buildInsightsEmptyState();
      }

      final performance = snapshot.data!;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildStrengthsWeaknessesCard(performance),
            const SizedBox(height: 12),
            _buildRecommendationsCard(performance),
            const SizedBox(height: 12),
            _buildLearningPatternsCard(performance),
          ],
        ),
      );
    },
  );
}

Widget _buildStrengthsWeaknessesCard(OverallPerformance performance) {
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
            'Strengths & Focus Areas',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          // ✅ FIXED: Stacked layout instead of Row to prevent overflow
          Column(
            children: [
              // Strengths section
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: .05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: .2)),
                ),
                child: _buildStrengthList(performance.strengthAreas),
              ),
              
              // Focus Areas section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: .05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: .2)),
                ),
                child: _buildWeaknessList(performance.improvementAreas),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildStrengthList(Map<String, double> strengths) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt, color: Colors.green, size: 14),
          ),
          const SizedBox(width: 6),
          const Text(
            'Strengths',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontSize: 13,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (strengths.isEmpty)
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            'Keep practicing!',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        )
      else
        ...strengths.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 12),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  e.key,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${e.value.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        )),
    ],
  );
}

Widget _buildWeaknessList(Map<String, double> weaknesses) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.trending_down, color: Colors.orange, size: 14),
          ),
          const SizedBox(width: 6),
          const Text(
            'Focus Areas',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
              fontSize: 13,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (weaknesses.isEmpty)
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            'Great job! No weak areas.',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        )
      else
        ...weaknesses.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning, color: Colors.orange, size: 12),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  e.key,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              if (e.value > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${e.value.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontSize: 11,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Not attempted',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        )),
    ],
  );
}

Widget _buildRecommendationsCard(OverallPerformance performance) {
  final recommendations = _getRecommendations(performance);
  
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb, color: Colors.deepPurple, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Recommendations',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations.map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(rec['icon'], color: rec['color'], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rec['description'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
  );
}

Widget _buildLearningPatternsCard(OverallPerformance performance) {
  final totalTime = performance.totalTimeSpent;
  final hours = totalTime ~/ 3600;
  final minutes = (totalTime % 3600) ~/ 60;
  
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
            'Learning Patterns',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          // Use Wrap instead of Row to prevent overflow
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCompactPatternItem(
                Icons.access_time,
                'Total Time',
                '${hours}h ${minutes}m',
                Colors.blue,
              ),
              _buildCompactPatternItem(
                Icons.speed,
                'Avg Time',
                '${(performance.totalTimeSpent / performance.totalExams ~/ 60)}m',
                Colors.green,
              ),
              _buildCompactPatternItem(
                Icons.check_circle,
                'Correct',
                '${performance.totalCorrect}',
                Colors.green,
              ),
              _buildCompactPatternItem(
                Icons.cancel,
                'Incorrect',
                '${performance.totalIncorrect}',
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildCompactPatternItem(IconData icon, String label, String value, Color color) {
  return Container(
    width: (MediaQuery.of(context).size.width - 56) / 2, // Exactly half width minus spacing
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .05),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: .2)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
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

// Also update _getRecommendations to have shorter descriptions for mobile
List<Map<String, dynamic>> _getRecommendations(OverallPerformance performance) {
  final recommendations = <Map<String, dynamic>>[];
  
  // Check if any subject never attempted
  final unattempted = performance.subjectPerformances
      .where((s) => s.attempts == 0)
      .map((s) => s.subjectName)
      .toList();
  
  if (unattempted.isNotEmpty) {
    recommendations.add({
      'icon': Icons.assignment,
      'color': Colors.blue,
      'title': 'Complete All Subjects',
      'description': 'Try: ${unattempted.take(2).join(', ')}${unattempted.length > 2 ? '...' : ''}',
    });
  }
  
  // Check for low scores
  final lowScores = performance.subjectPerformances
      .where((s) => s.attempts > 0 && s.averageScore < 60)
      .map((s) => s.subjectName)
      .toList();
  
  if (lowScores.isNotEmpty) {
    recommendations.add({
      'icon': Icons.school,
      'color': Colors.orange,
      'title': 'Focus on Weak Areas',
      'description': 'Practice: ${lowScores.take(2).join(', ')}',
    });
  }
  
  // Check consistency
  if (performance.subjectPerformances.any((s) {
    if (s.scoreHistory.length >= 2) {
      final variance = s.scoreHistory.reduce((a,b) => a + b) / s.scoreHistory.length;
      return variance > 20;
    }
    return false;
  })) {
    recommendations.add({
      'icon': Icons.trending_up,
      'color': Colors.green,
      'title': 'Improve Consistency',
      'description': 'Practice regularly',
    });
  }
  
  // If all good
  if (recommendations.isEmpty) {
    recommendations.add({
      'icon': Icons.emoji_events,
      'color': Colors.amber,
      'title': 'Excellent Progress!',
      'description': 'Keep up the good work!',
    });
  }
  
  return recommendations;
}

  Widget _buildSummaryItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
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
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // ==================== UTILITY WIDGETS ====================
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Failed to load performance data',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics,
              size: 64,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Performance Data Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Take your first exam to see detailed performance analytics and insights.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubjectListScreen()),
              );
            },
            icon: const Icon(Icons.quiz),
            label: const Text('Start Exam'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No Insights Available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete more exams to receive personalized insights',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

// Custom painter for weekly chart
class WeeklyChartPainter extends CustomPainter {
  final List<WeeklyProgress> weeklyData;
  
  WeeklyChartPainter(this.weeklyData);
  
  @override
  void paint(Canvas canvas, Size size) {
    if (weeklyData.isEmpty) return;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final width = size.width;
    final height = size.height;
    final pointWidth = width / (weeklyData.length - 1);
    
    // Find max score for scaling
    double maxScore = 0;
    for (final week in weeklyData) {
      if (week.averageScore > maxScore) maxScore = week.averageScore;
    }
    maxScore = maxScore < 10 ? 100 : maxScore; // Default to 100 if no data
    
    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i <= 4; i++) {
      final y = height - (i * height / 4);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }
    
    // Draw line
    final path = Path();
    
    for (int i = 0; i < weeklyData.length; i++) {
      final x = i * pointWidth;
      final y = weeklyData[i].examsTaken > 0
          ? height - (weeklyData[i].averageScore / maxScore * height * 0.8) - 20
          : height - 20;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    // Draw line
    paint.color = Colors.deepPurple;
    canvas.drawPath(path, paint);
    
    // Draw points
    for (int i = 0; i < weeklyData.length; i++) {
      final x = i * pointWidth;
      final y = weeklyData[i].examsTaken > 0
          ? height - (weeklyData[i].averageScore / maxScore * height * 0.8) - 20
          : height - 20;
      
      final pointPaint = Paint()
        ..color = weeklyData[i].examsTaken > 0 ? Colors.deepPurple : Colors.grey[400]!
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
      
      if (weeklyData[i].examsTaken > 0) {
        canvas.drawCircle(Offset(x, y), 6, Paint()..color = Colors.deepPurple.withValues(alpha: .3));
      }
      
      // Draw score value
     if (weeklyData[i].examsTaken > 0) {
       final textSpan = TextSpan(
    text: '${weeklyData[i].averageScore.toStringAsFixed(0)}%',
    style: const TextStyle(
      color: Colors.deepPurple,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    ),
  );
  
  final textPainter = TextPainter(
  text: textSpan,
  textDirection: ui.TextDirection.ltr, // Use the prefix
  textAlign: TextAlign.center,
);
  
  textPainter.layout();
  
  // Ensure we don't paint outside bounds
  final offset = Offset(
    (x - textPainter.width / 2).clamp(0, size.width - textPainter.width),
    (y - 25).clamp(0, size.height - textPainter.height),
  );
  
  textPainter.paint(canvas, offset);
}
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}