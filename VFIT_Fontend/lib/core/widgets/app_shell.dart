import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_assets.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _routes = [
    '/home',
    '/workouts',
    '/nutrition',
    '/progress',
    '/profile',
  ];

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final index = _routes.indexWhere((route) => path.startsWith(route));
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = switch (index < 0 ? 0 : index) {
      0 => 'Trang chủ',
      1 => 'Luyện tập',
      2 => 'Dinh dưỡng',
      3 => 'Tiến độ',
      _ => 'Hồ sơ',
    };
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF070711),
                    Color(0xFF111225),
                    Color(0xFF190B2D),
                    Color(0xFF061E2A),
                  ]
                : const [
                    Color(0xFFF8FAFF),
                    Color(0xFFEAF8FF),
                    Color(0xFFFFF0FB),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 58,
                      height: 42,
                      child: Image.asset(
                        AppAssets.vfitLogoMark,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            'V-FIT',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.right,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 70,
        surfaceTintColor: Colors.transparent,
        shadowColor: scheme.primary.withValues(alpha: 0.34),
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (value) => context.go(_routes[value]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center),
            label: 'Luyện tập',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant),
            label: 'Dinh dưỡng',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Tiến độ',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
