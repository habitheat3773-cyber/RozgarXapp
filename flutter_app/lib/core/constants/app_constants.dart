class AppConstants {
  // App Info
  static const String appName = 'RozgarX';
  static const String appTagline = 'Sarkari Naukri, Ek Click Mein';
  static const String appVersion = '2.0.0';
  static const String packageName = 'com.rozgarx.app';
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.rozgarx.app';

  // Firestore Collections
  static const String jobsCollection = 'jobs';
  static const String usersCollection = 'users';
  static const String notificationsCollection = 'notifications';

  // Shared Prefs Keys
  static const String savedJobsKey = 'saved_jobs';
  static const String onboardingKey = 'onboarding_done';
  static const String notifEnabledKey = 'notif_enabled';
  static const String selectedCategoriesKey = 'selected_categories';

  // Notification Channels
  static const String jobAlertsChannel = 'rozgarx_jobs';
  static const String deadlineChannel = 'rozgarx_deadlines';

  // Job Categories
  static const List<String> categories = [
    'All', 'SSC', 'Railway', 'Banking', 'UPSC',
    'Defence', 'Teaching', 'Police', 'Engineering',
    'Medical', 'State PSC',
  ];

  // AdMob (replace with real IDs)
  static const String adMobAppId = 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX';
  static const String bannerAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String interstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
}
