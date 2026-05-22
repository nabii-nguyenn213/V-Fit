import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

import '../../domain/entities/exercise_catalog.dart';

enum _MuscleMapSide { anterior, posterior }

class InteractiveMuscleMap extends StatefulWidget {
  const InteractiveMuscleMap({
    super.key,
    required this.groups,
    required this.onGroupSelected,
  });

  final List<MuscleGroup> groups;
  final ValueChanged<MuscleGroup> onGroupSelected;

  @override
  State<InteractiveMuscleMap> createState() => _InteractiveMuscleMapState();
}

class _InteractiveMuscleMapState extends State<InteractiveMuscleMap> {
  static const _anteriorAsset = 'assets/muscle_map/anterior.svg';
  static const _posteriorAsset = 'assets/muscle_map/posterior.svg';

  late final Future<_SvgMuscleMapData> _anteriorMap;
  late final Future<_SvgMuscleMapData> _posteriorMap;
  _MuscleMapSide _side = _MuscleMapSide.anterior;
  String? _selectedSlug;

  bool get _isAnterior => _side == _MuscleMapSide.anterior;
  String get _assetPath => _isAnterior ? _anteriorAsset : _posteriorAsset;
  Future<_SvgMuscleMapData> get _mapFuture =>
      _isAnterior ? _anteriorMap : _posteriorMap;

