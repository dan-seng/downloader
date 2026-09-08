import 'package:flutter/material.dart';

/// Design tokens matching the SPIDEY_DLX deck design.
class SpideyColors {
  const SpideyColors._();

  // Dark Theme Palette (Default Cyber-Deck)
  static const darkBgDeep = Color(0xFF0A0E12);
  static const darkBgPanel = Color(0xFF11171E);
  static const darkBgRaised = Color(0xFF161E27);
  static const darkBgWell = Color(0xFF0D1218);
  static const darkBorder = Color(0xFF232C36);
  static const darkBorderLit = Color(0xFF2E3B47);

  // Light Theme Palette (Clean Technical Deck)
  static const lightBgDeep = Color(0xFFE9EFF5);
  static const lightBgPanel = Color(0xFFFFFFFF);
  static const lightBgRaised = Color(0xFFF1F5F9);
  static const lightBgWell = Color(0xFFF8FAFC);
  static const lightBorder = Color(0xFFCBD5E1);
  static const lightBorderLit = Color(0xFF94A3B8);

  // Accents
  static const spideyRed = Color(0xFFE8232A); // Crimson / Spidey Red
  static const spideyRedDim = Color(0xFF8C1219);
  static const spideyRedGlow = Color(0x61E8232A);
  static const spideyBlue = Color(0xFF2C5FE0); // Web Cobalt Blue
  static const spideyBlueGlow = Color(0x662C5FE0);
  static const spideyGold = Color(0xFFFFC93C); // Peak Yellow/Gold
  static const spideyGreen = Color(0xFF22C55E); // Online / Green (HTML match)

  // Dark Text
  static const darkTextHi = Color(0xFFE7F2ED);
  static const darkText = Color(0xFFB9C6C0);
  static const darkTextDim = Color(0xFF5C6A66);

  // Light Text
  static const lightTextHi = Color(0xFF0D151D);
  static const lightText = Color(0xFF334155);
  static const lightTextDim = Color(0xFF64748B);
}

/// Central theme configuration providing the SPIDEY_DLX visual language.
class AppTheme {
  const AppTheme._();

  static const primaryColor = SpideyColors.spideyRed;
  static const secondaryColor = SpideyColors.spideyBlue;
  static const accentAmber = SpideyColors.spideyGold;

  /// Dark Theme (Primary SPIDEY Deck)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: SpideyColors.spideyRed,
        secondary: SpideyColors.spideyBlue,
        tertiary: SpideyColors.spideyGold,
        surface: SpideyColors.darkBgPanel,
        surfaceContainerHighest: SpideyColors.darkBgRaised,
        outline: SpideyColors.darkBorder,
        outlineVariant: SpideyColors.darkBorderLit,
        onSurface: SpideyColors.darkTextHi,
        onSurfaceVariant: SpideyColors.darkText,
      ),
      scaffoldBackgroundColor: SpideyColors.darkBgDeep,
      fontFamily: 'monospace',
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: SpideyColors.darkBorder),
        ),
        color: SpideyColors.darkBgPanel,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: SpideyColors.darkBgWell,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: SpideyColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: SpideyColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: SpideyColors.darkBorderLit, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
            side: const BorderSide(color: SpideyColors.spideyRedDim),
          ),
          backgroundColor: const Color(0xFF1F0E11),
          foregroundColor: SpideyColors.spideyRed,
        ),
      ),
    );
  }

  /// Light Theme (Technical Companion Deck)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: SpideyColors.spideyRed,
        secondary: SpideyColors.spideyBlue,
        tertiary: SpideyColors.spideyGold,
        surface: SpideyColors.lightBgPanel,
        surfaceContainerHighest: SpideyColors.lightBgRaised,
        outline: SpideyColors.lightBorder,
        outlineVariant: SpideyColors.lightBorderLit,
        onSurface: SpideyColors.lightTextHi,
        onSurfaceVariant: SpideyColors.lightText,
      ),
      scaffoldBackgroundColor: SpideyColors.lightBgDeep,
      fontFamily: 'monospace',
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: SpideyColors.lightBorder),
        ),
        color: SpideyColors.lightBgPanel,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: SpideyColors.lightBgWell,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: SpideyColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: SpideyColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: SpideyColors.spideyRed, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
            side: const BorderSide(color: SpideyColors.spideyRed),
          ),
          backgroundColor: const Color(0xFFFFECEE),
          foregroundColor: SpideyColors.spideyRed,
        ),
      ),
    );
  }
}
