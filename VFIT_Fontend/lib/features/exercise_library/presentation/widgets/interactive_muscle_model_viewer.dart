import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/exercise_catalog.dart';

class MuscleMapSelection {
  const MuscleMapSelection({
    required this.group,
    this.subGroupId,
  });

  final MuscleGroup group;
  final String? subGroupId;
}

class InteractiveMuscleModelViewer extends StatefulWidget {
  const InteractiveMuscleModelViewer({
    super.key,
    required this.groups,
    required this.onSelection,
  });

  final List<MuscleGroup> groups;
  final ValueChanged<MuscleMapSelection> onSelection;

  @override
  State<InteractiveMuscleModelViewer> createState() =>
      _InteractiveMuscleModelViewerState();
}

class _InteractiveMuscleModelViewerState
    extends State<InteractiveMuscleModelViewer> {
  double _angle = 0;
  _MuscleZone? _selectedZone;

  List<_MuscleZone> get _zones => _buildZones(widget.groups);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = math.min(MediaQuery.sizeOf(context).height * 0.58, 520.0);
    final zones = _zones;
    final selectedGroup = _selectedZone == null
        ? null
        : _groupById(widget.groups, _selectedZone!.groupId);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surface.withValues(alpha: isDark ? 0.94 : 0.98),
            scheme.surfaceContainerHighest
                .withValues(alpha: isDark ? 0.42 : 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: isDark ? 0.16 : 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _ModelToolbar(
                title: _selectedZone?.label ?? 'Kéo để xoay 360 độ',
                onOpenGroup: selectedGroup == null
                    ? null
                    : () => _openZone(_selectedZone!),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: height,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size =
                        Size(constraints.maxWidth, constraints.maxHeight);
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragUpdate: (details) {
                        setState(() => _angle += details.delta.dx * 0.85);
                      },
                      onTapUp: (details) {
                        final zone = _hitTestZone(
                          details.localPosition,
                          size,
                          zones,
                          _angle,
                        );
                        if (zone != null) {
                          setState(() => _selectedZone = zone);
                          _openZone(zone);
                        }
                      },
                      child: CustomPaint(
                        size: size,
                        painter: _MuscleModelPainter(
                          angle: _angle,
                          zones: zones,
                          selectedZone: _selectedZone,
                          primary: scheme.primary,
                          onSurface: scheme.onSurface,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.threesixty_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                  Expanded(
                    child: Slider(
                      value: ((_angle + 180) % 360) - 180,
                      min: -180,
                      max: 180,
                      onChanged: (value) => setState(() => _angle = value),
                    ),
                  ),
                  Text(
                    '${((_angle % 360 + 360) % 360).round()}°',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              _MuscleGroupChips(
                groups: widget.groups,
                selectedGroupId: _selectedZone?.groupId,
                onSelected: (group) {
                  final zone = zones.firstWhere(
                    (item) => item.groupId == group.id,
                    orElse: () => _MuscleZone.forGroup(group),
                  );
                  setState(() => _selectedZone = zone);
                  widget.onSelection(
                    MuscleMapSelection(
                      group: group,
                      subGroupId: zone.subGroupId,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openZone(_MuscleZone zone) {
    final group = _groupById(widget.groups, zone.groupId);
    if (group == null) {
      return;
    }
    widget.onSelection(
      MuscleMapSelection(group: group, subGroupId: zone.subGroupId),
    );
  }
}

class _ModelToolbar extends StatelessWidget {
  const _ModelToolbar({
    required this.title,
    required this.onOpenGroup,
  });

  final String title;
  final VoidCallback? onOpenGroup;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.view_in_ar_rounded, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            if (onOpenGroup != null)
              IconButton(
                tooltip: 'Mo bai tap',
                onPressed: onOpenGroup,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
          ],
        ),
      ),
    );
  }
}

class _MuscleModelPainter extends CustomPainter {
  const _MuscleModelPainter({
    required this.angle,
    required this.zones,
    required this.selectedZone,
    required this.primary,
    required this.onSurface,
  });

  final double angle;
  final List<_MuscleZone> zones;
  final _MuscleZone? selectedZone;
  final Color primary;
  final Color onSurface;

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawBodyBase(canvas, size);
    _drawAnatomyDetailLayer(canvas, size);

    final projectedZones = _visibleProjectedZones(zones, angle, size);
    projectedZones.sort((a, b) => a.depth.compareTo(b.depth));
    for (final projected in projectedZones) {
      _drawZone(canvas, projected);
    }

    final labelZone = selectedZone == null
        ? null
        : _projectedZoneById(projectedZones, selectedZone!.id);
    if (labelZone != null) {
      _drawLabel(canvas, labelZone);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primary.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (var x = 0.0; x <= size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.92),
        width: size.width * 0.70,
        height: 42,
      ),
      Paint()
        ..color = primary.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawBodyBase(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final scale = math.min(size.width / 260, size.height / 400);
    final squeeze = 0.82 + 0.18 * math.cos(angle * math.pi / 180).abs();
    Offset p(double x, double y) =>
        Offset(centerX + x * scale * squeeze, y * scale);

    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.18);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, size.height * 0.92),
        width: 185 * scale * squeeze,
        height: 24,
      ),
      shadow,
    );

    final base = Paint()
      ..color = const Color(0xFF241A22).withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = primary.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawOval(
      Rect.fromCenter(
        center: p(0, 34),
        width: 46 * scale,
        height: 52 * scale,
      ),
      base,
    );

    final torso = Path()
      ..moveTo(p(-48, 76).dx, p(-48, 76).dy)
      ..quadraticBezierTo(
          p(-70, 114).dx, p(-70, 114).dy, p(-54, 188).dx, p(-54, 188).dy)
      ..quadraticBezierTo(
          p(-34, 226).dx, p(-34, 226).dy, p(0, 222).dx, p(0, 222).dy)
      ..quadraticBezierTo(
          p(34, 226).dx, p(34, 226).dy, p(54, 188).dx, p(54, 188).dy)
      ..quadraticBezierTo(
          p(70, 114).dx, p(70, 114).dy, p(48, 76).dx, p(48, 76).dy)
      ..quadraticBezierTo(p(22, 66).dx, p(22, 66).dy, p(0, 72).dx, p(0, 72).dy)
      ..quadraticBezierTo(
          p(-22, 66).dx, p(-22, 66).dy, p(-48, 76).dx, p(-48, 76).dy)
      ..close();
    canvas.drawPath(torso, base);
    canvas.drawPath(torso, stroke);

    for (final side in [-1.0, 1.0]) {
      final arm = Path()
        ..moveTo(p(side * 72, 104).dx, p(side * 72, 104).dy)
        ..quadraticBezierTo(p(side * 98, 130).dx, p(side * 98, 130).dy,
            p(side * 88, 214).dx, p(side * 88, 214).dy)
        ..quadraticBezierTo(p(side * 78, 236).dx, p(side * 78, 236).dy,
            p(side * 64, 216).dx, p(side * 64, 216).dy)
        ..quadraticBezierTo(p(side * 61, 148).dx, p(side * 61, 148).dy,
            p(side * 72, 104).dx, p(side * 72, 104).dy)
        ..close();
      canvas.drawPath(arm, base);
      canvas.drawPath(arm, stroke);

      final leg = Path()
        ..moveTo(p(side * 18, 220).dx, p(side * 18, 220).dy)
        ..quadraticBezierTo(p(side * 48, 232).dx, p(side * 48, 232).dy,
            p(side * 44, 352).dx, p(side * 44, 352).dy)
        ..quadraticBezierTo(p(side * 30, 382).dx, p(side * 30, 382).dy,
            p(side * 16, 352).dx, p(side * 16, 352).dy)
        ..quadraticBezierTo(p(side * 8, 275).dx, p(side * 8, 275).dy,
            p(side * 18, 220).dx, p(side * 18, 220).dy)
        ..close();
      canvas.drawPath(leg, base);
      canvas.drawPath(leg, stroke);
    }
  }

  void _drawAnatomyDetailLayer(Canvas canvas, Size size) {
    final front = _visibilityFor(0, angle);
    final back = _visibilityFor(180, angle);
    final leftSide = _visibilityFor(-90, angle);
    final rightSide = _visibilityFor(90, angle);
    final centerX = size.width / 2;
    final scale = math.min(size.width / 260, size.height / 400);
    final squeeze = 0.82 + 0.18 * math.cos(angle * math.pi / 180).abs();
    Offset p(double x, double y) =>
        Offset(centerX + x * scale * squeeze, y * scale);

    if (front > 0.12) {
      _drawFrontDetails(canvas, p, scale, front);
    }
    if (back > 0.12) {
      _drawBackDetails(canvas, p, scale, back);
    }
    if (leftSide > 0.18) {
      _drawSideDetails(canvas, p, scale, -1, leftSide);
    }
    if (rightSide > 0.18) {
      _drawSideDetails(canvas, p, scale, 1, rightSide);
    }
  }

  void _drawFrontDetails(
    Canvas canvas,
    Offset Function(double x, double y) p,
    double scale,
    double visibility,
  ) {
    final muscle = Paint()
      ..color = const Color(0xFFD83B2E).withValues(alpha: 0.68 * visibility)
      ..style = PaintingStyle.fill;
    final light = Paint()
      ..color = const Color(0xFFFF8750).withValues(alpha: 0.38 * visibility)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1 * scale
      ..strokeCap = StrokeCap.round;
    final dark = Paint()
      ..color = const Color(0xFF5D1515).withValues(alpha: 0.78 * visibility)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;

    for (final side in [-1.0, 1.0]) {
      final pec = Path()
        ..moveTo(p(0, 86).dx, p(0, 86).dy)
        ..cubicTo(p(side * 18, 78).dx, p(side * 18, 78).dy, p(side * 48, 84).dx,
            p(side * 48, 84).dy, p(side * 58, 104).dx, p(side * 58, 104).dy)
        ..quadraticBezierTo(p(side * 42, 128).dx, p(side * 42, 128).dy,
            p(side * 7, 120).dx, p(side * 7, 120).dy)
        ..quadraticBezierTo(
            p(side * 2, 104).dx, p(side * 2, 104).dy, p(0, 86).dx, p(0, 86).dy)
        ..close();
      canvas.drawPath(pec, muscle);
      canvas.drawPath(pec, dark);

      for (var i = 0; i < 4; i++) {
        final y = 93 + i * 7.0;
        canvas.drawLine(p(side * 7, y), p(side * (48 - i * 4), y + 11), light);
      }

      final arm = Path()
        ..moveTo(p(side * 78, 120).dx, p(side * 78, 120).dy)
        ..quadraticBezierTo(p(side * 93, 152).dx, p(side * 93, 152).dy,
            p(side * 82, 204).dx, p(side * 82, 204).dy)
        ..quadraticBezierTo(p(side * 70, 178).dx, p(side * 70, 178).dy,
            p(side * 72, 126).dx, p(side * 72, 126).dy)
        ..close();
      canvas.drawPath(arm, muscle);
      canvas.drawPath(arm, dark);
      canvas.drawLine(p(side * 78, 132), p(side * 84, 190), light);

      final quad = Path()
        ..moveTo(p(side * 17, 224).dx, p(side * 17, 224).dy)
        ..quadraticBezierTo(p(side * 48, 238).dx, p(side * 48, 238).dy,
            p(side * 38, 322).dx, p(side * 38, 322).dy)
        ..quadraticBezierTo(p(side * 22, 306).dx, p(side * 22, 306).dy,
            p(side * 16, 230).dx, p(side * 16, 230).dy)
        ..close();
      canvas.drawPath(quad, muscle);
      canvas.drawPath(quad, dark);
      canvas.drawLine(p(side * 28, 236), p(side * 30, 310), light);
      canvas.drawLine(p(side * 40, 248), p(side * 34, 304), light);
    }

    final abs = Path()
      ..moveTo(p(-20, 126).dx, p(-20, 126).dy)
      ..quadraticBezierTo(
          p(0, 120).dx, p(0, 120).dy, p(20, 126).dx, p(20, 126).dy)
      ..lineTo(p(18, 198).dx, p(18, 198).dy)
      ..quadraticBezierTo(
          p(0, 208).dx, p(0, 208).dy, p(-18, 198).dx, p(-18, 198).dy)
      ..close();
    canvas.drawPath(abs, muscle);
    canvas.drawPath(abs, dark);
    canvas.drawLine(p(0, 128), p(0, 198), light);
    for (final y in [142.0, 158.0, 176.0]) {
      canvas.drawLine(p(-17, y), p(17, y), dark);
    }
  }

  void _drawBackDetails(
    Canvas canvas,
    Offset Function(double x, double y) p,
    double scale,
    double visibility,
  ) {
    final muscle = Paint()
      ..color = const Color(0xFFC7352D).withValues(alpha: 0.70 * visibility)
      ..style = PaintingStyle.fill;
    final light = Paint()
      ..color = const Color(0xFFFF8A55).withValues(alpha: 0.34 * visibility)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale
      ..strokeCap = StrokeCap.round;
    final dark = Paint()
      ..color = const Color(0xFF4D1111).withValues(alpha: 0.78 * visibility)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;

    final traps = Path()
      ..moveTo(p(0, 66).dx, p(0, 66).dy)
      ..lineTo(p(-45, 88).dx, p(-45, 88).dy)
      ..quadraticBezierTo(
          p(-28, 120).dx, p(-28, 120).dy, p(0, 136).dx, p(0, 136).dy)
      ..quadraticBezierTo(
          p(28, 120).dx, p(28, 120).dy, p(45, 88).dx, p(45, 88).dy)
      ..close();
    canvas.drawPath(traps, muscle);
    canvas.drawPath(traps, dark);
    canvas.drawLine(p(0, 74), p(0, 196), light);

    for (final side in [-1.0, 1.0]) {
      final lat = Path()
        ..moveTo(p(side * 14, 112).dx, p(side * 14, 112).dy)
        ..cubicTo(
            p(side * 60, 112).dx,
            p(side * 60, 112).dy,
            p(side * 62, 178).dx,
            p(side * 62, 178).dy,
            p(side * 28, 210).dx,
            p(side * 28, 210).dy)
        ..quadraticBezierTo(p(side * 9, 176).dx, p(side * 9, 176).dy,
            p(side * 14, 112).dx, p(side * 14, 112).dy)
        ..close();
      canvas.drawPath(lat, muscle);
      canvas.drawPath(lat, dark);
      for (var i = 0; i < 4; i++) {
        canvas.drawLine(
          p(side * (18 + i * 8), 124 + i * 7),
          p(side * (45 + i * 2), 176 + i * 8),
          light,
        );
      }

      final rearArm = Path()
        ..moveTo(p(side * 76, 118).dx, p(side * 76, 118).dy)
        ..quadraticBezierTo(p(side * 92, 154).dx, p(side * 92, 154).dy,
            p(side * 80, 206).dx, p(side * 80, 206).dy)
        ..quadraticBezierTo(p(side * 67, 180).dx, p(side * 67, 180).dy,
            p(side * 70, 128).dx, p(side * 70, 128).dy)
        ..close();
      canvas.drawPath(rearArm, muscle);
      canvas.drawPath(rearArm, dark);

      final hamstring = Path()
        ..moveTo(p(side * 17, 226).dx, p(side * 17, 226).dy)
        ..quadraticBezierTo(p(side * 45, 246).dx, p(side * 45, 246).dy,
            p(side * 37, 320).dx, p(side * 37, 320).dy)
        ..quadraticBezierTo(p(side * 20, 304).dx, p(side * 20, 304).dy,
            p(side * 16, 230).dx, p(side * 16, 230).dy)
        ..close();
      canvas.drawPath(hamstring, muscle);
      canvas.drawPath(hamstring, dark);
      canvas.drawLine(p(side * 28, 242), p(side * 30, 312), light);
    }
  }

  void _drawSideDetails(
    Canvas canvas,
    Offset Function(double x, double y) p,
    double scale,
    double side,
    double visibility,
  ) {
    final paint = Paint()
      ..color = const Color(0xFFE24A32).withValues(alpha: 0.42 * visibility)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = const Color(0xFF5D1515).withValues(alpha: 0.55 * visibility)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9 * scale;

    final oblique = Path()
      ..moveTo(p(side * 48, 128).dx, p(side * 48, 128).dy)
      ..quadraticBezierTo(p(side * 64, 164).dx, p(side * 64, 164).dy,
          p(side * 38, 206).dx, p(side * 38, 206).dy)
      ..quadraticBezierTo(p(side * 28, 166).dx, p(side * 28, 166).dy,
          p(side * 48, 128).dx, p(side * 48, 128).dy)
      ..close();
    canvas.drawPath(oblique, paint);
    canvas.drawPath(oblique, stroke);
  }

  void _drawZone(Canvas canvas, _ProjectedZone projected) {
    final isSelected = selectedZone?.id == projected.zone.id;
    final rect = Rect.fromCenter(
      center: projected.center,
      width: projected.width,
      height: projected.height,
    );
    final path = _zonePath(projected);
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          projected.zone.color.withValues(alpha: isSelected ? 0.98 : 0.84),
          const Color(0xFF8C1E1E).withValues(alpha: isSelected ? 0.92 : 0.72),
        ],
      ).createShader(rect);
    final border = Paint()
      ..color = isSelected ? primary : const Color(0xFF5D1515)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.4 : 1.2;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);

    if (isSelected) {
      canvas.drawPath(
        path,
        Paint()
          ..color = primary.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
    }
  }

  void _drawLabel(Canvas canvas, _ProjectedZone projected) {
    final painter = TextPainter(
      text: TextSpan(
        text: projected.zone.label,
        style: TextStyle(
          color: onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 130);
    final bubble = Rect.fromLTWH(
      (projected.center.dx - painter.width / 2 - 10).clamp(6, double.infinity),
      math.max(6, projected.center.dy - projected.height / 2 - 38),
      painter.width + 20,
      28,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bubble, const Radius.circular(10)),
      Paint()..color = Colors.black.withValues(alpha: 0.58),
    );
    painter.paint(canvas, bubble.topLeft + const Offset(10, 6));
  }

  @override
  bool shouldRepaint(covariant _MuscleModelPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.zones != zones ||
        oldDelegate.selectedZone != selectedZone ||
        oldDelegate.primary != primary;
  }
}

