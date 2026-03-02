import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> initialize() async {
    await _analytics.setAnalyticsCollectionEnabled(true);
  }

  static Future<void> logJobView(String jobId, String category) async {
    await _analytics.logEvent(
      name: 'job_view',
      parameters: {'job_id': jobId, 'category': category},
    );
  }

  static Future<void> logJobApply(String jobId, String category) async {
    await _analytics.logEvent(
      name: 'job_apply_click',
      parameters: {'job_id': jobId, 'category': category},
    );
  }

  static Future<void> logSearch(String query) async {
    await _analytics.logSearch(searchTerm: query);
  }

  static Future<void> logJobSave(String jobId) async {
    await _analytics.logEvent(name: 'job_save', parameters: {'job_id': jobId});
  }

  static Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  static Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  static Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  static Future<void> logNotificationOpened(String type) async {
    await _analytics.logEvent(
      name: 'notification_opened',
      parameters: {'type': type},
    );
  }

  static Future<void> setUserProperties({
    required String state,
    required String qualification,
    required bool isPremium,
  }) async {
    await _analytics.setUserProperty(name: 'preferred_state', value: state);
    await _analytics.setUserProperty(name: 'qualification', value: qualification);
    await _analytics.setUserProperty(name: 'is_premium', value: isPremium.toString());
  }
}
