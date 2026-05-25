import 'package:flutter/material.dart';

class WeeklySelectorWidget extends StatefulWidget {
  const WeeklySelectorWidget({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final int selectedDay;
  final ValueChanged<int> onDaySelected;

  @override
  State<WeeklySelectorWidget> createState() => _WeeklySelectorWidgetState();
}

class _WeeklySelectorWidgetState extends State<WeeklySelectorWidget> {
  late final ScrollController _scrollController;

  final List<Map<String, dynamic>> _days = const [
    {'day': 1, 'name': 'Thứ 2', 'short': 'T2'},
    {'day': 2, 'name': 'Thứ 3', 'short': 'T3'},
    {'day': 3, 'name': 'Thứ 4', 'short': 'T4'},
    {'day': 4, 'name': 'Thứ 5', 'short': 'T5'},
    {'day': 5, 'name': 'Thứ 6', 'short': 'T6'},
    {'day': 6, 'name': 'Thứ 7', 'short': 'T7'},
    {'day': 7, 'name': 'Chủ Nhật', 'short': 'CN'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Tự động cuộn đến ngày được chọn (hoặc ngày hôm nay) sau khi kết xuất xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToSelectedDay();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDay() {
    final index = _days.indexWhere((d) => d['day'] == widget.selectedDay);
    if (index != -1 && _scrollController.hasClients) {
      final position = index * 76.0; // 64 (card width) + 12 (spacing)
      final centerPosition = position - (MediaQuery.of(context).size.width / 2) + 38.0;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final targetScroll = centerPosition.clamp(0.0, maxScroll);
      
      _scrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now().weekday;

    return SizedBox(
      height: 84,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final dayItem = _days[index];
          final dayNum = dayItem['day'] as int;
          final isSelected = dayNum == widget.selectedDay;
          final isToday = dayNum == today;

          return Semantics(
            button: true,
            selected: isSelected,
            child: InkWell(
              onTap: () {
                widget.onDaySelected(dayNum);
                // Thực hiện cuộn khi click chọn
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) _scrollToSelectedDay();
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 64,
                decoration: BoxDecoration(
                  color: isSelected
                      ? scheme.primary
                      : isToday
                          ? scheme.primary.withValues(alpha: 0.08)
                          : scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? scheme.primary
                        : isToday
                            ? scheme.primary.withValues(alpha: 0.35)
                            : scheme.outlineVariant.withValues(alpha: 0.5),
                    width: isToday || isSelected ? 1.8 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayItem['short'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? scheme.onPrimary
                            : isToday
                                ? scheme.primary
                                : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isToday)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSelected ? scheme.onPrimary : scheme.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      Text(
                        'Buổi',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? scheme.onPrimary.withValues(alpha: 0.7)
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
