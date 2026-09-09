import 'package:flutter/material.dart';

/// Design tokens matching the pure monochrome (Black & White) deck design.
class SpideyColors {
  const SpideyColors._();

  // Dark Theme Palette (Pure Monochrome Black)
  static const darkBgDeep = Color(0xFF000000);
  static const darkBgPanel = Color(0xFF111111);
  static const darkBgRaised = Color(0xFF1C1C1C);
  static const darkBgWell = Color(0xFF080808);
  static const darkBorder = Color(0xFF2C2C2C);
  static const darkBorderLit = Color(0xFF444444);

  // Light Theme Palette (Warm Off-White #FAF9F6)
  static const lightBgDeep = Color(0xFFFAF9F6);
  static const lightBgPanel = Color(0xFFFAF9F6);
  static const lightBgRaised = Color(0xFFEDEAE3);
  static const lightBgWell = Color(0xFFFAF9F6);
  static const lightBorder = Color(0xFFD8D4CA);
  static const lightBorderLit = Color(0xFFB8B4AA);

  // Monochrome Accents (Zero color: Pure Black, White, Grays)
  static const spideyRed = Color(0xFFFFFFFF); // Primary high-contrast accent
  static const spideyRedDim = Color(0xFF777777);
  static const spideyRedGlow = Color(0x22FFFFFF);
  static const spideyBlue = Color(0xFFD0D0D0); // Secondary clean silver
  static const spideyBlueGlow = Color(0x22CCCCCC);
  static const spideyGold = Color(0xFFAAAAAA); // Neutral mid gray
  static const spideyGreen = Color(0xFFE8E8E8); // Bright silver

  // Dark Text
  static const darkTextHi = Color(0xFFFFFFFF);
  static const darkText = Color(0xFFCCCCCC);
  static const darkTextDim = Color(0xFF777777);

  // Light Text
  static const lightTextHi = Color(0xFF000000);
  static const lightText = Color(0xFF333333);
  static const lightTextDim = Color(0xFF777777);
}

/// Central theme configuration providing the pure monochrome visual language.
class AppTheme {
  const AppTheme._();

  static const primaryColor = SpideyColors.spideyRed;
  static const secondaryColor = SpideyColors.spideyBlue;
  static const accentAmber = SpideyColors.spideyGold;

  /// Dark Theme (Pure Monochrome Black)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        secondary: Color(0xFFCCCCCC),
        tertiary: Color(0xFF888888),
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
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
    );
  }

  /// Light Theme (Pure Monochrome White)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        secondary: Color(0xFF333333),
        tertiary: Color(0xFF777777),
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
          borderSide: const BorderSide(color: Colors.black, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
