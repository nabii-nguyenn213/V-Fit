import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import '../../data/models/admin_dashboard_models.dart';

enum TimeframeFilter { sixMonths, thisYear, allTime }

class FinancialChart extends StatefulWidget {
  final List<MonthlyRevenueItemModel> data;

  const FinancialChart({super.key, required this.data});

  @override
  State<FinancialChart> createState() => _FinancialChartState();
}

class _FinancialChartState extends State<FinancialChart> with SingleTickerProviderStateMixin {
  TimeframeFilter _filter = TimeframeFilter.sixMonths;
  int? _selectedIndex;
  Offset? _touchPosition;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<MonthlyRevenueItemModel> _getFilteredData() {
    if (widget.data.isEmpty) return [];

    final now = DateTime.now();

    switch (_filter) {
      case TimeframeFilter.sixMonths:
        return widget.data.length > 6
            ? widget.data.sublist(widget.data.length - 6)
            : widget.data;
      case TimeframeFilter.thisYear:
        final currentYearStr = now.year.toString();
        return widget.data
            .where((item) => item.month.startsWith(currentYearStr))
            .toList();
      case TimeframeFilter.allTime:
        return widget.data;
    }
  }

  void _handleTouch(Offset localPosition, double width, int dataCount) {
    const double paddingLeft = 40.0;
    const double paddingRight = 10.0;
    final double chartWidth = width - paddingLeft - paddingRight;

    if (chartWidth <= 0 || dataCount == 0) return;

    final double cellWidth = chartWidth / dataCount;
    final double rx = localPosition.dx - paddingLeft;
    final int index = (rx / cellWidth).floor();

    if (index >= 0 && index < dataCount) {
      setState(() {
        _selectedIndex = index;
        _touchPosition = localPosition;
      });
    }
  }

