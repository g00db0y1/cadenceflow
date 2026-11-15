import 'package:flutter/material.dart';

/// Clean, energetic Teal & Amber Material Design 3 theme with semantic
/// Eisenhower quadrant tokens, custom typography (`Outfit`,
/// `Plus Jakarta Sans`, `JetBrains Mono`), and full Light/Dark mode support.
class CadenceFlowTheme {
  const CadenceFlowTheme._();

  // Brand Primary & Secondary Palette
  static const Color primaryTealLight = Color(0xFF00796B);
  static const Color primaryTealDark = Color(0xFF14B8A6);
  static const Color accentAmberLight = Color(0xFFD97706);
  static const Color accentAmberDark = Color(0xFFF59E0B);

  // Surfaces
  static const Color surfaceOffWhite = Color(0xFFF5FAFA);
  static const Color surfaceCardLight = Color(0xFFFFFFFF);
  static const Color surfaceSlateDark = Color(0xFF0C1618);
  static const Color surfaceCardDark = Color(0xFF132226);

  // Eisenhower Quadrant Semantic Colors
  static const Color q1CoralRed = Color(0xFFE11D48);
  static const Color q2DeepTeal = Color(0xFF0D9488);
  static const Color q3WarmAmber = Color(0xFFD97706);
  static const Color q4CoolSlate = Color(0xFF64748B);

  static const String headingFontFamily = 'Outfit';
  static const String bodyFontFamily = 'Plus Jakarta Sans';
  static const String monoFontFamily = 'JetBrains Mono';

  static ThemeData lightTheme() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: primaryTealLight,
      brightness: Brightness.light,
      primary: primaryTealLight,
      secondary: accentAmberLight,
      surface: surfaceOffWhite,
    );

    return _buildTheme(
      colorScheme: baseScheme,
      scaffoldBg: surfaceOffWhite,
      cardColor: surfaceCardLight,
      isDark: false,
    );
  }

  static ThemeData darkTheme() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: primaryTealDark,
      brightness: Brightness.dark,
      primary: primaryTealDark,
      secondary: accentAmberDark,
      surface: surfaceSlateDark,
    );

    return _buildTheme(
      colorScheme: baseScheme,
      scaffoldBg: surfaceSlateDark,
      cardColor: surfaceCardDark,
      isDark: true,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required Color cardColor,
    required bool isDark,
  }) {
    final baseTextTheme =
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;

    final bodyTextTheme = baseTextTheme.apply(
      fontFamily: bodyFontFamily,
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    final textTheme = bodyTextTheme.copyWith(
      displaySmall: bodyTextTheme.displaySmall?.copyWith(
        fontFamily: headingFontFamily,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: bodyTextTheme.headlineMedium?.copyWith(
        fontFamily: headingFontFamily,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: bodyTextTheme.headlineSmall?.copyWith(
        fontFamily: headingFontFamily,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: bodyTextTheme.titleLarge?.copyWith(
        fontFamily: headingFontFamily,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: bodyTextTheme.titleMedium?.copyWith(
        fontFamily: headingFontFamily,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: bodyTextTheme.bodyLarge?.copyWith(
        fontFamily: bodyFontFamily,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: bodyTextTheme.bodyMedium?.copyWith(
        fontFamily: bodyFontFamily,
      ),
      labelLarge: bodyTextTheme.labelLarge?.copyWith(
        fontFamily: bodyFontFamily,
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: headingFontFamily,
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontFamily: bodyFontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  /// Monospace style (`JetBrains Mono`) for countdowns and timestamps.
  static TextStyle monoStyle(
    BuildContext context, {
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: monoFontFamily,
      fontFamilyFallback: const ['monospace'],
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
