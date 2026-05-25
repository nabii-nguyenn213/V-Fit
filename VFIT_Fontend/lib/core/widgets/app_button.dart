import 'package:flutter/material.dart';

import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_radius.dart';
import '../../presentation/theme/app_spacing.dart';
import '../utils/responsive.dart';

enum AppButtonVariant {
  primary,
  secondary,
  ghost,
  destructive,
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.fullWidth = true,
    this.confirmTitle,
    this.confirmMessage,
    this.confirmLabel,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.fullWidth = true,
  })  : variant = AppButtonVariant.primary,
        confirmTitle = null,
        confirmMessage = null,
        confirmLabel = null;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.fullWidth = true,
  })  : variant = AppButtonVariant.secondary,
        confirmTitle = null,
        confirmMessage = null,
        confirmLabel = null;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.fullWidth = false,
  })  : variant = AppButtonVariant.ghost,
        confirmTitle = null,
        confirmMessage = null,
        confirmLabel = null;

  const AppButton.back({
    super.key,
    this.label = 'Quay lại',
    required this.onPressed,
    this.loading = false,
    this.fullWidth = false,
  })  : icon = Icons.arrow_back_rounded,
        variant = AppButtonVariant.ghost,
        confirmTitle = null,
        confirmMessage = null,
        confirmLabel = null;

  const AppButton.cancel({
    super.key,
    this.label = 'Hủy',
    required this.onPressed,
    this.loading = false,
    this.fullWidth = false,
  })  : icon = null,
        variant = AppButtonVariant.secondary,
        confirmTitle = null,
        confirmMessage = null,
        confirmLabel = null;

  const AppButton.confirm({
    super.key,
    this.label = 'Xác nhận',
    required this.onPressed,
    this.loading = false,
    this.icon = Icons.check_rounded,
    this.fullWidth = false,
  })  : variant = AppButtonVariant.primary,
        confirmTitle = null,
        confirmMessage = null,
        confirmLabel = null;

  const AppButton.add({
    super.key,
    this.label = 'Thêm mới',
    required this.onPressed,
    this.loading = false,
    this.fullWidth = false,
  })  : icon = Icons.add_rounded,
        variant = AppButtonVariant.primary,
        confirmTitle = null,
        confirmMessage = null,
        confirmLabel = null;

  const AppButton.close({
    super.key,
    this.label = 'Đóng',
    required this.onPressed,
    this.loading = false,
    this.fullWidth = false,
  })  : icon = Icons.close_rounded,
        variant = AppButtonVariant.ghost,
        confirmTitle = null,
        confirmMessage = null,
        confirmLabel = null;

  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon = Icons.delete_outline_rounded,
    this.fullWidth = false,
    this.confirmTitle = 'Xác nhận xóa',
    this.confirmMessage = 'Hành động này không thể hoàn tác.',
    this.confirmLabel = 'Xóa',
  }) : variant = AppButtonVariant.destructive;

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool fullWidth;
  final String? confirmTitle;
  final String? confirmMessage;
  final String? confirmLabel;

  bool get _isDestructiveConfirmed =>
      variant == AppButtonVariant.destructive && confirmTitle != null;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final style = _styleFor(context);
    final height = AppResponsive.buttonHeight(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: _PressScale(
        enabled: enabled,
        child: SizedBox(
          width: fullWidth ? double.infinity : null,
          height: height,
          child: TextButton(
            style: style,
            onPressed: enabled ? () => _handlePressed(context) : null,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: loading
                  ? _LoadingIndicator(variant: variant)
                  : _Label(icon: icon, label: label),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePressed(BuildContext context) async {
    if (!_isDestructiveConfirmed) {
      onPressed?.call();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(confirmTitle!),
          content: Text(confirmMessage!),
          actions: [
            AppButton.cancel(
              onPressed: () => Navigator.of(context).pop(false),
            ),
            AppButton.destructive(
              label: confirmLabel ?? label,
              confirmTitle: null,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      onPressed?.call();
    }
  }

  ButtonStyle _styleFor(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        );

    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal:
              AppResponsive.isCompact(context) ? AppSpacing.x4 : AppSpacing.x6,
          vertical: AppSpacing.x3,
        ),
      ),
      textStyle: WidgetStatePropertyAll(textStyle),
      mouseCursor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.disabled)
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click;
      }),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      side: WidgetStateProperty.resolveWith((states) {
        if (variant == AppButtonVariant.secondary) {
          return BorderSide(
            color: _stateColor(
              states,
              normal: AppColors.borderSubtleOf(context),
              hover: AppColors.primaryOf(context).withValues(alpha: 0.58),
              pressed: AppColors.primaryOf(context),
              disabled:
                  AppColors.borderSubtleOf(context).withValues(alpha: 0.5),
            ),
          );
        }
        return BorderSide.none;
      }),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => _backgroundColor(context, states),
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => _foregroundColor(context, states),
      ),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return AppColors.overlayPressedOf(context);
        }
        if (states.contains(WidgetState.hovered)) {
          return AppColors.primaryOf(context).withValues(alpha: 0.08);
        }
        return null;
      }),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (variant != AppButtonVariant.primary) return 0;
        if (states.contains(WidgetState.disabled)) return 0;
        if (states.contains(WidgetState.pressed)) return 0;
        return 1;
      }),
      shadowColor: WidgetStatePropertyAll(
        AppColors.primaryOf(context).withValues(alpha: 0.22),
      ),
    );
  }

  Color _backgroundColor(BuildContext context, Set<WidgetState> states) {
    final disabled = states.contains(WidgetState.disabled);
    final hovered = states.contains(WidgetState.hovered);
    final pressed = states.contains(WidgetState.pressed);

    if (disabled) {
      return AppColors.surface2Of(context).withValues(alpha: 0.48);
    }

    switch (variant) {
      case AppButtonVariant.primary:
        if (pressed) {
          return Color.lerp(AppColors.primaryOf(context), Colors.black, 0.16)!;
        }
        if (hovered) {
          return Color.lerp(AppColors.primaryOf(context), Colors.white, 0.10)!;
        }
        return AppColors.primaryOf(context);
      case AppButtonVariant.secondary:
        if (pressed) {
          return AppColors.surface2Of(context).withValues(alpha: 0.96);
        }
        if (hovered) {
          return AppColors.surface2Of(context).withValues(alpha: 0.82);
        }
        return AppColors.surface2Of(context).withValues(alpha: 0.64);
      case AppButtonVariant.ghost:
        if (pressed) {
          return AppColors.primaryOf(context).withValues(alpha: 0.14);
        }
        if (hovered) {
          return AppColors.primaryOf(context).withValues(alpha: 0.08);
        }
        return Colors.transparent;
      case AppButtonVariant.destructive:
        if (pressed) return Color.lerp(AppColors.error, Colors.black, 0.16)!;
        if (hovered) return Color.lerp(AppColors.error, Colors.white, 0.08)!;
        return AppColors.error;
    }
  }

  Color _foregroundColor(BuildContext context, Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return AppColors.textSecondaryOf(context).withValues(alpha: 0.48);
    }

    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.onAccentOf(context);
      case AppButtonVariant.secondary:
      case AppButtonVariant.ghost:
        return AppColors.primaryOf(context);
      case AppButtonVariant.destructive:
        return AppColors.textPrimary;
    }
  }

  Color _stateColor(
    Set<WidgetState> states, {
    required Color normal,
    required Color hover,
    required Color pressed,
    required Color disabled,
  }) {
    if (states.contains(WidgetState.disabled)) return disabled;
    if (states.contains(WidgetState.pressed)) return pressed;
    if (states.contains(WidgetState.hovered)) return hover;
    return normal;
  }
}

class _PressScale extends StatefulWidget {
  const _PressScale({
    required this.enabled,
    required this.child,
  });

  final bool enabled;
  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: widget.enabled ? (_) => _setPressed(true) : null,
      onPointerUp: widget.enabled ? (_) => _setPressed(false) : null,
      onPointerCancel: widget.enabled ? (_) => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.icon,
    required this.label,
  });

  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('label'),
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.x2),
        ],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({required this.variant});

  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final color = switch (variant) {
      AppButtonVariant.primary => AppColors.onAccentOf(context),
      AppButtonVariant.destructive => AppColors.textPrimary,
      AppButtonVariant.secondary ||
      AppButtonVariant.ghost =>
        AppColors.primaryOf(context),
    };

    return SizedBox.square(
      key: const ValueKey('loading'),
      dimension: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
