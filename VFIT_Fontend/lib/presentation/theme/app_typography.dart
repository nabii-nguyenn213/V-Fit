import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static TextStyle headerLarge({Color color = AppColors.textPrimary}) {
    return GoogleFonts.plusJakartaSans(
      color: color,
      fontSize: 28,
      fontWeight: FontWeight.w800,
      height: 1.08,
      letterSpacing: 0,
    );
  }

  static TextStyle headerLargeFor(BuildContext context, {Color? color}) {
    return headerLarge(color: color ?? AppColors.textPrimaryOf(context));
  }

  static TextStyle headerMedium({Color color = AppColors.textPrimary}) {
    return GoogleFonts.plusJakartaSans(
      color: color,
      fontSize: 20,
      fontWeight: FontWeight.w800,
      height: 1.16,
      letterSpacing: 0,
    );
  }

  static TextStyle headerMediumFor(BuildContext context, {Color? color}) {
    return headerMedium(color: color ?? AppColors.textPrimaryOf(context));
  }

  static TextStyle label({Color color = AppColors.textSecondary}) {
    return GoogleFonts.inter(
      color: color,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      height: 1.2,
      letterSpacing: 0.2,
    );
  }

  static TextStyle labelFor(BuildContext context, {Color? color}) {
    return label(color: color ?? AppColors.textSecondaryOf(context));
  }

  static TextStyle body({Color color = AppColors.textPrimary}) {
    return GoogleFonts.inter(
      color: color,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.45,
      letterSpacing: 0,
    );
  }

  static TextStyle bodyFor(BuildContext context, {Color? color}) {
    return body(color: color ?? AppColors.textPrimaryOf(context));
  }

  static TextStyle bodySmall({Color color = AppColors.textSecondary}) {
    return GoogleFonts.inter(
      color: color,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.35,
      letterSpacing: 0,
    );
  }

  static TextStyle bodySmallFor(BuildContext context, {Color? color}) {
    return bodySmall(color: color ?? AppColors.textSecondaryOf(context));
  }

  static TextStyle metric({Color color = AppColors.textPrimary}) {
    return GoogleFonts.interTight(
      color: color,
      fontSize: 30,
      fontWeight: FontWeight.w800,
      height: 1,
      letterSpacing: 0,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle metricFor(BuildContext context, {Color? color}) {
    return metric(color: color ?? AppColors.textPrimaryOf(context));
  }
}
