// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Comprehensive design system for Vet2U Clinic App
/// Features calming medical tones, modern Material Design 3 principles,
/// and accessibility-first approach

class AppTheme {
  // ===== COLOR SYSTEM =====
  // Primary Palette - Calming Medical Greens and Blues
  static const Color primary50 = Color(0xFFE8F5E8);
  static const Color primary100 = Color(0xFFC8E6C9);
  static const Color primary200 = Color(0xFFA5D6A7);
  static const Color primary300 = Color(0xFF81C784);
  static const Color primary400 = Color(0xFF66BB6A);
  static const Color primary500 = Color(0xFF4CAF50); // Main Primary
  static const Color primary600 = Color(0xFF43A047);
  static const Color primary700 = Color(0xFF388E3C);
  static const Color primary800 = Color(0xFF2E7D32);
  static const Color primary900 = Color(0xFF1B5E20);

  // Secondary Palette - Trustworthy Blues
  static const Color secondary50 = Color(0xFFE3F2FD);
  static const Color secondary100 = Color(0xFFBBDEFB);
  static const Color secondary200 = Color(0xFF90CAF9);
  static const Color secondary300 = Color(0xFF64B5F6);
  static const Color secondary400 = Color(0xFF42A5F5);
  static const Color secondary500 = Color(0xFF2196F3); // Main Secondary
  static const Color secondary600 = Color(0xFF1E88E5);
  static const Color secondary700 = Color(0xFF1976D2);
  static const Color secondary800 = Color(0xFF1565C0);
  static const Color secondary900 = Color(0xFF0D47A1);

  // Accent Palette - Warm Professional Oranges
  static const Color accent50 = Color(0xFFFFF3E0);
  static const Color accent100 = Color(0xFFFFE0B2);
  static const Color accent200 = Color(0xFFFFCC80);
  static const Color accent300 = Color(0xFFFFB74D);
  static const Color accent400 = Color(0xFFFFA726);
  static const Color accent500 = Color(0xFFFF9800); // Main Accent
  static const Color accent600 = Color(0xFFFB8C00);
  static const Color accent700 = Color(0xFFF57C00);
  static const Color accent800 = Color(0xFFEF6C00);
  static const Color accent900 = Color(0xFFE65100);

