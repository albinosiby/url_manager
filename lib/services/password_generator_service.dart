import 'dart:math';
import 'package:flutter/material.dart';

class PasswordStrength {
  final String label;
  final Color color;
  final double score; // 0.0 to 1.0

  const PasswordStrength({
    required this.label,
    required this.color,
    required this.score,
  });
}

class PasswordGeneratorService {
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  static String generatePassword({int length = 16}) {
    final Random random = Random.secure();
    final String allChars = _lowercase + _uppercase + _numbers + _symbols;

    // Ensure at least one character from each set
    final List<String> result = [
      _lowercase[random.nextInt(_lowercase.length)],
      _uppercase[random.nextInt(_uppercase.length)],
      _numbers[random.nextInt(_numbers.length)],
      _symbols[random.nextInt(_symbols.length)],
    ];

    for (int i = 4; i < length; i++) {
      result.add(allChars[random.nextInt(allChars.length)]);
    }

    result.shuffle(random);
    return result.join();
  }

  static PasswordStrength calculateStrength(String password) {
    if (password.isEmpty) {
      return const PasswordStrength(
        label: 'Empty',
        color: Colors.white24,
        score: 0.0,
      );
    }

    int points = 0;
    if (password.length >= 8) points++;
    if (password.length >= 12) points++;
    if (password.length >= 16) points++;
    if (password.contains(RegExp(r'[A-Z]'))) points++;
    if (password.contains(RegExp(r'[a-z]'))) points++;
    if (password.contains(RegExp(r'[0-9]'))) points++;
    if (password.contains(RegExp(r'[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?]'))) points++;

    if (points <= 2) {
      return const PasswordStrength(
        label: 'Weak',
        color: Colors.redAccent,
        score: 0.25,
      );
    } else if (points <= 4) {
      return const PasswordStrength(
        label: 'Fair',
        color: Colors.amber,
        score: 0.50,
      );
    } else if (points <= 5) {
      return const PasswordStrength(
        label: 'Strong',
        color: Color(0xFF00FF88),
        score: 0.75,
      );
    } else {
      return const PasswordStrength(
        label: 'Ultra-Secure',
        color: Color(0xFF00F2FF),
        score: 1.0,
      );
    }
  }
}
