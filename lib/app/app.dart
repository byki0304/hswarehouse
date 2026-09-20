import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hswarehouse/app/router.dart';
import 'package:hswarehouse/app/theme/app_theme.dart';
import 'package:hswarehouse/processes/data/auth_service.dart';
import 'package:hswarehouse/processes/data/firestore_service.dart';

class HsWarehouseApp extends StatefulWidget {
  const HsWarehouseApp({super.key});

  @override
  State<HsWarehouseApp> createState() => _HsWarehouseAppState();
}

class _HsWarehouseAppState extends State<HsWarehouseApp> {
  late final AuthService _authService;
  late final FirestoreService _firestoreService;
  late final FirebaseAnalytics _analytics;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _firestoreService = FirestoreService();
    _analytics = FirebaseAnalytics.instance;
    _router = createAppRouter(
      _authService,
      observers: defaultObservers(_analytics),
    );
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: _authService),
        Provider<FirestoreService>.value(value: _firestoreService),
        // Alias for existing feature code still injecting BranchAppService
        Provider<BranchAppService>.value(value: _firestoreService),
        Provider<FirebaseAnalytics>.value(value: _analytics),
      ],
      child: MaterialApp.router(
        title: 'hswarehouse',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: _router,
      ),
    );
  }
}
