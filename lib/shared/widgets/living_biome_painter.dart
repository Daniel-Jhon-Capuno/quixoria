import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders rich, animated Living World Biomes (full swaying trees, animals,
/// ponds, coral reefs, aurora, fireflies, petals, fish, birds) both on the
/// Quest Map and inside the Themes Shop live preview cards.
class LivingBiomePainter extends CustomPainter {
  final String biomeId;
  final double animValue;
  final bool isDark;
  final bool isPreview;

  LivingBiomePainter({
    required this.biomeId,
    required this.animValue,
    required this.isDark,
    this.isPreview = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    switch (biomeId) {
      case 'emerald_woods':
        _paintEmeraldWoods(canvas, size);
        break;
      case 'sakura_koi':
        _paintSakuraKoi(canvas, size);
        break;
      case 'savannah':
        _paintSavannah(canvas, size);
        break;
      case 'arctic_aurora':
        _paintArcticAurora(canvas, size);
        break;
      case 'coral_lagoon':
        _paintCoralLagoon(canvas, size);
        break;
    }

    canvas.restore();
  }

  // ===========================================================================
  // 1. WHISPERING EMERALD WOODS (Full Oak & Pine Trees + Deer, Birds, Fireflies)
  // ===========================================================================
  void _paintEmeraldWoods(Canvas canvas, Size size) {
    if (isPreview) {
      _paintBackdropGradient(
        canvas,
        size,
        isDark
            ? [const Color(0xFF0A1D13), const Color(0xFF133222), const Color(0xFF1B432D)]
            : [const Color(0xFFD6F0DD), const Color(0xFFEAF7ED), const Color(0xFFC9E7D1)],
      );
      _paintRollingHill(canvas, size, 0.72, isDark ? const Color(0xFF163824) : const Color(0xFF9ED4AE));
      _paintOakTree(canvas, Offset(size.width * 0.16, size.height * 0.78), 34, sway: math.sin(animValue * math.pi * 2) * 2.5);
      _paintPineTree(canvas, Offset(size.width * 0.31, size.height * 0.75), 28, snowy: false);
      _paintOakTree(canvas, Offset(size.width * 0.84, size.height * 0.80), 38, sway: math.cos(animValue * math.pi * 2) * 2.5);
      _paintPineTree(canvas, Offset(size.width * 0.70, size.height * 0.74), 26, snowy: false);
      _paintDeer(canvas, Offset(size.width * 0.52, size.height * 0.80), 1.05);
      _paintFlappingBird(canvas, Offset(size.width * ((0.15 + animValue * 0.75) % 1.0), size.height * 0.24 + math.sin(animValue * math.pi * 4) * 5), 1.0, isDark ? const Color(0xFF9BF0C0) : const Color(0xFF1B4332));
      _paintFireflies(canvas, size, 10);
      return;
    }

    final rows = math.max(3, (size.height / 145).ceil());
    for (int i = 0; i < rows; i++) {
      final y = 75.0 + i * 145.0;
      final onLeft = i.isEven;
      final sway = math.sin(animValue * math.pi * 2 + i * 0.9) * 2.5;
      // Full oak & pine groves framing both sides of the winding path
      _paintOakTree(canvas, Offset(onLeft ? 34 : size.width - 34, y), 36, sway: sway);
      _paintPineTree(canvas, Offset(onLeft ? 68 : size.width - 68, y + 26), 28, snowy: false);
      _paintPineTree(canvas, Offset(onLeft ? size.width - 30 : 30, y + 48), 24, snowy: false);
      // Woodland deer in alternating clearings
      if (i % 2 == 0) {
        _paintDeer(canvas, Offset(onLeft ? size.width - 54 : 54, y + 18), 0.95);
      }
      // Gliding songbird crossing the canopy
      final bx = (size.width * ((animValue + i * 0.29) % 1.0));
      final by = y - 28 + math.sin(animValue * math.pi * 4 + i) * 7;
      _paintFlappingBird(canvas, Offset(bx, by), 0.95, isDark ? const Color(0xFFA7F3D0) : const Color(0xFF1B4332));
    }
    _paintFireflies(canvas, size, math.max(12, rows * 4));
  }

  // ===========================================================================
  // 2. SAKURA KOI SANCTUARY (Full Sakura Trees + Rippling Koi Ponds & Butterflies)
  // ===========================================================================
  void _paintSakuraKoi(Canvas canvas, Size size) {
    if (isPreview) {
      _paintBackdropGradient(
        canvas,
        size,
        isDark
            ? [const Color(0xFF1F111B), const Color(0xFF311929), const Color(0xFF231320)]
            : [const Color(0xFFFFE5EE), const Color(0xFFFFF3F7), const Color(0xFFFCD5E3)],
      );
      _paintKoiPond(canvas, Offset(size.width * 0.50, size.height * 0.78), 64, 22);
      _paintSakuraTree(canvas, Offset(size.width * 0.16, size.height * 0.82), 38, sway: math.sin(animValue * math.pi * 2) * 2.5);
      _paintSakuraTree(canvas, Offset(size.width * 0.85, size.height * 0.84), 40, sway: math.cos(animValue * math.pi * 2) * 2.5);
      _paintButterfly(canvas, Offset(size.width * 0.42 + math.sin(animValue * math.pi * 2) * 18, size.height * 0.34 + math.cos(animValue * math.pi * 4) * 6), const Color(0xFFF48FB1));
      _paintFallingPetals(canvas, size, 12);
      return;
    }

    final rows = math.max(3, (size.height / 150).ceil());
    for (int i = 0; i < rows; i++) {
      final y = 80.0 + i * 150.0;
      final onLeft = i.isEven;
      final sway = math.sin(animValue * math.pi * 2 + i) * 2.5;
      _paintSakuraTree(canvas, Offset(onLeft ? 36 : size.width - 36, y), 38, sway: sway);
      _paintSakuraTree(canvas, Offset(onLeft ? size.width - 32 : 32, y + 58), 28, sway: -sway);
      // Tranquil koi pond with swimming koi & ripples
      _paintKoiPond(canvas, Offset(onLeft ? size.width - 60 : 60, y + 10), 42, 16);
      // Fluttering butterfly
      final bx = (onLeft ? 74.0 : size.width - 74.0) + math.sin(animValue * math.pi * 2 + i) * 16;
      final by = y - 24 + math.cos(animValue * math.pi * 4 + i) * 6;
      _paintButterfly(canvas, Offset(bx, by), isDark ? const Color(0xFFF8BBD0) : const Color(0xFFD81B60));
    }
    _paintFallingPetals(canvas, size, math.max(14, rows * 5));
  }

  // ===========================================================================
  // 3. GOLDEN SAVANNAH SAFARI (Full Acacia Trees + Giraffes & Soaring Hawks)
  // ===========================================================================
  void _paintSavannah(Canvas canvas, Size size) {
    if (isPreview) {
      _paintBackdropGradient(
        canvas,
        size,
        isDark
            ? [const Color(0xFF23160B), const Color(0xFF3A2311), const Color(0xFF1F140B)]
            : [const Color(0xFFFDE3B4), const Color(0xFFFFF3DA), const Color(0xFFF4CE93)],
      );
      // Warm horizon sun
      canvas.drawCircle(
        Offset(size.width * 0.52, size.height * 0.44),
        22,
        Paint()..color = (isDark ? const Color(0xFFF59E0B) : const Color(0xFFFBBF24)).withValues(alpha: 0.45),
      );
      _paintRollingHill(canvas, size, 0.74, isDark ? const Color(0xFF342212) : const Color(0xFFE7B977));
      _paintAcaciaTree(canvas, Offset(size.width * 0.19, size.height * 0.80), 38);
      _paintAcaciaTree(canvas, Offset(size.width * 0.82, size.height * 0.82), 34);
      _paintGiraffe(canvas, Offset(size.width * 0.62, size.height * 0.82), 1.0);
      _paintFlappingBird(canvas, Offset(size.width * ((0.2 + animValue * 0.7) % 1.0), size.height * 0.24), 1.1, isDark ? const Color(0xFFFCD34D) : const Color(0xFF7C2D12));
      return;
    }

    final rows = math.max(3, (size.height / 155).ceil());
    for (int i = 0; i < rows; i++) {
      final y = 82.0 + i * 155.0;
      final onLeft = i.isEven;
      _paintAcaciaTree(canvas, Offset(onLeft ? 42 : size.width - 42, y), 38);
      _paintAcaciaTree(canvas, Offset(onLeft ? size.width - 36 : 36, y + 62), 28);
      if (i % 2 == 0) {
        _paintGiraffe(canvas, Offset(onLeft ? size.width - 58 : 58, y + 22), 0.92);
      }
      final hx = size.width * ((animValue + i * 0.31) % 1.0);
      final hy = y - 30 + math.sin(animValue * math.pi * 2 + i) * 8;
      _paintFlappingBird(canvas, Offset(hx, hy), 1.05, isDark ? const Color(0xFFFCD34D) : const Color(0xFF9A3412));
    }
  }

  // ===========================================================================
  // 4. ARCTIC AURORA PINE (Snowy Pine Forests + Owls, Foxes & Northern Lights)
  // ===========================================================================
  void _paintArcticAurora(Canvas canvas, Size size) {
    if (isPreview) {
      _paintBackdropGradient(
        canvas,
        size,
        isDark
            ? [const Color(0xFF061523), const Color(0xFF0D283E), const Color(0xFF091B2C)]
            : [const Color(0xFFD2EEF9), const Color(0xFFEAF7FC), const Color(0xFFC2E5F4)],
      );
      _paintAuroraRibbon(canvas, size, 0.25);
      _paintRollingHill(canvas, size, 0.74, isDark ? const Color(0xFF122C42) : const Color(0xFFFFFFFF));
      _paintPineTree(canvas, Offset(size.width * 0.14, size.height * 0.80), 34, snowy: true);
      _paintPineTree(canvas, Offset(size.width * 0.27, size.height * 0.78), 26, snowy: true);
      _paintPineTree(canvas, Offset(size.width * 0.84, size.height * 0.82), 36, snowy: true);
      _paintSnowyOwl(canvas, Offset(size.width * ((0.22 + animValue * 0.65) % 1.0), size.height * 0.34 + math.sin(animValue * math.pi * 4) * 5));
      _paintArcticFox(canvas, Offset(size.width * 0.56, size.height * 0.80));
      _paintSnowflakes(canvas, size, 14);
      return;
    }

    _paintAuroraRibbon(canvas, size, 0.10);
    final rows = math.max(3, (size.height / 145).ceil());
    for (int i = 0; i < rows; i++) {
      final y = 78.0 + i * 145.0;
      final onLeft = i.isEven;
      _paintPineTree(canvas, Offset(onLeft ? 32 : size.width - 32, y), 36, snowy: true);
      _paintPineTree(canvas, Offset(onLeft ? 64 : size.width - 64, y + 26), 26, snowy: true);
      _paintPineTree(canvas, Offset(onLeft ? size.width - 30 : 30, y + 48), 28, snowy: true);
      if (i % 2 == 0) {
        _paintArcticFox(canvas, Offset(onLeft ? size.width - 52 : 52, y + 18));
      } else {
        final ox = size.width * ((animValue + i * 0.27) % 1.0);
        _paintSnowyOwl(canvas, Offset(ox, y - 20 + math.sin(animValue * math.pi * 4 + i) * 6));
      }
    }
    _paintSnowflakes(canvas, size, math.max(16, rows * 5));
  }

  // ===========================================================================
  // 5. CORAL REEF LAGOON (Swaying Kelp & Coral + Sea Turtles, Fish & Jellyfish)
  // ===========================================================================
  void _paintCoralLagoon(Canvas canvas, Size size) {
    if (isPreview) {
      _paintBackdropGradient(
        canvas,
        size,
        isDark
            ? [const Color(0xFF041720), const Color(0xFF0A2D3A), const Color(0xFF061E29)]
            : [const Color(0xFFC5F2F5), const Color(0xFFE3F9FA), const Color(0xFFB3EBF0)],
      );
      _paintKelpCluster(canvas, Offset(size.width * 0.12, size.height * 0.96), 48);
      _paintCoralCluster(canvas, Offset(size.width * 0.26, size.height * 0.94), const Color(0xFFF97316));
      _paintKelpCluster(canvas, Offset(size.width * 0.88, size.height * 0.96), 52);
      _paintCoralCluster(canvas, Offset(size.width * 0.74, size.height * 0.94), const Color(0xFFEC4899));
      _paintSeaTurtle(canvas, Offset(size.width * ((0.18 + animValue * 0.7) % 1.0), size.height * 0.36 + math.sin(animValue * math.pi * 2) * 6));
      _paintTropicalFish(canvas, Offset(size.width * ((0.75 - animValue * 0.65) % 1.0), size.height * 0.62), const Color(0xFFF97316), flipX: true);
      _paintJellyfish(canvas, Offset(size.width * 0.62, size.height * 0.32 + math.sin(animValue * math.pi * 2) * 5));
      _paintBubbles(canvas, size, 12);
      return;
    }

    final rows = math.max(3, (size.height / 150).ceil());
    for (int i = 0; i < rows; i++) {
      final y = 85.0 + i * 150.0;
      final onLeft = i.isEven;
      _paintKelpCluster(canvas, Offset(onLeft ? 28 : size.width - 28, y + 36), 52);
      _paintCoralCluster(
        canvas,
        Offset(onLeft ? 62 : size.width - 62, y + 34),
        i.isEven ? const Color(0xFFF97316) : const Color(0xFFEC4899),
      );
      if (i % 2 == 0) {
        final tx = size.width * ((animValue + i * 0.23) % 1.0);
        _paintSeaTurtle(canvas, Offset(tx, y - 16 + math.sin(animValue * math.pi * 2 + i) * 7));
      } else {
        final fx = size.width * ((1.0 - animValue + i * 0.19) % 1.0);
        _paintTropicalFish(canvas, Offset(fx, y - 8), const Color(0xFFF59E0B), flipX: true);
        _paintTropicalFish(canvas, Offset((fx + 22) % size.width, y + 6), const Color(0xFFFB7185), flipX: true);
      }
      _paintJellyfish(canvas, Offset(onLeft ? size.width - 42 : 42, y + math.sin(animValue * math.pi * 2 + i) * 8));
    }
    _paintBubbles(canvas, size, math.max(14, rows * 4));
  }

  // ===========================================================================
  // SHARED ILLUSTRATED TREES, ANIMALS & AMBIENT FX HELPERS
  // ===========================================================================
  void _paintBackdropGradient(Canvas canvas, Size size, List<Color> colors) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _paintRollingHill(Canvas canvas, Size size, double yFrac, Color color) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * yFrac)
      ..quadraticBezierTo(size.width * 0.28, size.height * (yFrac - 0.14), size.width * 0.55, size.height * yFrac)
      ..quadraticBezierTo(size.width * 0.80, size.height * (yFrac + 0.10), size.width, size.height * (yFrac - 0.06))
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.72));
  }

  void _paintOakTree(Canvas canvas, Offset base, double height, {double sway = 0}) {
    final trunkPaint = Paint()..color = isDark ? const Color(0xFF4A3525) : const Color(0xFF6B4423);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(base.dx, base.dy - height * 0.30), width: height * 0.18, height: height * 0.62),
        const Radius.circular(3),
      ),
      trunkPaint,
    );
    final crownCenter = Offset(base.dx + sway, base.dy - height * 0.72);
    final darkLeaf = isDark ? const Color(0xFF14532D) : const Color(0xFF1B6B42);
    final midLeaf = isDark ? const Color(0xFF1D7A48) : const Color(0xFF2E935D);
    final lightLeaf = isDark ? const Color(0xFF34D399) : const Color(0xFF52B788);

    canvas.drawCircle(Offset(crownCenter.dx - height * 0.24, crownCenter.dy + 4), height * 0.30, Paint()..color = darkLeaf);
    canvas.drawCircle(Offset(crownCenter.dx + height * 0.24, crownCenter.dy + 5), height * 0.28, Paint()..color = darkLeaf);
    canvas.drawCircle(crownCenter, height * 0.36, Paint()..color = midLeaf);
    canvas.drawCircle(Offset(crownCenter.dx - height * 0.08, crownCenter.dy - height * 0.10), height * 0.18, Paint()..color = lightLeaf.withValues(alpha: 0.65));
  }

  void _paintPineTree(Canvas canvas, Offset base, double height, {required bool snowy}) {
    canvas.drawRect(
      Rect.fromCenter(center: Offset(base.dx, base.dy - height * 0.14), width: height * 0.14, height: height * 0.30),
      Paint()..color = isDark ? const Color(0xFF3E2C1E) : const Color(0xFF5C3D24),
    );
    final pineColor = snowy
        ? (isDark ? const Color(0xFF164E63) : const Color(0xFF1E607A))
        : (isDark ? const Color(0xFF14532D) : const Color(0xFF1E6B44));
    for (int t = 0; t < 3; t++) {
      final tierY = base.dy - height * (0.26 + t * 0.25);
      final halfW = height * (0.42 - t * 0.09);
      final tierH = height * 0.42;
      final path = Path()
        ..moveTo(base.dx, tierY - tierH)
        ..lineTo(base.dx - halfW, tierY)
        ..lineTo(base.dx + halfW, tierY)
        ..close();
      canvas.drawPath(path, Paint()..color = pineColor);
      if (snowy) {
        final snowCap = Path()
          ..moveTo(base.dx, tierY - tierH)
          ..lineTo(base.dx - halfW * 0.55, tierY - tierH * 0.45)
          ..lineTo(base.dx + halfW * 0.55, tierY - tierH * 0.45)
          ..close();
        canvas.drawPath(snowCap, Paint()..color = Colors.white.withValues(alpha: isDark ? 0.78 : 0.92));
      }
    }
  }

  void _paintSakuraTree(Canvas canvas, Offset base, double height, {double sway = 0}) {
    final trunkPaint = Paint()
      ..color = isDark ? const Color(0xFF4A2E3B) : const Color(0xFF5D3A47)
      ..strokeWidth = height * 0.14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final trunk = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(base.dx - 4, base.dy - height * 0.42, base.dx + 3, base.dy - height * 0.72);
    canvas.drawPath(trunk, trunkPaint);

    final c = Offset(base.dx + sway, base.dy - height * 0.78);
    final deepPink = isDark ? const Color(0xFF9D174D) : const Color(0xFFEC4899);
    final softPink = isDark ? const Color(0xFFF472B6) : const Color(0xFFF9A8D4);
    final palePink = isDark ? const Color(0xFFFBCFE8) : const Color(0xFFFFE4EE);

    canvas.drawCircle(Offset(c.dx - height * 0.28, c.dy + 5), height * 0.26, Paint()..color = deepPink.withValues(alpha: 0.85));
    canvas.drawCircle(Offset(c.dx + height * 0.28, c.dy + 6), height * 0.26, Paint()..color = deepPink.withValues(alpha: 0.85));
    canvas.drawCircle(c, height * 0.34, Paint()..color = softPink);
    canvas.drawCircle(Offset(c.dx - 5, c.dy - 6), height * 0.18, Paint()..color = palePink.withValues(alpha: 0.85));
  }

  void _paintAcaciaTree(Canvas canvas, Offset base, double height) {
    final trunkPaint = Paint()
      ..color = isDark ? const Color(0xFF5C3A21) : const Color(0xFF78350F)
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(base, Offset(base.dx, base.dy - height * 0.72), trunkPaint);
    canvas.drawLine(Offset(base.dx, base.dy - height * 0.50), Offset(base.dx - 16, base.dy - height * 0.74), trunkPaint..strokeWidth = 2.6);
    canvas.drawLine(Offset(base.dx, base.dy - height * 0.54), Offset(base.dx + 16, base.dy - height * 0.74), trunkPaint);

    final canopyColor = isDark ? const Color(0xFF6B8E23) : const Color(0xFF65A30D);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(base.dx, base.dy - height * 0.78), width: height * 1.45, height: height * 0.34),
      Paint()..color = canopyColor.withValues(alpha: 0.90),
    );
  }

  void _paintDeer(Canvas canvas, Offset feet, double s) {
    final bodyPaint = Paint()..color = isDark ? const Color(0xFFC08457) : const Color(0xFF8B5A2B);
    // Body
    canvas.drawOval(Rect.fromCenter(center: Offset(feet.dx, feet.dy - 11 * s), width: 18 * s, height: 9 * s), bodyPaint);
    // Legs
    final legPaint = Paint()..color = bodyPaint.color..strokeWidth = 1.8 * s..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(feet.dx - 5 * s, feet.dy - 8 * s), Offset(feet.dx - 6 * s, feet.dy), legPaint);
    canvas.drawLine(Offset(feet.dx + 5 * s, feet.dy - 8 * s), Offset(feet.dx + 6 * s, feet.dy), legPaint);
    // Neck & head
    canvas.drawLine(Offset(feet.dx + 6 * s, feet.dy - 13 * s), Offset(feet.dx + 9 * s, feet.dy - 21 * s), legPaint..strokeWidth = 3 * s);
    canvas.drawCircle(Offset(feet.dx + 10 * s, feet.dy - 22 * s), 3.2 * s, bodyPaint);
    // Antlers
    final antlerPaint = Paint()..color = isDark ? const Color(0xFFFDE68A) : const Color(0xFF5C3A21)..strokeWidth = 1.2 * s;
    canvas.drawLine(Offset(feet.dx + 9 * s, feet.dy - 24 * s), Offset(feet.dx + 7 * s, feet.dy - 29 * s), antlerPaint);
    canvas.drawLine(Offset(feet.dx + 11 * s, feet.dy - 24 * s), Offset(feet.dx + 13 * s, feet.dy - 29 * s), antlerPaint);
  }

  void _paintGiraffe(Canvas canvas, Offset feet, double s) {
    final p = Paint()..color = isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309);
    final leg = Paint()..color = p.color..strokeWidth = 2.0 * s..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(feet.dx - 4 * s, feet.dy - 12 * s), Offset(feet.dx - 5 * s, feet.dy), leg);
    canvas.drawLine(Offset(feet.dx + 4 * s, feet.dy - 12 * s), Offset(feet.dx + 5 * s, feet.dy), leg);
    canvas.drawOval(Rect.fromCenter(center: Offset(feet.dx, feet.dy - 14 * s), width: 14 * s, height: 8 * s), p);
    canvas.drawLine(Offset(feet.dx + 5 * s, feet.dy - 16 * s), Offset(feet.dx + 9 * s, feet.dy - 34 * s), leg..strokeWidth = 3.0 * s);
    canvas.drawCircle(Offset(feet.dx + 10 * s, feet.dy - 35 * s), 3.0 * s, p);
  }

  void _paintArcticFox(Canvas canvas, Offset feet) {
    final white = Paint()..color = isDark ? const Color(0xFFE0F2FE) : const Color(0xFFFFFFFF);
    final outline = Paint()..color = const Color(0xFF64748B).withValues(alpha: 0.45)..style = PaintingStyle.stroke..strokeWidth = 1.0;
    final body = Rect.fromCenter(center: Offset(feet.dx, feet.dy - 7), width: 16, height: 8);
    canvas.drawOval(body, white);
    canvas.drawOval(body, outline);
    canvas.drawCircle(Offset(feet.dx + 7, feet.dy - 11), 3.8, white);
    canvas.drawOval(Rect.fromCenter(center: Offset(feet.dx - 9, feet.dy - 8), width: 9, height: 5), white);
  }

  void _paintSnowyOwl(Canvas canvas, Offset pos) {
    final flap = math.sin(animValue * math.pi * 8) * 5;
    final p = Paint()..color = Colors.white.withValues(alpha: 0.92)..strokeWidth = 2.4..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final wings = Path()
      ..moveTo(pos.dx - 11, pos.dy - flap)
      ..quadraticBezierTo(pos.dx - 4, pos.dy - 5, pos.dx, pos.dy)
      ..quadraticBezierTo(pos.dx + 4, pos.dy - 5, pos.dx + 11, pos.dy - flap);
    canvas.drawPath(wings, p);
    canvas.drawCircle(pos, 2.5, Paint()..color = Colors.white);
  }

  void _paintFlappingBird(Canvas canvas, Offset pos, double s, Color color) {
    final flap = math.sin(animValue * math.pi * 10 + pos.dx * 0.05) * 4.5 * s;
    final p = Paint()..color = color.withValues(alpha: 0.85)..strokeWidth = 1.9 * s..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(pos.dx - 8 * s, pos.dy - flap)
      ..quadraticBezierTo(pos.dx - 3 * s, pos.dy - 4 * s, pos.dx, pos.dy)
      ..quadraticBezierTo(pos.dx + 3 * s, pos.dy - 4 * s, pos.dx + 8 * s, pos.dy - flap);
    canvas.drawPath(path, p);
  }

  void _paintKoiPond(Canvas canvas, Offset center, double rx, double ry) {
    final pondColor = isDark ? const Color(0xFF1E3A5F) : const Color(0xFF7DD3FC);
    canvas.drawOval(Rect.fromCenter(center: center, width: rx * 2, height: ry * 2), Paint()..color = pondColor.withValues(alpha: 0.55));
    // Expanding water ripple
    final rPhase = (animValue * 2) % 1.0;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * (0.4 + rPhase * 1.1), height: ry * (0.4 + rPhase * 1.1)),
      Paint()
        ..color = Colors.white.withValues(alpha: (1 - rPhase) * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    // Animated swimming Koi fish
    final angle = animValue * math.pi * 2;
    final kx = center.dx + math.cos(angle) * (rx * 0.48);
    final ky = center.dy + math.sin(angle) * (ry * 0.42);
    canvas.drawOval(Rect.fromCenter(center: Offset(kx, ky), width: 10, height: 4.5), Paint()..color = const Color(0xFFF97316));
    canvas.drawCircle(Offset(kx + 2, ky), 1.8, Paint()..color = Colors.white);
  }

  void _paintButterfly(Canvas canvas, Offset pos, Color color) {
    final wingW = 4.0 + math.sin(animValue * math.pi * 16).abs() * 3.5;
    final p = Paint()..color = color.withValues(alpha: 0.90);
    canvas.drawOval(Rect.fromCenter(center: Offset(pos.dx - wingW * 0.6, pos.dy), width: wingW, height: 6), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(pos.dx + wingW * 0.6, pos.dy), width: wingW, height: 6), p);
  }

  void _paintKelpCluster(Canvas canvas, Offset base, double height) {
    final p = Paint()
      ..color = (isDark ? const Color(0xFF10B981) : const Color(0xFF0D9488)).withValues(alpha: 0.72)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int k = -1; k <= 1; k++) {
      final sway = math.sin(animValue * math.pi * 2 + k) * 6;
      final path = Path()
        ..moveTo(base.dx + k * 7, base.dy)
        ..quadraticBezierTo(base.dx + k * 7 + sway, base.dy - height * 0.5, base.dx + k * 5 - sway * 0.6, base.dy - height * (0.85 + k.abs() * 0.1));
      canvas.drawPath(path, p);
    }
  }

  void _paintCoralCluster(Canvas canvas, Offset base, Color color) {
    final p = Paint()..color = color.withValues(alpha: 0.85)..strokeWidth = 3.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    canvas.drawLine(base, Offset(base.dx, base.dy - 18), p);
    canvas.drawLine(Offset(base.dx, base.dy - 8), Offset(base.dx - 9, base.dy - 17), p);
    canvas.drawLine(Offset(base.dx, base.dy - 10), Offset(base.dx + 9, base.dy - 19), p);
  }

  void _paintSeaTurtle(Canvas canvas, Offset pos) {
    final shell = Paint()..color = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);
    final flipper = math.sin(animValue * math.pi * 6) * 3;
    canvas.drawOval(Rect.fromCenter(center: pos, width: 16, height: 11), shell);
    canvas.drawCircle(Offset(pos.dx + 10, pos.dy), 3.4, shell);
    canvas.drawOval(Rect.fromCenter(center: Offset(pos.dx + 2, pos.dy - 7 + flipper * 0.4), width: 6, height: 3.2), shell);
    canvas.drawOval(Rect.fromCenter(center: Offset(pos.dx + 2, pos.dy + 7 - flipper * 0.4), width: 6, height: 3.2), shell);
  }

  void _paintTropicalFish(Canvas canvas, Offset pos, Color color, {bool flipX = false}) {
    final dir = flipX ? -1.0 : 1.0;
    canvas.drawOval(Rect.fromCenter(center: pos, width: 12, height: 6.5), Paint()..color = color);
    final tail = Path()
      ..moveTo(pos.dx - 5 * dir, pos.dy)
      ..lineTo(pos.dx - 10 * dir, pos.dy - 4)
      ..lineTo(pos.dx - 10 * dir, pos.dy + 4)
      ..close();
    canvas.drawPath(tail, Paint()..color = color);
    canvas.drawLine(Offset(pos.dx, pos.dy - 3), Offset(pos.dx, pos.dy + 3), Paint()..color = Colors.white..strokeWidth = 1.6);
  }

  void _paintJellyfish(Canvas canvas, Offset pos) {
    final color = isDark ? const Color(0xFFC084FC) : const Color(0xFF9333EA);
    canvas.drawArc(Rect.fromCenter(center: pos, width: 14, height: 12), math.pi, math.pi, true, Paint()..color = color.withValues(alpha: 0.65));
    final tp = Paint()..color = color.withValues(alpha: 0.5)..strokeWidth = 1.2..style = PaintingStyle.stroke;
    for (int t = -1; t <= 1; t++) {
      final w = math.sin(animValue * math.pi * 4 + t) * 2;
      canvas.drawLine(Offset(pos.dx + t * 3.5, pos.dy), Offset(pos.dx + t * 3.5 + w, pos.dy + 9), tp);
    }
  }

  void _paintAuroraRibbon(Canvas canvas, Size size, double yFrac) {
    final path = Path()..moveTo(0, size.height * yFrac);
    for (double x = 0; x <= size.width; x += 18) {
      final y = size.height * yFrac + math.sin((x / size.width) * math.pi * 2 + animValue * math.pi * 2) * 14;
      path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF34D399).withValues(alpha: isDark ? 0.45 : 0.28),
            const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.42 : 0.25),
            const Color(0xFFA855F7).withValues(alpha: isDark ? 0.35 : 0.22),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.4))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  void _paintFireflies(Canvas canvas, Size size, int count) {
    for (int i = 0; i < count; i++) {
      final phase = (animValue + i * 0.13) % 1.0;
      final x = size.width * ((0.08 + (i * 0.19) % 0.86)) + math.sin(phase * math.pi * 2 + i) * 8;
      final y = size.height * ((0.10 + (i * 0.23) % 0.82)) + math.cos(phase * math.pi * 2) * 6;
      final glow = (math.sin(phase * math.pi)).clamp(0.15, 1.0);
      canvas.drawCircle(Offset(x, y), 4.5, Paint()..color = const Color(0xFFFDE047).withValues(alpha: glow * 0.35));
      canvas.drawCircle(Offset(x, y), 2.0, Paint()..color = const Color(0xFFFEF08A).withValues(alpha: glow));
    }
  }

  void _paintFallingPetals(Canvas canvas, Size size, int count) {
    final p = Paint()..color = const Color(0xFFF9A8D4).withValues(alpha: 0.85);
    for (int i = 0; i < count; i++) {
      final phase = (animValue + i * 0.11) % 1.0;
      final x = (size.width * ((i * 0.17) % 1.0) + math.sin(phase * math.pi * 2 + i) * 14) % size.width;
      final y = size.height * phase;
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 5.5, height: 3.2), p);
    }
  }

  void _paintSnowflakes(Canvas canvas, Size size, int count) {
    final p = Paint()..color = Colors.white.withValues(alpha: isDark ? 0.78 : 0.90);
    for (int i = 0; i < count; i++) {
      final phase = (animValue + i * 0.09) % 1.0;
      final x = (size.width * ((i * 0.13) % 1.0) + math.sin(phase * math.pi * 2 + i) * 10) % size.width;
      final y = size.height * phase;
      canvas.drawCircle(Offset(x, y), (i % 2 == 0) ? 2.2 : 1.5, p);
    }
  }

  void _paintBubbles(Canvas canvas, Size size, int count) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (int i = 0; i < count; i++) {
      final phase = (animValue + i * 0.12) % 1.0;
      final x = size.width * ((0.1 + i * 0.14) % 0.88) + math.sin(phase * math.pi * 4) * 5;
      final y = size.height * (1.0 - phase);
      canvas.drawCircle(Offset(x, y), 2.0 + (i % 3), p);
    }
  }

  @override
  bool shouldRepaint(covariant LivingBiomePainter oldDelegate) =>
      oldDelegate.animValue != animValue ||
      oldDelegate.biomeId != biomeId ||
      oldDelegate.isDark != isDark ||
      oldDelegate.isPreview != isPreview;
}

/// Compact live-animated preview diorama of a Living World Biome for the Themes Shop.
class LivingBiomePreviewBanner extends StatefulWidget {
  final String biomeId;
  final bool isDark;
  final double height;

  const LivingBiomePreviewBanner({
    super.key,
    required this.biomeId,
    required this.isDark,
    this.height = 112,
  });

  @override
  State<LivingBiomePreviewBanner> createState() => _LivingBiomePreviewBannerState();
}

class _LivingBiomePreviewBannerState extends State<LivingBiomePreviewBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: LivingBiomePainter(
                biomeId: widget.biomeId,
                animValue: _controller.value,
                isDark: widget.isDark,
                isPreview: true,
              ),
            );
          },
        ),
      ),
    );
  }
}
