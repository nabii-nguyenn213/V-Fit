import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF09090B); // pure deep dark
  static const surface1 = Color(0xFF18181B); // zinc 900
  static const surface2 = Color(0xFF27272A); // zinc 800

  static const lightBackground = Color(0xFFF4F4F5); // zinc 100
  static const lightSurface1 = Color(0xFFFFFFFF); // pure white
  static const lightSurface2 = Color(0xFFF8F9FA); // ultra light

  static const primaryCyan = Color(0xFF06B6D4); // modern vibrant cyan
  static const primaryEmerald = Color(0xFF10B981); // premium emerald
  static const energyMagenta = Color(0xFFE81CFF);
  static const limePerformance = Color(0xFFD9F920);

  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  static const textPrimary = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xFFA1A1AA);

  static const borderSubtle = Color(0xFF27272A);
  static const overlayPressed = Color(0x1AFAFAFA);

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color backgroundOf(BuildContext context) {
    return isDark(context) ? background : lightBackground;
  }

  static Color surface1Of(BuildContext context) {
    return isDark(context) ? surface1 : lightSurface1;
  }

  static Color surface2Of(BuildContext context) {
    return isDark(context) ? surface2 : lightSurface2;
  }

  static Color textPrimaryOf(BuildContext context) {
    return isDark(context) ? textPrimary : const Color(0xFF09090B); // Zinc 950
  }

  static Color textSecondaryOf(BuildContext context) {
    return isDark(context) ? textSecondary : const Color(0xFF71717A); // Zinc 500
  }

  static Color borderSubtleOf(BuildContext context) {
    return isDark(context) ? borderSubtle : const Color(0xFFE4E4E7); // Zinc 200
  }

  static Color overlayPressedOf(BuildContext context) {
    return isDark(context) ? overlayPressed : const Color(0x0F09090B);
  }

  static Color primaryOf(BuildContext context) {
    return isDark(context) ? primaryCyan : const Color(0xFF0F766E); // Deep modern teal
  }

  static Color onAccentOf(BuildContext context) {
    return isDark(context) ? const Color(0xFF082F49) : Colors.white;
  }
}
