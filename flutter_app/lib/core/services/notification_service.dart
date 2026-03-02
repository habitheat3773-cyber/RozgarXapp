import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.notification?.title}');
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Notification channels
  static const _jobsChannel = AndroidNotificationChannel(
    'rozgarx_jobs', 'Job Alerts',
    description: 'New government job notifications',
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
    showBadge: true,
  );

  static const _deadlineChannel = AndroidNotificationChannel(
    'rozgarx_deadlines', 'Deadline Reminders',
    description: 'Application deadline reminders',
    importance: Importance.defaultImportance,
    enableVibration: true,
  );

  static const _examChannel = AndroidNotificationChannel(
    'rozgarx_exams', 'Exam Schedules',
    description: 'Exam dates and admit card notifications',
    importance: Importance.defaultImportance,
  );

  static Future<void> initialize() async {
    // Background handler
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);

    // Request permissions
    final settings = await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
      provisional: false, criticalAlert: false,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // Create notification channels (Android)
    await _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_jobsChannel);
    await _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_deadlineChannel);
    await _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_examChannel);

    // Initialize plugin
    const android = AndroidInitializationSettings('@drawable/ic_notification');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // FCM foreground handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // App opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // Subscribe to default topic
    await _fcm.subscribeToTopic('all_jobs');

    debugPrint('[NotificationService] Initialized successfully');
  }

  // ─── Show Notifications ───────────────────────────────────────────────────
  static Future<void> showNewJobNotification({
    required String title,
    required String body,
    required String jobId,
    String? category,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'rozgarx_jobs', 'Job Alerts',
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFF1E3A8A),
      icon: '@drawable/ic_notification',
      channelShowBadge: true,
      styleInformation: BigTextStyleInformation(body),
      actions: [
        const AndroidNotificationAction('view_job', 'View Job', showsUserInterface: true),
        const AndroidNotificationAction('save_job', 'Save'),
      ],
    );
    final details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      jobId.hashCode,
      title,
      body,
      details,
      payload: 'job:$jobId',
    );
  }

  static Future<void> showDeadlineReminder({
    required String jobTitle,
    required int daysLeft,
    required String jobId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'rozgarx_deadlines', 'Deadline Reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      color: Color(0xFFF97316),
      icon: '@drawable/ic_notification',
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      'deadline_${jobId}'.hashCode,
      '⏰ Last ${daysLeft} Day${daysLeft > 1 ? 's' : ''} to Apply!',
      jobTitle,
      details,
      payload: 'job:$jobId',
    );
  }

  static Future<void> showExamScheduleNotification({
    required String examName,
    required DateTime examDate,
    required String jobId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'rozgarx_exams', 'Exam Schedules',
      importance: Importance.defaultImportance,
      color: Color(0xFF22C55E),
      icon: '@drawable/ic_notification',
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      'exam_${jobId}'.hashCode,
      '📋 Exam Date Announced!',
      '$examName — ${_formatDate(examDate)}',
      details,
      payload: 'job:$jobId',
    );
  }

  // ─── Topic Subscriptions ──────────────────────────────────────────────────
  static Future<void> subscribeToCategory(String category) async {
    final topic = 'cat_${category.toLowerCase().replaceAll(' ', '_').replaceAll('/', '_')}';
    await _fcm.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromCategory(String category) async {
    final topic = 'cat_${category.toLowerCase().replaceAll(' ', '_').replaceAll('/', '_')}';
    await _fcm.unsubscribeFromTopic(topic);
  }

  static Future<void> subscribeToState(String state) async {
    final topic = 'state_${state.toLowerCase().replaceAll(' ', '_')}';
    await _fcm.subscribeToTopic(topic);
  }

  // ─── FCM Token ────────────────────────────────────────────────────────────
  static Future<String?> getToken() async => await _fcm.getToken();

  static Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  // ─── Handlers ─────────────────────────────────────────────────────────────
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground: ${message.notification?.title}');
    if (message.notification != null) {
      showNewJobNotification(
        title: message.notification!.title ?? 'New Job Alert',
        body: message.notification!.body ?? '',
        jobId: message.data['job_id'] ?? '',
        category: message.data['category'],
      );
    }
  }

  static void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('[FCM] Opened from notification: ${message.data}');
    // Navigate to job detail — handled by router
  }

  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('[Notification] Tapped: ${response.payload}');
    // Navigate based on payload
  }

  // ─── Schedule ─────────────────────────────────────────────────────────────
  static Future<void> scheduleJobDeadlineReminders(
    String jobId, String jobTitle, DateTime lastDate) async {
    // 7 days before
    final sevenDays = lastDate.subtract(const Duration(days: 7));
    final threeDays = lastDate.subtract(const Duration(days: 3));
    final oneDay   = lastDate.subtract(const Duration(days: 1));

    for (final reminderDate in [sevenDays, threeDays, oneDay]) {
      if (reminderDate.isAfter(DateTime.now())) {
        final daysLeft = lastDate.difference(reminderDate).inDays;
        // Schedule using flutter_local_notifications
        // zonedSchedule requires timezone package setup
      }
    }
  }

  static String _formatDate(DateTime date) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${date.day} ${m[date.month-1]} ${date.year}';
  }
}
