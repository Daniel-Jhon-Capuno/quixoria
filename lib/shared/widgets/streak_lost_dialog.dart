import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/sound_service.dart';
import 'duo_button.dart';
import 'quixote_avatar.dart';

class StreakLostDialog extends StatefulWidget {
  final int previousStreak;
  final VoidCallback onRekindle;
  final VoidCallback onRestore;
  final VoidCallback onDismiss;

  const StreakLostDialog({
    super.key,
    required this.previousStreak,
    required this.onRekindle,
    required this.onRestore,
    required this.onDismiss,
  });

  static Future<void> show({
    required BuildContext context,
    required int previousStreak,
    required VoidCallback onRekindle,
    required VoidCallback onRestore,
    required VoidCallback onDismiss,
  }) {
    SoundService.instance.play(Sfx.dialog);
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StreakLostDialog(
        previousStreak: previousStreak,
        onRekindle: onRekindle,
        onRestore: onRestore,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  State<StreakLostDialog> createState() => _StreakLostDialogState();
}

class _StreakLostDialogState extends State<StreakLostDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isRekindling = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerRekindleWithGems() async {
    if (_isRekindling) return;
    setState(() => _isRekindling = true);
    SoundService.instance.play(Sfx.streak);
    HapticFeedback.heavyImpact();

    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      Navigator.of(context).pop();
      widget.onRestore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B1F1C),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: _isRekindling ? AppColors.antiqueGold : const Color(0xFF4A554E),
            width: _isRekindling ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isRekindling ? AppColors.streakOrange.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: SingleChildScrollView(physics: const BouncingScrollPhysics(), child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Campfire Custom Animation (Extinguished vs Roaring Blazing Flame)
            SizedBox(
              height: 140,
              width: 180,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _isRekindling
                        ? _BlazingCampfirePainter(_controller.value)
                        : _ExtinguishedCampfirePainter(_controller.value),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Badge: Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _isRekindling ? const Color(0xFF38240D) : const Color(0xFF2E1C1D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isRekindling ? AppColors.antiqueGold : AppColors.energyRed.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isRekindling ? Icons.local_fire_department_rounded : Icons.nightlight_round,
                    size: 13,
                    color: _isRekindling ? AppColors.streakOrange : AppColors.energyRed,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isRekindling ? 'CAMPFIRE REKINDLED • STREAK INTACT' : '12:00 AM MIDNIGHT DEADLINE PASSED',
                    style: AppTypography.labelSmall.copyWith(
                      color: _isRekindling ? AppColors.antiqueGold : const Color(0xFFFF8B80),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Text(
              _isRekindling ? 'Campfire Roars Anew!' : 'Thy Flame Has Burned Down',
              textAlign: TextAlign.center,
              style: AppTypography.displaySmall.copyWith(
                color: const Color(0xFFFAF6EE),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              _isRekindling
                  ? 'Thy campfire blazes with radiant chivalric fire! Thy ${widget.previousStreak}-day reading streak has been faithfully preserved.'
                  : 'Alas! Midnight arrived and the embers grew cold. Thy ${widget.previousStreak}-day reading streak has been extinguished into ash.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: const Color(0xFFB0BDB5),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),

            // Don Quixote Character Speech
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF252C27),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF38433C)),
              ),
              child: Row(
                children: [
                  QuixoteAvatar(
                    size: 48,
                    mood: _isRekindling ? QuixoteMood.proud : QuixoteMood.sad,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isRekindling
                          ? '“By the stars! The campfire blazes higher than ever before, noble scholar! March forth!”'
                          : '“Grieve not, noble squire! A true knight fears no fall. The kindling awaits thy spark today!”',
                      style: AppTypography.bodySmall.copyWith(
                        color: const Color(0xFFE2EBE5),
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (!_isRekindling) ...[
              // Rekindle Today Button
              DuoButton(
                text: 'Kindle a New Flame Today',
                icon: Icons.local_fire_department_rounded,
                variant: DuoButtonVariant.gold,
                height: 48,
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onRekindle();
                },
              ),
              const SizedBox(height: 10),

              // Restore with Shield / Golden Key
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.shield_outlined, size: 16, color: AppColors.antiqueGold),
                      label: const Text('Restore Streak (50 Gems)', style: TextStyle(color: AppColors.antiqueGold, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.antiqueGold),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _triggerRekindleWithGems,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onDismiss();
                    },
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.antiqueGold, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Streak Safely Restored!',
                      style: TextStyle(color: AppColors.antiqueGold, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}

/// Custom painter for an extinguished campfire with wafting smoke, cool embers, and drifting ash
class _ExtinguishedCampfirePainter extends CustomPainter {
  final double progress;

  _ExtinguishedCampfirePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final groundY = size.height - 25;

    // 1. Cool stone circle
    final stonePaint = Paint()
      ..color = const Color(0xFF333834)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 7; i++) {
      final ang = (i / 7) * pi + 0.1;
      final sx = cx + cos(ang) * 45;
      final sy = groundY + sin(ang) * 12;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(sx, sy), width: 18, height: 10),
        stonePaint,
      );
    }

    // 2. Charred logs criss-crossing
    final logPaint = Paint()
      ..color = const Color(0xFF1E1A17)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    final logHighlight = Paint()
      ..color = const Color(0xFF3B332E)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Log 1
    canvas.drawLine(Offset(cx - 38, groundY + 4), Offset(cx + 34, groundY - 14), logPaint);
    canvas.drawLine(Offset(cx - 32, groundY + 2), Offset(cx + 30, groundY - 14), logHighlight);

    // Log 2
    canvas.drawLine(Offset(cx + 36, groundY + 4), Offset(cx - 36, groundY - 12), logPaint);
    canvas.drawLine(Offset(cx + 30, groundY + 2), Offset(cx - 32, groundY - 12), logHighlight);

    // 3. Dying coals / embers (faint pulsation)
    final emberGlow = (sin(progress * 2 * pi) * 0.3 + 0.7);
    final emberPaint = Paint()
      ..color = Color.fromRGBO(200, 60, 20, 0.4 * emberGlow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(cx, groundY - 4), 16, emberPaint);

    final coalPaint = Paint()..color = Color.fromRGBO(230, 80, 20, 0.7 * emberGlow);
    canvas.drawCircle(Offset(cx - 6, groundY - 5), 3, coalPaint);
    canvas.drawCircle(Offset(cx + 5, groundY - 3), 2.5, coalPaint);
    canvas.drawCircle(Offset(cx + 1, groundY - 8), 2, coalPaint);

    // 4. Wafting gray smoke curls
    final smokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int s = 0; s < 3; s++) {
      final t = (progress + s * 0.33) % 1.0;
      final smokeY = groundY - 15 - t * 75;
      final smokeX = cx + sin(t * 3 * pi + s) * 14 * (1 + t);
      final alpha = (sin(t * pi) * 160).toInt().clamp(0, 255);

      smokePaint.color = Color.fromARGB(alpha, 160, 170, 165);
      smokePaint.strokeWidth = 3.5 + t * 5;

      canvas.drawCircle(Offset(smokeX, smokeY), 4 + t * 7, smokePaint);
    }

    // 5. Drifting cold ash specks
    final ashPaint = Paint()..color = const Color(0xFFC0CCC4);
    for (int a = 0; a < 6; a++) {
      final at = (progress + a * 0.17) % 1.0;
      final ax = cx + cos(a * 1.5) * 28 + sin(at * 2 * pi) * 8;
      final ay = groundY - 10 - at * 60;
      final opacity = (1.0 - at).clamp(0.0, 1.0);
      ashPaint.color = Color.fromRGBO(190, 200, 195, opacity * 0.8);
      canvas.drawCircle(Offset(ax, ay), 1.5, ashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ExtinguishedCampfirePainter oldDelegate) => true;
}

/// Custom painter for a roaring, rekindled campfire with dancing golden flames and sparks
class _BlazingCampfirePainter extends CustomPainter {
  final double progress;

  _BlazingCampfirePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final groundY = size.height - 25;

    // 1. Hot stone circle glowing
    final stonePaint = Paint()
      ..color = const Color(0xFF553C22)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 7; i++) {
      final ang = (i / 7) * pi + 0.1;
      final sx = cx + cos(ang) * 45;
      final sy = groundY + sin(ang) * 12;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(sx, sy), width: 14, height: 10),
        stonePaint,
      );
    }

    // 2. Burning Fire logs
    final logPaint = Paint()
      ..color = const Color(0xFF6D3B18)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 32, groundY - 4), Offset(cx + 32, groundY + 4), logPaint);
    canvas.drawLine(Offset(cx + 30, groundY - 6), Offset(cx - 28, groundY + 5), logPaint);

    // 3. Ambient Glow Aura
    final glowPaint = Paint()
      ..color = AppColors.antiqueGold.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset(cx, groundY - 35), 45, glowPaint);

    // 4. Outer Red/Orange Flame
    final flameOuterPath = Path();
    final flicker1 = sin(progress * pi * 4) * 6;
    final flicker2 = cos(progress * pi * 6) * 5;

    flameOuterPath.moveTo(cx - 26, groundY - 2);
    flameOuterPath.quadraticBezierTo(cx - 28, groundY - 40, cx + flicker1, groundY - 78);
    flameOuterPath.quadraticBezierTo(cx + 28, groundY - 40, cx + 26, groundY - 2);
    flameOuterPath.close();

    final outerFlamePaint = Paint()
      ..color = AppColors.streakOrange
      ..style = PaintingStyle.fill;
    canvas.drawPath(flameOuterPath, outerFlamePaint);

    // 5. Inner Bright Golden Flame Core
    final flameInnerPath = Path();
    flameInnerPath.moveTo(cx - 16, groundY - 4);
    flameInnerPath.quadraticBezierTo(cx - 16, groundY - 30, cx + flicker2, groundY - 55);
    flameInnerPath.quadraticBezierTo(cx + 16, groundY - 30, cx + 16, groundY - 4);
    flameInnerPath.close();

    final innerFlamePaint = Paint()
      ..color = AppColors.antiqueGold
      ..style = PaintingStyle.fill;
    canvas.drawPath(flameInnerPath, innerFlamePaint);

    // 6. Center White-Hot Core
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, groundY - 14), width: 14, height: 20),
      corePaint,
    );

    // 7. Rising Golden Sparks & Embers
    final sparkPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 9; i++) {
      final t = (progress + i * 0.11) % 1.0;
      final sx = cx + sin(i * 1.7 + t * 4 * pi) * 26;
      final sy = groundY - 25 - t * 85;
      final sparkOpacity = (1.0 - t).clamp(0.0, 1.0);
      sparkPaint.color = (i % 2 == 0 ? AppColors.antiqueGold : AppColors.streakOrange).withValues(alpha: sparkOpacity);
      canvas.drawCircle(Offset(sx, sy), 1.8 + (1.0 - t), sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlazingCampfirePainter oldDelegate) => true;
}