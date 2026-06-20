import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';

class AwesomeNotificationService {
  static final AwesomeNotificationService _instance = AwesomeNotificationService._internal();
  factory AwesomeNotificationService() => _instance;
  AwesomeNotificationService._internal();

  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // Use default icon
      [
        NotificationChannel(
          channelKey: 'study_channel',
          channelName: 'Study Reminders',
          channelDescription: 'Daily study reminders',
          defaultColor: const Color(0xFF4A148C),
          ledColor: const Color(0xFF4A148C),
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
        NotificationChannel(
          channelKey: 'achievements_channel',
          channelName: 'Achievements',
          channelDescription: 'Achievement notifications',
          defaultColor: const Color(0xFFFFD700),
          ledColor: const Color(0xFFFFD700),
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
      ],
    );
  }

  Future<void> showAchievementNotification(String badgeName) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecond,
        channelKey: 'achievements_channel',
        title: '🏆 Achievement Unlocked!',
        body: 'You earned: $badgeName',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'study_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        repeats: true,
      ),
    );
  }
}