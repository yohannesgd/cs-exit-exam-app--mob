// screens/quiz_screen.dart - Real exam mode (manual check, no auto-advance)

import 'package:cs_exit_exam_app/services/error_handler.dart';
import 'package:cs_exit_exam_app/services/shuffle_service.dart';
import 'package:cs_exit_exam_app/services/haptic_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../models/subject.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final Subject subject;
  const QuizScreen({super.key, required this.subject});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  bool _showExplanation = false;     // after "Check Answer"
  int? _selectedAnswerIndex;
  Timer? _timer;
  int _timeSpent = 0;
  late List<int> _userAnswers;
  late List<bool> _answerStatus;
  final Stopwatch _stopwatch = Stopwatch();
  final ScrollController _scrollController = ScrollController();

  late Subject _shuffledSubject;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShuffledSubject();
  }

  // FIX 1: Initialize timer safely to avoid LateInitializationError
  //Timer? _timer;
  Future<void> _loadShuffledSubject() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shuffleQuestions = prefs.getBool('shuffleQuestions') ?? true;
      final shuffleOptions = prefs.getBool('shuffleOptions') ?? true;
      
      // Ensure we have questions before proceeding
      if (widget.subject.questions.isEmpty) throw Exception('No questions found');

      setState(() {
        _shuffledSubject = ShuffleService.getShuffledSubject(
          subject: widget.subject,
          shuffleQuestions: shuffleQuestions,
          shuffleOptions: shuffleOptions,
        );
        _userAnswers = List.filled(_shuffledSubject.questions.length, -1);
        _answerStatus = List.filled(_shuffledSubject.questions.length, false);
        _isLoading = false;
      });
      
      _startTimer();
      _stopwatch.start();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorOverlay(context, "Error loading quiz: $e");
    }
  }

  void _startTimer() {
  _timer?.cancel(); // Cancel any existing timer first
  _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (mounted) setState(() => _timeSpent++);
  });
}

  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$remainingSeconds';
  }

  void _nextQuestion() {
    // AUTO-RECORD any selected but unconfirmed answer before moving to next question
    if (_selectedAnswerIndex != null && !_showExplanation) {
      final currentQuestion = _shuffledSubject.questions[_currentQuestionIndex];
      final isCorrect = _selectedAnswerIndex == currentQuestion.correctAnswerIndex;
      _userAnswers[_currentQuestionIndex] = _selectedAnswerIndex!;
      _answerStatus[_currentQuestionIndex] = isCorrect;
    }

    if (_currentQuestionIndex < _shuffledSubject.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _showExplanation = false;
        _selectedAnswerIndex = null;
      });

      // Reset scroll to top
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;      
        _showExplanation = _userAnswers[_currentQuestionIndex] != -1;
        _selectedAnswerIndex = _userAnswers[_currentQuestionIndex];
      });
    }
  }

  // FIX 3: Robust Jumping Logic
  void _jumpToQuestion(int index) {
    setState(() {
      _currentQuestionIndex = index;
      _selectedAnswerIndex = _userAnswers[index] != -1 ? _userAnswers[index] : null;
      _showExplanation = _userAnswers[index] != -1;
    });
  }

void _handleCheckAnswer() {
  if (_selectedAnswerIndex == null) return;

  final currentQuestion = _shuffledSubject.questions[_currentQuestionIndex];
  final isCorrect = _selectedAnswerIndex == currentQuestion.correctAnswerIndex;

  setState(() {
    // Record the answer and the status in our lists
    _userAnswers[_currentQuestionIndex] = _selectedAnswerIndex!;
    _answerStatus[_currentQuestionIndex] = isCorrect;
    _showExplanation = true;
  });
  
  try {
    HapticService().vibrateSelection(); 
  } catch (_) {}
}
  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Exam?'),
        content: const Text('Your progress will be lost if you exit now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _finishQuiz() async {
  _stopwatch.stop();
  _timer?.cancel();
  
  // AUTO-RECORD the last question if an answer is selected but not confirmed
  if (_selectedAnswerIndex != null && !_showExplanation) {
    final currentQuestion = _shuffledSubject.questions[_currentQuestionIndex];
    final isCorrect = _selectedAnswerIndex == currentQuestion.correctAnswerIndex;
    _userAnswers[_currentQuestionIndex] = _selectedAnswerIndex!;
    _answerStatus[_currentQuestionIndex] = isCorrect;
  }
  
  // CALCULATE TOTALS HERE - This prevents the "Circling" bug
  int finalCorrect = 0;
  int finalIncorrect = 0;
  
  for (int i = 0; i < _userAnswers.length; i++) {
    if (_userAnswers[i] != -1) { // If the question was answered
      if (_answerStatus[i]) {
        finalCorrect++;
      } else {
        finalIncorrect++;
      }
    }
  }

  final int totalQuestions = _shuffledSubject.questions.length;
  // Use double for precision, then round to int
  final int finalScore = ((finalCorrect / totalQuestions) * 100).round();

  // Navigation to ResultScreen...
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => ResultScreen(
        subject: _shuffledSubject,
        score: finalScore,
        correctCount: finalCorrect,
        incorrectCount: finalIncorrect,
        totalQuestions: totalQuestions,
        timeSpent: _stopwatch.elapsed.inSeconds,
        userAnswers: _userAnswers,
        answerStatus: _answerStatus,
      ),
    ),
  );
}
    
  Widget _buildQuestionNavigation() {
    final totalQuestions = _shuffledSubject.questions.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1} of $totalQuestions',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.deepPurple[50], borderRadius: BorderRadius.circular(12)),
                  child: Text('${_answerStatus.where((status) => status == true).length}/$totalQuestions',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: totalQuestions,
              itemBuilder: (context, index) {
                final isAnswered = _userAnswers[index] != -1;
                final isCurrent = index == _currentQuestionIndex;
                final isCorrect = isAnswered && _answerStatus[index];
                return GestureDetector(
                  onTap: () => _jumpToQuestion(index),
                  child: Container(
                    width: 36,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: isCurrent ? Colors.deepPurple : (isAnswered ? (isCorrect ? Colors.green : Colors.red) : Colors.grey[200]),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isCurrent ? Colors.deepPurple : Colors.grey[400]!, width: isCurrent ? 2 : 1),
                    ),
                    child: Center(
                      child: Text('${index + 1}',
                        style: TextStyle(color: isCurrent || isAnswered ? Colors.white : Colors.black87,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12),
                      ),
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

  // Improved Navigation Buttons logic
 Widget _buildNavigationButtons() {
  final isLast = _currentQuestionIndex == _shuffledSubject.questions.length - 1;
  final bool isAnswered = _userAnswers[_currentQuestionIndex] != -1;

  return Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
          child: const Text('Prev'),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton(
          onPressed: isLast 
            ? (isAnswered || _selectedAnswerIndex != null ? _finishQuiz : null) 
            : _nextQuestion,
          style: ElevatedButton.styleFrom(
            backgroundColor: isLast ? Colors.green : null,
          ),
          child: Text(isLast ? 'Finish' : 'Next'),
        ),
      ),
    ],
  );
}

