import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../screens/splash_screen.dart';
import '../../screens/onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/main_shell.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/home/job_detail_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/saved/saved_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/exam/exam_screen.dart';
import '../../screens/exam/syllabus_screen.dart';
import '../../screens/premium/premium_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../models/job_model.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (ctx, state) => _buildPage(ctx, state, const SplashScreen()),
      ),
      // Onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (ctx, state) => _buildPage(ctx, state, const OnboardingScreen()),
      ),
      // Auth
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (ctx, state) => _buildPage(ctx, state, const LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        pageBuilder: (ctx, state) => _buildPage(ctx, state, const SignupScreen()),
      ),
      // Main shell with bottom nav
      ShellRoute(
        builder: (ctx, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (ctx, state) => _buildPage(ctx, state, const HomeScreen()),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            pageBuilder: (ctx, state) {
              final query = state.uri.queryParameters['q'] ?? '';
              return _buildPage(ctx, state, SearchScreen(initialQuery: query));
            },
          ),
          GoRoute(
            path: '/saved',
            name: 'saved',
            pageBuilder: (ctx, state) => _buildPage(ctx, state, const SavedScreen()),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (ctx, state) => _buildPage(ctx, state, const ProfileScreen()),
          ),
          GoRoute(
            path: '/exams',
            name: 'exams',
            pageBuilder: (ctx, state) => _buildPage(ctx, state, const ExamScreen()),
          ),
        ],
      ),
      // Job detail (outside shell for full screen)
      GoRoute(
        path: '/job/:id',
        name: 'job-detail',
        pageBuilder: (ctx, state) {
          final job = state.extra as JobModel?;
          final jobId = state.pathParameters['id']!;
          return _buildSlidePage(ctx, state, JobDetailScreen(jobId: jobId, job: job));
        },
      ),
      // Syllabus
      GoRoute(
        path: '/syllabus/:jobId',
        name: 'syllabus',
        pageBuilder: (ctx, state) {
          final job = state.extra as JobModel;
          return _buildSlidePage(ctx, state, SyllabusScreen(job: job));
        },
      ),
      // Premium
      GoRoute(
        path: '/premium',
        name: 'premium',
        pageBuilder: (ctx, state) => _buildPage(ctx, state, const PremiumScreen()),
      ),
      // Notifications
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (ctx, state) => _buildPage(ctx, state, const NotificationsScreen()),
      ),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});

CustomTransitionPage<void> _buildPage(
    BuildContext ctx, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}

CustomTransitionPage<void> _buildSlidePage(
    BuildContext ctx, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeInOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}
