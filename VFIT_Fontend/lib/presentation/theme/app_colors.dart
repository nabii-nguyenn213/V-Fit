import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF08090C);
  static const surface1 = Color(0xFF111225);
  static const surface2 = Color(0xFF1B1C36);

  static const lightBackground = Color(0xFFF8FAFF);
  static const lightSurface1 = Color(0xFFFFFFFF);
  static const lightSurface2 = Color(0xFFEAF1FF);

  static const primaryCyan = Color(0xFF00F5FF);
  static const energyMagenta = Color(0xFFFF2BD6);
  static const limePerformance = Color(0xFFD8FF3E);

  static const success = Color(0xFF32D583);
  static const warning = Color(0xFFFFB020);
  static const error = Color(0xFFFF4D6D);

  static const textPrimary = Color(0xFFF4F7FF);
  static const textSecondary = Color(0xFFB9C2E6);

  static const borderSubtle = Color(0x1FF4F7FF);
  static const overlayPressed = Color(0x1AF4F7FF);

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
    return isDark(context) ? textPrimary : const Color(0xFF101321);
  }

  static Color textSecondaryOf(BuildContext context) {
    return isDark(context) ? textSecondary : const Color(0xFF596074);
  }

  static Color borderSubtleOf(BuildContext context) {
    return isDark(context) ? borderSubtle : const Color(0xFFC8D4F3);
  }

  static Color overlayPressedOf(BuildContext context) {
    return isDark(context) ? overlayPressed : const Color(0x14007A85);
  }

  static Color primaryOf(BuildContext context) {
    return isDark(context) ? primaryCyan : const Color(0xFF007A85);
  }

  static Color onAccentOf(BuildContext context) {
    return isDark(context) ? background : Colors.white;
  }
}
