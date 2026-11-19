import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/difficulty_quiz_engine.dart';

/// Interactive animated Treasure Chest with 3 distinct rarities:
/// - Common (Bronze / Oak) — when the player made several mistakes
/// - Rare (Sapphire / Silver-Cyan) — when the player made few mistakes (70–99%)
/// - Legendary (Royal Gold / Prismatic Aura) — when the player scored 100% perfect!
class AnimatedRewardChest extends StatefulWidget {
  final QuizRewardOutcome outcome;
  final bool isOpened;
  final bool awardsGoldenKey;
  final void Function(Offset? origin) onOpenChest;

  const AnimatedRewardChest({
    super.key,
    required this.outcome,
    required this.isOpened,
    this.awardsGoldenKey = false,
    required this.onOpenChest,
  });

  @override
  State<AnimatedRewardChest> createState() => _AnimatedRewardChestState();
}

class _AnimatedRewardChestState extends State<AnimatedRewardChest>
    with TickerProviderStateMixin {
  late final AnimationController _wiggleController;
  late final AnimationController _openBurstController;

  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _openBurstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    if (widget.isOpened) {
      _openBurstController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedRewardChest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpened && !oldWidget.isOpened) {
      _wiggleController.stop();
      _openBurstController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    _openBurstController.dispose();
    super.dispose();
  }

  Color get _primaryColor {
    switch (widget.outcome.chestRarity) {
      case ChestRarity.common:
        return const Color(0xFFB57B45);
      case ChestRarity.rare:
        return const Color(0xFF2980B9);
      case ChestRarity.legendary:
        return const Color(0xFFD4A338);
    }
  }

  Color get _secondaryColor {
    switch (widget.outcome.chestRarity) {
      case ChestRarity.common:
        return const Color(0xFF7A4E27);
      case ChestRarity.rare:
        return const Color(0xFF00A8CC);
      case ChestRarity.legendary:
        return const Color(0xFF9B59B6);
    }
  }

  String get _rarityLabel {
    switch (widget.outcome.chestRarity) {
      case ChestRarity.common:
        return 'COMMON CHEST';
      case ChestRarity.rare:
        return 'RARE CHEST';
      case ChestRarity.legendary:
        return 'LEGENDARY CHEST';
    }
  }

  String get _subtitle {
    if (widget.isOpened) {
      return 'Rewards added to your profile & Live Leaderboard!';
    }
    switch (widget.outcome.chestRarity) {
      case ChestRarity.common:
        return 'Good effort! Tap to claim your bronze bounty.';
      case ChestRarity.rare:
        return 'Great accuracy! Tap to unlock your sapphire chest.';
      case ChestRarity.legendary:
        return '100% FLAWLESS! Tap to open the Royal Legendary Chest!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = _primaryColor;
    final secondary = _secondaryColor;

    return Builder(
      builder: (boxCtx) => GestureDetector(
        onTap: widget.isOpened
            ? null
            : () {
                final renderBox = boxCtx.findRenderObject() as RenderBox?;
                final origin = renderBox != null && renderBox.hasSize
                    ? renderBox.localToGlobal(renderBox.size.center(Offset.zero))
                    : null;
                widget.onOpenChest(origin);
              },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [primary.withValues(alpha: 0.22), const Color(0xFF18171E)]
                  : [primary.withValues(alpha: 0.14), Colors.white],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primary, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: widget.outcome.chestRarity == ChestRarity.legendary ? 0.35 : 0.2),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Rarity Tag Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primary, secondary]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _rarityLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Animated Chest Visual
              AnimatedBuilder(
                animation: Listenable.merge([_wiggleController, _openBurstController]),
                builder: (context, _) {
                  final wiggleT = _wiggleController.value;
                  final angle = widget.isOpened
                      ? 0.0
                      : (wiggleT < 0.35 ? math.sin(wiggleT * math.pi * 12) * 0.08 : 0.0);
                  final hop = widget.isOpened
                      ? 0.0
                      : (wiggleT < 0.35 ? -math.sin((wiggleT / 0.35) * math.pi) * 8.0 : 0.0);
                  final burst = _openBurstController.value;
                  final scale = widget.isOpened
                      ? (1.0 + math.sin(burst * math.pi) * 0.14)
                      : 1.0;

                  return SizedBox(
                    height: 142,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Radiant aura halo
                        Container(
                          width: widget.isOpened ? 136 : 108,
                          height: widget.isOpened ? 136 : 108,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                primary.withValues(alpha: widget.isOpened ? 0.45 : 0.26),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        // Sparkle particles on open
                        if (widget.isOpened)
                          for (int i = 0; i < 8; i++)
                            Transform.translate(
                              offset: Offset(
                                math.cos(i * math.pi / 4) * (46 + burst * 20),
                                math.sin(i * math.pi / 4) * (34 + burst * 16) - 8,
                              ),
                              child: Opacity(
                                opacity: (1.0 - burst * 0.45).clamp(0.0, 1.0),
                                child: Icon(
                                  Icons.auto_awesome_rounded,
                                  size: i.isEven ? 18 : 13,
                                  color: i.isEven ? const Color(0xFFFFE066) : primary,
                                ),
                              ),
                            ),
                        // Illustrated RPG Treasure Chest
                        Transform.translate(
                          offset: Offset(0, hop),
                          child: Transform.rotate(
                            angle: angle,
                            child: Transform.scale(
                              scale: scale,
                              child: CustomPaint(
                                size: const Size(134, 118),
                                painter: _RpgTreasureChestPainter(
                                  rarity: widget.outcome.chestRarity,
                                  openProgress: widget.isOpened ? burst : 0.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 14),

              if (!widget.isOpened)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.key_rounded, size: 18),
                    label: Text(
                      'TAP TO OPEN $_rarityLabel',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, letterSpacing: 0.6),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      final renderBox = boxCtx.findRenderObject() as RenderBox?;
                      final origin = renderBox != null && renderBox.hasSize
                          ? renderBox.localToGlobal(renderBox.size.center(Offset.zero))
                          : null;
                      widget.onOpenChest(origin);
                    },
                  ),
                )
              else
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _lootChip(
                      '+${widget.outcome.gemsEarned} Gems',
                      Icons.diamond_rounded,
                      AppColors.gemCyan,
                    ),
                    _lootChip(
                      '+${widget.outcome.leaderboardXpEarned} Leaderboard XP',
                      Icons.emoji_events_rounded,
                      AppColors.antiqueGold,
                    ),
                    if (widget.outcome.bonusHearts > 0)
                      _lootChip(
                        '+${widget.outcome.bonusHearts} Heart${widget.outcome.bonusHearts > 1 ? 's' : ''}',
                        Icons.favorite_rounded,
                        AppColors.energyRed,
                      ),
                    if (widget.awardsGoldenKey)
                      _lootChip(
                        '+1 Golden Key',
                        Icons.vpn_key_rounded,
                        AppColors.goldenKey,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lootChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bespoke stylized RPG Treasure Chest painter with 3 distinct rarity tiers
/// (Common Oak & Bronze, Rare Ivory & Sapphire, Legendary Crimson & Royal Gold)
/// and an animated opening lid spilling golden treasure light rays.
class _RpgTreasureChestPainter extends CustomPainter {
  final ChestRarity rarity;
  final double openProgress;

  const _RpgTreasureChestPainter({
    required this.rarity,
    required this.openProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Palette per rarity
    late Color bodyDark;
    late Color bodyLight;
    late Color lidDark;
    late Color lidLight;
    late Color trimGold;
    late Color trimShadow;
    late Color gemColor;

    switch (rarity) {
      case ChestRarity.common:
        bodyDark = const Color(0xFF4A3538);
        bodyLight = const Color(0xFF6B4D4B);
        lidDark = const Color(0xFF7D5342);
        lidLight = const Color(0xFFA67458);
        trimGold = const Color(0xFFE5A952);
        trimShadow = const Color(0xFF9E6625);
        gemColor = const Color(0xFFF5C563);
        break;
      case ChestRarity.rare:
        bodyDark = const Color(0xFFD5DCE8);
        bodyLight = const Color(0xFFF5F7FB);
        lidDark = const Color(0xFF2B6CB0);
        lidLight = const Color(0xFF54A8E8);
        trimGold = const Color(0xFFF6C453);
        trimShadow = const Color(0xFFB37D1E);
        gemColor = const Color(0xFF38BDF8);
        break;
      case ChestRarity.legendary:
        bodyDark = const Color(0xFF431C2B);
        bodyLight = const Color(0xFF881B37);
        lidDark = const Color(0xFFC82849);
        lidLight = const Color(0xFFF04D6B);
        trimGold = const Color(0xFFFFD15C);
        trimShadow = const Color(0xFFB87614);
        gemColor = const Color(0xFFFF3864);
        break;
    }

    final outlinePaint = Paint()
      ..color = const Color(0xFF231822)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeJoin = StrokeJoin.round;

    // 1. Soft ground shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.91), width: w * 0.78, height: h * 0.14),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );

    // 2. Treasure Light Rays when opening
    if (openProgress > 0.05) {
      final rayPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFFFFE57F).withValues(alpha: 0.85 * openProgress),
            const Color(0xFFFFF8E1).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(w * 0.12, 0, w * 0.76, h * 0.65));

      final rays = Path()
        ..moveTo(w * 0.24, h * 0.54)
        ..lineTo(w * 0.08, h * 0.04)
        ..lineTo(w * 0.92, h * 0.04)
        ..lineTo(w * 0.76, h * 0.54)
        ..close();
      canvas.drawPath(rays, rayPaint);
    }

    // 3. Side Crystals for Rare & Legendary chests
    if (rarity != ChestRarity.common) {
      final leftCrystal = Path()
        ..moveTo(w * 0.17, h * 0.56)
        ..lineTo(w * 0.04, h * 0.64)
        ..lineTo(w * 0.10, h * 0.78)
        ..lineTo(w * 0.19, h * 0.72)
        ..close();
      final rightCrystal = Path()
        ..moveTo(w * 0.83, h * 0.56)
        ..lineTo(w * 0.96, h * 0.64)
        ..lineTo(w * 0.90, h * 0.78)
        ..lineTo(w * 0.81, h * 0.72)
        ..close();
      final crystalPaint = Paint()..color = gemColor;
      canvas.drawPath(leftCrystal, crystalPaint);
      canvas.drawPath(rightCrystal, crystalPaint);
      canvas.drawPath(leftCrystal, outlinePaint);
      canvas.drawPath(rightCrystal, outlinePaint);
    }

    // 4. Lower Chest Body (tapered trapezoid)
    final bodyPath = Path()
      ..moveTo(w * 0.16, h * 0.52)
      ..lineTo(w * 0.84, h * 0.52)
      ..lineTo(w * 0.79, h * 0.86)
      ..quadraticBezierTo(w * 0.78, h * 0.90, w * 0.73, h * 0.90)
      ..lineTo(w * 0.27, h * 0.90)
      ..quadraticBezierTo(w * 0.22, h * 0.90, w * 0.21, h * 0.86)
      ..close();

    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bodyLight, bodyDark],
        ).createShader(Rect.fromLTWH(w * 0.16, h * 0.52, w * 0.68, h * 0.38)),
    );

    // Subtle plank lines on body
    final seamPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(w * 0.19, h * 0.66), Offset(w * 0.81, h * 0.66), seamPaint);
    canvas.drawLine(Offset(w * 0.20, h * 0.78), Offset(w * 0.80, h * 0.78), seamPaint);

    // Corner gold brackets & feet
    final goldPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [trimGold, trimShadow],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final leftStrap = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.19, h * 0.52, w * 0.10, h * 0.38),
      const Radius.circular(4),
    );
    final rightStrap = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.71, h * 0.52, w * 0.10, h * 0.38),
      const Radius.circular(4),
    );
    canvas.drawRRect(leftStrap, goldPaint);
    canvas.drawRRect(rightStrap, goldPaint);
    canvas.drawPath(bodyPath, outlinePaint);
    canvas.drawRRect(leftStrap, outlinePaint);
    canvas.drawRRect(rightStrap, outlinePaint);

    // 5. Glowing Interior Treasure Mound when open
    if (openProgress > 0.05) {
      final glowRect = Rect.fromLTWH(w * 0.20, h * 0.44, w * 0.60, h * 0.14);
      canvas.drawOval(
        glowRect,
        Paint()..color = const Color(0xFFFFD54F).withValues(alpha: openProgress),
      );
      canvas.drawOval(
        glowRect.deflate(6),
        Paint()..color = const Color(0xFFFFF9C4).withValues(alpha: openProgress),
      );
    }

    // 6. Hinged Arched Chest Lid (lifts & tilts slightly open when openProgress > 0)
    canvas.save();
    final liftY = -openProgress * h * 0.18;
    final tilt = -openProgress * 0.14;
    canvas.translate(cx, h * 0.50 + liftY);
    canvas.rotate(tilt);
    canvas.translate(-cx, -(h * 0.50));

    final lidPath = Path()
      ..moveTo(w * 0.13, h * 0.52)
      ..lineTo(w * 0.15, h * 0.30)
      ..quadraticBezierTo(w * 0.18, h * 0.16, cx, h * 0.15)
      ..quadraticBezierTo(w * 0.82, h * 0.16, w * 0.85, h * 0.30)
      ..lineTo(w * 0.87, h * 0.52)
      ..close();

    canvas.drawPath(
      lidPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lidLight, lidDark],
        ).createShader(Rect.fromLTWH(w * 0.13, h * 0.15, w * 0.74, h * 0.37)),
    );

    // Lid gold arch bands
    final lidBandLeft = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.18, w * 0.11, h * 0.34),
      const Radius.circular(6),
    );
    final lidBandRight = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.71, h * 0.18, w * 0.11, h * 0.34),
      const Radius.circular(6),
    );
    final lidRim = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.45, w * 0.76, h * 0.10),
      const Radius.circular(6),
    );
    canvas.drawRRect(lidBandLeft, goldPaint);
    canvas.drawRRect(lidBandRight, goldPaint);
    canvas.drawRRect(lidRim, goldPaint);

    // Top Center Crest Gem (Heart/Crown/Diamond)
    final crestCenter = Offset(cx, h * 0.25);
    canvas.drawCircle(crestCenter, 12, goldPaint);
    canvas.drawCircle(crestCenter, 12, outlinePaint);
    final gemDiamond = Path()
      ..moveTo(cx, crestCenter.dy - 7.5)
      ..lineTo(cx + 7, crestCenter.dy)
      ..lineTo(cx, crestCenter.dy + 7.5)
      ..lineTo(cx - 7, crestCenter.dy)
      ..close();
    canvas.drawPath(gemDiamond, Paint()..color = gemColor);
    canvas.drawPath(gemDiamond, outlinePaint);

    // Highlight specular shine on lid
    canvas.drawLine(
      Offset(w * 0.34, h * 0.23),
      Offset(w * 0.44, h * 0.21),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawPath(lidPath, outlinePaint);
    canvas.drawRRect(lidBandLeft, outlinePaint);
    canvas.drawRRect(lidBandRight, outlinePaint);
    canvas.drawRRect(lidRim, outlinePaint);
    canvas.restore();

    // 7. Ornate Front Keyhole Clasp
    final claspRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, h * 0.56 + liftY * 0.25), width: 24, height: 26),
      const Radius.circular(8),
    );
    canvas.drawRRect(claspRect, goldPaint);
    canvas.drawRRect(claspRect, outlinePaint);

    // Keyhole slot
    final keyholePaint = Paint()..color = const Color(0xFF231822);
    final ky = h * 0.545 + liftY * 0.25;
    canvas.drawCircle(Offset(cx, ky), 3.6, keyholePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, ky + 5.2), width: 3.4, height: 6.5),
        const Radius.circular(1.5),
      ),
      keyholePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RpgTreasureChestPainter oldDelegate) =>
      oldDelegate.rarity != rarity || oldDelegate.openProgress != openProgress;
}