class _MuscleGroupChips extends StatelessWidget {
  const _MuscleGroupChips({
    required this.groups,
    required this.selectedGroupId,
    required this.onSelected,
  });

  final List<MuscleGroup> groups;
  final String? selectedGroupId;
  final ValueChanged<MuscleGroup> onSelected;

  @override
  Widget build(BuildContext context) {
    final visibleGroups = groups.take(8).toList();
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final group in visibleGroups)
            ChoiceChip(
              label: Text(group.name),
              selected: selectedGroupId == group.id,
              onSelected: (_) => onSelected(group),
            ),
        ],
      ),
    );
  }
}

class _MuscleZone {
  const _MuscleZone({
    required this.id,
    required this.groupId,
    required this.label,
    required this.x,
    required this.y,
    required this.z,
    required this.width,
    required this.height,
    required this.normalDeg,
    required this.color,
    this.subGroupId,
  });

  factory _MuscleZone.forGroup(MuscleGroup group) {
    return _MuscleZone(
      id: group.id,
      groupId: group.id,
      label: group.name,
      x: 0,
      y: 145,
      z: -36,
      width: 62,
      height: 40,
      normalDeg: 0,
      color: const Color(0xFFE4472F),
    );
  }

  final String id;
  final String groupId;
  final String? subGroupId;
  final String label;
  final double x;
  final double y;
  final double z;
  final double width;
  final double height;
  final double normalDeg;
  final Color color;
}

