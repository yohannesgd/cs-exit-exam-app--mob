// screens/contribute_screen.dart - COMPLETE FIXED VERSION

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ContributeScreen extends StatefulWidget {
  const ContributeScreen({super.key});

  @override
  State<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends State<ContributeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();
  final _explanationController = TextEditingController();
  final _contextController = TextEditingController();
  
  String _selectedSubject = 'Programming';
  int _selectedDifficulty = 2;
  int _correctAnswer = 0;
  String _userName = '';
  
  final List<String> _subjects = [
    'Programming', 'Database', 'Networking', 'Architecture', 
    'Intelligent Systems', 'Project Management', 'Mobile Dev',
    'Cloud Computing', 'Cyber Security', 'Machine Learning', 
    'Internet of Things', 'Data Science', 'Blockchain',
    'Quantum Computing', 'Game Development', 'DevOps'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Student';
    });
  }

  Future<void> _submitQuestion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Create question object
      final question = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'subject': _selectedSubject,
        'difficulty': _selectedDifficulty,
        'question_text': _questionController.text.trim(),
        'option_a': _optionAController.text.trim(),
        'option_b': _optionBController.text.trim(),
        'option_c': _optionCController.text.trim(),
        'option_d': _optionDController.text.trim(),
        'correct_index': _correctAnswer,
        'explanation': _explanationController.text.trim(),
        'ethiopian_context': _contextController.text.trim(),
        'submitted_by': _userName,
        'submission_date': DateTime.now().toIso8601String(),
        'status': 'pending',
      };

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      final String? existing = prefs.getString('pending_questions');
      List<dynamic> pendingQuestions = [];
      
      if (existing != null) {
        pendingQuestions = json.decode(existing);
      }
      
      pendingQuestions.add(question);
      await prefs.setString('pending_questions', json.encode(pendingQuestions));

      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);

      // Show success message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thank You! 🇪🇹'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, size: 50, color: Colors.amber),
              SizedBox(height: 16),
              Text(
                'Your question has been submitted for review.\n\n'
                'If approved, you will receive:',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text('• Contributor badge in your profile'),
              Text('• Name mentioned in question credit'),
              Text('• Chance to win monthly prizes'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      );

      // Clear form
      _clearForm();

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting question: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearForm() {
    _questionController.clear();
    _optionAController.clear();
    _optionBController.clear();
    _optionCController.clear();
    _optionDController.clear();
    _explanationController.clear();
    _contextController.clear();
    setState(() {
      _selectedSubject = 'Programming';
      _selectedDifficulty = 2;
      _correctAnswer = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contribute a Question'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          TextButton.icon(
            onPressed: _submitQuestion,
            icon: Icon(Icons.send, color: Theme.of(context).colorScheme.onPrimary),
            label: Text('Submit', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Earn Recognition!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Your questions help thousands of Ethiopian students.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Subject dropdown - FIXED: removed const
            DropdownButtonFormField<String>(
              initialValue: _selectedSubject,
              decoration: const InputDecoration( // Removed const
                labelText: 'Subject',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              items: _subjects.map((subject) {
                return DropdownMenuItem(
                  value: subject,
                  child: Text(subject),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedSubject = value!),
            ),
            const SizedBox(height: 12),

            // Difficulty slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Difficulty: ${_getDifficultyText(_selectedDifficulty)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Slider(
                  value: _selectedDifficulty.toDouble(),
                  min: 1,
                  max: 3,
                  divisions: 2,
                  label: _getDifficultyText(_selectedDifficulty),
                  onChanged: (value) {
                    setState(() {
                      _selectedDifficulty = value.round();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Question text
            TextFormField(
              controller: _questionController,
              decoration: const InputDecoration( // Removed const
                labelText: 'Question',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.question_mark),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a question';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Option A - FIXED: using Icons.looks_one instead of Icons.a
            TextFormField(
              controller: _optionAController,
              decoration: const InputDecoration(
                labelText: 'Option A',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.looks_one),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            
            // Option B - FIXED: using Icons.looks_two
            TextFormField(
              controller: _optionBController,
              decoration: const InputDecoration(
                labelText: 'Option B',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.looks_two),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            
            // Option C - FIXED: using Icons.looks_3
            TextFormField(
              controller: _optionCController,
              decoration: const InputDecoration(
                labelText: 'Option C',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.looks_3),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            
            // Option D - FIXED: using Icons.looks_4
            TextFormField(
              controller: _optionDController,
              decoration: const InputDecoration(
                labelText: 'Option D',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.looks_4),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Correct answer dropdown
            DropdownButtonFormField<int>(
              initialValue: _correctAnswer,
              decoration: const InputDecoration(
                labelText: 'Correct Answer',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.check_circle),
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text('A - First option')),
                DropdownMenuItem(value: 1, child: Text('B - Second option')),
                DropdownMenuItem(value: 2, child: Text('C - Third option')),
                DropdownMenuItem(value: 3, child: Text('D - Fourth option')),
              ],
              onChanged: (value) => setState(() => _correctAnswer = value!),
            ),
            const SizedBox(height: 12),

            // Explanation - FIXED: using Icons.description
            TextFormField(
              controller: _explanationController,
              decoration: const InputDecoration(
                labelText: 'Explanation (why answer is correct)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please provide an explanation';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Ethiopian context
            TextFormField(
              controller: _contextController,
              decoration: const InputDecoration(
                labelText: 'Ethiopian Context (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map),
                hintText: 'e.g., Commercial Bank of Ethiopia, Ethio Telecom...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Guidelines
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Guidelines:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('• Questions should be accurate', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    Text('• Include Ethiopian context when possible', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    Text('• Explanations help students learn', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    Text('• Submitted questions are reviewed', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDifficultyText(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'Easy';
      case 2:
        return 'Medium';
      case 3:
        return 'Hard';
      default:
        return 'Medium';
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _explanationController.dispose();
    _contextController.dispose();
    super.dispose();
  }
}