@override
void dispose() {
  _timer?.cancel(); // The '?' makes it safe if the timer is null
  _stopwatch.stop();
  _scrollController.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.subject.name)),
        body: const Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Preparing your exam...')],
        )),
      );
    }

    final currentQuestion = _shuffledSubject.questions[_currentQuestionIndex];
    final totalQuestions = _shuffledSubject.questions.length;
    final progress = (_currentQuestionIndex + 1) / totalQuestions;
    final bool isSelectionDisabled = _showExplanation || _userAnswers[_currentQuestionIndex] != -1;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.subject.name.length > 20 ? '${widget.subject.name.substring(0, 20)}...' : widget.subject.name,
              style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 2),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300],
              color: Colors.deepPurple,
              minHeight: 3,
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _showExitConfirmation(context),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.deepPurple[700] : Colors.deepPurple[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, size: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.deepPurple),
                const SizedBox(width: 4),
                Text(_formatTime(_timeSpent),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildQuestionNavigation(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Question ${_currentQuestionIndex + 1}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.deepPurple[50], borderRadius: BorderRadius.circular(12)),
                          child: Text('${_answerStatus.where((status) => status == true).length}/$totalQuestions', 
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[200]!),
                      ),
                      child: Text(currentQuestion.text, style: TextStyle(fontSize: 15, height: 1.4, color: Theme.of(context).textTheme.bodyLarge?.color)),
                    ),
                    const SizedBox(height: 20),
                    const Text('Options:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Column(
                      children: List.generate(currentQuestion.options.length, (index) {
                        final option = currentQuestion.options[index];
                        final isSelected = index == _selectedAnswerIndex;
                        final isCorrectAnswer = index == currentQuestion.correctAnswerIndex;
                        Color? backgroundColor;
                        Color? borderColor;
                        Widget? trailingIcon;
  
                        if (_showExplanation) {
                          if (isCorrectAnswer) {
                            backgroundColor = Colors.green[50];
                            borderColor = Colors.green;
                            trailingIcon = const Icon(Icons.check_circle, color: Colors.green, size: 18);
                          } else if (isSelected && !isCorrectAnswer) {
                            backgroundColor = Colors.red[50];
                            borderColor = Colors.red;
                            trailingIcon = const Icon(Icons.cancel, color: Colors.red, size: 18);
                          }
                          } else if (isSelected) {
                            backgroundColor = Colors.blue[50];
                            borderColor = Colors.blue;
                          } 
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: borderColor ?? Colors.grey[300]!,
                                width: borderColor != null ? 2 : 1,
                              ),
                            ),
                            child: ListTile(
                              onTap: isSelectionDisabled ? null : () => setState(() => _selectedAnswerIndex = index),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              // ✅ Custom leading indicator (replaces Radio)
                              leading: Container(
                                 width: 24,
                                 height: 24,
                                 decoration: BoxDecoration(
                                   shape: BoxShape.circle,
                                   color: isSelected ? Colors.deepPurple : Colors.transparent,
                                   border: Border.all(
                                     color: isSelected ? Colors.deepPurple : Colors.grey[400]!,
                                     width: 2,
                                   ),
                                 ),
                                 child: isSelected
                                 ? const Icon(Icons.check, size: 14, color: Colors.white)
                                 : null,
                              ),
                              title: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected ? Colors.deepPurple : null,
                                ),
                              ),
                              trailing: trailingIcon,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      // Only show the Confirm button if an answer is selected AND it hasn't been checked yet
                      if (_selectedAnswerIndex != null && !_showExplanation)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _handleCheckAnswer,
                            child: const Text(
                              "Confirm & Check Answer",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    if (_showExplanation) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.green[900] : Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 18),
                              SizedBox(width: 8),
                              Text('Correct Answer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            ]),
                            const SizedBox(height: 8),
                            Text(
                              '${String.fromCharCode(65 + currentQuestion.correctAnswerIndex)}. ${currentQuestion.options[currentQuestion.correctAnswerIndex]}',
                              style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color),
                           ),
                            const SizedBox(height: 12),
                            const Text('Explanation:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              currentQuestion.explanation ?? 'No explanation provided.',
                              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                            )
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, -2))],
              ),
              child: _buildNavigationButtons(),
            ),
          ],
        ),
      ),
    );
  }
}