class _ProjectedZone {
  const _ProjectedZone({
    required this.zone,
    required this.center,
    required this.width,
    required this.height,
    required this.depth,
  });

  final _MuscleZone zone;
  final Offset center;
  final double width;
  final double height;
  final double depth;
}

Path _zonePath(_ProjectedZone projected) {
  final c = projected.center;
  final w = projected.width;
  final h = projected.height;
  final id = projected.zone.id;
  final side = projected.zone.x < 0 ? -1.0 : 1.0;

  if (id.contains('delt')) {
    return Path()
      ..moveTo(c.dx - side * w * 0.48, c.dy - h * 0.10)
      ..quadraticBezierTo(
          c.dx - side * w * 0.18, c.dy - h * 0.58, c.dx, c.dy - h * 0.48)
      ..quadraticBezierTo(c.dx + side * w * 0.50, c.dy - h * 0.34,
          c.dx + side * w * 0.46, c.dy + h * 0.10)
      ..quadraticBezierTo(c.dx + side * w * 0.20, c.dy + h * 0.58,
          c.dx - side * w * 0.26, c.dy + h * 0.36)
      ..quadraticBezierTo(c.dx - side * w * 0.54, c.dy + h * 0.18,
          c.dx - side * w * 0.48, c.dy - h * 0.10)
      ..close();
  }

  if (id.contains('chest')) {
    final left = c.dx - w / 2;
    final right = c.dx + w / 2;
    final top = c.dy - h / 2;
    final bottom = c.dy + h / 2;
    return Path()
      ..moveTo(c.dx, top)
      ..cubicTo(
          left + w * 0.16, top - h * 0.10, left, c.dy, left + w * 0.10, bottom)
      ..quadraticBezierTo(c.dx, bottom + h * 0.10, right - w * 0.10, bottom)
      ..cubicTo(right, c.dy, right - w * 0.16, top - h * 0.10, c.dx, top)
      ..close();
  }

  if (id == 'lat' || id == 'mid-back') {
    final left = c.dx - w / 2;
    final right = c.dx + w / 2;
    final top = c.dy - h / 2;
    final bottom = c.dy + h / 2;
    return Path()
      ..moveTo(c.dx, top)
      ..cubicTo(
          left + w * 0.05, top + h * 0.18, left, c.dy, left + w * 0.20, bottom)
      ..quadraticBezierTo(c.dx, bottom + h * 0.18, right - w * 0.20, bottom)
      ..cubicTo(right, c.dy, right - w * 0.05, top + h * 0.18, c.dx, top)
      ..close();
  }

  if (id.contains('biceps') || id.contains('triceps')) {
    return Path()
      ..moveTo(c.dx, c.dy - h / 2)
      ..quadraticBezierTo(
          c.dx + w * 0.58, c.dy - h * 0.20, c.dx + w * 0.40, c.dy + h * 0.42)
      ..quadraticBezierTo(
          c.dx, c.dy + h * 0.58, c.dx - w * 0.40, c.dy + h * 0.42)
      ..quadraticBezierTo(c.dx - w * 0.58, c.dy - h * 0.20, c.dx, c.dy - h / 2)
      ..close();
  }

  if (id == 'abdominals') {
    return Path()
      ..moveTo(c.dx - w * 0.36, c.dy - h * 0.50)
      ..quadraticBezierTo(
          c.dx, c.dy - h * 0.62, c.dx + w * 0.36, c.dy - h * 0.50)
      ..lineTo(c.dx + w * 0.28, c.dy + h * 0.48)
      ..quadraticBezierTo(
          c.dx, c.dy + h * 0.58, c.dx - w * 0.28, c.dy + h * 0.48)
      ..close();
  }

  if (id == 'legs-main') {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(c.dx - w * 0.24, c.dy),
            width: w * 0.42,
            height: h,
          ),
          Radius.circular(w * 0.18),
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(c.dx + w * 0.24, c.dy),
            width: w * 0.42,
            height: h,
          ),
          Radius.circular(w * 0.18),
        ),
      );
  }

  return Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: w, height: h),
        Radius.circular(math.min(w, h) * 0.32),
      ),
    );
}

