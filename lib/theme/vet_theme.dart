import 'package:flutter/material.dart';

class VetTheme {
  // Enhanced Modern Color Palette - Professional Veterinary Aesthetic
  static const Color primary = Color(
    0xFF2563EB,
  ); // Modern blue - trust and reliability
  static const Color primaryLight = Color(0xFF60A5FA); // Lighter blue
  static const Color primaryDark = Color(0xFF1D4ED8); // Darker blue
  static const Color primaryContainer = Color(
    0xFFDBEAFE,
  ); // Very light blue background

  static const Color secondary = Color(0xFF64748B); // Modern slate gray
  static const Color secondaryLight = Color(0xFF94A3B8); // Lighter slate
  static const Color secondaryDark = Color(0xFF475569); // Darker slate
  static const Color secondaryContainer = Color(
    0xFFF1F5F9,
  ); // Light slate background

  static const Color accent = Color(
    0xFFF59E0B,
  ); // Warm amber - friendly and approachable
  static const Color accentLight = Color(0xFFFCD34D); // Lighter amber
  static const Color accentDark = Color(0xFFD97706); // Darker amber

  static const Color success = Color(0xFF10B981); // Modern emerald green
  static const Color warning = Color(0xFFF59E0B); // Amber for warnings
  static const Color error = Color(0xFFEF4444); // Modern red
  static const Color info = Color(0xFF3B82F6); // Bright blue for info

  // Enhanced Neutral Colors - Clean and Modern
  static const Color background = Color(
    0xFFF8FAFC,
  ); // Clean light gray background
  static const Color surface = Color(0xFFFFFFFF); // Pure white surfaces
  static const Color surfaceVariant = Color(
    0xFFF1F5F9,
  ); // Subtle surface variation
  static const Color onSurface = Color(0xFF0F172A); // Deep dark for text
  static const Color onSurfaceVariant = Color(
    0xFF64748B,
  ); // Medium gray for secondary text

  // Pet-themed accent colors - Modern and Friendly
  static const Color petPrimary = Color(0xFFF472B6); // Modern pink for pets
  static const Color petSecondary = Color(
    0xFF34D399,
  ); // Fresh green for nature/health

  // Enhanced Spacing System - More Refined
  static const double padding = 16.0; // Standard padding
  static const double paddingLarge = 24.0; // Large padding for sections
  static const double paddingSmall = 12.0; // Small padding for tight spaces

  // Modern Border Radius System
  static const double cardRadius = 16.0; // Cards and containers
  static const double buttonRadius = 12.0; // Buttons and interactive elements
  static const double smallRadius = 8.0; // Small elements
  static const double largeRadius = 24.0; // Large containers

  // Enhanced Shadow System - More Sophisticated
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

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        tertiary: accent,
        error: error,
        surface: surface,
        surfaceContainer: surfaceVariant,
        surfaceContainerHighest: surface,
        background: background,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: secondaryLight,
        outlineVariant: secondaryLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: onSurface),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        color: surface,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: BorderSide(color: secondaryLight.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: BorderSide(color: secondaryLight.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(
          color: onSurfaceVariant.withValues(alpha: 0.6),
          fontSize: 16,
        ),
        labelStyle: TextStyle(color: onSurfaceVariant, fontSize: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(smallRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.25,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: secondaryContainer,
        selectedColor: primaryContainer,
        checkmarkColor: primary,
        deleteIconColor: error,
        labelStyle: TextStyle(
          color: onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(color: primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(largeRadius),
        ),
        side: BorderSide(color: secondaryLight.withValues(alpha: 0.2)),
      ),
      dividerTheme: DividerThemeData(
        color: secondaryLight.withValues(alpha: 0.2),
        thickness: 1,
        space: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(largeRadius),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryLight,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        secondary: secondaryLight,
        tertiary: accentLight,
        error: error,
        surface: Color(0xFF1E293B),
        surfaceContainer: Color(0xFF334155),
        surfaceContainerHighest: Color(0xFF475569),
        background: Color(0xFF0F172A),
        onSurface: Color(0xFFF8FAFC),
        onSurfaceVariant: Color(0xFF94A3B8),
        outline: Color(0xFF475569),
        outlineVariant: Color(0xFF64748B),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        color: const Color(0xFF1E293B),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF334155),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: Color(0xFF475569)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: Color(0xFF475569)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: primaryLight, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(smallRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.25,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF334155),
        selectedColor: const Color(0xFF0F766E),
        checkmarkColor: primaryLight,
        deleteIconColor: error,
        labelStyle: const TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(color: primaryLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(largeRadius),
        ),
        side: const BorderSide(color: Color(0xFF475569)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF475569),
        thickness: 1,
        space: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(largeRadius),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
    );
  }

  // Helper method to get theme-aware colors
  static Color getThemeAwareColor(
    BuildContext context,
    Color lightColor,
    Color darkColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkColor : lightColor;
  }

  // Helper method to get theme-aware text color
  static Color getThemeAwareTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  // Helper method to get theme-aware icon color
  static Color getThemeAwareIconColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  // Helper method to get success color based on theme
  static Color getSuccessColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF34D399) : success;
  }

  // Helper method to get warning color based on theme
  static Color getWarningColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFFFB74D) : warning;
  }

  // Helper method to get error color based on theme
  static Color getErrorColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFF87171) : error;
  }
}
