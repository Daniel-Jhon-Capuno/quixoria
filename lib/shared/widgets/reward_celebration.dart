import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import 'currency_bar.dart';
import 'duo_button.dart';
import 'quixote_mascot.dart';

enum CelebrationType {
  gems,
  levelComplete,
  streak,
}

enum RewardCurrencyType {
  gem,
  heart,
  key,
  streakFlame,
}

class RewardCelebrationOverlay extends StatefulWidget {
  final Widget child;

  const RewardCelebrationOverlay({super.key, required this.child});

  static RewardCelebrationOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<RewardCelebrationOverlayState>() ??
        RewardCelebrationOverlayState.instance;
  }

  /// Global static accessor for the active celebration overlay
  static RewardCelebrationOverlayState? get instance => RewardCelebrationOverlayState.instance;

  /// Global notifier when a flying currency item impacts its target counter at the top
  static final ValueNotifier<RewardCurrencyType?> onCurrencyArrived = ValueNotifier(null);

  /// Triggers standard celebratory confetti burst
  static void show(BuildContext context) {
    of(context)?.burst();
  }

  static void showCelebration(BuildContext context, {CelebrationType? celebrationType}) {
    of(context)?.burst();
  }

  /// Pops [gems], [hearts], [keys] from [origin] (or the context widget)
  /// and gracefully flies them to their respective currency destinations at the top bar.
  static void emitFlight({
    required BuildContext context,
    Offset? origin,
    int gems = 0,
    int hearts = 0,
    int keys = 0,
    VoidCallback? onComplete,
  }) {
    final effectiveOrigin = origin ?? _getWidgetCenter(context);
    of(context)?.launchFlight(
      origin: effectiveOrigin,
      gems: gems,
      hearts: hearts,
      keys: keys,
      onComplete: onComplete,
    );
  }

  /// Specialized chest opening animation with gems, energy hearts, and optional golden keys.
  static void openChest(
    BuildContext context, {
    Offset? origin,
    int gems = 50,
    int hearts = 2,
    int keys = 0,
    VoidCallback? onComplete,
  }) {
    emitFlight(
      context: context,
      origin: origin,
      gems: gems,
      hearts: hearts,
      keys: keys,
      onComplete: onComplete,
    );
  }

  /// Specialized daily quest claim animation.
  static void claimDailyQuest(
    BuildContext context, {
    Offset? origin,
    int gems = 20,
    VoidCallback? onComplete,
  }) {
    emitFlight(
      context: context,
      origin: origin,
      gems: gems,
      onComplete: onComplete,
    );
  }

  static Offset? _getWidgetCenter(BuildContext context) {
    if (!context.mounted) return null;
    try {
      final renderObject = context.findRenderObject();
      if (renderObject is RenderBox && renderObject.hasSize && renderObject.attached) {
        return renderObject.localToGlobal(renderObject.size.center(Offset.zero));
      }
    } catch (_) {
      // Gracefully fall back if context is deactivated or renderObject is unattached
    }
    return null;
  }

  @override
  State<RewardCelebrationOverlay> createState() => RewardCelebrationOverlayState();
}

