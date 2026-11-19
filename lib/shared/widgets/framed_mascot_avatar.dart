import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/cosmetic_item.dart';
import '../../models/profile_avatar_icon.dart';
import 'quixote_mascot.dart';

/// Renders either the user's equipped [ProfileAvatarIconItem] (Don Quixote mascot,
/// static animal/emblem icons, or animated magical literary icons) wrapped in
/// the user's equipped [AvatarFrame] (static or animated glowing border).
class FramedMascotAvatar extends StatefulWidget {
  final AvatarFrame frame;
  final double size;
  final String? monogram;
  final bool showMascot;
  final String? avatarIconId;

  const FramedMascotAvatar({
    super.key,
    required this.frame,
    this.size = 92,
    this.monogram,
    this.showMascot = true,
    this.avatarIconId,
  });

  @override
  State<FramedMascotAvatar> createState() => _FramedMascotAvatarState();
}

class _FramedMascotAvatarState extends State<FramedMascotAvatar>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  ProfileAvatarIconItem? get _iconItem =>
      (widget.avatarIconId != null && widget.avatarIconId!.isNotEmpty)
          ? ProfileAvatarIconCatalog.byId(widget.avatarIconId!)
          : null;

  bool get _needsAnimation =>
      widget.frame.isAnimated || (_iconItem?.isAnimated ?? false);

  @override
  void initState() {
    super.initState();
    _syncController();
  }

  @override
  void didUpdateWidget(covariant FramedMascotAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frame.id != widget.frame.id ||
        oldWidget.avatarIconId != widget.avatarIconId) {
      _syncController();
    }
  }

  void _syncController() {
    if (_needsAnimation) {
      _controller ??= AnimationController(
        vsync: this,
        duration: const Duration(seconds: 6),
      )..repeat();
    } else {
      _controller?.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return _buildAvatar(0.0);
    }
    return AnimatedBuilder(
      animation: _controller!,
      builder: (_, _) => _buildAvatar(_controller!.value),
    );
  }

  Widget _buildAvatar(double progress) {
    final frame = widget.frame;
    final size = widget.size;
    final ringPadding = size * 0.085;
    final totalSize = size + ringPadding * 2;
    final emblemSize = (size * 0.28).clamp(18.0, 28.0);
    final t = progress * 2 * math.pi;

    // Calm animated ring rotation & glow intensity
    final double sweepAngle = switch (frame.motion) {
      AvatarBorderMotion.rotatingGradient ||
      AvatarBorderMotion.shimmeringGold ||
      AvatarBorderMotion.inkSwirl ||
      AvatarBorderMotion.frostShimmer =>
        t,
      AvatarBorderMotion.moonlightWave => math.sin(t) * 0.85,
      _ => 0.0,
    };

    final double pulse = 0.5 + 0.5 * math.sin(t);
    final double glowBlur = frame.isAnimated
        ? (14.0 + pulse * 10.0)
        : (frame.hasGlow ? 16.0 : 0.0);
    final double glowAlpha = frame.isAnimated
        ? (0.38 + pulse * 0.28)
        : (frame.hasGlow ? 0.42 : 0.0);

    return SizedBox(
      width: totalSize,
      height: totalSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: totalSize,
            height: totalSize,
            padding: EdgeInsets.all(ringPadding * 0.68),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                transform: GradientRotation(sweepAngle),
                colors: [
                  frame.primaryColor,
                  frame.accentColor,
                  frame.secondaryColor,
                  frame.primaryColor,
                ],
              ),
              boxShadow: [
                if (frame.hasGlow || frame.isAnimated)
                  BoxShadow(
                    color: frame.primaryColor.withValues(alpha: glowAlpha),
                    blurRadius: glowBlur,
                    spreadRadius: frame.isAnimated ? (1.2 + pulse * 1.4) : 1.0,
                  ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: frame.accentColor.withValues(alpha: 0.92),
                border: Border.all(
                  color: frame.secondaryColor.withValues(alpha: 0.55),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: _buildInnerAvatar(progress, t),
              ),
            ),
          ),

          // Custom animated particle/orbit ring overlay for animated borders
          if (frame.isAnimated)
            IgnorePointer(
              child: SizedBox(
                width: totalSize + 10,
                height: totalSize + 10,
                child: CustomPaint(
                  painter: _AnimatedBorderEffectsPainter(
                    frame: frame,
                    progress: progress,
                  ),
                ),
              ),
            ),

          // Corner frame emblem badge
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: emblemSize,
              height: emblemSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: frame.primaryColor,
                border: Border.all(color: Colors.white, width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                frame.emblemIcon,
                size: emblemSize * 0.56,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInnerAvatar(double progress, double t) {
    final size = widget.size;
    final iconItem = _iconItem;

    if (iconItem != null && !iconItem.isMascot) {
      if (!iconItem.isAnimated) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: iconItem.bgGradient,
            ),
          ),
          child: Center(
            child: Text(
              iconItem.glyph,
              style: TextStyle(fontSize: size * 0.48, height: 1.0),
            ),
          ),
        );
      }

      // Calm, distinct animated motion per magical literary icon
      final double bobY = switch (iconItem.motion) {
        AvatarIconMotion.floatingQuill ||
        AvatarIconMotion.glowingBook ||
        AvatarIconMotion.lunarGlow ||
        AvatarIconMotion.hourglassShimmer =>
          math.sin(t) * (size * 0.045),
        AvatarIconMotion.flutterWings => math.sin(t * 2) * (size * 0.035),
        _ => 0.0,
      };
      final double tilt = switch (iconItem.motion) {
        AvatarIconMotion.swayingBookmark ||
        AvatarIconMotion.warmLantern =>
          math.sin(t) * 0.14,
        AvatarIconMotion.compassDrift => math.sin(t) * 0.22,
        AvatarIconMotion.floatingQuill => math.cos(t) * 0.09,
        _ => 0.0,
      };
      final double scale = switch (iconItem.motion) {
        AvatarIconMotion.tinyFlame => 0.96 + 0.08 * (0.5 + 0.5 * math.sin(t * 3)),
        AvatarIconMotion.glowingBook ||
        AvatarIconMotion.orbitingStar =>
          0.97 + 0.06 * (0.5 + 0.5 * math.sin(t)),
        AvatarIconMotion.flutterWings => 0.95 + 0.09 * (0.5 + 0.5 * math.sin(t * 2.5)),
        _ => 1.0,
      };
      final double glowAlpha = 0.24 + 0.22 * (0.5 + 0.5 * math.sin(t * 1.5));

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: iconItem.bgGradient,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft inner radiant halo
            Container(
              width: size * 0.68,
              height: size * 0.68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    iconItem.accentColor.withValues(alpha: glowAlpha),
                    iconItem.accentColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            // Gentle floating sparkles inside the icon circle
            Positioned.fill(
              child: CustomPaint(
                painter: _AnimatedIconSparklesPainter(
                  accentColor: iconItem.accentColor,
                  progress: progress,
                ),
              ),
            ),
            // Animated glyph
            Transform.translate(
              offset: Offset(0, bobY),
              child: Transform.rotate(
                angle: tilt,
                child: Transform.scale(
                  scale: scale,
                  child: Text(
                    iconItem.glyph,
                    style: TextStyle(fontSize: size * 0.46, height: 1.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.showMascot) {
      return Center(
        child: QuixoteMascot(
          size: size * 0.86,
          expression: QuixoteExpression.idle,
          showSpeechBubble: false,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.frame.primaryColor.withValues(alpha: 0.88),
            widget.frame.secondaryColor,
          ],
        ),
      ),
      child: Center(
        child: Text(
          (widget.monogram ?? 'Q').trim().isEmpty
              ? 'Q'
              : (widget.monogram ?? 'Q').trim().substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.42,
          ),
        ),
      ),
    );
  }
}

class _AnimatedBorderEffectsPainter extends CustomPainter {
  final AvatarFrame frame;
  final double progress;

  const _AnimatedBorderEffectsPainter({
    required this.frame,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;
    final t = progress * 2 * math.pi;

    switch (frame.motion) {
      case AvatarBorderMotion.orbitingSparkles:
      case AvatarBorderMotion.frostShimmer:
        for (int i = 0; i < 6; i++) {
          final angle = t + (i * math.pi / 3);
          final pos = Offset(
            center.dx + math.cos(angle) * radius,
            center.dy + math.sin(angle) * radius,
          );
          final twinkle = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(t * 2 + i * 1.4));
          canvas.drawCircle(
            pos,
            3.6,
            Paint()
              ..color = frame.accentColor.withValues(alpha: twinkle * 0.4)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
          );
          canvas.drawCircle(
            pos,
            1.8,
            Paint()..color = Colors.white.withValues(alpha: twinkle),
          );
        }
        break;
      case AvatarBorderMotion.flickeringEmber:
        for (int i = 0; i < 5; i++) {
          final p = (progress * 1.5 + i * 0.21) % 1.0;
          final angle = -math.pi * 0.85 + (i * 0.42) + math.sin(t + i) * 0.1;
          final pos = Offset(
            center.dx + math.cos(angle) * radius,
            center.dy + math.sin(angle) * radius - p * 10,
          );
          final alpha = (1.0 - p) * 0.9;
          canvas.drawCircle(
            pos,
            2.2,
            Paint()..color = frame.accentColor.withValues(alpha: alpha),
          );
        }
        break;
      case AvatarBorderMotion.enchantedVines:
      case AvatarBorderMotion.petalOrbit:
        for (int i = 0; i < 4; i++) {
          final angle = t + (i * math.pi / 2);
          final pos = Offset(
            center.dx + math.cos(angle) * radius,
            center.dy + math.sin(angle) * radius,
          );
          canvas.save();
          canvas.translate(pos.dx, pos.dy);
          canvas.rotate(angle + 0.6);
          canvas.drawOval(
            const Rect.fromLTWH(-4.5, -2.2, 9, 4.4),
            Paint()..color = frame.accentColor.withValues(alpha: 0.85),
          );
          canvas.restore();
        }
        break;
      case AvatarBorderMotion.pulsingGlow:
      case AvatarBorderMotion.moonlightWave:
        final pulse = 0.5 + 0.5 * math.sin(t);
        canvas.drawCircle(
          center,
          radius + pulse * 2.5,
          Paint()
            ..color = frame.accentColor.withValues(alpha: 0.25 + pulse * 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
        break;
      default:
        // Subtle glint orbiting along the rim for rotatingGradient / shimmeringGold / inkSwirl
        for (int i = 0; i < 2; i++) {
          final angle = t + i * math.pi;
          final pos = Offset(
            center.dx + math.cos(angle) * radius,
            center.dy + math.sin(angle) * radius,
          );
          canvas.drawCircle(
            pos,
            3.0,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.78)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
          );
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedBorderEffectsPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.frame.id != frame.id;
}

class _AnimatedIconSparklesPainter extends CustomPainter {
  final Color accentColor;
  final double progress;

  const _AnimatedIconSparklesPainter({
    required this.accentColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * math.pi;
    final pts = [
      Offset(size.width * 0.24, size.height * 0.28),
      Offset(size.width * 0.78, size.height * 0.24),
      Offset(size.width * 0.74, size.height * 0.76),
      Offset(size.width * 0.22, size.height * 0.72),
    ];
    for (int i = 0; i < pts.length; i++) {
      final twinkle = 0.25 + 0.75 * (0.5 + 0.5 * math.sin(t * 2 + i * 1.5));
      final p = pts[i] + Offset(0, math.cos(t + i) * 2.2);
      canvas.drawCircle(
        p,
        1.6,
        Paint()..color = accentColor.withValues(alpha: twinkle * 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedIconSparklesPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accentColor != accentColor;
}
