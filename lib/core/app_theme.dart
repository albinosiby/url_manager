import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF0A0A12);
  static const Color surface = Color(0xFF1E1E2E);
  static const Color neonCyan = Color(0xFF00F2FF);
  static const Color neonPurple = Color(0xFF9D50BB);
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    primaryColor: neonCyan,
    colorScheme: const ColorScheme.dark(
      primary: neonCyan,
      secondary: neonPurple,
      surface: surface,
      onSurface: Colors.white,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 15,
        color: Colors.white.withValues(alpha: 0.8),
      ),
      bodySmall: GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: glassWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: neonCyan, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: neonCyan,
      foregroundColor: Colors.black,
      elevation: 10,
    ),
  );
}
