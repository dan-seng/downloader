import 'package:flutter/material.dart';

/// Design tokens matching the SPIDEY_DLX deck design.
class SpideyColors {
  const SpideyColors._();

  // Dark Theme Palette (Modern Obsidian Slate)
  static const darkBgDeep = Color(0xFF0D1117);
  static const darkBgPanel = Color(0xFF161B22);
  static const darkBgRaised = Color(0xFF21262D);
  static const darkBgWell = Color(0xFF0B0E14);
  static const darkBorder = Color(0xFF30363D);
  static const darkBorderLit = Color(0xFF484F58);

  // Light Theme Palette (Clean Pearl & White)
  static const lightBgDeep = Color(0xFFF6F8FA);
  static const lightBgPanel = Color(0xFFFFFFFF);
  static const lightBgRaised = Color(0xFFF0F3F6);
  static const lightBgWell = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFD0D7DE);
  static const lightBorderLit = Color(0xFFAFB8C1);

  // Accents
  static const spideyRed = Color(0xFFE8232A); // Crimson / Spidey Red
  static const spideyRedDim = Color(0xFF9E1B20);
  static const spideyRedGlow = Color(0x33E8232A);
  static const spideyBlue = Color(0xFF2C5FE0); // Cobalt Blue
  static const spideyBlueGlow = Color(0x332C5FE0);
  static const spideyGold = Color(0xFFFFC93C); // Amber / Gold
  static const spideyGreen = Color(0xFF22C55E); // Success Green

  // Dark Text
  static const darkTextHi = Color(0xFFF0F6FC);
  static const darkText = Color(0xFFC9D1D9);
  static const darkTextDim = Color(0xFF8B949E);

  // Light Text
  static const lightTextHi = Color(0xFF1F2328);
  static const lightText = Color(0xFF424A53);
  static const lightTextDim = Color(0xFF656D76);
}

/// Central theme configuration providing the SPIDEY visual language.
class AppTheme {
  const AppTheme._();

  static const primaryColor = SpideyColors.spideyRed;
  static const secondaryColor = SpideyColors.spideyBlue;
  static const accentAmber = SpideyColors.spideyGold;

  /// Dark Theme (Modern Obsidian Slate)
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
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: SpideyColors.darkBorder),
        ),
        color: SpideyColors.darkBgPanel,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SpideyColors.darkBgWell,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SpideyColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SpideyColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SpideyColors.spideyRed, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: SpideyColors.spideyRed,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  /// Light Theme (Clean Pearl)
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
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: SpideyColors.lightBorder),
        ),
        color: SpideyColors.lightBgPanel,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SpideyColors.lightBgWell,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SpideyColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SpideyColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SpideyColors.spideyRed, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: SpideyColors.spideyRed,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
