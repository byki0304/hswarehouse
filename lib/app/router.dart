import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hswarehouse/features/admin/ui/admin_page.dart';
import 'package:hswarehouse/features/auth/ui/login_page.dart';
import 'package:hswarehouse/features/guidelines/ui/guidelines_page.dart';
import 'package:hswarehouse/features/home/ui/home_page.dart';
import 'package:hswarehouse/features/upload/ui/upload_page.dart';
import 'package:hswarehouse/features/viewer/ui/viewer_page.dart';
import 'package:hswarehouse/processes/data/auth_service.dart';
import 'package:hswarehouse/shared/ui/app_shell.dart';

GoRouter createAppRouter(
  AuthService auth, {
  List<NavigatorObserver> observers = const [],
}) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    observers: observers,
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      final uploading = state.matchedLocation == '/upload';
      final admin = state.matchedLocation == '/admin';

      if (auth.loading) return null;
      if (!auth.isSignedIn && (uploading || admin)) return '/login';
      if (auth.isSignedIn && loggingIn) return '/';
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) =>
                const HomeScreen(mode: HomeFeedMode.overview),
          ),
          GoRoute(
            path: '/new',
            name: 'new',
            builder: (context, state) =>
                const HomeScreen(mode: HomeFeedMode.newest),
          ),
          GoRoute(
            path: '/popular',
            name: 'popular',
            builder: (context, state) =>
                const HomeScreen(mode: HomeFeedMode.popular),
          ),
          GoRoute(
            path: '/login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/upload',
            name: 'upload',
            builder: (context, state) => const UploadPage(),
          ),
          GoRoute(
            path: '/admin',
            name: 'admin',
            builder: (context, state) => const AdminScreen(),
          ),
          GoRoute(
            path: '/guidelines',
            name: 'guidelines',
            builder: (context, state) => const DeveloperGuidelinesScreen(),
          ),
          GoRoute(
            path: '/app/:id',
            name: 'viewer',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              final launchUrl = state.uri.queryParameters['url'] ?? '';
              final title = state.uri.queryParameters['title'] ?? 'Branch App';
              return BranchAppViewerScreen(
                appId: id,
                title: title,
                launchUrl: Uri.decodeComponent(launchUrl),
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}

/// Optional analytics observer helper for app wiring.
List<NavigatorObserver> defaultObservers(FirebaseAnalytics analytics) => [
      FirebaseAnalyticsObserver(analytics: analytics),
    ];

extension GoRouterX on BuildContext {
  AuthService get auth => read<AuthService>();
}