class RewardCelebrationOverlayState extends State<RewardCelebrationOverlay>
    with TickerProviderStateMixin {
  static RewardCelebrationOverlayState? instance;

  late AnimationController _confettiController;
  late AnimationController _flightController;

  final List<_ConfettiParticle> _confetti = [];
  final List<_FlyingCurrencyItem> _flyingItems = [];
  final List<_ImpactSpark> _impacts = [];
  final math.Random _random = math.Random();

  bool _isConfettiActive = false;
  bool _isFlightActive = false;
  VoidCallback? _onFlightComplete;

  @override
  void initState() {
    super.initState();
    instance = this;

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..addListener(() {
        if (mounted) setState(() {});
      })..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) {
            setState(() {
              _isConfettiActive = false;
              _confetti.clear();
            });
          }
        }
      });

    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1750),
    )..addListener(_onFlightTick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) {
            setState(() {
              _isFlightActive = false;
              _flyingItems.clear();
              _impacts.clear();
            });
          }
          _onFlightComplete?.call();
          _onFlightComplete = null;
        }
      });
  }

  @override
  void dispose() {
    if (instance == this) instance = null;
    _confettiController.dispose();
    _flightController.dispose();
    super.dispose();
  }

  void burst() {
    _confetti.clear();
    final colors = [
      AppColors.antiqueGold,
      AppColors.vermillion,
      AppColors.successGreen,
      AppColors.gemCyan,
      AppColors.sageGreen,
    ];

    for (int i = 0; i < 42; i++) {
      _confetti.add(
        _ConfettiParticle(
          angle: _random.nextDouble() * 2 * math.pi,
          speed: 180 + _random.nextDouble() * 260,
          color: colors[_random.nextInt(colors.length)],
          size: 6 + _random.nextDouble() * 8,
          rotationSpeed: (_random.nextDouble() - 0.5) * 6,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isConfettiActive = true;
      });
    }
    _confettiController.forward(from: 0.0);
  }

  void launchFlight({
    Offset? origin,
    int gems = 0,
    int hearts = 0,
    int keys = 0,
    VoidCallback? onComplete,
  }) {
    final media = MediaQuery.maybeOf(context);
    final screenSize = media?.size ?? const Size(400, 800);
    final topPadding = media?.padding.top ?? 24.0;

    final start = origin ?? Offset(screenSize.width / 2, screenSize.height * 0.52);
    _flyingItems.clear();
    _impacts.clear();
    _onFlightComplete = onComplete;

    // Determine particle quantities
    final gemCount = gems > 0 ? (gems >= 50 ? 10 : (gems >= 20 ? 7 : 5)) : 0;
    final heartCount = hearts > 0 ? (hearts >= 2 ? 3 : 2) : 0;
    final keyCount = keys > 0 ? (keys >= 2 ? 2 : 1) : 0;

    int totalItems = gemCount + heartCount + keyCount;
    if (totalItems == 0) {
      onComplete?.call();
      return;
    }

    int itemIndex = 0;

    // Helper to calculate burst position in random radial fan with upward lift
    Offset makeBurstOffset(double angle, double dist) {
      return Offset(
        start.dx + math.cos(angle) * dist,
        start.dy + math.sin(angle) * dist - 26.0,
      );
    }

    // 1. GEMS
    final gemTarget = _getDestination(RewardCurrencyType.gem, screenSize, topPadding);
    for (int i = 0; i < gemCount; i++) {
      final angle = -math.pi * 0.85 + (i / math.max(1, gemCount - 1)) * (math.pi * 0.7) +
          (_random.nextDouble() - 0.5) * 0.35;
      final dist = 45.0 + _random.nextDouble() * 45.0;
      final burstPos = makeBurstOffset(angle, dist);

      final midX = (burstPos.dx + gemTarget.dx) / 2;
      final lateralArc = ((i % 2 == 0) ? 1 : -1) * (35.0 + i * 8.0);
      final controlPoint = Offset(
        midX + lateralArc,
        math.min(burstPos.dy, gemTarget.dy) - (40.0 + _random.nextDouble() * 30.0),
      );

      _flyingItems.add(
        _FlyingCurrencyItem(
          type: RewardCurrencyType.gem,
          startPosition: start,
          burstPosition: burstPos,
          targetPosition: gemTarget,
          controlPoint: controlPoint,
          delayStart: 0.20 + (itemIndex * 0.035),
          flightDuration: 0.44,
          size: 26.0,
          rotation: (_random.nextDouble() - 0.5) * 0.6,
        ),
      );
      itemIndex++;
    }

    // 2. HEARTS (Energy)
    final heartTarget = _getDestination(RewardCurrencyType.heart, screenSize, topPadding);
    for (int i = 0; i < heartCount; i++) {
      final angle = -math.pi * 0.65 - (_random.nextDouble() * 0.6);
      final dist = 55.0 + _random.nextDouble() * 35.0;
      final burstPos = makeBurstOffset(angle, dist);

      final midX = (burstPos.dx + heartTarget.dx) / 2;
      final lateralArc = -45.0 - (i * 12.0);
      final controlPoint = Offset(
        midX + lateralArc,
        math.min(burstPos.dy, heartTarget.dy) - 50.0,
      );

      _flyingItems.add(
        _FlyingCurrencyItem(
          type: RewardCurrencyType.heart,
          startPosition: start,
          burstPosition: burstPos,
          targetPosition: heartTarget,
          controlPoint: controlPoint,
          delayStart: 0.24 + (itemIndex * 0.04),
          flightDuration: 0.46,
          size: 28.0,
          rotation: 0.0,
        ),
      );
      itemIndex++;
    }

    // 3. KEYS (Golden Keys)
    final keyTarget = _getDestination(RewardCurrencyType.key, screenSize, topPadding);
    for (int i = 0; i < keyCount; i++) {
      final angle = -math.pi * 0.25 + (_random.nextDouble() * 0.5);
      final dist = 60.0 + _random.nextDouble() * 30.0;
      final burstPos = makeBurstOffset(angle, dist);

      final midX = (burstPos.dx + keyTarget.dx) / 2;
      final lateralArc = 50.0 + (i * 15.0);
      final controlPoint = Offset(
        midX + lateralArc,
        math.min(burstPos.dy, keyTarget.dy) - 60.0,
      );

      _flyingItems.add(
        _FlyingCurrencyItem(
          type: RewardCurrencyType.key,
          startPosition: start,
          burstPosition: burstPos,
          targetPosition: keyTarget,
          controlPoint: controlPoint,
          delayStart: 0.28 + (itemIndex * 0.045),
          flightDuration: 0.48,
          size: 30.0,
          rotation: (_random.nextDouble() - 0.5) * 0.4,
        ),
      );
      itemIndex++;
    }

    // Play initial burst sound and haptics
    SoundService.instance.play(Sfx.reward);
    HapticService.instance.medium();

    if (mounted) {
      setState(() {
        _isFlightActive = true;
      });
    }
    _flightController.forward(from: 0.0);
  }

  void _onFlightTick() {
    final t = _flightController.value;

    // Check arrivals
    for (final item in _flyingItems) {
      if (!item.hasArrived) {
        final flightEnd = item.delayStart + item.flightDuration;
        if (t >= flightEnd) {
          item.hasArrived = true;

          // Impact shockwave at target
          _impacts.add(
            _ImpactSpark(
              type: item.type,
              center: item.targetPosition,
              startTime: t,
            ),
          );

          // Audio chime & light haptic for each arrived currency
          SoundService.instance.play(Sfx.tap);
          HapticService.instance.light();

          // Notify CurrencyBar to bounce corresponding pill
          RewardCelebrationOverlay.onCurrencyArrived.value = item.type;
        }
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Offset _getDestination(RewardCurrencyType type, Size screenSize, double topPadding) {
    GlobalKey? targetKey;
    switch (type) {
      case RewardCurrencyType.gem:
        targetKey = CurrencyBar.gemsKey;
        break;
      case RewardCurrencyType.heart:
        targetKey = CurrencyBar.energyKey;
        break;
      case RewardCurrencyType.streakFlame:
        targetKey = CurrencyBar.streakKey;
        break;
      case RewardCurrencyType.key:
        targetKey = CurrencyBar.keysKey;
        break;
    }

    final targetContext = targetKey.currentContext;
    if (targetContext != null) {
      final box = targetContext.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        return box.localToGlobal(box.size.center(Offset.zero));
      }
    }

    // High-precision screen-proportional fallback targets
    switch (type) {
      case RewardCurrencyType.gem:
        return Offset(screenSize.width * 0.72, topPadding + 26);
      case RewardCurrencyType.heart:
        return Offset(screenSize.width * 0.44, topPadding + 26);
      case RewardCurrencyType.key:
        return Offset(screenSize.width * 0.88, topPadding + 26);
      case RewardCurrencyType.streakFlame:
        return Offset(screenSize.width * 0.18, topPadding + 26);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isConfettiActive)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _CelebrationPainter(
                  progress: _confettiController.value,
                  particles: _confetti,
                ),
              ),
            ),
          ),
        if (_isFlightActive)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _FlyingRewardPainter(
                  t: _flightController.value,
                  items: _flyingItems,
                  impacts: _impacts,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Confetti Models & Painter
// ---------------------------------------------------------------------------

class _ConfettiParticle {
  final double angle;
  final double speed;
  final Color color;
  final double size;
  final double rotationSpeed;

  _ConfettiParticle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.rotationSpeed,
  });
}

