import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await AwesomeNotifications().initialize(
      // Use default app icon
      null,
      [
        NotificationChannel(
          channelKey: 'study_reminders',
          channelName: 'Study Reminders',
          channelDescription: 'Daily reminders to practice for your CS Exit Exam',
          defaultColor: const Color(0xFF4A148C),
          ledColor: const Color(0xFF4A148C),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          playSound: true,
          soundSource: 'resource://raw/notification_sound',
        ),
        NotificationChannel(
          channelKey: 'achievements',
          channelName: 'Achievements',
          channelDescription: 'Notifications when you unlock achievements',
          defaultColor: const Color(0xFFFFD700),
          ledColor: const Color(0xFFFFD700),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          playSound: true,
          soundSource: 'resource://raw/achievement_sound',
        ),
      ],
    );

    _initialized = true;
    debugPrint('✅ Notification service initialized');
  }

  Future<void> showAchievementNotification(String badgeName, String description) async {
    if (!_initialized) await initialize();

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecond,
        channelKey: 'achievements',
        title: '🏆 Achievement Unlocked!',
        body: 'You earned: $badgeName\n$description',
        bigPicture: 'asset://assets/images/achievement_badge.png',
        notificationLayout: NotificationLayout.BigPicture,
        displayOnForeground: true,
        displayOnBackground: true,
        fullScreenIntent: true,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'VIEW',
          label: 'View Achievements',
          actionType: ActionType.Default,
        ),
        NotificationActionButton(
          key: 'SHARE',
          label: 'Share',
          actionType: ActionType.Default,
        ),
      ],
    );
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!_initialized) await initialize();

    // Schedule for tomorrow if time has passed today
    var scheduledDate = DateTime.now()
        .copyWith(hour: hour, minute: minute, second: 0, millisecond: 0);
    
    if (scheduledDate.isBefore(DateTime.now())) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'study_reminders',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        displayOnForeground: true,
        displayOnBackground: true,
      ),
      schedule: NotificationCalendar.fromDate(date: scheduledDate),
    );
  }

  Future<void> showExamResultNotification({
    required String subject,
    required int score,
    required int correctCount,
    required int totalQuestions,
  }) async {
    if (!_initialized) await initialize();

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecond,
        channelKey: 'study_reminders',
        title: '📝 Exam Completed!',
        body: '$subject: $score% ($correctCount/$totalQuestions correct)',
        notificationLayout: NotificationLayout.Default,
        displayOnForeground: true,
        displayOnBackground: true,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'VIEW_RESULT',
          label: 'View Details',
          actionType: ActionType.Default,
        ),
        NotificationActionButton(
          key: 'SHARE',
          label: 'Share Result',
          actionType: ActionType.Default,
        ),
      ],
    );
  }

  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }
}