  // Neutral Palette - Clean and Accessible
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral800 = Color(0xFF424242);
  static const Color neutral900 = Color(0xFF212121);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF64B5F6);

  // Status Colors for Drivers
  static const Color driverAvailable = Color(0xFF4CAF50);
  static const Color driverOnRoute = Color(0xFFFF9800);
  static const Color driverArrived = Color(0xFF2196F3);
  static const Color driverOffline = Color(0xFF9E9E9E);

  // ===== ENHANCED TYPOGRAPHY SYSTEM =====
  static const String fontFamily = 'Inter'; // Modern, readable font

  // Font Sizes - Premium Scale
  static const double fontSizeXs = 12.0;
  static const double fontSizeSm = 14.0;
  static const double fontSizeBase = 16.0;
  static const double fontSizeLg = 18.0;
  static const double fontSizeXl = 20.0;
  static const double fontSize2xl = 24.0;
  static const double fontSize3xl = 30.0;
  static const double fontSize4xl = 36.0;
  static const double fontSize5xl = 48.0;

  // Font Weights - Extended Range
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;
  static const FontWeight fontWeightBlack = FontWeight.w900;

  // ===== PREMIUM SPACING SYSTEM =====
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacing2xl = 48.0;
  static const double spacing3xl = 64.0;
  static const double spacing4xl = 80.0;

  // ===== VET THEME COMPATIBILITY SPACING =====
  static const double padding = spacingMd; // 16.0 - Standard padding
  static const double paddingLarge =
      spacingLg; // 24.0 - Large padding for sections
  static const double paddingSmall =
      spacingSm; // 8.0 - Small padding for tight spaces

  // ===== ENHANCED BORDER RADIUS SYSTEM =====
  static const double borderRadiusNone = 0.0;
  static const double borderRadiusSm = 8.0; // Small elements
  static const double borderRadiusMd = 12.0; // Buttons and interactive elements
  static const double borderRadiusLg = 16.0; // Cards and containers
  static const double borderRadiusXl = 20.0; // Large containers
  static const double borderRadius2xl = 24.0; // Vet theme inspired large radius
  static const double borderRadius3xl = 32.0; // Premium large size
  static const double borderRadiusFull = 9999.0;

  // ===== VET THEME COMPATIBILITY =====
  static const double cardRadius = borderRadiusLg; // 16.0
  static const double buttonRadius = borderRadiusMd; // 12.0
  static const double smallRadius = borderRadiusSm; // 8.0
  static const double largeRadius = borderRadius2xl; // 24.0

  // Vet theme color compatibility
  static const Color background = neutral50;
  static const Color onSurfaceVariant = neutral600;
  static const Color primary = primary500;

  // ===== PREMIUM SHADOW SYSTEM =====
  static const List<BoxShadow> shadowXs = [
    BoxShadow(color: Color(0x08000000), offset: Offset(0, 1), blurRadius: 1),
  ];

  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(color: Color(0x14000000), offset: Offset(0, 2), blurRadius: 4),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 8),
  ];

  static const List<BoxShadow> shadowXl = [
    BoxShadow(color: Color(0x26000000), offset: Offset(0, 8), blurRadius: 16),
  ];

  static const List<BoxShadow> shadow2xl = [
    BoxShadow(color: Color(0x33000000), offset: Offset(0, 16), blurRadius: 24),
  ];

  // ===== VET THEME COMPATIBILITY SHADOWS =====
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0A000000), // Very subtle shadow
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Color(0x12000000), // Medium shadow for cards
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> strongShadow = [
    BoxShadow(
      color: Color(0x1F000000), // Strong shadow for emphasis
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevationShadow = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 6)),
  ];

  // ===== ANIMATION SYSTEM =====
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  static const Curve curveEaseOut = Curves.easeOutCubic;
  static const Curve curveEaseIn = Curves.easeInCubic;
  static const Curve curveBounce = Curves.elasticOut;

  // ===== LIGHT THEME =====
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    brightness: Brightness.light,

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: primary500,
      onPrimary: Colors.white,
      primaryContainer: primary100,
      onPrimaryContainer: primary800,

      secondary: secondary500,
      onSecondary: Colors.white,
      secondaryContainer: secondary100,
      onSecondaryContainer: secondary800,

      tertiary: accent500,
      onTertiary: Colors.white,
      tertiaryContainer: accent100,
      onTertiaryContainer: accent800,

      error: error,
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),

      surface: neutral50,
      onSurface: neutral900,
      surfaceVariant: neutral100,
      onSurfaceVariant: neutral700,

      outline: neutral400,
      outlineVariant: neutral300,

      shadow: neutral200,
      scrim: neutral900,

      inverseSurface: neutral800,
      onInverseSurface: neutral50,
      inversePrimary: primary400,

      surfaceTint: primary500,
    ),

    // App Bar
    appBarTheme: AppBarTheme(
      backgroundColor: primary500,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeXl,
        fontWeight: fontWeightSemiBold,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
    ),

    // Scaffold
    scaffoldBackgroundColor: neutral50,

    // Icon Theme
    iconTheme: const IconThemeData(color: neutral900),

    // Cards
    cardTheme: CardThemeData(
      color: Colors.white,
      shadowColor: neutral200,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusLg),
      ),
      margin: EdgeInsets.zero,
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary500,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: spacingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
        ),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeBase,
          fontWeight: fontWeightMedium,
        ),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary500,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: spacingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
        ),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeBase,
          fontWeight: fontWeightMedium,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary500,
        side: const BorderSide(color: primary500, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: spacingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
        ),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeBase,
          fontWeight: fontWeightMedium,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary500,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingSm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
        ),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeBase,
          fontWeight: fontWeightMedium,
        ),
      ),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: neutral100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
        borderSide: const BorderSide(color: neutral300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
        borderSide: const BorderSide(color: neutral300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
        borderSide: const BorderSide(color: primary500, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingMd,
        vertical: spacingMd,
      ),
      labelStyle: const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeBase,
        fontWeight: fontWeightMedium,
        color: neutral600,
      ),
      hintStyle: const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeBase,
        color: neutral500,
      ),
      iconColor: neutral600,
    ),

    // Bottom Navigation Bar
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primary500,
      unselectedItemColor: neutral500,
      selectedLabelStyle: const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeXs,
        fontWeight: fontWeightMedium,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeXs,
        fontWeight: fontWeightRegular,
      ),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),

    // Tab Bar
    tabBarTheme: TabBarThemeData(
      labelColor: primary500,
      unselectedLabelColor: neutral600,
      labelStyle: const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeBase,
        fontWeight: fontWeightMedium,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeBase,
        fontWeight: fontWeightRegular,
      ),
      indicatorColor: primary500,
      indicatorSize: TabBarIndicatorSize.tab,
    ),

    // Text Theme
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize4xl,
        fontWeight: fontWeightBold,
        color: neutral900,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize3xl,
        fontWeight: fontWeightBold,
        color: neutral900,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize2xl,
        fontWeight: fontWeightBold,
        color: neutral900,
        height: 1.3,
      ),
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeXl,
        fontWeight: fontWeightSemiBold,
        color: neutral900,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeLg,
        fontWeight: fontWeightSemiBold,
        color: neutral900,
        height: 1.4,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeBase,
        fontWeight: fontWeightSemiBold,
        color: neutral900,
        height: 1.4,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeLg,
        fontWeight: fontWeightMedium,
        color: neutral900,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeBase,
        fontWeight: fontWeightMedium,
        color: neutral900,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeSm,
        fontWeight: fontWeightMedium,
        color: neutral900,
        height: 1.5,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeBase,
        fontWeight: fontWeightRegular,
        color: neutral900,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeSm,
        fontWeight: fontWeightRegular,
        color: neutral900,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeXs,
        fontWeight: fontWeightRegular,
        color: neutral700,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeBase,
        fontWeight: fontWeightMedium,
        color: neutral900,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeSm,
        fontWeight: fontWeightMedium,
        color: neutral900,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeXs,
        fontWeight: fontWeightMedium,
        color: neutral700,
        height: 1.4,
      ),
    ),
  );

  // ===== DARK THEME =====
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    brightness: Brightness.dark,

    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: primary400,
      onPrimary: neutral900,
      primaryContainer: primary800,
      onPrimaryContainer: primary100,

      secondary: secondary400,
      onSecondary: neutral900,
      secondaryContainer: secondary800,
      onSecondaryContainer: secondary100,

      tertiary: accent400,
      onTertiary: neutral900,
      tertiaryContainer: accent800,
      onTertiaryContainer: accent100,

      error: errorLight,
      onError: neutral900,
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),

      surface: neutral900,
      onSurface: neutral50,
      surfaceVariant: neutral800,
      onSurfaceVariant: neutral300,

      outline: neutral500,
      outlineVariant: neutral600,

      shadow: neutral900,
      scrim: neutral50,

      inverseSurface: neutral100,
      onInverseSurface: neutral900,
      inversePrimary: primary600,

      surfaceTint: primary400,
    ),

    // App Bar
    appBarTheme: AppBarTheme(
      backgroundColor: neutral900,
      foregroundColor: neutral50,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeXl,
        fontWeight: fontWeightSemiBold,
        color: neutral50,
      ),
      iconTheme: const IconThemeData(color: neutral50),
      actionsIconTheme: const IconThemeData(color: neutral50),
    ),

    // Scaffold
    scaffoldBackgroundColor: neutral900,

    // Icon Theme
    iconTheme: const IconThemeData(color: neutral50),

    // Cards
    cardTheme: CardThemeData(
      color: neutral800,
      shadowColor: neutral900,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusLg),
      ),
      margin: EdgeInsets.zero,
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary400,
        foregroundColor: neutral900,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: spacingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
        ),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeBase,
          fontWeight: fontWeightMedium,
        ),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary400,
        foregroundColor: neutral900,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: spacingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
        ),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeBase,
          fontWeight: fontWeightMedium,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary400,
        side: const BorderSide(color: primary400, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: spacingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
        ),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeBase,
          fontWeight: fontWeightMedium,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary400,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingSm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
        ),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeBase,
          fontWeight: fontWeightMedium,
        ),
      ),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: neutral800,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
        borderSide: const BorderSide(color: neutral600),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
        borderSide: const BorderSide(color: neutral600),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
        borderSide: const BorderSide(color: primary400, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
        borderSide: const BorderSide(color: errorLight),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingMd,
        vertical: spacingMd,
      ),
      labelStyle: const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeBase,
        fontWeight: fontWeightMedium,
        color: neutral300,
      ),
      hintStyle: const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeBase,
        color: neutral500,
      ),
    ),

    // Bottom Navigation Bar
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: neutral800,
      selectedItemColor: primary400,
      unselectedItemColor: neutral400,
      selectedLabelStyle: const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeXs,
        fontWeight: fontWeightMedium,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeXs,
        fontWeight: fontWeightRegular,
      ),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),

    // Tab Bar
    tabBarTheme: TabBarThemeData(
      labelColor: primary400,
      unselectedLabelColor: neutral400,
      labelStyle: const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeBase,
        fontWeight: fontWeightMedium,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeBase,
        fontWeight: fontWeightRegular,
      ),
      indicatorColor: primary400,
      indicatorSize: TabBarIndicatorSize.tab,
    ),

    // Text Theme
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize4xl,
        fontWeight: fontWeightBold,
        color: neutral50,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize3xl,
        fontWeight: fontWeightBold,
        color: neutral50,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize2xl,
        fontWeight: fontWeightBold,
        color: neutral50,
        height: 1.3,
      ),
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeXl,
        fontWeight: fontWeightSemiBold,
        color: neutral50,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeLg,
        fontWeight: fontWeightSemiBold,
        color: neutral50,
        height: 1.4,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeBase,
        fontWeight: fontWeightSemiBold,
        color: neutral50,
        height: 1.4,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeLg,
        fontWeight: fontWeightMedium,
        color: neutral50,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeBase,
        fontWeight: fontWeightMedium,
        color: neutral50,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeSm,
        fontWeight: fontWeightMedium,
        color: neutral50,
        height: 1.5,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeBase,
        fontWeight: fontWeightRegular,
        color: neutral50,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeSm,
        fontWeight: fontWeightRegular,
        color: neutral50,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeXs,
        fontWeight: fontWeightRegular,
        color: neutral300,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeBase,
        fontWeight: fontWeightMedium,
        color: neutral50,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeSm,
        fontWeight: fontWeightMedium,
        color: neutral50,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeXs,
        fontWeight: fontWeightMedium,
        color: neutral300,
        height: 1.4,
      ),
    ),
  );

  // ===== COMPONENT STYLES =====

  // Custom Card Styles
  static CardTheme get modernCard => CardTheme(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadiusLg),
    ),
    shadowColor: Colors.transparent,
    color: Colors.white,
    margin: EdgeInsets.zero,
  );

  static CardTheme get elevatedCard => CardTheme(
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadiusLg),
    ),
    shadowColor: neutral200.withOpacity(0.3),
    color: Colors.white,
    margin: EdgeInsets.zero,
  );

  // Custom Button Styles
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: primary500,
    foregroundColor: Colors.white,
    elevation: 0,
    shadowColor: Colors.transparent,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingLg,
      vertical: spacingMd,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadiusMd),
    ),
    textStyle: const TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSizeBase,
      fontWeight: fontWeightMedium,
    ),
  );

  static ButtonStyle get secondaryButton => OutlinedButton.styleFrom(
    foregroundColor: primary500,
    side: const BorderSide(color: primary500, width: 1.5),
    padding: const EdgeInsets.symmetric(
      horizontal: spacingLg,
      vertical: spacingMd,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadiusMd),
    ),
    textStyle: const TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSizeBase,
      fontWeight: fontWeightMedium,
    ),
  );

  static ButtonStyle get ghostButton => TextButton.styleFrom(
    foregroundColor: primary500,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingMd,
      vertical: spacingSm,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadiusMd),
    ),
    textStyle: const TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSizeBase,
      fontWeight: fontWeightMedium,
    ),
  );

  // ===== UTILITY METHODS =====

  static Color getDriverStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return driverAvailable;
      case 'on_route':
      case 'on route':
        return driverOnRoute;
      case 'arrived':
        return driverArrived;
      case 'offline':
      default:
        return driverOffline;
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'completed':
        return success;
      case 'pending':
        return warning;
      case 'cancelled':
      case 'canceled':
        return error;
      default:
        return info;
    }
  }

  static BoxDecoration getGradientDecoration({
    required List<Color> colors,
    double borderRadius = borderRadiusMd,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: shadowMd,
    );
  }

  static BoxDecoration getGlassDecoration({
    double opacity = 0.1,
    double borderRadius = borderRadiusMd,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      boxShadow: shadowSm,
    );
  }
}
