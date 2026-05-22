import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

class VFitLogoAvatar extends StatelessWidget {
  const VFitLogoAvatar({super.key, this.size = 76});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surface,
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.42),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          AppAssets.vfitLogoMark,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.fitness_center_rounded,
              color: scheme.primary,
              size: size * 0.42,
            );
          },
        ),
      ),
    );
  }
}
