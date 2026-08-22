import 'package:flutter/material.dart';

enum TrialWelcomeAction { startTrial, upgrade }

class TrialWelcomeDialog extends StatelessWidget {
  const TrialWelcomeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.workspace_premium_rounded,
          color: colors.onPrimaryContainer,
          size: 34,
        ),
      ),
      title: const Text(
        'Bạn đã nhận 3 ngày VIP miễn phí!',
        textAlign: TextAlign.center,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tài khoản của bạn đã được kích hoạt VIP Trial trong 3 ngày. '
              'Bạn có thể trải nghiệm toàn bộ tính năng VIP ngay bây giờ.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.upgrade_rounded,
                    color: colors.onSecondaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Trong thời gian dùng thử, bạn vẫn có thể nâng cấp lên '
                      'gói VIP tháng hoặc năm bất cứ lúc nào.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSecondaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const ValueKey('trial-welcome-start'),
              onPressed: () => Navigator.of(context).pop(
                TrialWelcomeAction.startTrial,
              ),
              child: const Text('Bắt đầu trải nghiệm'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const ValueKey('trial-welcome-upgrade'),
              onPressed: () => Navigator.of(context).pop(
                TrialWelcomeAction.upgrade,
              ),
              child: const Text('Nâng cấp VIP ngay'),
            ),
          ],
        ),
      ),
    );
  }
}
