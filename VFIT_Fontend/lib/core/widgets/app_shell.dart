import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_radius.dart';
import '../../presentation/theme/app_spacing.dart';
import '../../presentation/theme/app_typography.dart';
import '../constants/app_assets.dart';
import '../utils/responsive.dart';

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
    final selectedIndex = _routes.indexWhere((route) => path.startsWith(route));
    final safeIndex = selectedIndex < 0 ? 0 : selectedIndex;
    final title = switch (safeIndex) {
      0 => 'Trang chủ',
      1 => 'Luyện tập',
      2 => 'Dinh dưỡng',
      3 => 'Tiến độ',
      _ => 'Hồ sơ',
    };
    final isDark = AppColors.isDark(context);
    final wide = AppResponsive.isWide(context);
    final body = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  AppColors.background,
                  AppColors.surface1,
                  Color(0xFF101328),
                ]
              : const [
                  AppColors.lightBackground,
                  AppColors.lightSurface1,
                  Color(0xFFEAF1FF),
                ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ShellHeader(title: title),
            Expanded(
              child: AppResponsive.centeredContent(
                context: context,
                maxWidth: wide ? 1080 : AppResponsive.maxContentWidth,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: wide
          ? Row(
              children: [
                _ShellNavigationRail(
                  selectedIndex: safeIndex,
                  onDestinationSelected: (value) => context.go(_routes[value]),
                ),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: wide
          ? null
          : _ShellNavigationBar(
              selectedIndex: safeIndex,
              onDestinationSelected: (value) => context.go(_routes[value]),
            ),
    );
  }
}

class _ShellHeader extends StatelessWidget {
  const _ShellHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final compact = AppResponsive.isCompact(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppResponsive.horizontalPadding(context),
        compact ? AppSpacing.x2 : AppSpacing.x3,
        AppResponsive.horizontalPadding(context),
        AppSpacing.x2,
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 40 : 46,
            height: compact ? 40 : 46,
            padding: EdgeInsets.all(compact ? 6 : AppSpacing.x2),
            decoration: BoxDecoration(
              color: AppColors.surface2Of(context).withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(color: AppColors.borderSubtleOf(context)),
            ),
            child: Image.asset(
              AppAssets.vfitLogoMark,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Text(
                    'VF',
                    style: AppTypography.labelFor(
                      context,
                      color: AppColors.primaryOf(context),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'V-FIT',
                  style: AppTypography.labelFor(
                    context,
                    color: AppColors.primaryOf(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: compact
                      ? Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          )
                      : AppTypography.headerMediumFor(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShellNavigationBar extends StatelessWidget {
  const _ShellNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final compact = AppResponsive.isCompact(context);
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: AppColors.surface1Of(context),
        indicatorColor: AppColors.primaryOf(context).withValues(alpha: 0.16),
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? AppColors.primaryOf(context)
                : AppColors.textSecondaryOf(context),
            size: compact ? 21 : 23,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.labelFor(
            context,
            color: selected
                ? AppColors.primaryOf(context)
                : AppColors.textSecondaryOf(context),
          ).copyWith(fontSize: compact ? 10 : 11);
        }),
      ),
      child: NavigationBar(
        height: compact ? 64 : 72,
        elevation: 0,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Icons.dashboard_rounded),
            icon: Icon(Icons.dashboard_outlined),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.fitness_center_rounded),
            icon: Icon(Icons.fitness_center_outlined),
            label: 'Luyện tập',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.restaurant_rounded),
            icon: Icon(Icons.restaurant_outlined),
            label: 'Dinh dưỡng',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.show_chart_rounded),
            icon: Icon(Icons.show_chart_outlined),
            label: 'Tiến độ',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.person_rounded),
            icon: Icon(Icons.person_outline_rounded),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}

class _ShellNavigationRail extends StatelessWidget {
  const _ShellNavigationRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      backgroundColor: AppColors.surface1Of(context),
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      minWidth: 92,
      selectedIconTheme: IconThemeData(color: AppColors.primaryOf(context)),
      unselectedIconTheme:
          IconThemeData(color: AppColors.textSecondaryOf(context)),
      selectedLabelTextStyle: AppTypography.labelFor(
        context,
        color: AppColors.primaryOf(context),
      ),
      unselectedLabelTextStyle: AppTypography.labelFor(
        context,
        color: AppColors.textSecondaryOf(context),
      ),
      destinations: const [
        NavigationRailDestination(
          selectedIcon: Icon(Icons.dashboard_rounded),
          icon: Icon(Icons.dashboard_outlined),
          label: Text('Trang chủ'),
        ),
        NavigationRailDestination(
          selectedIcon: Icon(Icons.fitness_center_rounded),
          icon: Icon(Icons.fitness_center_outlined),
          label: Text('Luyện tập'),
        ),
        NavigationRailDestination(
          selectedIcon: Icon(Icons.restaurant_rounded),
          icon: Icon(Icons.restaurant_outlined),
          label: Text('Dinh dưỡng'),
        ),
        NavigationRailDestination(
          selectedIcon: Icon(Icons.show_chart_rounded),
          icon: Icon(Icons.show_chart_outlined),
          label: Text('Tiến độ'),
        ),
        NavigationRailDestination(
          selectedIcon: Icon(Icons.person_rounded),
          icon: Icon(Icons.person_outline_rounded),
          label: Text('Hồ sơ'),
        ),
      ],
    );
  }
}