  String _formatCurrency(double val) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0)
        .format(val);
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _getFilteredData();
    if (filteredData.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(
          child: Text(
            'Chưa có dữ liệu thống kê',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    final double maxRevenue = filteredData
        .map((e) => e.totalRevenue)
        .reduce((a, b) => a > b ? a : b);
    final double maxY = maxRevenue == 0 ? 100000 : maxRevenue * 1.25;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff1C1D24).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'XU HƯỚNG TÀI CHÍNH (THÁNG)',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              _buildFilterDropdown(),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final double height = constraints.maxHeight;

                // Position calculation for Glassmorphism Tooltip
                double? tooltipLeft;
                double? tooltipTop;
                MonthlyRevenueItemModel? selectedItem;

                if (_selectedIndex != null && _selectedIndex! < filteredData.length) {
                  selectedItem = filteredData[_selectedIndex!];
                  const double paddingLeft = 40.0;
                  const double paddingRight = 10.0;
                  final double chartWidth = width - paddingLeft - paddingRight;
                  final double cellWidth = chartWidth / filteredData.length;
                  
                  // Compute center x of the bar
                  final double barWidth = cellWidth * 0.45;
                  final double barX = paddingLeft + _selectedIndex! * cellWidth + (cellWidth - barWidth) / 2;
                  tooltipLeft = barX + (barWidth / 2) - 80; // Tooltip width is 160
                  
                  // Keep tooltip inside bounds
                  if (tooltipLeft < 10) tooltipLeft = 10;
                  if (tooltipLeft + 160 > width - 10) tooltipLeft = width - 170;

                  // Compute top y of the bar
                  const double paddingTop = 20.0;
                  const double paddingBottom = 30.0;
                  final double drawHeight = height - paddingTop - paddingBottom;
                  final double barHeight = (selectedItem.totalRevenue / maxY) * drawHeight * _animation.value;
                  tooltipTop = paddingTop + drawHeight - barHeight - 75; // Tooltip height around 65
                  if (tooltipTop < 5) tooltipTop = 5;
                }

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Gesture Detector over CustomPaint
                    GestureDetector(
                      onTapDown: (details) => _handleTouch(details.localPosition, width, filteredData.length),
                      onPanUpdate: (details) => _handleTouch(details.localPosition, width, filteredData.length),
                      onPanEnd: (_) => setState(() {
                        _selectedIndex = null;
                        _touchPosition = null;
                      }),
                      onTapUp: (_) => setState(() {
                        _selectedIndex = null;
                        _touchPosition = null;
                      }),
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return CustomPaint(
                            size: Size(width, height),
                            painter: ChartPainter(
                              data: filteredData,
                              maxY: maxY,
                              selectedIndex: _selectedIndex,
                              animationValue: _animation.value,
                            ),
                          );
                        },
                      ),
                    ),

                    // Interactive Glassmorphism Tooltip
                    if (_selectedIndex != null && selectedItem != null && tooltipLeft != null && tooltipTop != null)
                      Positioned(
                        left: tooltipLeft,
                        top: tooltipTop,
                        child: IgnorePointer(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                width: 160,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xff1C1D24).withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xff00E676).withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tháng ${selectedItem.month.substring(5)}/${selectedItem.month.substring(0, 4)}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatCurrency(selectedItem.totalRevenue),
                                      style: const TextStyle(
                                        color: Color(0xff00E676),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${selectedItem.totalOrders} đơn hàng (${selectedItem.growthRate >= 0 ? '+' : ''}${selectedItem.growthRate.toStringAsFixed(1)}%)',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TimeframeFilter>(
          value: _filter,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 16),
          dropdownColor: const Color(0xff1C1D24),
          style: const TextStyle(color: Colors.white, fontSize: 11),
          items: const [
            DropdownMenuItem(value: TimeframeFilter.sixMonths, child: Text('6 tháng qua')),
            DropdownMenuItem(value: TimeframeFilter.thisYear, child: Text('Năm nay')),
            DropdownMenuItem(value: TimeframeFilter.allTime, child: Text('Toàn bộ')),
          ],
          onChanged: (TimeframeFilter? newValue) {
            if (newValue != null && newValue != _filter) {
              setState(() {
                _filter = newValue;
                _selectedIndex = null;
                _touchPosition = null;
              });
              _animationController.forward(from: 0.0);
            }
          },
        ),
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<MonthlyRevenueItemModel> data;
  final double maxY;
  final int? selectedIndex;
  final double animationValue;

  ChartPainter({
    required this.data,
    required this.maxY,
    required this.selectedIndex,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 40.0;
    const double paddingRight = 10.0;
    const double paddingTop = 20.0;
    const double paddingBottom = 30.0;

    final double width = size.width - paddingLeft - paddingRight;
    final double height = size.height - paddingTop - paddingBottom;

    if (data.isEmpty) return;

    // Draw Grid Lines (horizontal) and Left Axis Labels
    final Paint gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    final Paint dashedGridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    const int gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final double y = paddingTop + height * (1 - i / gridLines);
      
      // Draw grid line
      if (i == 0) {
        canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);
      } else {
        // Draw simple dashed line
        final double lineLength = size.width - paddingRight - paddingLeft;
        const double dashWidth = 4.0;
        const double dashSpace = 4.0;
        double currentX = paddingLeft;
        while (currentX < paddingLeft + lineLength) {
          canvas.drawLine(Offset(currentX, y), Offset(currentX + dashWidth, y), dashedGridPaint);
          currentX += dashWidth + dashSpace;
        }
      }

      // Draw grid labels on the left
      final double gridVal = maxY * (i / gridLines);
      final String label = _formatCompact(gridVal);
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 9,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2));
    }

    final double cellWidth = width / data.length;
    final double barWidth = cellWidth * 0.45;

    // Draw bars
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final double barHeight = (item.totalRevenue / maxY) * height * animationValue;

      final double x = paddingLeft + i * cellWidth + (cellWidth - barWidth) / 2;
      final double y = paddingTop + height - barHeight;

      if (barHeight > 0) {
        final Rect rect = Rect.fromLTWH(x, y, barWidth, barHeight);
        final RRect rrect = RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        );

        // Gradient from Neon Emerald to Deep Teal
        final Paint barPaint = Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xff004D40), Color(0xff00E676)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ).createShader(rect);

        // Highlight selected bar
        if (i == selectedIndex) {
          barPaint.colorFilter = ColorFilter.mode(
            Colors.white.withValues(alpha: 0.15),
            BlendMode.srcOver,
          );
        }

        canvas.drawRRect(rrect, barPaint);

        // Glowing effect on selected bar
        if (i == selectedIndex) {
          final Paint glowPaint = Paint()
            ..shader = const LinearGradient(
              colors: [Color(0x00000000), Color(0x6600E676)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ).createShader(rect)
            ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);
          canvas.drawRRect(rrect, glowPaint);
        }
      }

      // Draw bottom text (Month label)
      final String monthLabel = 'T${item.month.substring(5)}';
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: monthLabel,
          style: TextStyle(
            color: i == selectedIndex ? const Color(0xff00E676) : Colors.grey,
            fontSize: 9,
            fontWeight: i == selectedIndex ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, paddingTop + height + 8),
      );
    }
  }

  String _formatCompact(double val) {
    if (val == 0) return '0';
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(val % 1000000 == 0 ? 0 : 1)}M';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(val % 1000 == 0 ? 0 : 1)}k';
    }
    return val.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.maxY != maxY ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.animationValue != animationValue;
  }
}
