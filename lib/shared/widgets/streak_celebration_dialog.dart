import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';
import 'duo_button.dart';
import 'quixote_avatar.dart';

class StreakCelebrationDialog extends StatefulWidget {
  final int streakDays;
  final bool isRekindled;
  final int? gemsEarned;
  final String? levelTitle;
  final VoidCallback onContinue;

  const StreakCelebrationDialog({
    super.key,
    required this.streakDays,
    this.isRekindled = false,
    this.gemsEarned,
    this.levelTitle,
    required this.onContinue,
  });

  static Future<void> show({
    required BuildContext context,
    required int streakDays,
    bool isRekindled = false,
    int? gemsEarned,
    String? levelTitle,
    required VoidCallback onContinue,
  }) {
    SoundService.instance.play(isRekindled ? Sfx.streakRekindle : Sfx.streak);
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StreakCelebrationDialog(
        streakDays: streakDays,
        isRekindled: isRekindled,
        gemsEarned: gemsEarned,
        levelTitle: levelTitle,
        onContinue: onContinue,
      ),
    );
  }

  @override
  State<StreakCelebrationDialog> createState() => _StreakCelebrationDialogState();
}

class _StreakCelebrationDialogState extends State<StreakCelebrationDialog>
    with TickerProviderStateMixin {
  late AnimationController _fireController;
  late AnimationController _popController;
  late AnimationController _burstController;
  final List<_ConfettiParticle> _confetti = [];
  final Random _random = Random();
  late int _quoteIndex;

  static const List<Map<String, dynamic>> _quixotePraises = [
    {
      'mood': QuixoteMood.proud,
      'quote': 'By the blade of Mambrino, {name}! The windmills of sloth crumble before our blazing resolve!',
      'badge': 'Chivalric Triumph',
    },
    {
      'mood': QuixoteMood.triumphant,
      'quote': 'Sancho, sound the trumpets! Our noble companion {name} hath conquered another literary summit!',
      'badge': 'Hero of Letters',
    },
    {
      'mood': QuixoteMood.proud,
      'quote': 'A masterstroke of knightly dedication, {name}! Even the enchanters of Toledo would marvel at this brilliance!',
      'badge': 'Scholar of Renown',
    },
    {
      'mood': QuixoteMood.triumphant,
      'quote': 'Behold the flame of curiosity! {name}\'s quest burns with unquenchable valor and wisdom!',
      'badge': 'Eternal Flame',
    },
    {
      'mood': QuixoteMood.proud,
      'quote': 'Neither dragons nor giants could stay your intellect today, {name}! Forward to greater glory!',
      'badge': 'Unwavering Knight',
    },
    {
      'mood': QuixoteMood.triumphant,
      'quote': 'Fortune smiles upon the steadfast! Another golden triumph inscribed into the timeless annals of the guild!',
      'badge': 'Scroll of Honor',
    },
    {
      'mood': QuixoteMood.proud,
      'quote': 'Thou hast proven that true nobility lies in the pursuit of stories! Cervantes himself would salute thee!',
      'badge': 'Master Bibliophile',
    },
    {
      'mood': QuixoteMood.triumphant,
      'quote': 'The stars burn bright over La Mancha tonight! Keep this heroic campfire alive, and no obstacle shall stand!',
      'badge': 'La Mancha Vanguard',
    },
  ];

  @override
  void initState() {
    super.initState();
    _quoteIndex = _random.nextInt(_quixotePraises.length);

    _fireController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Generate lively confetti with assorted shapes & speeds
    final colors = [
      AppColors.streakOrange,
      AppColors.antiqueGold,
      AppColors.vermillion,
      AppColors.gemCyan,
      AppColors.successGreen,
      const Color(0xFFF1C40F),
      const Color(0xFFE67E22),
      Colors.white,
    ];

    for (int i = 0; i < 55; i++) {
      _confetti.add(
        _ConfettiParticle(
          x: _random.nextDouble() * 340,
          y: _random.nextDouble() * 450,
          size: 4 + _random.nextDouble() * 8,
          color: colors[_random.nextInt(colors.length)],
          rotation: _random.nextDouble() * pi * 2,
          speed: 45 + _random.nextDouble() * 95,
          wobbleRate: 2 + _random.nextDouble() * 4,
          shape: _random.nextInt(3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fireController.dispose();
    _popController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final userName = state.profile.name;
    final praiseData = _quixotePraises[_quoteIndex];
    final praiseText = (praiseData['quote'] as String).replaceAll('{name}', userName);
    final badgeTitle = praiseData['badge'] as String;
    final mood = praiseData['mood'] as QuixoteMood;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Background Card with Warm Campfire Glow
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF28180A), Color(0xFF150D05)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.antiqueGold, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.streakOrange.withValues(alpha: 0.4),
                  blurRadius: 36,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.antiqueGold.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Animated Floating Praise Badge
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _popController,
                    curve: Curves.elasticOut,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.antiqueGold, Color(0xFFB8860B)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.antiqueGold.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.military_tech_rounded, color: Theme.of(context).colorScheme.primary, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          badgeTitle.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Dynamic Blazing Campfire Animation with Sparks
                SizedBox(
                  height: 120,
                  width: 180,
                  child: AnimatedBuilder(
                    animation: _fireController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _BlazingCampfirePainter(_fireController.value),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Streak Banner Pill
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _popController,
                    curve: const Interval(0.2, 1.0, curve: Curves.bounceOut),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.streakOrange, Color(0xFFD35400)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.streakOrange.withValues(alpha: 0.55),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 6),
                        Text(
                          widget.isRekindled ? 'CAMPFIRE REKINDLED' : 'STREAK EXTENDED',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Big Dynamic Streak Counter
                Text(
                  '${widget.streakDays} Day${widget.streakDays == 1 ? '' : 's'} of Literature',
                  textAlign: TextAlign.center,
                  style: AppTypography.displayMedium.copyWith(
                    color: const Color(0xFFFAF6EE),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: AppColors.streakOrange.withValues(alpha: 0.6),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  widget.isRekindled
                      ? 'The campfire roars anew, $userName! Read daily before 12:00 AM midnight to keep the flame alive.'
                      : 'Your daily commitment honors the guild! Keep this flame blazing before tomorrow midnight (12:00 AM).',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFFDFD7CA),
                    height: 1.35,
                    fontSize: 12,
                  ),
                ),

                // Bonus Gems Earned Tag
                if (widget.gemsEarned != null && widget.gemsEarned! > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gemCyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.gemCyan.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond_rounded, color: AppColors.gemCyan, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          '+${widget.gemsEarned} Gems Claimed',
                          style: AppTypography.labelSmall.copyWith(
                            color: const Color(0xFFD6EAF8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Dynamic Character Dialogue Box (Refreshes dynamically!)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF352010),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.antiqueGold.withValues(alpha: 0.55), width: 1.2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      QuixoteAvatar(size: 52, mood: mood),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Don Quixote de la Mancha',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.antiqueGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '"$praiseText"',
                              style: AppTypography.bodySmall.copyWith(
                                color: const Color(0xFFFFF7EA),
                                fontStyle: FontStyle.italic,
                                height: 1.35,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tactile Duolingo Action Button
                DuoButton(
                  text: 'Continue the Quest',
                  icon: Icons.arrow_forward_rounded,
                  variant: DuoButtonVariant.gold,
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onContinue();
                  },
                ),
              ],
            ),
          ),
        ),

          // Flowing Animated Confetti Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _burstController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _CelebrationConfettiPainter(
                      particles: _confetti,
                      progress: _burstController.value,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiParticle {
  double x;
  double y;
  final double size;
  final Color color;
  double rotation;
  final double speed;
  final double wobbleRate;
  final int shape; // 0 = rect, 1 = circle, 2 = diamond

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.rotation,
    required this.speed,
    this.wobbleRate = 3.0,
    this.shape = 0,
  });
}

class _CelebrationConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _CelebrationConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final currentY = (p.y + progress * p.speed * 4) % (size.height + 40) - 20;
      final wobble = sin(progress * 2 * pi * p.wobbleRate) * 8;
      final currentX = (p.x + wobble) % size.width;

      final paint = Paint()
        ..color = p.color.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(p.rotation + progress * 2 * pi);

      if (p.shape == 0) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          paint,
        );
      } else if (p.shape == 1) {
        canvas.drawCircle(Offset.zero, p.size * 0.45, paint);
      } else {
        final path = Path()
          ..moveTo(0, -p.size * 0.6)
          ..lineTo(p.size * 0.5, 0)
          ..lineTo(0, p.size * 0.6)
          ..lineTo(-p.size * 0.5, 0)
          ..close();
        canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationConfettiPainter oldDelegate) => true;
}

