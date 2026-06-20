// lib/services/share_service.dart

import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ShareService {
  static Future<void> shareResult({
    required String subject,
    required int score,
    required int correct,
    required int total,
    required int timeSpent,
  }) async {
    final date = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    
    final message = '''
🎓 Ethiopian CS Exit Exam - Result
📚 Subject: $subject
📊 Score: $score%
✅ Correct: $correct/$total
⏱️ Time: ${_formatTime(timeSpent)}
📅 Date: $date

I'm preparing for my CS Exit Exam with this awesome app! 🇪🇹
    ''';
    
    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: 'My CS Exit Exam Result', // Optional: Used in email
      ),
    );
  }

  static Future<void> shareAchievement(String badgeName) async {
    final message = '''
🏆 I just unlocked the "$badgeName" achievement in the Ethiopian CS Exit Exam Prep App!
Ready to ace my exam! 🇪🇹
    ''';
    
    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: 'Achievement Unlocked!',
      ),
    );
  }

  static String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }
}