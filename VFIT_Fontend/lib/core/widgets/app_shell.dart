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
import 'flashy_vip_required_modal.dart';

final aiCoachButtonPositionProvider = StateProvider<Offset?>((ref) => null);
final aiCoachDraggingProvider = StateProvider<bool>((ref) => false);

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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bottomBarHeight = 64.0;
    final bottomBarMargin = bottomPadding > 0 ? bottomPadding : 24.0;
    final bottomBarTop = size.height - bottomBarHeight - bottomBarMargin;
    final maxButtonY = bottomBarTop - 60.0 - 16.0;

    final coachInitialOffset = Offset(size.width - 76.0, maxButtonY);

    final auth = ref.watch(authControllerProvider);
    final isWorkoutOrNutrition = path == '/workouts' || path == '/nutrition';
    final showButtons = isWorkoutOrNutrition && !wide;

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
      final isWorkout = path == '/workouts';
      return Stack(
        children: [
          scaffold,
          DraggablePremiumAiSpeedDial(
            positionProvider: aiCoachButtonPositionProvider,
            draggingProvider: aiCoachDraggingProvider,
            initialOffset: coachInitialOffset,
            isWorkout: isWorkout,
            isVip: auth.user?.isVipActive == true,
          ),
        ],
      );
    }

    return scaffold;
  }
}

class DraggablePremiumAiSpeedDial extends ConsumerStatefulWidget {
  const DraggablePremiumAiSpeedDial({
    super.key,
    required this.positionProvider,
    required this.draggingProvider,
    required this.initialOffset,
    required this.isWorkout,
    required this.isVip,
  });

  final StateProvider<Offset?> positionProvider;
  final StateProvider<bool> draggingProvider;
  final Offset initialOffset;
  final bool isWorkout;
  final bool isVip;

  @override
  ConsumerState<DraggablePremiumAiSpeedDial> createState() => _DraggablePremiumAiSpeedDialState();
}

class _DraggablePremiumAiSpeedDialState extends ConsumerState<DraggablePremiumAiSpeedDial>
    with SingleTickerProviderStateMixin {
  double _opacity = 1.0;
  Timer? _fadeTimer;
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _resetFadeTimer();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _resetFadeTimer() {
    _fadeTimer?.cancel();
    if (mounted && !_isOpen) {
      setState(() {
        _opacity = 1.0;
      });
    }
    _fadeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_isOpen) {
        setState(() {
          _opacity = 0.3;
        });
      }
    });
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      _opacity = 1.0;
      if (_isOpen) {
        _animationController.forward();
        _fadeTimer?.cancel();
      } else {
        _animationController.reverse();
        _resetFadeTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bottomBarHeight = 64.0;
    final bottomBarMargin = bottomPadding > 0 ? bottomPadding : 24.0;
    final bottomBarTop = size.height - bottomBarHeight - bottomBarMargin;
    final maxButtonY = bottomBarTop - 60.0 - 16.0;

    final pos = ref.watch(widget.positionProvider) ?? widget.initialOffset;
    final isDragging = ref.watch(widget.draggingProvider);

    final isLeft = (pos.dx + 30) < (size.width / 2);
    final double clampedX = pos.dx.clamp(16.0, size.width - 76.0);
    final double clampedY = pos.dy.clamp(80.0, maxButtonY);

    return AnimatedPositioned(
      duration: isDragging ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      left: isLeft ? clampedX : null,
      right: isLeft ? null : size.width - clampedX - 60.0,
      top: clampedY,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          if (_isOpen)
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: FadeTransition(
                opacity: _expandAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                    children: [
                      _buildMenuOption(
                        context,
                        title: widget.isWorkout ? 'Lập lịch AI' : 'Lên thực đơn AI',
                        icon: widget.isWorkout ? Icons.fitness_center_rounded : Icons.restaurant_menu_rounded,
                        color: const Color(0xFFE81CFF),
                        isLeft: isLeft,
                        isVipOption: true,
                        isVipActive: widget.isVip,
                        onTap: () {
                          _toggleMenu();
                          if (widget.isVip) {
                            context.push(widget.isWorkout ? '/ai/coach?tab=1' : '/ai/coach?tab=2');
                          } else {
                            showDialog<void>(
                              context: context,
                              builder: (context) => const FlashyVipRequiredModal(),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildMenuOption(
                        context,
                        title: 'AI Coach',
                        icon: Icons.chat_bubble_outline_rounded,
                        color: const Color(0xFF06B6D4),
                        isLeft: isLeft,
                        isVipOption: false,
                        isVipActive: widget.isVip,
                        onTap: () {
                          _toggleMenu();
                          context.push('/ai/coach?tab=0');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) {
              if (_isOpen) _toggleMenu();
              ref.read(widget.draggingProvider.notifier).state = true;
              _resetFadeTimer();
            },
            onPanUpdate: (details) {
              final current = ref.read(widget.positionProvider) ?? widget.initialOffset;
              ref.read(widget.positionProvider.notifier).state = Offset(
                (current.dx + details.delta.dx).clamp(16.0, size.width - 76.0),
                (current.dy + details.delta.dy).clamp(80.0, maxButtonY),
              );
              _resetFadeTimer();
            },
            onPanEnd: (_) {
              ref.read(widget.draggingProvider.notifier).state = false;
              final current = ref.read(widget.positionProvider) ?? widget.initialOffset;
              final double targetX = (current.dx + 30) < (size.width / 2)
                  ? 16.0
                  : size.width - 76.0;
              ref.read(widget.positionProvider.notifier).state = Offset(targetX, current.dy);
              _resetFadeTimer();
            },
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _opacity,
              child: Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE81CFF), Color(0xFF06B6D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE81CFF).withOpacity(0.35),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _toggleMenu,
                    child: RotationTransition(
                      turns: _rotateAnimation,
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required bool isLeft,
    required bool isVipOption,
    required bool isVipActive,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final label = Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 13,
                decoration: TextDecoration.none,
              ),
            ),
            if (isVipOption) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB03A), Color(0xFFFF7E00)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'VIP',
                  style: TextStyle(
                    fontSize: 8, 
                    color: Colors.white, 
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(width: 4),
              const Text(
                'FREE',
                style: TextStyle(
                  fontSize: 8, 
                  color: Colors.green, 
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final button = FloatingActionButton.small(
      heroTag: 'speed_dial_$title',
      backgroundColor: color,
      foregroundColor: Colors.white,
      onPressed: onTap,
      child: Icon(icon),
    );

    return Material(
      type: MaterialType.transparency,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isLeft
            ? [button, const SizedBox(width: 10), label]
            : [label, const SizedBox(width: 10), button],
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
