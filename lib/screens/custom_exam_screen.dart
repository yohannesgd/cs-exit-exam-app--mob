// screens/custom_exam_screen.dart

import 'dart:async';
import 'package:cs_exit_exam_app/models/question.dart';
import 'package:flutter/material.dart';

import '../models/subject.dart';
import '../models/exam_config.dart';
import 'result_screen.dart';

class CustomExamScreen extends StatefulWidget {
  final ExamConfig examConfig;
  final List<Map<String, dynamic>> questions;
  
  const CustomExamScreen({
    super.key,
    required this.examConfig,
    required this.questions,
  });

  @override
  State<CustomExamScreen> createState() => _CustomExamScreenState();
}

class _CustomExamScreenState extends State<CustomExamScreen> {
  int _currentIndex = 0;
  int _correctCount = 0;
  late Timer _timer;
  int _secondsRemaining = 0;

  // tracking answer selection for current question
  bool _isAnswered = false;
  int? _selectedOption;
  
  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.examConfig.timeLimitMinutes * 60;
    _startTimer();
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer.cancel();
          _finishExam();
        }
      });
    });
  }
  
  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  void _finishExam() {
    // stop timer if still running
    if (_timer.isActive) {
      _timer.cancel();
    }

    final total = widget.questions.length;
    final score = total > 0 ? (_correctCount / total * 100).round() : 0;
    final incorrect = total - _correctCount;
    final timeSpent = widget.examConfig.timeLimitMinutes * 60 - _secondsRemaining;

    // create a dummy subject for mixed/custom exam
    final mixedSubject = Subject(
      id: -1,
      name: widget.examConfig.name,
      description: 'Custom exam',
      questions: [],
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          subject: mixedSubject,
          score: score,
          correctCount: _correctCount,
          incorrectCount: incorrect,
          totalQuestions: total,
          timeSpent: timeSpent,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final current = widget.questions[_currentIndex];
    final question = current['question'] as Question;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.examConfig.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_currentIndex + 1) / widget.questions.length,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_currentIndex + 1}/${widget.questions.length}'),
                    Text('Time: ${_formatTime(_secondsRemaining)}'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // options list
            ...List.generate(question.options.length, (idx) {
              final optionText = question.options[idx];
              final isSelected = _selectedOption == idx;
              Color? tileColor;
              if (_isAnswered) {
                if (idx == question.correctAnswerIndex) {
                  tileColor = Colors.green.shade200;
                } else if (isSelected) {
                  tileColor = Colors.red.shade200;
                }
              } else if (isSelected) {
                tileColor = Colors.blue.shade100;
              }

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tileColor,
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: _isAnswered
                      ? null
                      : () {
                          setState(() {
                            _selectedOption = idx;
                          });
                        },
                  child: Text(optionText),
                ),
              );
            }),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentIndex > 0)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentIndex--;
                        _isAnswered = false;
                        _selectedOption = null;
                      });
                    },
                    child: const Text('Previous'),
                  ),
                ElevatedButton(
                  onPressed: _selectedOption == null
                      ? null
                      : () {
                          if (!_isAnswered) {
                            // grade current answer
                            setState(() {
                              _isAnswered = true;
                              if (_selectedOption == question.correctAnswerIndex) {
                                _correctCount++;
                              }
                            });
                          } else {
                            // move next or finish
                            if (_currentIndex < widget.questions.length - 1) {
                              setState(() {
                                _currentIndex++;
                                _isAnswered = false;
                                _selectedOption = null;
                              });
                            } else {
                              _finishExam();
                            }
                          }
                        },
                  child: Text(_isAnswered
                      ? (_currentIndex < widget.questions.length - 1 ? 'Next' : 'Finish')
                      : 'Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}