import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Dark Minimalist Monochrome & Titanium Palette
  static const Color background = Color(0xFF0D0E12);
  static const Color surface = Color(0xFF16181F);
  static const Color surfaceLight = Color(0xFF20232E);

  // Titanium Silver & Platinum Tokens
  static const Color titaniumSilver = Color(0xFFE2E8F0);
  static const Color titaniumSlate = Color(0xFF94A3B8);
  static const Color titaniumWhite = Color(0xFFF8FAFC);
  static const Color titaniumGold = Color(0xFFF59E0B);

  // Alias tokens for app-wide compatibility
  static const Color neonCyan = Color(0xFFE2E8F0);
  static const Color neonPurple = Color(0xFF94A3B8);
  static const Color neonPink = Color(0xFFF472B6);
  static const Color neonEmerald = Color(0xFF38BDF8);
  static const Color neonGold = Color(0xFFF59E0B);

  // Glassmorphic Accents
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x26FFFFFF);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    primaryColor: titaniumSilver,
    colorScheme: const ColorScheme.dark(
      primary: titaniumSilver,
      secondary: titaniumSlate,
      surface: surface,
      onSurface: Colors.white,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineMedium: GoogleFonts.outfit(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 15,
        color: Colors.white.withOpacity(0.85),
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
        borderSide: const BorderSide(color: titaniumSilver, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: titaniumSilver,
      foregroundColor: Colors.black,
      elevation: 12,
    ),
  );

  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Dev':
        return const Color(0xFF38BDF8); // Ice Sky Blue
      case 'Work':
        return const Color(0xFF818CF8); // Soft Indigo
      case 'Finance':
        return const Color(0xFFFBBF24); // Platinum Gold
      case 'Social':
        return const Color(0xFFF472B6); // Soft Rose
      case 'Personal':
        return const Color(0xFFC084FC); // Soft Violet
      case 'Favorites':
        return titaniumGold;
      default:
        return titaniumSilver;
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Dev':
        return Icons.code_rounded;
      case 'Work':
        return Icons.work_outline_rounded;
      case 'Finance':
        return Icons.account_balance_wallet_outlined;
      case 'Social':
        return Icons.forum_outlined;
      case 'Personal':
        return Icons.person_outline_rounded;
      case 'Favorites':
        return Icons.star_rounded;
      default:
        return Icons.folder_outlined;
    }
  }
}
