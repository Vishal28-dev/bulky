import 'package:flutter/material.dart';

class BulkyTheme {
  static const bg = Color(0xFF101214);
  static const panel = Color(0xFF181B1F);
  static const panelAlt = Color(0xFF1F2328);
  static const accent = Color(0xFFE8A317);
  static const text = Color(0xFFF2F4F7);
  static const muted = Color(0xFF9AA3AE);
  static const danger = Color(0xFFE85D4C);
  static const ok = Color(0xFF3DDC97);

  static ThemeData data() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'Segoe UI',
    );
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: panel,
        error: danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: panel,
        foregroundColor: text,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelAlt,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        hintStyle: const TextStyle(color: muted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          minimumSize: const Size(120, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
