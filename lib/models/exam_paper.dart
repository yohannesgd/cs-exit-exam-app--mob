// models/exam_paper.dart - COMPLETE FIXED VERSION

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExamQuestion {
  final int id;
  final String text;
  final List<String> options;
  final int? correctIndex;

  ExamQuestion({
    required this.id,
    required this.text,
    required this.options,
    this.correctIndex,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'options': options,
      'correctIndex': correctIndex,
    };
  }

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    return ExamQuestion(
      id: json['id'],
      text: json['text'],
      options: List<String>.from(json['options']),
      correctIndex: json['correctIndex'],
    );
  }
}

class ExamPaper {
  final String id;
  final String title;
  final int durationMinutes;
  final List<ExamQuestion> questions;
  final Map<int, String> answerKey;
  final DateTime createdAt;

  ExamPaper({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.questions,
    required this.answerKey,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Future<File> generateAnswerSheet() async {
    try {
      final pdf = pw.Document();

      // Add PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Text(
              'CS Exit Exam - Answer Sheet',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          footer: (context) => pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
          build: (context) => [
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Exam: $title'),
                      pw.Text('Date: ${_formatDate(createdAt)}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Duration: $durationMinutes minutes'),
                      pw.Text('Total Questions: ${questions.length}'),
                    ],
                  ),
                ],
              ),
            ),
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 30),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Student Name: _______________________'),
                  pw.SizedBox(height: 8),
                  pw.Text('ID Number: __________________________'),
                ],
              ),
            ),
            pw.Divider(),
            pw.SizedBox(height: 20),
            ..._buildAnswerTable(),
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Text(
              'INSTRUCTIONS:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('• Choose the best answer for each question'),
            pw.Text('• Circle the letter corresponding to your answer'),
            pw.Text('• Make sure your marks are clear and dark'),
            pw.Text('• Erase any changes completely'),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                '_________________________',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Signature',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      );

      // Save PDF to temporary directory
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/answer_sheet_$id.pdf');
      await file.writeAsBytes(await pdf.save());

      return file;
      
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      rethrow;
    }
  }

  // Helper method to build answer table
  List<pw.Widget> _buildAnswerTable() {
    final List<pw.Widget> rows = [];
    
    // Table header - FIXED: removed const from pw.TextStyle
    rows.add(
      pw.Container(
        color: PdfColors.grey300,
        padding: const pw.EdgeInsets.all(8),
        child: pw.Row(
          children: [
            pw.Expanded(
              flex: 1,
              child: pw.Text(
                'No.',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold), // Removed const
              ),
            ),
            pw.Expanded(
              flex: 4,
              child: pw.Text(
                'Question',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold), // Removed const
              ),
            ),
            pw.Expanded(
              flex: 5,
              child: pw.Text(
                'Answer Choices',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold), // Removed const
              ),
            ),
          ],
        ),
      ),
    );

    // Table rows for each question
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      
      rows.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey300),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Text('${i + 1}'),
              ),
              pw.Expanded(
                flex: 4,
                child: pw.Text(
                  question.text.length > 50
                      ? '${question.text.substring(0, 50)}...'
                      : question.text,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Expanded(
                flex: 5,
                child: pw.Row(
                  children: [
                    _buildAnswerBubble('A'),
                    _buildAnswerBubble('B'),
                    _buildAnswerBubble('C'),
                    _buildAnswerBubble('D'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return rows;
  }

  pw.Widget _buildAnswerBubble(String letter) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 4),
        child: pw.Column(
          children: [
            pw.Container(
              width: 20,
              height: 20,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: PdfColors.black),
              ),
            ),
            pw.Text(letter, style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'durationMinutes': durationMinutes,
      'questions': questions.map((q) => q.toJson()).toList(),
      'answerKey': answerKey.map((key, value) => MapEntry(key.toString(), value)),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExamPaper.fromJson(Map<String, dynamic> json) {
    return ExamPaper(
      id: json['id'],
      title: json['title'],
      durationMinutes: json['durationMinutes'],
      questions: (json['questions'] as List)
          .map((q) => ExamQuestion.fromJson(q))
          .toList(),
      answerKey: (json['answerKey'] as Map).map(
        (key, value) => MapEntry(int.parse(key), value as String),
      ),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // Generate answer key (correct answers)
  String generateAnswerKeyText() {
    final buffer = StringBuffer();
    buffer.writeln('ANSWER KEY - $title');
    buffer.writeln('Generated: ${_formatDate(DateTime.now())}');
    buffer.writeln('-' * 40);
    
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      final correctAnswer = answerKey[question.id] ?? '?';
      buffer.writeln('${i + 1}. ${_answerLetter(correctAnswer)}');
    }
    
    buffer.writeln('-' * 40);
    return buffer.toString();
  }

  String _answerLetter(String answer) {
    switch (answer.toLowerCase()) {
      case 'a': return 'A';
      case 'b': return 'B';
      case 'c': return 'C';
      case 'd': return 'D';
      default: return answer;
    }
  }
}