class _CelebrationPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  _CelebrationPainter({
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.4);

    for (final p in particles) {
      final distance = p.speed * progress;
      final x = center.dx + math.cos(p.angle) * distance;
      final y = center.dy + math.sin(p.angle) * distance + (250 * progress * progress); // gravity
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotationSpeed * progress);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.8),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ---------------------------------------------------------------------------
// Flying Currency Engine Models & Painter
// ---------------------------------------------------------------------------

class _FlyingCurrencyItem {
  final RewardCurrencyType type;
  final Offset startPosition;
  final Offset burstPosition;
  final Offset targetPosition;
  final Offset controlPoint;
  final double delayStart;
  final double flightDuration;
  final double size;
  final double rotation;
  bool hasArrived = false;
  final List<Offset> trail = [];

  _FlyingCurrencyItem({
    required this.type,
    required this.startPosition,
    required this.burstPosition,
    required this.targetPosition,
    required this.controlPoint,
    required this.delayStart,
    required this.flightDuration,
    required this.size,
    required this.rotation,
  });
}

class _ImpactSpark {
  final RewardCurrencyType type;
  final Offset center;
  final double startTime;

  _ImpactSpark({
    required this.type,
    required this.center,
    required this.startTime,
  });
}

class _FlyingRewardPainter extends CustomPainter {
  final double t;
  final List<_FlyingCurrencyItem> items;
  final List<_ImpactSpark> impacts;

