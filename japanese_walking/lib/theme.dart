import 'package:flutter/material.dart';

/// 2026-style theming: dark-first, Material 3, expressive rounded shapes,
/// high-contrast accent colors per phase.
class AppTheme {
  static const fastColor = Color(0xFFFF7A59); // coral — "push"
  static const slowColor = Color(0xFF4FD8C4); // teal — "recover"

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: slowColor,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0E1116),
      fontFamily: null, // system font (SF Pro / Roboto / Segoe)
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
