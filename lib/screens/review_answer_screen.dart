import 'package:flutter/material.dart';
import '../models/question.dart';

class ReviewAnswersScreen extends StatelessWidget {
  final List<Question> questions;
  final List<int?> userAnswers; // Null if they skipped or haven't answered

  const ReviewAnswersScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Answers'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          final userAnswer = userAnswers[index];
          final isCorrect = userAnswer == question.correctAnswerIndex; // Now we use it!

          return Card(
            // Use isCorrect to highlight the border: green if right, red if wrong
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isCorrect ? Colors.green.withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Number and Topic
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Question ${index + 1}", 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(question.topic ?? "General", 
                          style: const TextStyle(fontSize: 10, color: Colors.blue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(question.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                  
                  // Options List
                  ...List.generate(question.options.length, (optIndex) {
                    return _buildOptionTile(
                      context,
                      question.options[optIndex],
                      optIndex == question.correctAnswerIndex, // Is this the right answer?
                      optIndex == userAnswer, // Did the user pick this?
                    );
                  }),
                  
                  if (question.explanation != null && question.explanation!.isNotEmpty) ...[
                    const Divider(height: 32),
                    const Text("Explanation:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(question.explanation!, 
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context, String text, bool isCorrect, bool isSelected) {
  Color? tileColor;
  IconData? icon;

  if (isCorrect) {
    // This is the right answer
    tileColor = Colors.green.withValues(alpha: 0.15);
    icon = Icons.check_circle;
  } else if (isSelected) {
    // User picked this, but isCorrect is false (implied by the 'else if')
    tileColor = Colors.red.withValues(alpha: 0.15);
    icon = Icons.cancel;
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: tileColor ?? Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: tileColor != null ? tileColor.withValues(alpha: 0.5) : Colors.grey.shade300,
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(text, style: TextStyle(
            color: isCorrect ? Colors.green : (isSelected ? Colors.red : null),
            fontWeight: (isCorrect || isSelected) ? FontWeight.bold : FontWeight.normal,
          )),
        ),
        if (icon != null) Icon(icon, size: 18, color: isCorrect ? Colors.green : Colors.red),
      ],
    ),
  );
}
}