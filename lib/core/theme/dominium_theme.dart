import 'package:flutter/material.dart';

class DominiumTheme {
  static const black = Color(0xFF000000);
  static const red = Color(0xFF6A0912);
  static const royalBlue = Color(0xFF12264A);
  static const gold = Color(0xFFB2873F);

  static ThemeData theme({Color? primary}) {
    final accent = primary ?? red;
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: black,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: gold,
        surface: const Color(0xFF121212),
      ),
      textTheme: base.textTheme.apply(fontFamily: 'Roboto', bodyColor: Colors.white),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withOpacity(0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0A0A0A),
        indicatorColor: accent.withOpacity(0.4),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Color(0x22000000),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
    );
  }
}
