import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.fallbackRoute = '/home',
  });

  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Về trang chủ',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go(fallbackRoute);
          },
          child: SizedBox(
            width: 48,
            height: 42,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: scheme.onSurface,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
