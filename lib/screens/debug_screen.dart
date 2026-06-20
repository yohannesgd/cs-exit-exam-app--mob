// screens/debug_screen.dart - Add platform info
import 'package:flutter/material.dart';
import 'dart:io';
import '../services/database_helper.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  List<Map<String, dynamic>> _results = [];
  bool _loading = true;
  String _platformInfo = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _getPlatformInfo();
  }

  void _getPlatformInfo() {
    String platform = '';
    if (Platform.isWindows) {
      platform = 'Windows';
    } else if (Platform.isMacOS) {
      platform = 'macOS';
    } else if (Platform.isLinux) {
      platform = 'Linux';
    } else if (Platform.isAndroid) {
      platform = 'Android';
    } else if (Platform.isIOS) {
      platform = 'iOS';
    }
    
    setState(() {
      _platformInfo = 'Platform: $platform';
    });
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    await DatabaseHelper.debugDatabase();
    final results = await DatabaseHelper.getAllResults();
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Database Debug')),
      body: Column(
        children: [
          // Platform info
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.computer),
                  const SizedBox(width: 8),
                  Text(_platformInfo),
                ],
              ),
            ),
          ),
          
          // Debug controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Results: ${_results.length}'),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ),
          
          // Results list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const Center(
                        child: Text('No results found in database'),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final result = _results[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ID: ${result['id']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('Subject: ${result['subject_name']}'),
                                  Text('Score: ${result['score']}%'),
                                  Text('Correct: ${result['correct_count']}'),
                                  Text('Incorrect: ${result['incorrect_count']}'),
                                  Text('Total: ${result['total_questions']}'),
                                  Text('Time: ${result['time_spent']}s'),
                                  Text(
                                    'Date: ${result['completed_at']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}