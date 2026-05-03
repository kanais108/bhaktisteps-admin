import 'package:flutter/material.dart';

class AdminTheme {
  static const primary = Color(0xFF7B1FA2);
  static const accent = Color(0xFFFFC107);
  static const background = Color(0xFFF5F5F5);
  static const card = Colors.white;

  static ThemeData light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
    ),

    appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),

    cardTheme: CardThemeData(
      color: card,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
