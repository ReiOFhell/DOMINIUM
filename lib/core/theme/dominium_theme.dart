import 'package:flutter/material.dart';

class DominiumTheme {
  static const black = Color(0xFF000000);
  static const red = Color(0xFF6A0912);
  static const gold = Color(0xFFB2873F);

  static ThemeData get theme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: black,
      colorScheme: base.colorScheme.copyWith(
        primary: red,
        secondary: gold,
        surface: const Color(0xFF121212),
      ),
      textTheme: base.textTheme.apply(fontFamily: 'Roboto', bodyColor: Colors.white),
      cardTheme: CardTheme(
        elevation: 0,
        color: Colors.white.withOpacity(0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0A0A0A),
        indicatorColor: red.withOpacity(0.4),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Color(0x22000000),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: red,
        foregroundColor: Colors.white,
      ),
    );
  }
}