  _FlyingRewardPainter({
    required this.t,
    required this.items,
    required this.impacts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Impact Sparks & Arrival Rings at Destinations
    for (final impact in impacts) {
      final elapsed = t - impact.startTime;
      if (elapsed >= 0.0 && elapsed <= 0.22) {
        final progress = (elapsed / 0.22).clamp(0.0, 1.0);
        final color = _getCurrencyColor(impact.type);
        final opacity = (1.0 - progress).clamp(0.0, 1.0);

        // Expanding shockwave ring
        final ringPaint = Paint()
          ..color = color.withValues(alpha: opacity * 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (1.0 - progress) * 2.8;
        canvas.drawCircle(impact.center, 5.0 + progress * 24.0, ringPaint);

        // Sparkle rays
        for (int i = 0; i < 6; i++) {
          final rayAngle = (i / 6.0) * math.pi * 2 + progress * 0.5;
          final rayDist = 6.0 + progress * 22.0;
          final sparkPaint = Paint()
            ..color = Colors.white.withValues(alpha: opacity)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(
            Offset(
              impact.center.dx + math.cos(rayAngle) * rayDist,
              impact.center.dy + math.sin(rayAngle) * rayDist,
            ),
            (1.0 - progress) * 2.2,
            sparkPaint,
          );
        }
      }
    }

    // 2. Draw Flying Items & Trails
    for (final item in items) {
      if (item.hasArrived) continue;

      Offset currentPos;
      double scale = 1.0;
      double rotation = item.rotation;

      if (t < 0.20) {
        // Phase 1: Spring pop from startPosition to burstPosition
        final p = (t / 0.20).clamp(0.0, 1.0);
        final curveP = Curves.easeOutBack.transform(p);
        currentPos = Offset.lerp(item.startPosition, item.burstPosition, curveP)!;
        scale = curveP * 1.25;
      } else if (t < item.delayStart) {
        // Phase 2: Gentle hover suspension
        currentPos = item.burstPosition;
        scale = 1.15;
      } else {
        // Phase 3: Curved Bézier flight towards destination
        final flightT = ((t - item.delayStart) / item.flightDuration).clamp(0.0, 1.0);
        final curveFlight = Curves.easeInOutCubic.transform(flightT);

        // Quadratic Bézier: (1-p)^2 * P0 + 2(1-p)p * Pc + p^2 * Pt
        final u = 1.0 - curveFlight;
        final tt = curveFlight * curveFlight;
        final uu = u * u;
        final x = uu * item.burstPosition.dx + 2 * u * curveFlight * item.controlPoint.dx + tt * item.targetPosition.dx;
        final y = uu * item.burstPosition.dy + 2 * u * curveFlight * item.controlPoint.dy + tt * item.targetPosition.dy;
        currentPos = Offset(x, y);

        // Scale scales down slightly to blend into destination icon
        scale = 1.15 - (curveFlight * 0.35);

        // Add to motion trail
        item.trail.add(currentPos);
        if (item.trail.length > 5) {
          item.trail.removeAt(0);
        }

        // Rotate along trajectory
        rotation += flightT * 2.5;
      }

      // Draw glowing motion trail
      final trailColor = _getCurrencyColor(item.type);
      for (int i = 0; i < item.trail.length; i++) {
        final tp = item.trail[i];
        final trailFraction = (i + 1) / (item.trail.length + 1);
        final trailPaint = Paint()
          ..color = trailColor.withValues(alpha: trailFraction * 0.45)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(tp, 2.0 + (trailFraction * 3.5), trailPaint);
      }

      // Draw Currency Vector Icon
      switch (item.type) {
        case RewardCurrencyType.gem:
          _drawGem(canvas, currentPos, item.size * scale, rotation);
          break;
        case RewardCurrencyType.heart:
          _drawHeart(canvas, currentPos, item.size * scale);
          break;
        case RewardCurrencyType.key:
          _drawKey(canvas, currentPos, item.size * scale, rotation);
          break;
        case RewardCurrencyType.streakFlame:
          _drawFlame(canvas, currentPos, item.size * scale);
          break;
      }
    }
  }

  Color _getCurrencyColor(RewardCurrencyType type) {
    switch (type) {
      case RewardCurrencyType.gem:
        return AppColors.gemCyan;
      case RewardCurrencyType.heart:
        return AppColors.energyRed;
      case RewardCurrencyType.key:
        return AppColors.goldenKey;
      case RewardCurrencyType.streakFlame:
        return AppColors.streakOrange;
    }
  }

  void _drawGem(Canvas canvas, Offset center, double size, double rotation) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final r = size / 2;

    // Ambient Cyan Glow
    final glowPaint = Paint()
      ..color = AppColors.gemCyan.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawCircle(Offset.zero, r * 1.1, glowPaint);

    final topY = -r * 0.85;
    final crownY = -r * 0.32;
    final cornerY = -r * 0.05;
    final botY = r * 0.95;
    final w = r * 0.85;

    // Outer faceted polygon
    final outer = Path()
      ..moveTo(-w * 0.65, topY)
      ..lineTo(w * 0.65, topY)
      ..lineTo(w, cornerY)
      ..lineTo(0, botY)
      ..lineTo(-w, cornerY)
      ..close();

    final basePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF80DEEA), Color(0xFF00ACC1), Color(0xFF006064)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawPath(outer, basePaint);

    // Crown facet
    final crownPath = Path()
      ..moveTo(-w * 0.65, topY)
      ..lineTo(w * 0.65, topY)
      ..lineTo(w * 0.35, crownY)
      ..lineTo(-w * 0.35, crownY)
      ..close();
    final crownPaint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawPath(crownPath, crownPaint);

    // Center facet
    final centerFacet = Path()
      ..moveTo(-w * 0.35, crownY)
      ..lineTo(w * 0.35, crownY)
      ..lineTo(0, botY)
      ..close();
    final centerPaint = Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.7);
    canvas.drawPath(centerFacet, centerPaint);

