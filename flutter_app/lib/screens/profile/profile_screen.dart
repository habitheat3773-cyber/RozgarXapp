import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/saved_provider.dart';
import '../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final saved = context.watch<SavedProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Profile'), automaticallyImplyLeading: false),
      body: ListView(
        children: [
          // User card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: auth.isLoggedIn
                ? Row(children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: auth.user?.photoURL != null ? NetworkImage(auth.user!.photoURL!) : null,
                      backgroundColor: Colors.white24,
                      child: auth.user?.photoURL == null ? const Icon(Icons.person, color: Colors.white, size: 30) : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(auth.user?.displayName ?? 'User', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(auth.user?.email ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    ])),
                  ])
                : Column(children: [
                    const Icon(Icons.person_outline, size: 48, color: Colors.white),
                    const SizedBox(height: 10),
                    const Text('Sign in to sync your saved jobs', style: TextStyle(color: Colors.white, fontSize: 15)),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () => context.read<AuthProvider>().signInWithGoogle(),
                      icon: const Icon(Icons.login),
                      label: const Text('Sign in with Google'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primary),
                    ),
                  ]),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              _statCard('Saved Jobs', '${saved.savedIds.length}', Icons.bookmark, Colors.blue),
              const SizedBox(width: 10),
              _statCard('Categories', '11', Icons.category, Colors.purple),
              const SizedBox(width: 10),
              _statCard('Active Jobs', '1000+', Icons.work, Colors.green),
            ]),
          ),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('Settings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          ),

          _tile(Icons.notifications_outlined, 'Job Alerts', 'Get notified about new jobs', Colors.orange, () {}),
          _tile(Icons.star_outline, 'Rate RozgarX', 'Love the app? Rate us!', Colors.amber, () async {
            final review = InAppReview.instance;
            if (await review.isAvailable()) review.requestReview();
          }),
          _tile(Icons.share_outlined, 'Share App', 'Share with friends', Colors.green, () {
            Share.share('Download RozgarX for latest government jobs!\nhttps://play.google.com/store/apps/details?id=com.rozgarx.app');
          }),
          _tile(Icons.privacy_tip_outlined, 'Privacy Policy', '', Colors.blue, () async {
            final uri = Uri.parse('https://rozgarx.app/privacy');
            if (await canLaunchUrl(uri)) launchUrl(uri);
          }),
          _tile(Icons.info_outline, 'About', 'Version 2.0.0', Colors.grey, () {}),

          if (auth.isLoggedIn) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton.icon(
                onPressed: () => context.read<AuthProvider>().signOut(),
                icon: const Icon(Icons.logout, color: AppTheme.error),
                label: const Text('Sign Out', style: TextStyle(color: AppTheme.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.error),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)) : null,
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }
}
