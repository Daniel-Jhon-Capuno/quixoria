import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

enum CharacterPose {
  idle,
  greeting,
  walking,
  celebration,
  encouraging,
  thinking,
  reading,
  lessonComplete,
}

enum CharacterEmotion {
  happy,
  excited,
  thinking,
  encouraging,
  determined,
  surprised,
  sad,
}

/// A high-fidelity, volumetric 3D-styled animated chibi Don Quixote companion.
/// Built directly according to the official character concept sheet:
/// - Floppy tan/brown hat with brim shadow and crown volume
/// - Soft peach chibi face with expressive shiny eyes & dynamic blinking
/// - Large curled white moustache & fluffy white beard
/// - Silver-grey steel armor cuirass with specular metallic highlights & golden rivets
/// - Burgundy velvet cape with cloth folds
/// - Leather tome with gold embossed windmill & silver-tipped lance
/// - Perspective 3D matrix rotation and ambient contact drop shadow
class DonQuixote3DCharacter extends StatelessWidget {
  final double size;
  final CharacterPose pose;
  final CharacterEmotion emotion;
  final double idleValue; // 0.0 to 1.0 from AnimationController
  final double bounceValue; // 0.0 to 1.0 on tap/jump
  final double blinkValue; // 0.0 to 1.0 when blinking
  final double yaw; // user drag yaw
  final double pitch; // user drag pitch
  final bool showShadow; // whether to draw contact shadow pill on ground

  const DonQuixote3DCharacter({
    super.key,
    required this.size,
    this.pose = CharacterPose.idle,
    this.emotion = CharacterEmotion.happy,
    this.idleValue = 0.0,
    this.bounceValue = 0.0,
    this.blinkValue = 0.0,
    this.yaw = 0.0,
    this.pitch = 0.0,
    this.showShadow = true,
  });

  String get _assetPath {
    if (emotion == CharacterEmotion.sad) {
      return 'assets/images/mascot/quixote_sad.png';
    }
    if (emotion == CharacterEmotion.excited ||
        pose == CharacterPose.celebration ||
        pose == CharacterPose.lessonComplete) {
      return 'assets/images/mascot/quixote_excited.png';
    }
    if (emotion == CharacterEmotion.thinking || pose == CharacterPose.thinking) {
      return 'assets/images/mascot/quixote_thinking.png';
    }
    if (emotion == CharacterEmotion.determined) {
      return 'assets/images/mascot/quixote_determined.png';
    }
    if (emotion == CharacterEmotion.happy ||
        pose == CharacterPose.greeting ||
        pose == CharacterPose.reading ||
        pose == CharacterPose.encouraging) {
      return 'assets/images/mascot/quixote_happy.png';
    }
    return 'assets/images/mascot/quixote_idle.png';
  }

