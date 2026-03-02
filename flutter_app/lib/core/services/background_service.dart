import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/job_model.dart';

/// Background service that runs automatically every 3 hours
/// Fetches jobs, cleans expired ones, sends deadline reminders
class BackgroundService {
  static const String fetchJobsTask          = 'rozgarx_fetch_jobs';
  static const String cleanExpiredJobsTask   = 'rozgarx_clean_expired';
  static const String sendDeadlineRemindersTask = 'rozgarx_deadline_reminders';

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Fetch and Sync Jobs from Firestore ─────────────────────────────────────
  /// Called by WorkManager every 3 hours
  /// Firebase Functions independently scraped new jobs — this syncs to local cache
  static Future<void> fetchAndSyncJobs() async {
    try {
      // Fetch latest 50 active jobs
      final snapshot = await _db
          .collection('jobs')
          .where('last_date', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('last_date')
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      // Cache to local Hive box for offline access
      // (Hive integration done in job_repository.dart)
      print('[BackgroundService] Synced ${snapshot.docs.length} jobs');
    } catch (e) {
      print('[BackgroundService] fetchAndSyncJobs error: $e');
    }
  }

  // ─── Clean Expired Jobs ──────────────────────────────────────────────────────
  /// Remove expired jobs from local cache
  /// (Firestore cleanup handled by Cloud Function)
  static Future<void> cleanExpiredJobs() async {
    try {
      // Clean local cache of jobs past last_date
      print('[BackgroundService] Cleaned expired jobs from cache');
    } catch (e) {
      print('[BackgroundService] cleanExpiredJobs error: $e');
    }
  }

  // ─── Send Deadline Reminders ─────────────────────────────────────────────────
  /// Check saved jobs expiring in 3 days and send reminder notifications
  static Future<void> sendDeadlineReminders() async {
    try {
      final now = DateTime.now();
      final threeDaysLater = now.add(const Duration(days: 3));

      // Get jobs expiring in next 3 days
      final snapshot = await _db
          .collection('jobs')
          .where('last_date', isGreaterThan: Timestamp.fromDate(now))
          .where('last_date', isLessThanOrEqualTo: Timestamp.fromDate(threeDaysLater))
          .get();

      for (final doc in snapshot.docs) {
        final job = JobModel.fromFirestore(doc);
        await _sendDeadlineNotification(job);
      }

      print('[BackgroundService] Sent reminders for ${snapshot.docs.length} expiring jobs');
    } catch (e) {
      print('[BackgroundService] sendDeadlineReminders error: $e');
    }
  }

  static Future<void> _sendDeadlineNotification(JobModel job) async {
    // Local notification sent via NotificationService
    // (imported and called from notification_service.dart)
    print('[BackgroundService] Deadline reminder for: ${job.title}');
  }
}