    // Facet borders
    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawPath(outer, strokePaint);

    // Specular Star Sparkle
    _drawSparkle(canvas, Offset(-w * 0.3, topY + 3), r * 0.38, Colors.white);

    canvas.restore();
  }

  void _drawHeart(Canvas canvas, Offset center, double size) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final r = size / 2;

    // Warm Crimson Glow
    final glowPaint = Paint()
      ..color = AppColors.energyRed.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawCircle(Offset.zero, r * 1.1, glowPaint);

    final path = Path();
    path.moveTo(0, r * 0.68);
    path.cubicTo(-r * 1.25, -r * 0.12, -r * 0.7, -r * 0.95, 0, -r * 0.35);
    path.cubicTo(r * 0.7, -r * 0.95, r * 1.25, -r * 0.12, 0, r * 0.68);
    path.close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF5252), Color(0xFFD32F2F), Color(0xFF880E4F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawPath(path, fillPaint);

    // Specular highlight on left lobe
    final sheenPaint = Paint()..color = Colors.white.withValues(alpha: 0.65);
    canvas.drawCircle(Offset(-r * 0.34, -r * 0.36), r * 0.22, sheenPaint);

    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawPath(path, strokePaint);

    canvas.restore();
  }

  void _drawKey(Canvas canvas, Offset center, double size, double rotation) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final r = size / 2;

    // Golden Aura Glow
    final glowPaint = Paint()
      ..color = AppColors.goldenKey.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset.zero, r * 1.15, glowPaint);

    // Key bow ring
    final ringPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF59D), Color(0xFFFFD54F), Color(0xFFFFA000)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r))
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.44;
    canvas.drawCircle(Offset(0, -r * 0.35), r * 0.38, ringPaint);

    // Key shank
    final shankPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF59D), Color(0xFFFFD54F)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r))
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.28
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, -r * 0.08), Offset(0, r * 0.8), shankPaint);

    // Key bit teeth
    final teethPaint = Paint()
      ..color = const Color(0xFFFFC107)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.24
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, r * 0.48), Offset(r * 0.38, r * 0.48), teethPaint);
    canvas.drawLine(Offset(0, r * 0.74), Offset(r * 0.32, r * 0.74), teethPaint);

    // Specular sparkle
    _drawSparkle(canvas, Offset(r * 0.28, -r * 0.52), r * 0.38, Colors.white);

    canvas.restore();
  }

  void _drawFlame(Canvas canvas, Offset center, double size) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final r = size / 2;

    final glowPaint = Paint()
      ..color = AppColors.streakOrange.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset.zero, r * 1.1, glowPaint);

    final flamePath = Path()
      ..moveTo(0, -r * 0.9)
      ..cubicTo(r * 0.8, -r * 0.3, r * 0.9, r * 0.6, 0, r * 0.9)
      ..cubicTo(-r * 0.9, r * 0.6, -r * 0.8, -r * 0.3, 0, -r * 0.9)
      ..close();

    final flamePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFB74D), Color(0xFFFF7043), Color(0xFFD84315)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawPath(flamePath, flamePaint);

    // Inner bright yellow flame core
    final corePath = Path()
      ..moveTo(0, -r * 0.45)
      ..cubicTo(r * 0.4, -r * 0.1, r * 0.45, r * 0.4, 0, r * 0.65)
      ..cubicTo(-r * 0.45, r * 0.4, -r * 0.4, -r * 0.1, 0, -r * 0.45)
      ..close();
    final corePaint = Paint()..color = const Color(0xFFFFF176).withValues(alpha: 0.85);
    canvas.drawPath(corePath, corePaint);

    canvas.restore();
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FlyingRewardPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}

