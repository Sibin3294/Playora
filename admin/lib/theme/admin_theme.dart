import 'package:flutter/material.dart';

class AdminColors {
  static const bg = Color(0xFF0B1020);
  static const panel = Color(0xFF151C33);
  static const border = Color(0xFF2C365C);
  static const accent = Color(0xFF33F0FF);
  static const text = Color(0xFFF4F7FF);
  static const mute = Color(0xFF9AA3C7);
  static const danger = Color(0xFFFF5D73);
  static const ok = Color(0xFF7CFF6B);
}

ThemeData buildAdminTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AdminColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AdminColors.accent,
      surface: AdminColors.panel,
      error: AdminColors.danger,
    ),
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AdminColors.text,
        fontWeight: FontWeight.w800,
        fontSize: 18,
        letterSpacing: 0.6,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0A0F1E),
      hintStyle: const TextStyle(color: AdminColors.mute),
      labelStyle: const TextStyle(color: AdminColors.mute),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AdminColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AdminColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AdminColors.accent, width: 1.4),
      ),
    ),
    cardTheme: CardTheme(
      color: AdminColors.panel,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AdminColors.border),
      ),
    ),
  );
}
