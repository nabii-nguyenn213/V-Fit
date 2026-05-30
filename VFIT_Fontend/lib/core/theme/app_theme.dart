import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const _primary = Color(0xFF00F5FF);
  static const _secondary = Color(0xFFFF2BD6);
  static const _tertiary = Color(0xFFD8FF3E);
  static const _darkBackground = Color(0xFF070711);
  static const _darkSurface = Color(0xFF111225);
  static const _lightBackground = Color(0xFFF8FAFF);
  static const _lightSurface = Color(0xFFFFFFFF);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F766E), // Modern Teal
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF0F766E),
      onPrimary: const Color(0xFFFFFFFF),
      secondary: const Color(0xFF10B981), // Emerald
      surface: _lightSurface,
      onSurface: const Color(0xFF09090B), // Zinc 950
      surfaceContainerHighest: const Color(0xFFF4F4F5), // Zinc 100
      onSurfaceVariant: const Color(0xFF71717A), // Zinc 500
      outlineVariant: const Color(0xFFE4E4E7), // Zinc 200
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: _lightBackground,
      textTheme: _textTheme(const Color(0xFF101321)),
      inputDecorationTheme: _inputDecorationTheme(scheme),
      cardTheme: _cardTheme(scheme),
      chipTheme: _chipTheme(scheme),
      filledButtonTheme: _filledButtonTheme(),
      listTileTheme: _listTileTheme(scheme),
      navigationBarTheme: _navigationBarTheme(scheme),
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _primary, // 06B6D4
      onPrimary: Color(0xFF082F49),
      secondary: _secondary,
      onSecondary: Color(0xFF25001E),
      error: Color(0xFFEF4444),
      onError: Color(0xFFFFFFFF),
      surface: _darkSurface,
      onSurface: Color(0xFFFAFAFA),
      surfaceContainerHighest: Color(0xFF27272A),
      onSurfaceVariant: Color(0xFFA1A1AA),
      outline: Color(0xFF52525B),
      outlineVariant: Color(0xFF27272A),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFFAFAFA),
      onInverseSurface: Color(0xFF09090B),
      inversePrimary: Color(0xFF0F766E),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: _darkBackground,
      textTheme: _textTheme(scheme.onSurface),
      inputDecorationTheme: _inputDecorationTheme(scheme),
      cardTheme: _cardTheme(scheme),
      chipTheme: _chipTheme(scheme),
      filledButtonTheme: _filledButtonTheme(),
      listTileTheme: _listTileTheme(scheme),
      navigationBarTheme: _navigationBarTheme(scheme),
    );
  }

  static TextTheme _textTheme(Color color) {
    // Use Plus Jakarta Sans as the base font for all Material widgets.
    // Screens that need Inter or metric styles still use AppTypography helpers.
    return GoogleFonts.plusJakartaSansTextTheme(
      Typography.material2021().black,
    ).apply(
      bodyColor: color,
      displayColor: color,
    );
  }

  static InputDecorationTheme _inputDecorationTheme(ColorScheme scheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      prefixIconColor: scheme.primary,
      suffixIconColor: scheme.secondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 1.7),
      ),
    );
  }

  static CardThemeData _cardTheme(ColorScheme scheme) {
    return CardThemeData(
      elevation: 0,
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // More modern, rounder corners
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.8),
          width: 0.8,
        ),
      ),
      margin: EdgeInsets.zero,
    );
  }

  static ChipThemeData _chipTheme(ColorScheme scheme) {
    return ChipThemeData(
      backgroundColor: scheme.surfaceContainerHighest,
      selectedColor: _tertiary,
      labelStyle: TextStyle(color: scheme.onSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide(color: scheme.outlineVariant),
    );
  }

  static FilledButtonThemeData _filledButtonTheme() {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  static ListTileThemeData _listTileTheme(ColorScheme scheme) {
    return ListTileThemeData(
      iconColor: scheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  static NavigationBarThemeData _navigationBarTheme(ColorScheme scheme) {
    return NavigationBarThemeData(
      backgroundColor: scheme.surface.withValues(alpha: 0.94),
      indicatorColor: scheme.primary.withValues(alpha: 0.22),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        // Use primary for selected labels — secondary (magenta) is too visually noisy.
        return TextStyle(
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
        );
      }),
    );
  }
}
