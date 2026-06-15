import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_radius.dart';
import '../../presentation/theme/app_spacing.dart';
import '../../presentation/theme/app_typography.dart';
import '../constants/app_assets.dart';
import '../utils/responsive.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/ai/presentation/widgets/ai_coach_sheet.dart';
import '../../features/ai/presentation/widgets/ai_meal_sheet.dart';

final aiCoachButtonPositionProvider = StateProvider<Offset?>((ref) => null);
final aiMealButtonPositionProvider = StateProvider<Offset?>((ref) => null);

class AppShell extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
    final size = MediaQuery.of(context).size;
    const bottomNavOffset = 100.0;

    final auth = ref.watch(authControllerProvider);
    final isVip = auth.user?.isVipActive == true;
    final showButtons = isVip && !wide;

    final body = Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
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
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.borderSubtleOf(context),
                  ),
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
          ),
        ),
      ],
    );

    final scaffold = Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      extendBody: true,
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

    if (showButtons) {
      return Stack(
        children: [
          scaffold,
          DraggableFloatingButton(
            key: const ValueKey('ai-coach-touch'),
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 26,
            ),
            initialOffset: Offset(size.width - 72.0, size.height - bottomNavOffset - 72.0),
            positionProvider: aiCoachButtonPositionProvider,
            onTap: () => AiCoachSheet.show(context),
          ),
          DraggableFloatingButton(
            key: const ValueKey('ai-meal-touch'),
            icon: const Icon(
              Icons.restaurant_menu_rounded,
              color: Colors.white,
              size: 26,
            ),
            initialOffset: Offset(size.width - 72.0, size.height - bottomNavOffset - 144.0),
            positionProvider: aiMealButtonPositionProvider,
            onTap: () => AiMealSheet.show(context),
          ),
        ],
      );
    }

    return scaffold;
  }
}

class DraggableFloatingButton extends ConsumerStatefulWidget {
  const DraggableFloatingButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.initialOffset,
    required this.positionProvider,
  });

  final Widget icon;
  final VoidCallback onTap;
  final Offset initialOffset;
  final StateProvider<Offset?> positionProvider;

  @override
  ConsumerState<DraggableFloatingButton> createState() => _DraggableFloatingButtonState();
}

class _DraggableFloatingButtonState extends ConsumerState<DraggableFloatingButton> {
  late Offset _position;
  bool _isDragging = false;
  double _opacity = 1.0;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(widget.positionProvider);
    _position = saved ?? widget.initialOffset;
    _resetFadeTimer();
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    super.dispose();
  }

  void _resetFadeTimer() {
    _fadeTimer?.cancel();
    setState(() {
      _opacity = 1.0;
    });
    _fadeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _opacity = 0.3;
        });
      }
    });
  }

  void _snapToEdge(Size screenSize, double bottomNavOffset) {
    final x = _position.dx;
    final y = _position.dy;

    // Nearest horizontal edge
    final double targetX = (x + 28) < (screenSize.width / 2)
        ? 16.0
        : screenSize.width - 72.0;

    final newPos = Offset(targetX, y);
    setState(() {
      _isDragging = false;
      _position = newPos;
    });
    ref.read(widget.positionProvider.notifier).state = newPos;
    _resetFadeTimer();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomNavOffset = 100.0;

    final clampedPos = Offset(
      _position.dx.clamp(16.0, size.width - 72.0),
      _position.dy.clamp(80.0, size.height - bottomNavOffset - 72.0),
    );

    return AnimatedPositioned(
      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      left: clampedPos.dx,
      top: clampedPos.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
            _opacity = 1.0;
          });
          _fadeTimer?.cancel();
        },
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx).clamp(16.0, size.width - 72.0),
              (_position.dy + details.delta.dy).clamp(80.0, size.height - bottomNavOffset - 72.0),
            );
          });
        },
        onPanEnd: (_) => _snapToEdge(size, bottomNavOffset),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: InkWell(
                onTap: () {
                  _resetFadeTimer();
                  widget.onTap();
                },
                customBorder: const CircleBorder(),
                child: Center(child: widget.icon),
              ),
            ),
          ),
        ),
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: bottomPadding > 0 ? bottomPadding : 24,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.isDark(context) 
                  ? Colors.black.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: AppColors.isDark(context)
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Trang chủ',
                  isSelected: selectedIndex == 0,
                  onTap: () => onDestinationSelected(0),
                  compact: compact,
                ),
                _NavItem(
                  icon: Icons.fitness_center_outlined,
                  activeIcon: Icons.fitness_center_rounded,
                  label: 'Tập luyện',
                  isSelected: selectedIndex == 1,
                  onTap: () => onDestinationSelected(1),
                  compact: compact,
                ),
                _NavItem(
                  icon: Icons.restaurant_outlined,
                  activeIcon: Icons.restaurant_rounded,
                  label: 'Dinh dưỡng',
                  isSelected: selectedIndex == 2,
                  onTap: () => onDestinationSelected(2),
                  compact: compact,
                ),
                _NavItem(
                  icon: Icons.show_chart_outlined,
                  activeIcon: Icons.show_chart_rounded,
                  label: 'Tiến độ',
                  isSelected: selectedIndex == 3,
                  onTap: () => onDestinationSelected(3),
                  compact: compact,
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Hồ sơ',
                  isSelected: selectedIndex == 4,
                  onTap: () => onDestinationSelected(4),
                  compact: compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.compact,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final secondary = AppColors.textSecondaryOf(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: compact ? 56 : 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? primary : secondary,
                size: compact ? 22 : 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: compact ? 9 : 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? primary : secondary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
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