  @override
  void initState() {
    super.initState();
    _anteriorMap = _SvgMuscleMapData.load(_anteriorAsset);
    _posteriorMap = _SvgMuscleMapData.load(_posteriorAsset);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupsBySlug = {
      for (final group in widget.groups) group.id: group,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surface.withValues(alpha: isDark ? 0.92 : 0.98),
            scheme.surfaceContainerHighest
                .withValues(alpha: isDark ? 0.46 : 0.62),
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
              _SideToggle(
                side: _side,
                onChanged: (side) {
                  setState(() {
                    _side = side;
                    _selectedSlug = null;
                  });
                },
              ),
              const SizedBox(height: 18),
              FutureBuilder<_SvgMuscleMapData>(
                future: _mapFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 430,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final mapData = snapshot.data!;
                  final selectedGroup = _selectedSlug == null
                      ? null
                      : groupsBySlug[_selectedSlug];

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final width = math.min(constraints.maxWidth, 340.0);
                      final height = width * mapData.aspectRatio;

                      return Center(
                        child: SizedBox(
                          width: width,
                          height: height,
                          child: _SvgMuscleMapViewport(
                            assetPath: _assetPath,
                            mapData: mapData,
                            groupsBySlug: groupsBySlug,
                            selectedSlug: _selectedSlug,
                            selectedGroup: selectedGroup,
                            onTapRegion: _selectAndOpen,
                            onTapBadge: () {
                              final group = selectedGroup;
                              if (group != null) {
                                widget.onGroupSelected(group);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectAndOpen(MuscleGroup group) async {
    setState(() => _selectedSlug = group.id);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (mounted) {
      widget.onGroupSelected(group);
    }
  }
}

class _SvgMuscleMapViewport extends StatelessWidget {
  const _SvgMuscleMapViewport({
    required this.assetPath,
    required this.mapData,
    required this.groupsBySlug,
    required this.selectedSlug,
    required this.selectedGroup,
    required this.onTapRegion,
    required this.onTapBadge,
  });

  final String assetPath;
  final _SvgMuscleMapData mapData;
  final Map<String, MuscleGroup> groupsBySlug;
  final String? selectedSlug;
  final MuscleGroup? selectedGroup;
  final ValueChanged<MuscleGroup> onTapRegion;
  final VoidCallback onTapBadge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedRegion =
        selectedSlug == null ? null : mapData.regions[selectedSlug];

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final transform = mapData.transformFor(size);
        final badgeOffset = selectedRegion == null
            ? null
            : transform.svgToLocal(selectedRegion.badgeAnchor);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final slug = mapData.hitTest(details.localPosition, size);
            final group = slug == null ? null : groupsBySlug[slug];
            if (group != null) {
              onTapRegion(group);
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _MuscleMapGridPainter(color: scheme.primary),
                ),
              ),
              Positioned.fill(
                child: SvgPicture.asset(
                  assetPath,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _MuscleHighlightPainter(
                    mapData: mapData,
                    selectedSlug: selectedSlug,
                    color: scheme.primary,
                  ),
                ),
              ),
              if (selectedGroup != null && badgeOffset != null)
                Positioned(
                  left: (badgeOffset.dx - 54).clamp(0, size.width - 108),
                  top: (badgeOffset.dy - 24).clamp(0, size.height - 48),
                  child: _MuscleInfoBadge(
                    group: selectedGroup!,
                    onTap: onTapBadge,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SideToggle extends StatelessWidget {
  const _SideToggle({
    required this.side,
    required this.onChanged,
  });

  final _MuscleMapSide side;
  final ValueChanged<_MuscleMapSide> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.50),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: _SideButton(
                    icon: Icons.accessibility_new,
                    label: 'Mặt trước',
                    selected: side == _MuscleMapSide.anterior,
                    onTap: () => onChanged(_MuscleMapSide.anterior),
                  ),
                ),
                Expanded(
                  child: _SideButton(
                    icon: Icons.accessibility,
                    label: 'Mặt sau',
                    selected: side == _MuscleMapSide.posterior,
                    onTap: () => onChanged(_MuscleMapSide.posterior),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MuscleInfoBadge extends StatelessWidget {
  const _MuscleInfoBadge({
    required this.group,
    required this.onTap,
  });

  final MuscleGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.64),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.55)),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.25),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${group.exerciseCount} bài',
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SvgMuscleMapData {
  const _SvgMuscleMapData({
    required this.viewBox,
    required this.regions,
  });

  final Rect viewBox;
  final Map<String, _MuscleRegion> regions;

  double get aspectRatio => viewBox.height / viewBox.width;

  static Future<_SvgMuscleMapData> load(String assetPath) async {
    final rawSvg = await rootBundle.loadString(assetPath);
    final document = XmlDocument.parse(rawSvg);
    final svg = document.rootElement;
    final viewBox = _parseViewBox(svg.getAttribute('viewBox'));
    final bySlug = <String, _MutableMuscleRegion>{};

    for (final element in document.descendants.whereType<XmlElement>()) {
      if (element.name.local != 'path') {
        continue;
      }
      final id = element.getAttribute('id');
      final data = element.getAttribute('d');
      if (id == null || id.isEmpty || data == null || data.isEmpty) {
        continue;
      }

      final path = parseSvgPathData(data);
      final region = bySlug.putIfAbsent(
        id,
        () => _MutableMuscleRegion(
          slug: id,
          label: element.getAttribute('data-label') ?? id,
          badgeAnchor: _parseBadgeAnchor(element) ?? path.getBounds().center,
        ),
      );
      region.path.addPath(path, Offset.zero);

      final anchor = _parseBadgeAnchor(element);
      if (anchor != null) {
        region.badgeAnchor = anchor;
      }
    }

    return _SvgMuscleMapData(
      viewBox: viewBox,
      regions: {
        for (final entry in bySlug.entries) entry.key: entry.value.freeze(),
      },
    );
  }

  String? hitTest(Offset localPosition, Size size) {
    final transform = transformFor(size);
    final svgPoint = transform.localToSvg(localPosition);
    for (final region in regions.values.toList().reversed) {
      if (region.path.contains(svgPoint)) {
        return region.slug;
      }
    }
    return null;
  }

  _SvgMapTransform transformFor(Size size) {
    final scale = math.min(
      size.width / viewBox.width,
      size.height / viewBox.height,
    );
    final drawnSize = Size(viewBox.width * scale, viewBox.height * scale);
    final offset = Offset(
      (size.width - drawnSize.width) / 2,
      (size.height - drawnSize.height) / 2,
    );
    return _SvgMapTransform(
      viewBox: viewBox,
      scale: scale,
      offset: offset,
    );
  }

  static Rect _parseViewBox(String? value) {
    if (value == null) {
      return const Rect.fromLTWH(0, 0, 240, 360);
    }
    final parts = value
        .split(RegExp(r'[\s,]+'))
        .where((part) => part.isNotEmpty)
        .map(double.parse)
        .toList();
    if (parts.length != 4) {
      return const Rect.fromLTWH(0, 0, 240, 360);
    }
    return Rect.fromLTWH(parts[0], parts[1], parts[2], parts[3]);
  }

  static Offset? _parseBadgeAnchor(XmlElement element) {
    final x = double.tryParse(element.getAttribute('data-badge-x') ?? '');
    final y = double.tryParse(element.getAttribute('data-badge-y') ?? '');
    if (x == null || y == null) {
      return null;
    }
    return Offset(x, y);
  }
}

class _MutableMuscleRegion {
  _MutableMuscleRegion({
    required this.slug,
    required this.label,
    required this.badgeAnchor,
  });

  final String slug;
  final String label;
  Offset badgeAnchor;
  final Path path = Path();

  _MuscleRegion freeze() {
    return _MuscleRegion(
      slug: slug,
      label: label,
      path: Path.from(path),
      badgeAnchor: badgeAnchor,
    );
  }
}

class _MuscleRegion {
  const _MuscleRegion({
    required this.slug,
    required this.label,
    required this.path,
    required this.badgeAnchor,
  });

  final String slug;
  final String label;
  final Path path;
  final Offset badgeAnchor;
}

class _SvgMapTransform {
  const _SvgMapTransform({
    required this.viewBox,
    required this.scale,
    required this.offset,
  });

  final Rect viewBox;
  final double scale;
  final Offset offset;

  Offset localToSvg(Offset local) {
    return Offset(
      (local.dx - offset.dx) / scale + viewBox.left,
      (local.dy - offset.dy) / scale + viewBox.top,
    );
  }

  Offset svgToLocal(Offset svgPoint) {
    return Offset(
      (svgPoint.dx - viewBox.left) * scale + offset.dx,
      (svgPoint.dy - viewBox.top) * scale + offset.dy,
    );
  }

  void apply(Canvas canvas) {
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    canvas.translate(-viewBox.left, -viewBox.top);
  }
}

class _MuscleHighlightPainter extends CustomPainter {
  const _MuscleHighlightPainter({
    required this.mapData,
    required this.selectedSlug,
    required this.color,
  });

  final _SvgMuscleMapData mapData;
  final String? selectedSlug;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final selected =
        selectedSlug == null ? null : mapData.regions[selectedSlug];
    if (selected == null) {
      return;
    }

    final transform = mapData.transformFor(size);
    canvas.save();
    transform.apply(canvas);
    canvas.drawPath(
      selected.path,
      Paint()
        ..color = color.withValues(alpha: 0.26)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      selected.path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 / transform.scale
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MuscleHighlightPainter oldDelegate) {
    return oldDelegate.mapData != mapData ||
        oldDelegate.selectedSlug != selectedSlug ||
        oldDelegate.color != color;
  }
}

class _MuscleMapGridPainter extends CustomPainter {
  const _MuscleMapGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (var x = 0.0; x <= size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MuscleMapGridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
