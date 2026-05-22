import 'package:flutter/material.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !loading;
    final style = _styleFor(context, scheme);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      child: SizedBox(
        width: fullWidth ? double.infinity : null,
        height: 52,
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

  ButtonStyle _styleFor(BuildContext context, ColorScheme scheme) {
    final baseTextStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        );

    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      textStyle: WidgetStatePropertyAll(baseTextStyle),
      mouseCursor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.disabled)
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click;
      }),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      side: WidgetStateProperty.resolveWith((states) {
        if (variant == AppButtonVariant.secondary) {
          return BorderSide(
            color: _stateColor(
              states,
              normal: scheme.outlineVariant,
              hover: scheme.primary.withValues(alpha: 0.62),
              pressed: scheme.primary,
              disabled: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          );
        }
        return BorderSide.none;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        return _backgroundColor(states, scheme);
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        return _foregroundColor(states, scheme);
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return _pressedOverlay(scheme);
        }
        if (states.contains(WidgetState.hovered)) {
          return _hoverOverlay(scheme);
        }
        return null;
      }),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (variant != AppButtonVariant.primary) {
          return 0;
        }
        if (states.contains(WidgetState.disabled)) {
          return 0;
        }
        if (states.contains(WidgetState.pressed)) {
          return 0;
        }
        return 2;
      }),
      shadowColor: WidgetStatePropertyAll(
        scheme.primary.withValues(alpha: 0.22),
      ),
    );
  }

  Color _backgroundColor(Set<WidgetState> states, ColorScheme scheme) {
    final disabled = states.contains(WidgetState.disabled);
    final hovered = states.contains(WidgetState.hovered);
    final pressed = states.contains(WidgetState.pressed);

    if (disabled) {
      return scheme.onSurface.withValues(alpha: 0.12);
    }

    switch (variant) {
      case AppButtonVariant.primary:
        if (pressed) {
          return Color.lerp(scheme.primary, Colors.black, 0.18)!;
        }
        if (hovered) {
          return Color.lerp(scheme.primary, Colors.white, 0.12)!;
        }
        return scheme.primary;
      case AppButtonVariant.secondary:
        if (pressed) {
          return scheme.secondary.withValues(alpha: 0.2);
        }
        if (hovered) {
          return scheme.secondary.withValues(alpha: 0.12);
        }
        return scheme.surfaceContainerHighest.withValues(alpha: 0.62);
      case AppButtonVariant.ghost:
        if (pressed) {
          return scheme.secondary.withValues(alpha: 0.14);
        }
        if (hovered) {
          return scheme.primary.withValues(alpha: 0.08);
        }
        return Colors.transparent;
      case AppButtonVariant.destructive:
        if (pressed) {
          return Color.lerp(scheme.error, Colors.black, 0.16)!;
        }
        if (hovered) {
          return Color.lerp(scheme.error, Colors.white, 0.1)!;
        }
        return scheme.error;
    }
  }

  Color _foregroundColor(Set<WidgetState> states, ColorScheme scheme) {
    if (states.contains(WidgetState.disabled)) {
      return scheme.onSurface.withValues(alpha: 0.46);
    }

    switch (variant) {
      case AppButtonVariant.primary:
        return scheme.onPrimary;
      case AppButtonVariant.secondary:
        return scheme.secondary;
      case AppButtonVariant.ghost:
        return scheme.primary;
      case AppButtonVariant.destructive:
        return scheme.onError;
    }
  }

  Color _hoverOverlay(ColorScheme scheme) {
    if (variant == AppButtonVariant.destructive) {
      return scheme.onError.withValues(alpha: 0.08);
    }
    return scheme.onPrimary.withValues(alpha: 0.08);
  }

  Color _pressedOverlay(ColorScheme scheme) {
    if (variant == AppButtonVariant.destructive) {
      return scheme.onError.withValues(alpha: 0.16);
    }
    return scheme.onPrimary.withValues(alpha: 0.14);
  }

  Color _stateColor(
    Set<WidgetState> states, {
    required Color normal,
    required Color hover,
    required Color pressed,
    required Color disabled,
  }) {
    if (states.contains(WidgetState.disabled)) {
      return disabled;
    }
    if (states.contains(WidgetState.pressed)) {
      return pressed;
    }
    if (states.contains(WidgetState.hovered)) {
      return hover;
    }
    return normal;
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
          const SizedBox(width: 8),
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
    final scheme = Theme.of(context).colorScheme;
    final color = switch (variant) {
      AppButtonVariant.primary => scheme.onPrimary,
      AppButtonVariant.destructive => scheme.onError,
      AppButtonVariant.secondary || AppButtonVariant.ghost => scheme.primary,
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
