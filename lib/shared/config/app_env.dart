import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to secrets / config from `.env.local` (and `.env.example` fallback).
///
/// Usage:
/// ```dart
/// final key = AppEnv.geminiApiKey;
/// final driveUrl = AppEnv.googleDriveWebAppUrl;
/// ```
class AppEnv {
  AppEnv._();

  static const String localFile = '.env.local';
  static const String exampleFile = '.env.example';

  /// Loads env files once at startup.
  /// Prefers `.env.local`, falls back to `.env.example`.
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: localFile, isOptional: true);
    } catch (_) {}

    if (dotenv.env.isEmpty) {
      try {
        await dotenv.load(fileName: exampleFile, isOptional: true);
      } catch (_) {}
    }
  }

  static String _get(String key) {
    final fromDotenv = dotenv.maybeGet(key)?.trim();
    if (fromDotenv != null && fromDotenv.isNotEmpty) return fromDotenv;
    return String.fromEnvironment(key, defaultValue: '').trim();
  }

  // --- User secrets (from .env.local) ---

  /// Gemini API Key
  static String get geminiApiKey => _get('GEMINI_API_KEY');

  /// OAuth 클라이언트 ID (Google / Firebase Web client ID)
  static String get oauthClientId => _get('OAUTH_CLIENT_ID');

  /// Google Drive 배포 ID
  static String get googleDriveDeploymentId =>
      _get('GOOGLE_DRIVE_DEPLOYMENT_ID');

  /// Google Drive 웹앱 URL
  static String get googleDriveWebAppUrl => _get('GOOGLE_DRIVE_WEBAPP_URL');

  /// Google Drive 라이브러리 URL
  static String get googleDriveLibraryUrl => _get('GOOGLE_DRIVE_LIBRARY_URL');

  // --- Optional Firebase overrides ---

  static String get firebaseApiKey => _get('FIREBASE_API_KEY');
  static String get firebaseAuthDomain => _get('FIREBASE_AUTH_DOMAIN');
  static String get firebaseProjectId => _get('FIREBASE_PROJECT_ID');
  static String get firebaseStorageBucket => _get('FIREBASE_STORAGE_BUCKET');
  static String get firebaseMessagingSenderId =>
      _get('FIREBASE_MESSAGING_SENDER_ID');
  static String get firebaseAppId => _get('FIREBASE_APP_ID');
  static String get firebaseMeasurementId => _get('FIREBASE_MEASUREMENT_ID');

  static bool get hasGeminiApiKey => geminiApiKey.isNotEmpty;
  static bool get hasOauthClientId => oauthClientId.isNotEmpty;
  static bool get hasGoogleDriveWebApp => googleDriveWebAppUrl.isNotEmpty;
}
