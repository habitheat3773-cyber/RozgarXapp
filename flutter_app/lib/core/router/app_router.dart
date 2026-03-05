import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/home/job_detail_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/saved/saved_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../widgets/main_shell.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
          GoRoute(path: '/saved', builder: (_, __) => const SavedScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(
            path: '/job/:id',
            builder: (_, state) => JobDetailScreen(jobId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
}