  @override
  Widget build(BuildContext context) {
    // Secondary motion physics
    double bobY = 0.0;
    double tiltZ = 0.0;
    double scaleX = 1.0;
    double scaleY = 1.0;

    switch (pose) {
      case CharacterPose.celebration:
      case CharacterPose.lessonComplete:
        bobY = -sin(idleValue * pi) * (size * 0.14) - sin(bounceValue * pi) * (size * 0.18);
        tiltZ = sin(idleValue * pi * 2) * 0.06 + yaw * 0.35;
        scaleX = 1.0 + sin(idleValue * pi) * 0.06;
        scaleY = 1.0 + sin(idleValue * pi) * 0.08;
        break;
      case CharacterPose.walking:
        bobY = -sin(idleValue * pi * 2).abs() * (size * 0.08);
        tiltZ = sin(idleValue * pi * 2) * 0.08 + yaw * 0.35;
        break;
      case CharacterPose.thinking:
        bobY = sin(idleValue * pi) * (size * 0.03);
        tiltZ = -0.06 + sin(idleValue * pi) * 0.03;
        break;
      case CharacterPose.greeting:
        bobY = sin(idleValue * pi) * (size * 0.04);
        tiltZ = 0.05 + sin(idleValue * pi * 2) * 0.04;
        break;
      case CharacterPose.reading:
        bobY = 0.0;
        tiltZ = 0.0;
        break;
      case CharacterPose.idle:
        // Calm, stable, grounded posture (no wobbling or bobbing)
        bobY = -sin(bounceValue * pi) * (size * 0.06);
        tiltZ = yaw * 0.2;
        break;
      case CharacterPose.encouraging:
        bobY = -sin(bounceValue * pi) * (size * 0.06);
        tiltZ = yaw * 0.2;
        break;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Dynamic Soft Ambient Contact Shadow on the Ground (contact shadow pill)
          if (showShadow)
            Positioned(
              bottom: size * 0.03,
              child: Container(
                width: (size * 0.60) * (1.0 - (bobY.abs() / (size * 0.5))),
                height: size * 0.12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: (0.24 - (bobY.abs() / size * 0.2)).clamp(0.08, 0.35)),
                      blurRadius: 10 + bobY.abs() * 0.6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),

          // 3D Transformed Character Mesh
          Transform.translate(
            offset: Offset(0, bobY),
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002) // Perspective depth
                ..rotateY(yaw)
                ..rotateX(pitch)
                ..rotateZ(tiltZ)
                ..scale(scaleX, scaleY, 1.0),
              child: SizedBox(
                width: size,
                height: size,
                child: Image.asset(
                  _assetPath,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (ctx, err, stack) {
                    return CustomPaint(
                      size: Size(size, size),
                      painter: _Quixote3DPainter(
                        pose: pose,
                        emotion: emotion,
                        idleValue: idleValue,
                        blinkValue: blinkValue,
                        bounceValue: bounceValue,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Quixote3DPainter extends CustomPainter {
  final CharacterPose pose;
  final CharacterEmotion emotion;
  final double idleValue;
  final double blinkValue;
  final double bounceValue;

  _Quixote3DPainter({
    required this.pose,
    required this.emotion,
    required this.idleValue,
    required this.blinkValue,
    required this.bounceValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;

    // Relative reference layout coordinates
    final headCenterY = h * 0.38;
    final headRadius = w * 0.26;

    // -------------------------------------------------------------
    // LAYER 1: Lance Shaft (Behind Body)
    // -------------------------------------------------------------
    final isHoldingLance = pose != CharacterPose.reading && pose != CharacterPose.celebration;
    if (isHoldingLance) {
      _drawLance(canvas, size, cx, headCenterY);
    }

    // -------------------------------------------------------------
    // LAYER 2: Burgundy Velvet Cape (Behind Body)
    // -------------------------------------------------------------
    _drawVelvetCape(canvas, size, cx, headCenterY);

    // -------------------------------------------------------------
    // LAYER 3: Boots & Legs
    // -------------------------------------------------------------
    _drawBootsAndLegs(canvas, size, cx, h);

    // -------------------------------------------------------------
    // LAYER 4: Steel Knight Cuirass (Armor Body & Pauldrons)
    // -------------------------------------------------------------
    _drawKnightArmor(canvas, size, cx, headCenterY);

    // -------------------------------------------------------------
    // LAYER 5: 3D Chibi Head & Peach Skin
    // -------------------------------------------------------------
    _draw3DHead(canvas, size, cx, headCenterY, headRadius);

    // -------------------------------------------------------------
    // LAYER 6: Facial Features (Eyes, Blush, Eyebrows)
    // -------------------------------------------------------------
    _drawFaceExpressions(canvas, size, cx, headCenterY, headRadius);

    // -------------------------------------------------------------
    // LAYER 7: Volumetric Curled Moustache & Fluffy Beard
    // -------------------------------------------------------------
    _drawMoustacheAndBeard(canvas, size, cx, headCenterY, headRadius);

    // -------------------------------------------------------------
    // LAYER 8: Floppy Tan/Brown Adventurer Hat & Brim
    // -------------------------------------------------------------
    _drawFloppyHat(canvas, size, cx, headCenterY, headRadius);

    // -------------------------------------------------------------
    // LAYER 9: Hands & Props (Windmill Tome or Gestures)
    // -------------------------------------------------------------
    _drawHandsAndProps(canvas, size, cx, headCenterY);
  }

  void _drawVelvetCape(Canvas canvas, Size size, double cx, double headY) {
    final w = size.width;
    final h = size.height;

    final capeTopY = headY + size.height * 0.12;
    final capeBottomY = h * 0.88;
    final capeSway = (pose == CharacterPose.idle || pose == CharacterPose.reading)
        ? 0.0
        : sin(idleValue * pi * 2) * (w * 0.02);

    final capePath = Path()
      ..moveTo(cx - w * 0.22, capeTopY)
      ..cubicTo(
        cx - w * 0.38 + capeSway,
        capeTopY + (capeBottomY - capeTopY) * 0.5,
        cx - w * 0.34 + capeSway,
        capeBottomY,
        cx - w * 0.28,
        capeBottomY,
      )
      ..quadraticBezierTo(cx, capeBottomY + w * 0.04, cx + w * 0.28, capeBottomY)
      ..cubicTo(
        cx + w * 0.34 - capeSway,
        capeBottomY,
        cx + w * 0.38 - capeSway,
        capeTopY + (capeBottomY - capeTopY) * 0.5,
        cx + w * 0.22,
        capeTopY,
      )
      ..close();

    final capeShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF8B1E28), // Rich crimson
        Color(0xFF6B141E), // Deep burgundy
        Color(0xFF420B11), // Shadow velvet
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(Rect.fromLTWH(0, capeTopY, w, capeBottomY - capeTopY));

    canvas.drawPath(capePath, Paint()..shader = capeShader);

    // Velvet fold highlights
    final foldPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025;

    final foldPath = Path()
      ..moveTo(cx - w * 0.12, capeTopY + w * 0.08)
      ..quadraticBezierTo(cx - w * 0.16 + capeSway * 0.5, capeBottomY * 0.6, cx - w * 0.18, capeBottomY - w * 0.04);
    canvas.drawPath(foldPath, foldPaint);
  }

  void _drawBootsAndLegs(Canvas canvas, Size size, double cx, double h) {
    final w = size.width;
    final legY = h * 0.72;
    final bootY = h * 0.88;

    // Leather Boot Gradient
    final bootShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF5A3825), Color(0xFF382214), Color(0xFF22140B)],
    ).createShader(Rect.fromLTWH(0, legY, w, bootY - legY));

    final bootPaint = Paint()..shader = bootShader;

    // Left Boot
    final leftBoot = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - w * 0.14, bootY), width: w * 0.18, height: w * 0.14),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(leftBoot, bootPaint);

    // Right Boot
    final rightBoot = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + w * 0.14, bootY), width: w * 0.18, height: w * 0.14),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(rightBoot, bootPaint);

    // Boot Soles & Highlights
    final solePaint = Paint()..color = const Color(0xFF1B1108);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - w * 0.14, bootY + w * 0.05), width: w * 0.19, height: w * 0.04),
        Radius.circular(w * 0.02),
      ),
      solePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + w * 0.14, bootY + w * 0.05), width: w * 0.19, height: w * 0.04),
        Radius.circular(w * 0.02),
      ),
      solePaint,
    );
  }

  void _drawKnightArmor(Canvas canvas, Size size, double cx, double headY) {
    final w = size.width;
    final armorTopY = headY + size.height * 0.10;
    final armorBottomY = headY + size.height * 0.38;

    // Metallic Steel Cuirass with Specular Sweep
    final armorRect = Rect.fromCenter(
      center: Offset(cx, (armorTopY + armorBottomY) * 0.5),
      width: w * 0.44,
      height: armorBottomY - armorTopY,
    );

    final steelShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFE2E8F0), // High silver shine
        Color(0xFFB0BDCE), // Polished steel
        Color(0xFF708096), // Medieval iron shadow
        Color(0xFF485566), // Deep ambient occlusion
      ],
      stops: [0.0, 0.32, 0.72, 1.0],
    ).createShader(armorRect);

    final armorRRect = RRect.fromRectAndCorners(
      armorRect,
      topLeft: Radius.circular(w * 0.10),
      topRight: Radius.circular(w * 0.10),
      bottomLeft: Radius.circular(w * 0.14),
      bottomRight: Radius.circular(w * 0.14),
    );

    canvas.drawRRect(armorRRect, Paint()..shader = steelShader);

    // Golden Trim & Rivets
    final goldBorderPaint = Paint()
      ..color = AppColors.antiqueGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018;
    canvas.drawRRect(armorRRect, goldBorderPaint);

    // Center Breastplate Ridge
    final ridgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.015;
    canvas.drawLine(
      Offset(cx, armorTopY + w * 0.02),
      Offset(cx, armorBottomY - w * 0.04),
      ridgePaint,
    );

    // Pauldrons (Curved 3D Shoulder Armor Plates)
    final pauldronShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFD6DFE8), Color(0xFF8294A8), Color(0xFF566575)],
    ).createShader(Rect.fromLTWH(0, armorTopY, w, w * 0.2));

    // Left Pauldron
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - w * 0.24, armorTopY + w * 0.05),
        width: w * 0.18,
        height: w * 0.15,
      ),
      Paint()..shader = pauldronShader,
    );
    // Right Pauldron
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + w * 0.24, armorTopY + w * 0.05),
        width: w * 0.18,
        height: w * 0.15,
      ),
      Paint()..shader = pauldronShader,
    );
  }

  void _draw3DHead(Canvas canvas, Size size, double cx, double headY, double radius) {
    // 3D Spherical Head Shader (Key-light from Top-Left, Soft Peach bounce)
    final headRect = Rect.fromCircle(center: Offset(cx, headY), radius: radius);
    final skinShader = RadialGradient(
      center: const Alignment(-0.25, -0.35), // 3D Top-Left Light Key
      radius: 0.85,
      colors: const [
        Color(0xFFFFF1E6), // Highlight
        Color(0xFFFFDFCE), // Warm Chibi Peach
        Color(0xFFF7C3A8), // Shaded cheek
        Color(0xFFE29B7A), // Occlusion edge
      ],
      stops: const [0.0, 0.45, 0.82, 1.0],
    ).createShader(headRect);

    canvas.drawCircle(Offset(cx, headY), radius, Paint()..shader = skinShader);

    // Rosy Blush Cheeks (Cute Chibi Style)
    final blushShader = RadialGradient(
      colors: [
        const Color(0xFFF87171).withValues(alpha: 0.38),
        const Color(0xFFF87171).withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(center: Offset(cx - radius * 0.58, headY + radius * 0.18), radius: radius * 0.35));

    canvas.drawCircle(
      Offset(cx - radius * 0.58, headY + radius * 0.18),
      radius * 0.28,
      Paint()..shader = blushShader,
    );

    final rightBlushShader = RadialGradient(
      colors: [
        const Color(0xFFF87171).withValues(alpha: 0.38),
        const Color(0xFFF87171).withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(center: Offset(cx + radius * 0.58, headY + radius * 0.18), radius: radius * 0.35));

    canvas.drawCircle(
      Offset(cx + radius * 0.58, headY + radius * 0.18),
      radius * 0.28,
      Paint()..shader = rightBlushShader,
    );
  }

  void _drawFaceExpressions(Canvas canvas, Size size, double cx, double headY, double radius) {
    final w = size.width;
    final eyeOffsetX = radius * 0.42;
    final eyeY = headY - radius * 0.05;
    final eyeW = radius * 0.22;
    final eyeH = radius * 0.30;

    // Handle Smooth Animated Blinking (eyelid squash)
    final blinkScaleY = (1.0 - blinkValue).clamp(0.08, 1.0);

    // Check Emotion for Eye Styles
    if (emotion == CharacterEmotion.excited) {
      // Star/Glint Excited Eyes
      _drawStarEye(canvas, Offset(cx - eyeOffsetX, eyeY), eyeW * 0.9);
      _drawStarEye(canvas, Offset(cx + eyeOffsetX, eyeY), eyeW * 0.9);
    } else if (emotion == CharacterEmotion.happy && (pose == CharacterPose.celebration || pose == CharacterPose.lessonComplete)) {
      // Cheerful Inverted Crescent Smiling Eyes
      final smileEyePaint = Paint()
        ..color = const Color(0xFF26180E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round;

      final leftArc = Path()
        ..moveTo(cx - eyeOffsetX - eyeW * 0.6, eyeY)
        ..quadraticBezierTo(cx - eyeOffsetX, eyeY - eyeH * 0.7, cx - eyeOffsetX + eyeW * 0.6, eyeY);
      final rightArc = Path()
        ..moveTo(cx + eyeOffsetX - eyeW * 0.6, eyeY)
        ..quadraticBezierTo(cx + eyeOffsetX, eyeY - eyeH * 0.7, cx + eyeOffsetX + eyeW * 0.6, eyeY);

      canvas.drawPath(leftArc, smileEyePaint);
      canvas.drawPath(rightArc, smileEyePaint);
    } else {
      // Standard Expressive 3D Obsidian Eyes with Specular Highlights
      final eyePaint = Paint()..color = const Color(0xFF1E140C);

      // Left Eye
      canvas.save();
      canvas.translate(cx - eyeOffsetX, eyeY);
      canvas.scale(1.0, blinkScaleY);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: eyeW, height: eyeH),
        eyePaint,
      );
      if (blinkScaleY > 0.4) {
        // Dual Catchlight Glints (Major and Minor Pixar Glints)
        canvas.drawCircle(Offset(-eyeW * 0.18, -eyeH * 0.22), eyeW * 0.24, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(eyeW * 0.20, eyeH * 0.18), eyeW * 0.12, Paint()..color = Colors.white.withValues(alpha: 0.85));
      }
      canvas.restore();

      // Right Eye
      canvas.save();
      canvas.translate(cx + eyeOffsetX, eyeY);
      canvas.scale(1.0, blinkScaleY);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: eyeW, height: eyeH),
        eyePaint,
      );
      if (blinkScaleY > 0.4) {
        // Dual Catchlight Glints
        canvas.drawCircle(Offset(-eyeW * 0.18, -eyeH * 0.22), eyeW * 0.24, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(eyeW * 0.20, eyeH * 0.18), eyeW * 0.12, Paint()..color = Colors.white.withValues(alpha: 0.85));
      }
      canvas.restore();
    }

    // Eyebrows
    final browPaint = Paint()
      ..color = const Color(0xFFE2E8F0) // Soft white knight eyebrows
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.028
      ..strokeCap = StrokeCap.round;

    double browTilt = 0.0;
    if (emotion == CharacterEmotion.thinking) {
      browTilt = -w * 0.03; // Inquisitive arched brow
    }

    canvas.drawLine(
      Offset(cx - eyeOffsetX - eyeW * 0.5, eyeY - eyeH * 0.65 + browTilt),
      Offset(cx - eyeOffsetX + eyeW * 0.5, eyeY - eyeH * 0.8),
      browPaint,
    );
    canvas.drawLine(
      Offset(cx + eyeOffsetX - eyeW * 0.5, eyeY - eyeH * 0.8),
      Offset(cx + eyeOffsetX + eyeW * 0.5, eyeY - eyeH * 0.65 - browTilt),
      browPaint,
    );
  }

  void _drawStarEye(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = const Color(0xFFF59E0B) // Golden star sparkle
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < 5; i++) {
      final double outerAngle = -pi / 2 + i * 4 * pi / 5;
      final double x = center.dx + radius * cos(outerAngle);
      final double y = center.dy + radius * sin(outerAngle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawMoustacheAndBeard(Canvas canvas, Size size, double cx, double headY, double radius) {
    final moustacheY = headY + radius * 0.34;

    // Beard Base (Soft Pillowy 3D White Beard)
    final beardPath = Path()
      ..moveTo(cx - radius * 0.52, moustacheY)
      ..cubicTo(
        cx - radius * 0.60,
        moustacheY + radius * 0.85,
        cx - radius * 0.28,
        moustacheY + radius * 1.05,
        cx,
        moustacheY + radius * 1.12,
      )
      ..cubicTo(
        cx + radius * 0.28,
        moustacheY + radius * 1.05,
        cx + radius * 0.60,
        moustacheY + radius * 0.85,
        cx + radius * 0.52,
        moustacheY,
      )
      ..close();

    final beardShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFF1F5F9),
        Color(0xFFCBD5E1),
      ],
      stops: [0.0, 0.55, 1.0],
    ).createShader(Rect.fromLTWH(cx - radius, moustacheY, radius * 2, radius * 1.2));

    canvas.drawPath(beardPath, Paint()..shader = beardShader);

    // Volumetric Curled Moustache (Don Quixote's Signature Curled Handlebar)
    // Left Wing
    final leftMustache = Path()
      ..moveTo(cx, moustacheY + radius * 0.08)
      ..cubicTo(
        cx - radius * 0.35,
        moustacheY + radius * 0.15,
        cx - radius * 0.75,
        moustacheY - radius * 0.02,
        cx - radius * 0.90,
        moustacheY - radius * 0.22, // Upward curled tip
      )
      ..cubicTo(
        cx - radius * 0.82,
        moustacheY - radius * 0.10,
        cx - radius * 0.45,
        moustacheY + radius * 0.02,
        cx,
        moustacheY + radius * 0.04,
      )
      ..close();

    // Right Wing
    final rightMustache = Path()
      ..moveTo(cx, moustacheY + radius * 0.08)
      ..cubicTo(
        cx + radius * 0.35,
        moustacheY + radius * 0.15,
        cx + radius * 0.75,
        moustacheY - radius * 0.02,
        cx + radius * 0.90,
        moustacheY - radius * 0.22, // Upward curled tip
      )
      ..cubicTo(
        cx + radius * 0.82,
        moustacheY - radius * 0.10,
        cx + radius * 0.45,
        moustacheY + radius * 0.02,
        cx,
        moustacheY + radius * 0.04,
      )
      ..close();

    final mustacheShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFE2E8F0),
        Color(0xFF94A3B8),
      ],
    ).createShader(Rect.fromLTWH(cx - radius, moustacheY - radius * 0.3, radius * 2, radius * 0.6));

    // Moustache Drop Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawPath(leftMustache.shift(const Offset(0, 2)), shadowPaint);
    canvas.drawPath(rightMustache.shift(const Offset(0, 2)), shadowPaint);

    canvas.drawPath(leftMustache, Paint()..shader = mustacheShader);
    canvas.drawPath(rightMustache, Paint()..shader = mustacheShader);
  }

  void _drawFloppyHat(Canvas canvas, Size size, double cx, double headY, double radius) {
    final w = size.width;
    final hatBrimY = headY - radius * 0.50;

    // Ambient Occlusion Shadow cast by Hat Brim onto the Forehead
    final brimShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, hatBrimY + w * 0.04), width: w * 0.72, height: w * 0.18),
      brimShadowPaint,
    );

    // Floppy Hat Crown (Volumetric 3D Dome)
    final crownPath = Path()
      ..moveTo(cx - w * 0.28, hatBrimY)
      ..cubicTo(
        cx - w * 0.32,
        hatBrimY - w * 0.30,
        cx - w * 0.14,
        hatBrimY - w * 0.42,
        cx + w * 0.05,
        hatBrimY - w * 0.40,
      )
      ..cubicTo(
        cx + w * 0.26,
        hatBrimY - w * 0.38,
        cx + w * 0.28,
        hatBrimY - w * 0.24,
        cx + w * 0.26,
        hatBrimY,
      )
      ..close();

    final crownShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFD4A373), // Warm tan highlight
        Color(0xFFB57D4C), // Leather brown midtone
        Color(0xFF825229), // Shadow brown
      ],
      stops: [0.0, 0.45, 1.0],
    ).createShader(Rect.fromLTWH(cx - w * 0.35, hatBrimY - w * 0.45, w * 0.7, w * 0.5));

    canvas.drawPath(crownPath, Paint()..shader = crownShader);

    // Leather Hat Band with Antique Gold Buckle
    final bandPaint = Paint()
      ..color = const Color(0xFF4A2810)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.038;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - w * 0.01, hatBrimY - w * 0.02), width: w * 0.54, height: w * 0.12),
      0,
      pi,
      false,
      bandPaint,
    );

    // Gold Buckle
    final bucklePaint = Paint()
      ..color = AppColors.antiqueGold
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - w * 0.14, hatBrimY - w * 0.02), width: w * 0.05, height: w * 0.04),
        Radius.circular(w * 0.01),
      ),
      bucklePaint,
    );

    // Curved Wide Hat Brim with 3D Bevel & Highlight
    final brimPath = Path()
      ..moveTo(cx - w * 0.46, hatBrimY + w * 0.03)
      ..cubicTo(
        cx - w * 0.24,
        hatBrimY - w * 0.05,
        cx + w * 0.24,
        hatBrimY - w * 0.08,
        cx + w * 0.46,
        hatBrimY + w * 0.02,
      )
      ..cubicTo(
        cx + w * 0.32,
        hatBrimY + w * 0.12,
        cx - w * 0.32,
        hatBrimY + w * 0.14,
        cx - w * 0.46,
        hatBrimY + w * 0.03,
      )
      ..close();

    final brimShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFE2B282), // Brim top sunlight
        Color(0xFFC48F5A), // Soft tan
        Color(0xFF8A5728), // Underside rim
      ],
      stops: [0.0, 0.48, 1.0],
    ).createShader(Rect.fromLTWH(cx - w * 0.5, hatBrimY - w * 0.1, w, w * 0.3));

    canvas.drawPath(brimPath, Paint()..shader = brimShader);

    // Crisp Brim Edge Rim
    final brimRimPaint = Paint()
      ..color = const Color(0xFFF1C79D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.014;
    canvas.drawPath(brimPath, brimRimPaint);
  }

  void _drawHandsAndProps(Canvas canvas, Size size, double cx, double headY) {
    final h = size.height;
    final bodyCenterY = headY + h * 0.24;

    // LEFT HAND: The Windmill Tome (Held against side or raised in celebration)
    _drawWindmillTome(canvas, size, cx, bodyCenterY);

    // RIGHT HAND: Gesturing or holding lance grip
    _drawRightArmAndHand(canvas, size, cx, bodyCenterY);
  }

  void _drawWindmillTome(Canvas canvas, Size size, double cx, double bodyY) {
    final w = size.width;

    double bookX = cx + w * 0.18;
    double bookY = bodyY;
    double bookRotation = 0.12;

    if (pose == CharacterPose.celebration || pose == CharacterPose.lessonComplete) {
      // Raised triumphantly overhead
      bookX = cx + w * 0.14;
      bookY = bodyY - w * 0.32;
      bookRotation = -0.22;
    } else if (pose == CharacterPose.reading) {
      // Held open in center lap
      bookX = cx;
      bookY = bodyY + w * 0.14;
      bookRotation = 0.0;
    }

    canvas.save();
    canvas.translate(bookX, bookY);
    canvas.rotate(bookRotation);

    final bookW = w * 0.24;
    final bookH = w * 0.30;
    final bookRect = Rect.fromCenter(center: Offset.zero, width: bookW, height: bookH);

    // Leather Book Cover Gradient
    final bookShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8B4513), Color(0xFF5C2C10), Color(0xFF381A08)],
    ).createShader(bookRect);

    final bookRRect = RRect.fromRectAndRadius(bookRect, Radius.circular(w * 0.025));
    canvas.drawRRect(bookRRect, Paint()..shader = bookShader);

    // Gilded Page Edges
    final pagePaint = Paint()..color = const Color(0xFFFDE68A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bookW * 0.35, -bookH * 0.44, bookW * 0.12, bookH * 0.88),
        Radius.circular(w * 0.01),
      ),
      pagePaint,
    );

    // Gold Embossed Windmill Emblem on Cover
    _drawGoldWindmill(canvas, bookW * 0.55);

    // Left Arm Gauntlet holding book
    final gauntletShader = const LinearGradient(
      colors: [Color(0xFFD6DFE8), Color(0xFF708096)],
    ).createShader(Rect.fromCircle(center: const Offset(-4, 0), radius: w * 0.08));

    canvas.drawCircle(Offset(-bookW * 0.35, 0), w * 0.065, Paint()..shader = gauntletShader);

    canvas.restore();
  }

  void _drawGoldWindmill(Canvas canvas, double size) {
    final goldPaint = Paint()
      ..color = AppColors.antiqueGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.12
      ..strokeCap = StrokeCap.round;

    // Windmill Base Tower
    final towerPath = Path()
      ..moveTo(-size * 0.22, size * 0.38)
      ..lineTo(-size * 0.14, -size * 0.08)
      ..lineTo(size * 0.14, -size * 0.08)
      ..lineTo(size * 0.22, size * 0.38)
      ..close();
    canvas.drawPath(towerPath, Paint()..color = AppColors.antiqueGold.withValues(alpha: 0.85));

    // 4 Rotating Windmill Blades
    final hubY = -size * 0.08;
    canvas.drawLine(Offset(-size * 0.35, hubY - size * 0.35), Offset(size * 0.35, hubY + size * 0.35), goldPaint);
    canvas.drawLine(Offset(-size * 0.35, hubY + size * 0.35), Offset(size * 0.35, hubY - size * 0.35), goldPaint);
    canvas.drawCircle(Offset(0, hubY), size * 0.08, Paint()..color = Colors.white);
  }

  void _drawRightArmAndHand(Canvas canvas, Size size, double cx, double bodyY) {
    final w = size.width;

    if (pose == CharacterPose.thinking) {
      // Thoughtful Hand Under Chin
      final handPaint = Paint()..color = const Color(0xFFFFDFC4);
      canvas.drawCircle(Offset(cx - w * 0.04, bodyY - w * 0.14), w * 0.055, handPaint);
    } else if (pose == CharacterPose.encouraging) {
      // Reassuring Thumbs-Up Gauntlet
      final gauntletShader = const LinearGradient(
        colors: [Color(0xFFE2E8F0), Color(0xFF708096)],
      ).createShader(Rect.fromCircle(center: Offset(cx - w * 0.22, bodyY), radius: w * 0.08));

      canvas.drawCircle(Offset(cx - w * 0.22, bodyY), w * 0.06, Paint()..shader = gauntletShader);
      // Thumb
      canvas.drawLine(
        Offset(cx - w * 0.22, bodyY),
        Offset(cx - w * 0.22, bodyY - w * 0.08),
        Paint()
          ..color = const Color(0xFFE2E8F0)
          ..strokeWidth = w * 0.04
          ..strokeCap = StrokeCap.round,
      );
    } else {
      // Standard Resting / Spear Holding Gauntlet
      final gauntletShader = const LinearGradient(
        colors: [Color(0xFFE2E8F0), Color(0xFF708096)],
      ).createShader(Rect.fromCircle(center: Offset(cx - w * 0.22, bodyY), radius: w * 0.08));

      canvas.drawCircle(Offset(cx - w * 0.22, bodyY), w * 0.06, Paint()..shader = gauntletShader);
    }
  }

  void _drawLance(Canvas canvas, Size size, double cx, double headY) {
    final w = size.width;
    final h = size.height;

    final lanceX = cx - w * 0.28;
    final lanceTopY = headY - h * 0.32;
    final lanceBottomY = h * 0.88;

    // Wooden Lance Shaft
    final shaftPaint = Paint()
      ..color = const Color(0xFF784212)
      ..strokeWidth = w * 0.024
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(lanceX, lanceTopY + w * 0.16), Offset(lanceX, lanceBottomY), shaftPaint);

    // Silver Steel Spearhead
    final spearPath = Path()
      ..moveTo(lanceX, lanceTopY) // Tip
      ..lineTo(lanceX - w * 0.04, lanceTopY + w * 0.15)
      ..lineTo(lanceX, lanceTopY + w * 0.13)
      ..lineTo(lanceX + w * 0.04, lanceTopY + w * 0.15)
      ..close();

    final spearShader = const LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFCBD5E1), Color(0xFF64748B)],
    ).createShader(Rect.fromLTWH(lanceX - w * 0.05, lanceTopY, w * 0.1, w * 0.15));

    canvas.drawPath(spearPath, Paint()..shader = spearShader);

    // Antique Gold Spear Collar
    final collarPaint = Paint()..color = AppColors.antiqueGold;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(lanceX, lanceTopY + w * 0.15), width: w * 0.06, height: w * 0.03),
        Radius.circular(w * 0.01),
      ),
      collarPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _Quixote3DPainter oldDelegate) {
    return oldDelegate.idleValue != idleValue ||
        oldDelegate.bounceValue != bounceValue ||
        oldDelegate.blinkValue != blinkValue ||
        oldDelegate.pose != pose ||
        oldDelegate.emotion != emotion;
  }
}
