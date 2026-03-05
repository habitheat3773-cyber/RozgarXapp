import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static final _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // Request permissions
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Local notifications setup
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    // Create channels
    const jobChannel = AndroidNotificationChannel(
      'rozgarx_jobs',
      'Job Alerts',
      description: 'New government job notifications',
      importance: Importance.high,
    );
    const deadlineChannel = AndroidNotificationChannel(
      'rozgarx_deadlines',
      'Deadline Reminders',
      description: 'Application deadline reminders',
      importance: Importance.defaultImportance,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(jobChannel);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(deadlineChannel);

    // FCM foreground handler
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        _plugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'rozgarx_jobs',
              'Job Alerts',
              channelDescription: 'New government job notifications',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // Subscribe to topics
    await _messaging.subscribeToTopic('all_jobs');
  }

  static Future<void> showDeadlineReminder(String title, String body) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'rozgarx_deadlines',
          'Deadline Reminders',
          importance: Importance.defaultImportance,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
