import 'package:flutter/material.dart';

/// Tactile, dimensional Teal & Amber Material Design 3 theme with solid
/// elevated cards, layered gradients, crisp borders, and realistic depth.
class CadenceFlowTheme {
  const CadenceFlowTheme._();

  // Brand Primary & Secondary Palette
  static const Color primaryTealLight = Color(0xFF00695C);
  static const Color primaryTealDark = Color(0xFF14B8A6);
  static const Color accentAmberLight = Color(0xFFD97706);
  static const Color accentAmberDark = Color(0xFFF59E0B);

  // Layered Solid Surfaces
  static const Color surfaceOffWhite = Color(0xFFEEF5F5);
  static const Color surfaceCardLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFF7FBFB);
  static const Color surfaceSlateDark = Color(0xFF0A1214);
  static const Color surfaceCardDark = Color(0xFF132226);
  static const Color surfaceElevatedDark = Color(0xFF1A2E33);

  // Priority Semantic Colors
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
      surface: surfaceCardLight,
    );

    return _buildTheme(
      colorScheme: baseScheme,
      scaffoldBg: surfaceOffWhite,
      cardColor: surfaceCardLight,
      elevatedSurface: surfaceElevatedLight,
      isDark: false,
    );
  }

  static ThemeData darkTheme() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: primaryTealDark,
      brightness: Brightness.dark,
      primary: primaryTealDark,
      secondary: accentAmberDark,
      surface: surfaceCardDark,
    );

    return _buildTheme(
      colorScheme: baseScheme,
      scaffoldBg: surfaceSlateDark,
      cardColor: surfaceCardDark,
      elevatedSurface: surfaceElevatedDark,
      isDark: true,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required Color cardColor,
    required Color elevatedSurface,
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
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: bodyTextTheme.headlineMedium?.copyWith(
        fontFamily: headingFontFamily,
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: bodyTextTheme.headlineSmall?.copyWith(
        fontFamily: headingFontFamily,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: bodyTextTheme.titleLarge?.copyWith(
        fontFamily: headingFontFamily,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: bodyTextTheme.titleMedium?.copyWith(
        fontFamily: headingFontFamily,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: bodyTextTheme.titleSmall?.copyWith(
        fontFamily: headingFontFamily,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: bodyTextTheme.bodyLarge?.copyWith(
        fontFamily: bodyFontFamily,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: bodyTextTheme.bodyMedium?.copyWith(
        fontFamily: bodyFontFamily,
      ),
      labelLarge: bodyTextTheme.labelLarge?.copyWith(
        fontFamily: bodyFontFamily,
        fontWeight: FontWeight.w700,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.45 : 0.10),
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: headingFontFamily,
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: colorScheme.primary.withValues(alpha: 0.04),
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.55 : 0.14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark
                ? colorScheme.outlineVariant.withValues(alpha: 0.55)
                : colorScheme.primary.withValues(alpha: 0.16),
            width: 1.2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 2,
          shadowColor: colorScheme.primary.withValues(alpha: 0.35),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: elevatedSurface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.45),
            width: 1.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: colorScheme.primary,
        secondarySelectedColor: colorScheme.primary,
        checkmarkColor: colorScheme.onPrimary,
        elevation: 1,
        pressElevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          width: 1.1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: TextStyle(
          fontFamily: bodyFontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: bodyFontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colorScheme.onPrimary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.6 : 0.18),
        indicatorColor: colorScheme.primary.withValues(alpha: 0.20),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontFamily: bodyFontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  /// Rich, dimensional hero banner decoration with deep gradient and shadow.
  static BoxDecoration heroBannerDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF133A3E), Color(0xFF0B2226)]
            : const [Color(0xFF00796B), Color(0xFF004D40)],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: isDark
            ? primaryTealDark.withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.24),
        width: 1.4,
      ),
      boxShadow: [
        BoxShadow(
          color: (isDark ? Colors.black : primaryTealLight)
              .withValues(alpha: isDark ? 0.48 : 0.28),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Solid, elevated card container decoration with tactile border and depth.
  static BoxDecoration solidCardDecoration(
    BuildContext context, {
    Color? accentColor,
    double borderRadius = 20,
    bool highlighted = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? surfaceCardDark : surfaceCardLight;
    final topTint = isDark ? surfaceElevatedDark : surfaceElevatedLight;
    final borderColor = accentColor != null
        ? accentColor.withValues(alpha: highlighted ? 0.75 : 0.38)
        : (isDark
            ? theme.colorScheme.outlineVariant.withValues(alpha: 0.55)
            : theme.colorScheme.primary.withValues(alpha: 0.18));

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topTint, baseColor],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor,
        width: highlighted ? 1.8 : 1.25,
      ),
      boxShadow: [
        BoxShadow(
          color: (accentColor ?? Colors.black)
              .withValues(alpha: isDark ? 0.38 : 0.09),
          blurRadius: highlighted ? 16 : 12,
          offset: const Offset(0, 5),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  /// Tactile raised tile decoration for individual tasks, routines, and events.
  static BoxDecoration tactileTileDecoration(
    BuildContext context, {
    Color? accentColor,
    bool isCompleted = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isCompleted
        ? (isDark
            ? surfaceSlateDark.withValues(alpha: 0.65)
            : surfaceOffWhite.withValues(alpha: 0.85))
        : (isDark ? surfaceElevatedDark : surfaceCardLight);

    return BoxDecoration(
      color: fillColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: accentColor != null && !isCompleted
            ? accentColor.withValues(alpha: 0.35)
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        width: 1.2,
      ),
      boxShadow: isCompleted
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
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
