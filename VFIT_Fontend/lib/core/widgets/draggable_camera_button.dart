import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../presentation/theme/app_colors.dart';

/// A floating, draggable circular camera button inspired by iPhone's
/// AssistiveTouch button.
///
/// Features:
/// - Freely draggable anywhere on screen
/// - Auto-snaps to the nearest side edge when released
/// - Collision-avoidance: keeps itself away from the bottom navigation bar
/// - Glassmorphism design with animated press/idle states
/// - Haptic feedback on press and on snap
/// - Uploading spinner state
class DraggableCameraButton extends StatefulWidget {
  const DraggableCameraButton({
    super.key,
    required this.onPressed,
    this.isUploading = false,
    /// Height of the bottom navigation bar (or any obstacle at the bottom)
    /// so the button snaps above it automatically.
    this.bottomObstacleHeight = 80.0,
  });

  final VoidCallback onPressed;
  final bool isUploading;
  final double bottomObstacleHeight;

  @override
  State<DraggableCameraButton> createState() => _DraggableCameraButtonState();
}

class _DraggableCameraButtonState extends State<DraggableCameraButton>
    with SingleTickerProviderStateMixin {
  static const double _buttonSize = 64.0;
  static const double _edgeMargin = 16.0;

  /// Current position of the button (top-left corner of the bounding box).
  Offset _position = const Offset(-1, -1); // sentinel: not placed yet
  bool _isDragging = false;
  bool _isPressed = false;

  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  /// Place button at default position (bottom-right, above nav bar) on first
  /// layout.
  void _initPosition(Size screenSize) {
    if (_position.dx < 0) {
      _position = Offset(
        screenSize.width - _buttonSize - _edgeMargin,
        screenSize.height -
            _buttonSize -
            _edgeMargin -
            widget.bottomObstacleHeight,
      );
    }
  }

  /// Clamp position so the button stays within safe screen bounds.
  Offset _clamp(Offset raw, Size screenSize) {
    final minY = MediaQuery.of(context).padding.top + _edgeMargin;
    final maxY = screenSize.height -
        _buttonSize -
        _edgeMargin -
        widget.bottomObstacleHeight;
    return Offset(
      raw.dx.clamp(_edgeMargin, screenSize.width - _buttonSize - _edgeMargin),
      raw.dy.clamp(minY, maxY),
    );
  }

  /// Snap to left or right edge depending on where the button centre is.
  void _snapToEdge(Size screenSize) {
    final centre = _position.dx + _buttonSize / 2;
    final snapX = centre < screenSize.width / 2
        ? _edgeMargin
        : screenSize.width - _buttonSize - _edgeMargin;
    setState(() {
      _position = _clamp(Offset(snapX, _position.dy), screenSize);
    });
    HapticFeedback.lightImpact();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() => _isDragging = true);
    HapticFeedback.selectionClick();
  }

  void _onPanUpdate(DragUpdateDetails details, Size screenSize) {
    setState(() {
      _position = _clamp(_position + details.delta, screenSize);
    });
  }

  void _onPanEnd(DragEndDetails details, Size screenSize) {
    setState(() => _isDragging = false);
    _snapToEdge(screenSize);
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
    _scaleController.forward();
    HapticFeedback.mediumImpact();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    _initPosition(screenSize);

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: (d) => _onPanUpdate(d, screenSize),
        onPanEnd: (d) => _onPanEnd(d, screenSize),
        onTapDown: widget.isUploading ? null : _onTapDown,
        onTapUp: widget.isUploading
            ? null
            : (d) {
                _onTapUp(d);
                if (!_isDragging) {
                  widget.onPressed();
                }
              },
        onTapCancel: _onTapCancel,
        child: AnimatedScale(
          scale: _isPressed ? 0.88 : (_isDragging ? 1.08 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: _ButtonBody(
            isUploading: widget.isUploading,
            isDragging: _isDragging,
          ),
        ),
      ),
    );
  }
}

class _ButtonBody extends StatelessWidget {
  const _ButtonBody({
    required this.isUploading,
    required this.isDragging,
  });

  final bool isUploading;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // V-FIT design-system colours — no purple/blue glow
    final Color glowColor = AppColors.primaryCyan;
    final Color glowColor2 = AppColors.primaryEmerald;
    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.90);

    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow halo (outer)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isDragging ? 80 : 64,
            height: isDragging ? 80 : 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  glowColor.withValues(alpha: isDragging ? 0.30 : 0.18),
                  glowColor2.withValues(alpha: isDragging ? 0.20 : 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Glass pill body
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF1A2340).withValues(alpha: 0.85),
                            const Color(0xFF0D1B36).withValues(alpha: 0.90),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.75),
                            Colors.white.withValues(alpha: 0.55),
                          ],
                  ),
                  border: Border.all(
                    color: borderColor,
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: isDragging ? 0.45 : 0.25),
                      blurRadius: isDragging ? 28 : 18,
                      spreadRadius: isDragging ? 2 : 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(child: _ButtonIcon(isUploading: isUploading)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonIcon extends StatefulWidget {
  const _ButtonIcon({required this.isUploading});
  final bool isUploading;

  @override
  State<_ButtonIcon> createState() => _ButtonIconState();
}

class _ButtonIconState extends State<_ButtonIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isUploading) {
      return SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.white.withValues(alpha: 0.9),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        final opacity = 0.75 + _pulseController.value * 0.25;
        return ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            colors: [AppColors.primaryCyan, AppColors.primaryEmerald],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect),
          blendMode: BlendMode.srcIn,
          child: Icon(
            Icons.camera_alt_rounded,
            size: 28,
            color: Colors.white.withValues(alpha: opacity),
          ),
        );
      },
    );
  }
}
