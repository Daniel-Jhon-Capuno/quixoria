import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Full-screen non-blocking atmospheric transition overlay whenever the user
/// toggles between Light Mode (Day) and Dark Mode (Night).
///
/// Combines:
/// 1. Expanding circular eclipse / sunburst radial ripple
/// 2. Soft parchment / twilight ink-wash dissolve
/// 3. Smoothly morphing Sun ↔ Crescent Moon emblem that fades cleanly out
class ThemeShiftOverlay extends StatefulWidget {
  final bool isDarkMode;
  final String? themePresetId;
  final Widget child;

  const ThemeShiftOverlay({
    super.key,
    required this.isDarkMode,
    this.themePresetId,
    required this.child,
  });

  @override
  State<ThemeShiftOverlay> createState() => _ThemeShiftOverlayState();
}

class _ThemeShiftOverlayState extends State<ThemeShiftOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late bool _lastIsDark;
  String? _lastThemePresetId;
  bool _shiftingToDark = false;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _lastIsDark = widget.isDarkMode;
    _lastThemePresetId = widget.themePresetId;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _isAnimating = false);
        }
      });
  }

  @override
  void didUpdateWidget(covariant ThemeShiftOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final darkChanged = widget.isDarkMode != _lastIsDark;
    final presetChanged =
        widget.themePresetId != null && widget.themePresetId != _lastThemePresetId;
    if (darkChanged || presetChanged) {
      _lastIsDark = widget.isDarkMode;
      _lastThemePresetId = widget.themePresetId;
      _shiftingToDark = widget.isDarkMode;
      setState(() => _isAnimating = true);
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = _controller.value;
                  // Smooth bell-curve opacity for the celestial emblem
                  final badgeOpacity = t < 0.25
                      ? Curves.easeOut.transform(t / 0.25)
                      : (1.0 - Curves.easeIn.transform(((t - 0.25) / 0.75).clamp(0.0, 1.0)));
                  final badgeScale = 0.72 + 0.32 * Curves.easeOutBack.transform(t.clamp(0.0, 0.65) / 0.65);
                  final badgeTurns = (_shiftingToDark ? 0.14 : -0.14) * Curves.easeOutCubic.transform(t);

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Expanding Circular Eclipse / Sunburst Ripple + Ink Wash
                      CustomPaint(
                        size: Size.infinite,
                        painter: _RealmShiftRipplePainter(
                          progress: t,
                          toDark: _shiftingToDark,
                        ),
                      ),
                      // 2. Floating Sun ↔ Crescent Moon Emblem
                      Opacity(
                        opacity: badgeOpacity.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: badgeScale,
                          child: Transform.rotate(
                            angle: badgeTurns * 2 * math.pi,
                            child: Container(
                              width: 78,
                              height: 78,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: _shiftingToDark
                                      ? const [Color(0xFF1F1D36), Color(0xFF110F1E)]
                                      : const [Color(0xFFFFFBF0), Color(0xFFF6E6B8)],
                                ),
                                border: Border.all(
                                  color: _shiftingToDark
                                      ? const Color(0xFFE5B842).withValues(alpha: 0.75)
                                      : AppColors.antiqueGold.withValues(alpha: 0.85),
                                  width: 2.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_shiftingToDark
                                            ? const Color(0xFF9D4EDD)
                                            : AppColors.antiqueGold)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _shiftingToDark
                                    ? Icons.nightlight_round
                                    : Icons.wb_sunny_rounded,
                                size: 36,
                                color: _shiftingToDark
                                    ? const Color(0xFFF3D58D)
                                    : const Color(0xFFD97B29),
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
          ),
      ],
    );
  }
}

class _RealmShiftRipplePainter extends CustomPainter {
  final double progress;
  final bool toDark;

  _RealmShiftRipplePainter({
    required this.progress,
    required this.toDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.45);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) * 0.85;
    final eased = Curves.easeInOutCubic.transform(progress);
    final currentRadius = maxRadius * eased;

    // Soft fading wash opacity (peaks early, dissolves cleanly to 0 by progress = 1.0)
    final washAlpha = (progress < 0.35
            ? (progress / 0.35)
            : (1.0 - ((progress - 0.35) / 0.65)))
        .clamp(0.0, 1.0);

    // 1. Subtle radial veil (deep midnight twilight vs warm sunlit cream)
    final veilColor = toDark
        ? const Color(0xFF0E0D1B).withValues(alpha: 0.28 * washAlpha)
        : const Color(0xFFFFF8E6).withValues(alpha: 0.34 * washAlpha);

    canvas.drawCircle(center, currentRadius, Paint()..color = veilColor);

    // 2. Luminous expanding eclipse / sunburst shockwave ring
    final ringColor = toDark
        ? const Color(0xFFE5B842).withValues(alpha: 0.42 * (1.0 - eased))
        : const Color(0xFFE8A838).withValues(alpha: 0.48 * (1.0 - eased));

    canvas.drawCircle(
      center,
      currentRadius,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 + (1.0 - eased) * 5.0,
    );

    // 3. Soft inner halo glow
    if (currentRadius > 24) {
      final haloPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            (toDark ? const Color(0xFF7B2CBF) : const Color(0xFFFFD54F))
                .withValues(alpha: 0.16 * washAlpha),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: currentRadius * 0.55));
      canvas.drawCircle(center, currentRadius * 0.55, haloPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RealmShiftRipplePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.toDark != toDark;
}
