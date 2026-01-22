import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:civicfix/services/auth_service.dart';
import 'package:civicfix/screens/auth/login_screen.dart';
import 'package:civicfix/screens/auth/signup_screen.dart';
import 'package:civicfix/screens/citizen/home_screen.dart';
import 'package:civicfix/screens/citizen/report_issue_screen.dart';
import 'package:civicfix/screens/citizen/complaint_detail_screen.dart';
import 'package:civicfix/screens/citizen/gamification_screen.dart';
import 'package:civicfix/models/complaint_model.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final authService = AuthService();
      final isLoggedIn = authService.isLoggedIn;
      final isLoading = authService.isLoading;

      if (isLoading) return null;

      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup;

      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }

      if (isLoggedIn && isAuthRoute) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SignupScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: HomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.reportIssue,
        name: 'report-issue',
        pageBuilder: (context, state) => const MaterialPage(
          child: ReportIssueScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.complaintDetail,
        name: 'complaint-detail',
        pageBuilder: (context, state) {
          final complaint = state.extra as ComplaintModel;
          return MaterialPage(
            child: ComplaintDetailScreen(complaint: complaint),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.gamification,
        name: 'gamification',
        pageBuilder: (context, state) => const MaterialPage(
          child: GamificationScreen(),
        ),
      ),
    ],
  );
}

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String reportIssue = '/report-issue';
  static const String complaintDetail = '/complaint-detail';
  static const String gamification = '/gamification';
}
