import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppResponsive {
  const AppResponsive._();

  static const double compactMaxWidth = 360;
  static const double phoneMaxWidth = 600;
  static const double tabletMaxWidth = 900;
  static const double maxContentWidth = 720;

  static bool isCompact(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width <= compactMaxWidth || size.height <= 640;
  }

  static bool isPhone(BuildContext context) {
    return MediaQuery.sizeOf(context).width < phoneMaxWidth;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= phoneMaxWidth && width < tabletMaxWidth;
  }

  static bool isWide(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= tabletMaxWidth;
  }

  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 340) return 12;
    if (width < phoneMaxWidth) return 16;
    if (width < tabletMaxWidth) return 24;
    return 32;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final horizontal = horizontalPadding(context);
    return EdgeInsets.fromLTRB(horizontal, 16, horizontal, 20);
  }

  static EdgeInsets cardPadding(BuildContext context) {
    return EdgeInsets.all(isCompact(context) ? 14 : 16);
  }

  static double iconButtonSize(BuildContext context) {
    return isCompact(context) ? 42 : 48;
  }

  static double buttonHeight(BuildContext context) {
    return isCompact(context) ? 48 : 52;
  }

  static double clampTextScale(double scale) {
    return scale.clamp(0.85, 1.18).toDouble();
  }

  static double dialogMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return math.min(width - horizontalPadding(context), 420);
  }

  static double dialogMaxHeight(BuildContext context, {double ratio = 0.86}) {
    final media = MediaQuery.of(context);
    return (media.size.height -
            media.padding.vertical -
            media.viewInsets.vertical -
            16)
        .clamp(280, media.size.height * ratio)
        .toDouble();
  }

  static Widget centeredContent({
    required BuildContext context,
    required Widget child,
    double maxWidth = maxContentWidth,
  }) {
    if (isPhone(context)) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
