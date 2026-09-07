import 'package:flutter/material.dart';

/// Shared learner design system for the ByteQuest mobile application.
///
/// The visual language is intentionally compact and task-first: calm blue
/// surfaces, crisp white cards, restrained depth, and clear semantic states.
/// Plus Jakarta Sans gives the app a friendly but professional learning voice.
class AppTheme {
  static const String fontFamily = 'Plus Jakarta Sans';

  /// The app's typeface is declared by name so Flutter can use an installed
  /// Plus Jakarta Sans font when available and fall back to the platform
  /// system sans-serif without performing a runtime network request. This is
  /// important for offline learners and deterministic widget tests.
  static TextStyle _sans({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // Brand colors
  static const Color primaryBlue = Color(0xFF1F5EFF);
  static const Color electricBlue = Color(0xFF4C7DFF);
  static const Color deepBlue = Color(0xFF173EA5);
  static const Color navy = Color(0xFF0B1F46);

  // Secondary Colors - Soft Accents
  static const Color softBlueAccent = Color(0xFFE7EEFF);
  static const Color skyBlue = Color(0xFF6E95FF);

  // Accent Colors - Modern Palette
  static const Color accentOrange = Color(0xFFB54708);
  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color accentGreen = Color(0xFF168A5B);
  static const Color accentYellow = Color(0xFFE7A511);
  static const Color accentRed = Color(0xFFD83B4C);

  // Background Colors - Soft & Light
  static const Color backgroundLight = Color(0xFFF4F7FC);
  static const Color backgroundOffWhite = Color(0xFFF7F9FD);
  static const Color backgroundPaleBlue = Color(0xFFEDF3FF);
  static const Color surfaceMuted = Color(0xFFF0F3F9);

  // Card Colors - Pure & Floating
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color cardLightGray = Color(0xFFF0F3F8);

  // Text Colors - Clear Hierarchy
  static const Color textDark = Color(0xFF12213A);
  static const Color textMedium = Color(0xFF53627A);
  static const Color textLight = Color(0xFF64748B);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Border & Divider Colors
  static const Color borderLight = Color(0xFFE3E8F1);
  static const Color borderMedium = Color(0xFFCAD3E1);

  // Status Colors - Soft & Clear
  static const Color successGreen = accentGreen;
  static const Color warningYellow = Color(0xFFB56C00);
  static const Color errorRed = accentRed;
  static const Color infoBlue = primaryBlue;

  // Shadow Colors - Soft & Subtle
  static Color shadowSoft = navy.withValues(alpha: 0.045);
  static Color shadowMedium = navy.withValues(alpha: 0.075);
  static Color shadowStrong = navy.withValues(alpha: 0.11);

  // Gradient Colors - Soft & Modern
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, electricBlue],
  );

