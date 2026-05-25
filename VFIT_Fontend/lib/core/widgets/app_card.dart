import 'package:flutter/material.dart';

import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_radius.dart';
import '../utils/responsive.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppRadius.card);
    final isDark = AppColors.isDark(context);
    final content = Material(
      color: AppColors.surface1Of(context),
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: AppColors.primaryOf(context).withValues(alpha: 0.08),
        highlightColor: AppColors.overlayPressedOf(context),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: AppColors.borderSubtleOf(context)),
            boxShadow: [
              BoxShadow(
                color:
                    isDark ? const Color(0x24000000) : const Color(0x1200235A),
                blurRadius: isDark ? 18 : 14,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: padding ?? AppResponsive.cardPadding(context),
            child: child,
          ),
        ),
      ),
    );

    return Semantics(
      button: onTap != null,
      container: true,
      child: content,
    );
  }
}
