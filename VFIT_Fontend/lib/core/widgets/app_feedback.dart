import 'package:flutter/material.dart';

import '../utils/responsive.dart';

final appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

enum AppFeedbackType { success, error, warning, info }

class AppFeedback {
  const AppFeedback._();

  static void success(String message, {String? title}) {
    show(message: message, title: title, type: AppFeedbackType.success);
  }

  static void error(String message, {String? title}) {
    show(message: message, title: title, type: AppFeedbackType.error);
  }

  static void warning(String message, {String? title}) {
    show(message: message, title: title, type: AppFeedbackType.warning);
  }

  static void info(String message, {String? title}) {
    show(message: message, title: title, type: AppFeedbackType.info);
  }

  static void show({
    required String message,
    AppFeedbackType type = AppFeedbackType.info,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    debugPrint(
      '[AppFeedback][$type] ${title == null ? message : '$title: $message'}',
    );

    final messenger = appScaffoldMessengerKey.currentState;
    if (messenger == null) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: Colors.transparent,
          duration: duration,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          padding: EdgeInsets.zero,
          content: _AppFeedbackToast(
            title: title ?? _defaultTitle(type),
            message: message,
            type: type,
          ),
        ),
      );
  }

  static String _defaultTitle(AppFeedbackType type) {
    return switch (type) {
      AppFeedbackType.success => 'Thành công',
      AppFeedbackType.error => 'Có lỗi xảy ra',
      AppFeedbackType.warning => 'Cần chú ý',
      AppFeedbackType.info => 'Thông báo',
    };
  }
}

class AppFeedbackPanel extends StatelessWidget {
  const AppFeedbackPanel({
    super.key,
    required this.message,
    this.title,
    this.type = AppFeedbackType.info,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    this.icon,
  });

  final String message;
  final String? title;
  final AppFeedbackType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = _AppFeedbackStyle.resolve(context, type);
    final compactWidth = MediaQuery.sizeOf(context).width < 340;
    final iconBox = compact ? 34.0 : 40.0;
    final icon = Container(
      width: iconBox,
      height: iconBox,
      decoration: BoxDecoration(
        color: style.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        this.icon ?? style.icon,
        color: style.accent,
        size: compact ? 19 : 22,
      ),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title ?? AppFeedback._defaultTitle(type),
          style: TextStyle(
            color: style.foreground,
            fontSize: compact ? 13 : 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          message,
          style: TextStyle(
            color: style.foreground.withValues(alpha: 0.82),
            fontSize: compact ? 12 : 13,
            height: 1.35,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh, size: 17),
              label: Text(actionLabel!),
              style: OutlinedButton.styleFrom(
                foregroundColor: style.accent,
                side: BorderSide(
                  color: style.accent.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
        ],
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        compact ? 12 : AppResponsive.cardPadding(context).horizontal / 2,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: style.border),
      ),
      child: compactWidth
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(height: 10),
                text,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(child: text),
              ],
            ),
    );
  }
}

class _AppFeedbackToast extends StatelessWidget {
  const _AppFeedbackToast({
    required this.title,
    required this.message,
    required this.type,
  });

  final String title;
  final String message;
  final AppFeedbackType type;

  @override
  Widget build(BuildContext context) {
    return AppFeedbackPanel(
      title: title,
      message: message,
      type: type,
      compact: true,
    );
  }
}

class _AppFeedbackStyle {
  const _AppFeedbackStyle({
    required this.icon,
    required this.accent,
    required this.background,
    required this.border,
    required this.foreground,
  });

  final IconData icon;
  final Color accent;
  final Color background;
  final Color border;
  final Color foreground;

  static _AppFeedbackStyle resolve(BuildContext context, AppFeedbackType type) {
    final scheme = Theme.of(context).colorScheme;
    final accent = switch (type) {
      AppFeedbackType.success => const Color(0xFF32D583),
      AppFeedbackType.error => scheme.error,
      AppFeedbackType.warning => const Color(0xFFFFC857),
      AppFeedbackType.info => scheme.primary,
    };
    final icon = switch (type) {
      AppFeedbackType.success => Icons.check_circle_outline,
      AppFeedbackType.error => Icons.error_outline,
      AppFeedbackType.warning => Icons.warning_amber_rounded,
      AppFeedbackType.info => Icons.info_outline,
    };
    return _AppFeedbackStyle(
      icon: icon,
      accent: accent,
      background: Color.alphaBlend(
        accent.withValues(alpha: 0.10),
        scheme.surface,
      ),
      border: accent.withValues(alpha: 0.38),
      foreground: scheme.onSurface,
    );
  }
}