List<_ProjectedZone> _visibleProjectedZones(
  List<_MuscleZone> zones,
  double angle,
  Size size,
) {
  final centerX = size.width / 2;
  final scale = math.min(size.width / 260, size.height / 400);
  final radians = angle * math.pi / 180;
  final cosA = math.cos(radians);
  final sinA = math.sin(radians);

  return [
    for (final zone in zones)
      if (_visibilityFor(zone.normalDeg, angle) > 0.18)
        _ProjectedZone(
          zone: zone,
          center: Offset(
            centerX + (zone.x * cosA + zone.z * sinA) * scale,
            zone.y * scale,
          ),
          width: zone.width *
              scale *
              (0.74 + _visibilityFor(zone.normalDeg, angle) * 0.26),
          height: zone.height * scale,
          depth: zone.z * cosA - zone.x * sinA,
        ),
  ];
}

_MuscleZone? _hitTestZone(
  Offset position,
  Size size,
  List<_MuscleZone> zones,
  double angle,
) {
  final projectedZones = _visibleProjectedZones(zones, angle, size)
    ..sort((a, b) => b.depth.compareTo(a.depth));
  for (final projected in projectedZones) {
    if (_zonePath(projected).contains(position)) {
      return projected.zone;
    }
  }
  return null;
}

