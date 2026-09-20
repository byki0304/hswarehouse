import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:hswarehouse/app/app.dart';
import 'package:hswarehouse/firebase_options.dart';
import 'package:hswarehouse/shared/config/app_env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppEnv.load();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kIsWeb) {
    FirebaseAnalytics.instance;
  }

  runApp(const HsWarehouseApp());
}
