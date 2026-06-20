// lib/screens/exam_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cs_exit_exam_app/services/exam_service.dart';

class ExamScreen extends StatefulWidget {
  final Map<String, dynamic> examData;
  final String examId;

  const ExamScreen({super.key, required this.examData, required this.examId});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  late List<dynamic> _questions;
  int _currentIndex = 0;
  List<int?> _userAnswers = [];
  late int _timeRemaining; // in seconds
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _questions = widget.examData['questions'];
    _userAnswers = List.filled(_questions.length, null);
    _timeRemaining = (widget.examData['timeLimit'] as int) * 60; // convert to seconds
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        _timer?.cancel();
        _submitExam(); // auto-submit when time expires
      }
    });
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _submitExam() {
    _timer?.cancel();
    // Calculate score using ExamService
    final result = ExamService().calculateScore(_userAnswers, _questions);
    // Navigate to result screen
    Navigator.pushReplacementNamed(
      context,
      '/exam_result',
      arguments: {'examData': widget.examData, 'result': result, 'answers': _userAnswers},
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.examData['title']),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_currentIndex + 1) / _questions.length,
                  backgroundColor: Colors.white24,
                  color: Colors.amber,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Question ${_currentIndex + 1}/${_questions.length}'),
                    Text('Time: ${_formatTime(_timeRemaining)}'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            question['text'],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          ...List.generate(4, (index) {
            final option = question['options'][index];
            final isSelected = _userAnswers[_currentIndex] == index;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isSelected ? Colors.blue.shade50 : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? Colors.blue : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: Text('${String.fromCharCode(65 + index)}.'),
                title: Text(option),
                onTap: () {
                  setState(() {
                    _userAnswers[_currentIndex] = index;
                  });
                },
              ),
            );
          }),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentIndex > 0)
                ElevatedButton(
                  onPressed: () => setState(() => _currentIndex--),
                  child: const Text('Previous'),
                ),
              if (_currentIndex < _questions.length - 1)
                ElevatedButton(
                  onPressed: () => setState(() => _currentIndex++),
                  child: const Text('Next'),
                )
              else
                ElevatedButton(
                  onPressed: _submitExam,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Submit Exam'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}