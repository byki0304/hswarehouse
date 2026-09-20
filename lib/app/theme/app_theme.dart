import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// HS Warehouse — refined dark AI portfolio theme.
/// Sidebar: dense charcoal panel. Main: open luminous mesh field.
class AppTheme {
  static const Color background = Color(0xFF05080F);
  static const Color sidebar = Color(0xFF0A101C);
  static const Color surface = Color(0xFF0E1624);
  static const Color surfaceElevated = Color(0xFF152033);
  static const Color mainPanel = Color(0xFF0B1220);
  static const Color neon = Color(0xFF1CE8B5);
  static const Color neonAlt = Color(0xFF5AB4FF);
  static const Color steel = Color(0xFF7E90A8);
  static const Color violet = Color(0xFF6B7CFF);
  static const Color danger = Color(0xFFFF5C7A);
  static const Color warning = Color(0xFFFFC857);
  static const Color textPrimary = Color(0xFFF2F6FC);
  static const Color textSecondary = Color(0xFF93A4BC);
  static const Color hairline = Color(0x3340E0C0);

  static TextStyle display(double size, {FontWeight weight = FontWeight.w800}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: textPrimary,
      letterSpacing: -0.8,
      height: 1.05,
    );
  }

  static TextStyle body(double size, {FontWeight weight = FontWeight.w500, Color? color}) {
    return GoogleFonts.dmSans(
      fontSize: size,
      fontWeight: weight,
      color: color ?? textPrimary,
      height: 1.35,
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: neon,
        secondary: neonAlt,
        tertiary: steel,
        surface: surface,
        error: danger,
        onPrimary: background,
        onSecondary: background,
        onSurface: textPrimary,
        onError: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: textPrimary,
        titleTextStyle: display(20, weight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: hairline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface.withValues(alpha: 0.85),
        hintStyle: body(14, color: textSecondary),
        labelStyle: body(14, color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neon, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neon,
          foregroundColor: background,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: neon.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: neonAlt),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: body(14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