class _BlazingCampfirePainter extends CustomPainter {
  final double animValue;

  _BlazingCampfirePainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.72;

    // 1. Ambient Warm Glow
    final glowRadius = 55.0 + sin(animValue * pi * 2) * 8.0;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF9F1C).withValues(alpha: 0.45),
          const Color(0xFFE65100).withValues(alpha: 0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy - 18), radius: glowRadius));
    canvas.drawCircle(Offset(cx, cy - 18), glowRadius, glowPaint);

    // 2. Charred Fireplace Hearth Stones
    final stonePaint = Paint()..color = const Color(0xFF2C2219);
    for (int i = -3; i <= 3; i++) {
      final sx = cx + i * 16.0;
      final sy = cy + 14.0 + (i.abs() % 2) * 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(sx, sy), width: 18, height: 10),
          const Radius.circular(4),
        ),
        stonePaint,
      );
    }

    // 3. Crossed Wooden Logs
    final logPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final logHighlight = Paint()
      ..color = const Color(0xFF795548)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(cx - 36, cy + 8), Offset(cx + 36, cy + 2), logPaint);
    canvas.drawLine(Offset(cx - 32, cy + 6), Offset(cx + 32, cy), logHighlight);

    canvas.drawLine(Offset(cx + 34, cy + 9), Offset(cx - 34, cy + 1), logPaint);
    canvas.drawLine(Offset(cx + 30, cy + 7), Offset(cx - 30, cy - 1), logHighlight);

    // 4. Multi-Layered Licking Campfire Flames
    _drawFlameTongue(canvas, cx - 14, cy, 32, 54, animValue, const Color(0xFFE65100));
    _drawFlameTongue(canvas, cx + 14, cy, 32, 56, animValue + 0.35, const Color(0xFFF57C00));
    _drawFlameTongue(canvas, cx, cy - 2, 44, 76, animValue + 0.15, const Color(0xFFFF9800));
    _drawFlameTongue(canvas, cx - 4, cy - 4, 26, 48, animValue + 0.6, const Color(0xFFFFD54F));
    _drawFlameTongue(canvas, cx + 2, cy - 6, 16, 32, animValue + 0.8, const Color(0xFFFFF9C4));

    // 5. Rising Crackling Sparks
    final sparkPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 9; i++) {
      final sparkProgress = (animValue + (i / 9.0)) % 1.0;
      final sparkX = cx + sin((i * 1.7) + sparkProgress * pi * 4) * (18 + i * 3);
      final sparkY = (cy - 12) - (sparkProgress * 68);
      final sparkOpacity = (1.0 - sparkProgress).clamp(0.0, 1.0);
      final sparkRadius = (1.2 + (i % 3) * 0.8) * (1.0 - sparkProgress * 0.5);

      sparkPaint.color = Color.lerp(
        const Color(0xFFFFD54F),
        const Color(0xFFFF5722),
        sparkProgress,
      )!.withValues(alpha: sparkOpacity);

      canvas.drawCircle(Offset(sparkX, sparkY), sparkRadius, sparkPaint);
    }
  }

  void _drawFlameTongue(
    Canvas canvas,
    double x,
    double y,
    double width,
    double height,
    double phase,
    Color color,
  ) {
    final t = (phase % 1.0);
    final wave1 = sin(t * pi * 2) * 5.0;
    final wave2 = cos(t * pi * 2) * 4.0;
    final dynamicHeight = height + wave1;

    final path = Path();
    path.moveTo(x - width / 2, y);

    path.cubicTo(
      x - width / 2 + wave2,
      y - dynamicHeight * 0.5,
      x - width * 0.2,
      y - dynamicHeight * 0.8,
      x + wave1,
      y - dynamicHeight,
    );

    path.cubicTo(
      x + width * 0.2,
      y - dynamicHeight * 0.8,
      x + width / 2 + wave2,
      y - dynamicHeight * 0.5,
      x + width / 2,
      y,
    );

    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BlazingCampfirePainter oldDelegate) {
    return oldDelegate.animValue != animValue;
  }
}