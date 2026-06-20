import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/database_helper.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Exam History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _showClearDialog(context),
            tooltip: 'Clear All History',
          ),
        ],
      ),
      // ValueListenableBuilder listens to the Hive box. 
      // If data is added or deleted, this UI updates instantly!
      body: ValueListenableBuilder(
        valueListenable: Hive.box('results_box').listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text("No exam history yet. Start practicing!"),
            );
          }

          // Convert Hive values to a list and sort by date descending
          final results = box.values.toList().cast<Map>();
          results.sort((a, b) => b['completed_at'].compareTo(a['completed_at']));
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = Map<String, dynamic>.from(results[index]);
              // Get the unique Hive key for this specific entry
              final itemKey = box.keyAt(index); 
              
              return Dismissible(
                key: Key(itemKey.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  box.delete(itemKey); // Deletes directly from Hive
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Exam record deleted")),
                  );
                },
                child: _buildHistoryItem(context, result, index, isDark),
              );
            }
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, Map<String, dynamic> result, int index, bool isDark) {
    final double score = result['score'] ?? 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getScoreColor(score).withValues(alpha: 0.1),
          child: Icon(Icons.assignment, color: _getScoreColor(score)),
        ),
        title: Text(
          result['subject_name'] ?? 'Unknown Subject',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("Completed: ${result['completed_at']}"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${score.toStringAsFixed(0)}%",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(score),
              ),
            ),
            Text(
              "${result['correct_count']}/${result['total_questions']}",
              style: const TextStyle(fontSize: 10, color: Colors.grey),
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

  Future<void> _showClearDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear History?"),
        content: const Text("This will permanently delete all exam records."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete All", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.clearAllResults();
    }
  }
}