_ProjectedZone? _projectedZoneById(List<_ProjectedZone> zones, String id) {
  for (final zone in zones) {
    if (zone.zone.id == id) {
      return zone;
    }
  }
  return null;
}

double _visibilityFor(double normalDeg, double angle) {
  final diff = (normalDeg - angle) * math.pi / 180;
  return math.cos(diff).clamp(0.0, 1.0);
}

MuscleGroup? _groupById(List<MuscleGroup> groups, String id) {
  for (final group in groups) {
    if (group.id == id) {
      return group;
    }
  }
  return null;
}

List<_MuscleZone> _buildZones(List<MuscleGroup> groups) {
  final groupIds = groups.map((group) => group.id).toSet();
  bool hasGroup(String id) => groupIds.contains(id);

  return [
    if (hasGroup('shoulders')) ...[
      const _MuscleZone(
        id: 'front-delt-left',
        groupId: 'shoulders',
        subGroupId: 'front-delt',
        label: 'Vai trước',
        x: -42,
        y: 92,
        z: -42,
        width: 28,
        height: 22,
        normalDeg: 0,
        color: Color(0xFFF06B3A),
      ),
      const _MuscleZone(
        id: 'front-delt-right',
        groupId: 'shoulders',
        subGroupId: 'front-delt',
        label: 'Vai trước',
        x: 42,
        y: 92,
        z: -42,
        width: 28,
        height: 22,
        normalDeg: 0,
        color: Color(0xFFF06B3A),
      ),
      const _MuscleZone(
        id: 'side-delt-left',
        groupId: 'shoulders',
        subGroupId: 'side-delt',
        label: 'Vai giữa',
        x: -62,
        y: 98,
        z: -4,
        width: 26,
        height: 28,
        normalDeg: -90,
        color: Color(0xFFE95235),
      ),
      const _MuscleZone(
        id: 'side-delt-right',
        groupId: 'shoulders',
        subGroupId: 'side-delt',
        label: 'Vai giữa',
        x: 62,
        y: 98,
        z: -4,
        width: 26,
        height: 28,
        normalDeg: 90,
        color: Color(0xFFE95235),
      ),
      const _MuscleZone(
        id: 'rear-delt-left',
        groupId: 'shoulders',
        subGroupId: 'rear-delt',
        label: 'Vai sau',
        x: -42,
        y: 94,
        z: 48,
        width: 28,
        height: 22,
        normalDeg: 180,
        color: Color(0xFFC93B2D),
      ),
      const _MuscleZone(
        id: 'rear-delt-right',
        groupId: 'shoulders',
        subGroupId: 'rear-delt',
        label: 'Vai sau',
        x: 42,
        y: 94,
        z: 48,
        width: 28,
        height: 22,
        normalDeg: 180,
        color: Color(0xFFC93B2D),
      ),
    ],
    if (hasGroup('chest')) ...[
      const _MuscleZone(
        id: 'upper-chest',
        groupId: 'chest',
        subGroupId: 'upper-chest',
        label: 'Ngực trên',
        x: 0,
        y: 112,
        z: -46,
        width: 74,
        height: 22,
        normalDeg: 0,
        color: Color(0xFFE4472F),
      ),
      const _MuscleZone(
        id: 'mid-chest',
        groupId: 'chest',
        subGroupId: 'mid-chest',
        label: 'Ngực giữa',
        x: 0,
        y: 134,
        z: -48,
        width: 78,
        height: 26,
        normalDeg: 0,
        color: Color(0xFFD93A2B),
      ),
      const _MuscleZone(
        id: 'lower-chest',
        groupId: 'chest',
        subGroupId: 'lower-chest',
        label: 'Ngực dưới',
        x: 0,
        y: 158,
        z: -44,
        width: 68,
        height: 22,
        normalDeg: 0,
        color: Color(0xFFC93028),
      ),
    ],
    if (hasGroup('back')) ...[
      const _MuscleZone(
        id: 'lat',
        groupId: 'back',
        subGroupId: 'lat',
        label: 'Xô',
        x: 0,
        y: 130,
        z: 48,
        width: 78,
        height: 52,
        normalDeg: 180,
        color: Color(0xFFD84630),
      ),
      const _MuscleZone(
        id: 'mid-back',
        groupId: 'back',
        subGroupId: 'mid-back',
        label: 'Lưng giữa',
        x: 0,
        y: 172,
        z: 48,
        width: 58,
        height: 38,
        normalDeg: 180,
        color: Color(0xFFB8332B),
      ),
    ],
    if (hasGroup('biceps')) ...[
      const _MuscleZone(
        id: 'biceps-left',
        groupId: 'biceps',
        subGroupId: 'biceps-general',
        label: 'Tay trước',
        x: -72,
        y: 154,
        z: -28,
        width: 22,
        height: 70,
        normalDeg: 0,
        color: Color(0xFFE45034),
      ),
      const _MuscleZone(
        id: 'biceps-right',
        groupId: 'biceps',
        subGroupId: 'biceps-general',
        label: 'Tay trước',
        x: 72,
        y: 154,
        z: -28,
        width: 22,
        height: 70,
        normalDeg: 0,
        color: Color(0xFFE45034),
      ),
    ],
    if (hasGroup('triceps')) ...[
      const _MuscleZone(
        id: 'triceps-left',
        groupId: 'triceps',
        subGroupId: 'triceps-general',
        label: 'Tay sau',
        x: -72,
        y: 154,
        z: 30,
        width: 22,
        height: 72,
        normalDeg: 180,
        color: Color(0xFFC83D30),
      ),
      const _MuscleZone(
        id: 'triceps-right',
        groupId: 'triceps',
        subGroupId: 'triceps-general',
        label: 'Tay sau',
        x: 72,
        y: 154,
        z: 30,
        width: 22,
        height: 72,
        normalDeg: 180,
        color: Color(0xFFC83D30),
      ),
    ],
    if (hasGroup('core-cardio'))
      const _MuscleZone(
        id: 'abdominals',
        groupId: 'core-cardio',
        subGroupId: 'abdominals',
        label: 'Bụng',
        x: 0,
        y: 186,
        z: -48,
        width: 48,
        height: 70,
        normalDeg: 0,
        color: Color(0xFFE34A32),
      ),
    if (hasGroup('legs'))
      const _MuscleZone(
        id: 'legs-main',
        groupId: 'legs',
        subGroupId: 'legs-general',
        label: 'Chân đùi',
        x: 0,
        y: 286,
        z: -20,
        width: 72,
        height: 118,
        normalDeg: 0,
        color: Color(0xFFD9432F),
      ),
  ];
}