// ---------------------------------------------------------------------------
// Masterpiece Conquered Dialog
// ---------------------------------------------------------------------------

/// A grand celebratory dialog shown upon completing all levels of a book, poem, or epic.
class MasterpieceConqueredDialog extends StatelessWidget {
  final String title;
  final String author;
  final int bonusGems;
  final VoidCallback onContinue;

  const MasterpieceConqueredDialog({
    super.key,
    required this.title,
    required this.author,
    this.bonusGems = 100,
    required this.onContinue,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String author,
    int bonusGems = 100,
    required VoidCallback onContinue,
  }) {
    SoundService.instance.play(Sfx.levelComplete);
    HapticService.instance.heavy();
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MasterpieceConqueredDialog(
        title: title,
        author: author,
        bonusGems: bonusGems,
        onContinue: onContinue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? (isDark ? const Color(0xFF1B221E) : Colors.white),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.antiqueGold, width: 2.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.antiqueGold.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Don Quixote in Lesson Complete pose holding up book with pride
            const QuixoteMascot(
              size: 92,
              poseOverride: MascotPose.lessonComplete,
              showSpeechBubble: false,
              interactive: false,
            ),
            const SizedBox(height: 12),

            // Laurels badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.antiqueGold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.antiqueGold, width: 1.2),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium_rounded, size: 16, color: AppColors.antiqueGold),
                  SizedBox(width: 6),
                  Text(
                    'CHIVALRIC MASTERWORK CONQUERED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.antiqueGold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Text(
              'A Grand Literary Triumph!',
              textAlign: TextAlign.center,
              style: AppTypography.displayMedium.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'Thou hast completed every chapter, recall challenge, and final examination for "$title" by $author!',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 13,
                height: 1.45,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),

            // Bonus Gem Loot Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.antiqueGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.antiqueGold.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.diamond_rounded, color: AppColors.gemCyan, size: 22),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '+$bonusGems Radiant Completion Gems Awarded!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.antiqueGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            DuoButton(
              text: 'Claim Laurels & Return to Map',
              variant: DuoButtonVariant.gold,
              onPressed: () {
                SoundService.instance.play(Sfx.reward);
                HapticService.instance.light();
                Navigator.pop(context);
                RewardCelebrationOverlay.emitFlight(
                  context: context,
                  gems: bonusGems,
                );
                onContinue();
              },
            ),
          ],
        ),
      ),
    );
  }
}
