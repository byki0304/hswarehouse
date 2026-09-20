// File generated for Firebase project hswarehouse.
// Web config matches Firebase Console SDK snippet exactly.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
        return web;
      case TargetPlatform.linux:
        return web;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// Web app: 1:584793321765:web:1abb60d10b26f7b9feeacc
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA82mdwO9wIuZGhgy12_vLnqgXSB9fFtG8',
    authDomain: 'hswarehouse.firebaseapp.com',
    projectId: 'hswarehouse',
    storageBucket: 'hswarehouse.firebasestorage.app',
    messagingSenderId: '584793321765',
    appId: '1:584793321765:web:1abb60d10b26f7b9feeacc',
    measurementId: 'G-YZDQYCTQYZ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAzOXCtvo530NzUjWsstUNzFaRoiBXmfTg',
    appId: '1:584793321765:android:271d1affe6e004d1feeacc',
    messagingSenderId: '584793321765',
    projectId: 'hswarehouse',
    storageBucket: 'hswarehouse.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDp49jGL8z8ktp_bepuUT3IkerzF0uulK0',
    appId: '1:584793321765:ios:9594baeb9ffab71bfeeacc',
    messagingSenderId: '584793321765',
    projectId: 'hswarehouse',
    storageBucket: 'hswarehouse.firebasestorage.app',
    iosBundleId: 'com.hswarehouse.hswarehouse',
  );
}