  static const LinearGradient softBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentOrange, Color(0xFFEA580C)],
  );

  // Border Radius - Soft UI Standards
  static BorderRadius radiusXs = BorderRadius.circular(8);
  static BorderRadius radiusSm = BorderRadius.circular(12);
  static BorderRadius radiusMd = BorderRadius.circular(14);
  static BorderRadius radiusLg = BorderRadius.circular(16);
  static BorderRadius radiusXl = BorderRadius.circular(20);
  static BorderRadius radiusXxl = BorderRadius.circular(24);

  // Legacy names for backward compatibility
  static BorderRadius cardRadius = BorderRadius.circular(16);
  static BorderRadius buttonRadius = BorderRadius.circular(14);
  static BorderRadius inputRadius = BorderRadius.circular(14);
  static BorderRadius badgeRadius = BorderRadius.circular(20);

  // Spacing - Consistent Scale
  static const double spacingXxs = 2.0;
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;
  static const double spacingXxxl = 64.0;

  // Simulation interaction standards.
  static const double minimumTapTarget = 48.0;
  static const Duration simulationTransitionDuration =
      Duration(milliseconds: 200);

  // Shadows - Soft UI Style
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: shadowSoft,
          offset: const Offset(0, 3),
          blurRadius: 14,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: shadowMedium,
          offset: const Offset(0, 8),
          blurRadius: 22,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: shadowStrong,
          offset: const Offset(0, 10),
          blurRadius: 28,
          spreadRadius: -6,
        ),
      ];

  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: shadowMedium,
          offset: const Offset(0, 12),
          blurRadius: 32,
          spreadRadius: -8,
        ),
      ];

  // Text Styles - Plus Jakarta Sans Typography Scale
  // The scale mirrors the compact, system-style hierarchy used by modern
  // learning apps: 24–32px display, 18–22px headings, 14–16px body, and
  // 11–13px metadata. All styles remain text-scale aware through Flutter's
  // inherited MediaQuery text scaling.
  static TextStyle get displayLarge => _sans(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textDark,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle get displayMedium => _sans(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textDark,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle get displaySmall => _sans(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textDark,
        letterSpacing: -0.3,
        height: 1.3,
      );

  // Headline Styles - For section titles (18-22px)
  static TextStyle get headlineLarge => _sans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textDark,
        height: 1.3,
      );

  static TextStyle get headlineMedium => _sans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textDark,
        height: 1.3,
      );

  static TextStyle get headlineSmall => _sans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textDark,
        height: 1.4,
      );

  // Title Styles - For card titles (16-17px)
  static TextStyle get titleLarge => _sans(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textDark,
        height: 1.4,
      );

  static TextStyle get titleMedium => _sans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textDark,
        height: 1.4,
      );

  static TextStyle get titleSmall => _sans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textDark,
        height: 1.4,
      );

  // Body Styles - For main content (14-16px)
  static TextStyle get bodyLarge => _sans(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textMedium,
        height: 1.6,
      );

  static TextStyle get bodyMedium => _sans(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: textMedium,
        height: 1.5,
      );

  static TextStyle get bodySmall => _sans(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textMedium,
        height: 1.5,
      );

  // Label Styles - For buttons and small headers (12-14px)
  static TextStyle get labelLarge => _sans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textDark,
        letterSpacing: 0.3,
        height: 1.4,
      );

  static TextStyle get labelMedium => _sans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textMedium,
        letterSpacing: 0.2,
        height: 1.4,
      );

  static TextStyle get labelSmall => _sans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textLight,
        letterSpacing: 0.2,
        height: 1.3,
      );

  // Caption Styles - For helper text and metadata (11-12px)
  static TextStyle get caption => _sans(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textLight,
        height: 1.4,
      );

  static TextStyle get captionSmall => _sans(
        fontSize: 11,
        fontWeight: FontWeight.normal,
        color: textLight,
        height: 1.3,
      );

  /// The single Material text-role source of truth for screens and controls.
  ///
  /// Individual surfaces may still use the named AppTheme getters when they
  /// need a color variant (for example, white text on a primary surface), but
  /// they should not invent a new font family or arbitrary size.
  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );

  // Theme Data
  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
      primary: primaryBlue,
      secondary: accentPurple,
      surface: cardWhite,
      error: errorRed,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: fontFamily,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textDark),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: headlineMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: buttonRadius,
          ),
          textStyle: _sans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardWhite,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        hintStyle: _sans(
          color: textLight,
          fontSize: 15,
          fontWeight: FontWeight.normal,
        ),
        labelStyle: _sans(
          color: textMedium,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shadowColor: shadowSoft,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: const BorderSide(color: borderLight),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: borderMedium),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          minimumSize: const Size(minimumTapTarget, minimumTapTarget),
          shape: RoundedRectangleBorder(borderRadius: radiusSm),
          textStyle: labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textDark,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: radiusSm),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardWhite,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: labelSmall,
        unselectedLabelStyle: labelSmall.copyWith(fontWeight: FontWeight.w500),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: softBlueAccent,
        labelStyle: _sans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: primaryBlue,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryBlue,
        linearTrackColor: softBlueAccent,
        circularTrackColor: softBlueAccent,
        linearMinHeight: 7,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: navy,
        contentTextStyle: bodyMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: radiusSm),
        insetPadding: const EdgeInsets.all(16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radiusLg),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardWhite,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: labelMedium.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: labelMedium,
        labelColor: primaryBlue,
        unselectedLabelColor: textMedium,
        dividerColor: Colors.transparent,
      ),
    );
  }
}
