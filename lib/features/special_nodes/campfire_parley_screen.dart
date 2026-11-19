import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';
import '../../data/special_nodes_data.dart';
import '../../models/literature.dart';
import '../../models/quest_level.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/reward_celebration.dart';

/// Full-screen interactive Campfire Parley experience featuring:
/// - Starlit animated campfire sky with flickering flames & rising embers
/// - Hand-crafted storybook character portrait tailored to the book's archetype
/// - Expressive mood shift when the player makes their choice
/// - Branching 3-choice moral dilemma with in-character reaction, literary insight,
///   and Gems + Leaderboard XP reward!
class CampfireParleyScreen extends StatefulWidget {
  final Literature literature;
  final QuestLevel level;

  const CampfireParleyScreen({
    super.key,
    required this.literature,
    required this.level,
  });

  @override
  State<CampfireParleyScreen> createState() => _CampfireParleyScreenState();
}

class _CampfireParleyScreenState extends State<CampfireParleyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fireController;
  late final CampfireParleyScenario _scenario;
  ParleyChoice? _selectedChoice;

  @override
  void initState() {
    super.initState();
    _scenario = SpecialNodesData.parleyForBook(widget.literature);
    _fireController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _fireController.dispose();
    super.dispose();
  }

  void _selectChoice(ParleyChoice choice) {
    if (_selectedChoice != null) return;
    HapticService.instance.celebration();
    SoundService.instance.play(Sfx.reward);
    setState(() {
      _selectedChoice = choice;
    });
  }

  void _claimAndReturn() {
    final choice = _selectedChoice;
    if (choice == null) return;
    final state = context.read<AppState>();
    state.completeQuestLevel(
      literatureId: widget.literature.id,
      levelId: widget.level.id,
      isPerfectScore: true,
    );
    if (state.isOnline) {
      state.addGems(choice.bonusGems);
      state.addLeaderboardXp(35);
    }
    Navigator.pop(context);
    RewardCelebrationOverlay.instance?.launchFlight(gems: choice.bonusGems);
  }

  @override
  Widget build(BuildContext context) {
    final chosen = _selectedChoice;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1120),
      body: Stack(
        children: [
          // 1. Animated Starlit Campfire Sky & Rising Embers
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fireController,
              builder: (_, __) => CustomPaint(
                painter: _CampfireSkyPainter(
                  t: _fireController.value,
                  accentColor: _scenario.accentColor,
                ),
              ),
            ),
          ),

          // 2. Foreground Interactive Story Content
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'CAMPFIRE PARLEY',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.antiqueGold,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                                fontSize: 10.5,
                              ),
                            ),
                            Text(
                              _scenario.campfireSetting,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                    child: Column(
                      children: [
                        // Illustrated Character Portrait with Firelit Halo + Campfire Flame
                        AnimatedBuilder(
                          animation: _fireController,
                          builder: (_, __) {
                            final glowPulse = 0.28 + 0.14 * math.sin(_fireController.value * 2 * math.pi);
                            return Column(
                              children: [
                                SizedBox(
                                  width: 158,
                                  height: 158,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Warm campfire halo
                                      Container(
                                        width: 156,
                                        height: 156,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              const Color(0xFFFF8F00).withValues(alpha: glowPulse),
                                              _scenario.accentColor.withValues(alpha: 0.12),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Ornate Golden Medallion Portrait
                                      Container(
                                        width: 132,
                                        height: 132,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              const Color(0xFF231F3A),
                                              _scenario.cloakColor.withValues(alpha: 0.85),
                                            ],
                                          ),
                                          border: Border.all(
                                            color: chosen != null
                                                ? chosen.traitColor
                                                : AppColors.antiqueGold,
                                            width: 3.0,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                                              blurRadius: 18,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: CustomPaint(
                                            painter: _CharacterPortraitPainter(
                                              archetype: _scenario.archetype,
                                              cloakColor: _scenario.cloakColor,
                                              accentColor: _scenario.accentColor,
                                              isPleased: chosen != null,
                                              flicker: _fireController.value,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Mini flickering campfire badge at bottom center
                                      Positioned(
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFFF6D00), Color(0xFFD4A338)],
                                            ),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.2),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.local_fire_department_rounded, size: 13, color: Colors.white),
                                              const SizedBox(width: 4),
                                              Text(
                                                chosen != null ? 'INSPIRED' : 'LISTENING',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // Character Name & Role
                        Text(
                          _scenario.characterName,
                          textAlign: TextAlign.center,
                          style: AppTypography.displaySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _scenario.characterRole,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.antiqueGold.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Character Speech Bubble (Opening Line OR In-Character Reaction)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: Container(
                            key: ValueKey(chosen?.traitTag ?? 'opening'),
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (chosen?.traitColor ?? AppColors.antiqueGold).withValues(alpha: 0.55),
                                width: 1.4,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (chosen != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: chosen.traitColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'TRAIT EARNED: ${chosen.traitTag.toUpperCase()}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                Text(
                                  chosen != null ? chosen.characterReaction : _scenario.openingLine,
                                  style: const TextStyle(
                                    color: Color(0xFFFAF6EE),
                                    fontSize: 15,
                                    height: 1.5,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        if (chosen == null) ...[
                          // Dilemma Prompt
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _scenario.dilemmaQuestion,
                              style: const TextStyle(
                                color: Color(0xFFF6DC8C),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 3 Tactile Choice Cards
                          for (final c in _scenario.choices)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => _selectChoice(c),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B1C30),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: c.traitColor.withValues(alpha: 0.6),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: c.traitColor.withValues(alpha: 0.18),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: c.traitColor.withValues(alpha: 0.22),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: c.traitColor.withValues(alpha: 0.6)),
                                        ),
                                        child: Text(
                                          c.traitTag,
                                          style: TextStyle(
                                            color: c.traitColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          c.label,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            height: 1.38,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(Icons.chevron_right_rounded, color: c.traitColor, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ] else ...[
                          // Literary Insight Card + Reward Banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.antiqueGold.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.antiqueGold.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.auto_stories_rounded, color: AppColors.antiqueGold, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'LITERARY INSIGHT',
                                        style: TextStyle(
                                          color: AppColors.antiqueGold,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        chosen.bonusInsight,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _rewardChip('+${chosen.bonusGems} Gems', Icons.diamond_rounded, AppColors.gemCyan),
                              const SizedBox(width: 10),
                              _rewardChip('+35 Leaderboard XP', Icons.emoji_events_rounded, AppColors.antiqueGold),
                            ],
                          ),
                          const SizedBox(height: 20),
                          DuoButton(
                            text: 'Claim Bounty & Continue',
                            icon: Icons.auto_awesome_rounded,
                            variant: DuoButtonVariant.gold,
                            onPressed: _claimAndReturn,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Paints a cozy starlit twilight sky with drifting golden campfire embers.
class _CampfireSkyPainter extends CustomPainter {
  final double t;
  final Color accentColor;

  _CampfireSkyPainter({required this.t, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0C1020), Color(0xFF1A162B), Color(0xFF2B1914)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    // Warm campfire ambient glow from bottom
    final fireGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 1.05),
        radius: 0.85,
        colors: [
          const Color(0xFFFF6D00).withValues(alpha: 0.24 + 0.06 * math.sin(t * 2 * math.pi)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fireGlow);

    // Twinkling stars in upper sky
    for (int i = 0; i < 24; i++) {
      final sx = size.width * (((i * 47 + 13) % 94) / 100.0 + 0.03);
      final sy = size.height * (((i * 29 + 7) % 45) / 100.0 + 0.03);
      final alpha = 0.25 + 0.65 * (0.5 + 0.5 * math.sin(t * 2 * math.pi + i));
      canvas.drawCircle(
        Offset(sx, sy),
        i % 4 == 0 ? 1.7 : 1.0,
        Paint()..color = const Color(0xFFFFF8E1).withValues(alpha: alpha),
      );
    }

    // Gently rising golden embers
    for (int i = 0; i < 12; i++) {
      final seedX = 0.15 + ((i * 61) % 70) / 100.0;
      final progress = (t + i * 0.13) % 1.0;
      final dx = size.width * seedX + math.sin(progress * math.pi * 3 + i) * 10;
      final dy = size.height * (0.96 - progress * 0.55);
      final fade = (1.0 - progress).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(dx, dy),
        1.8 + (i % 2) * 0.8,
        Paint()..color = const Color(0xFFFFB74D).withValues(alpha: 0.7 * fade),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CampfireSkyPainter oldDelegate) => oldDelegate.t != t;
}

/// Bespoke storybook bust portrait painter tailored to each literary archetype.
class _CharacterPortraitPainter extends CustomPainter {
  final CharacterArchetype archetype;
  final Color cloakColor;
  final Color accentColor;
  final bool isPleased;
  final double flicker;

  _CharacterPortraitPainter({
    required this.archetype,
    required this.cloakColor,
    required this.accentColor,
    required this.isPleased,
    required this.flicker,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.54;

    // 1. Shoulders & Cloak
    final cloakPaint = Paint()..color = cloakColor;
    final shoulders = Path()
      ..moveTo(cx - 56, size.height + 6)
      ..quadraticBezierTo(cx - 46, cy + 20, cx - 18, cy + 16)
      ..lineTo(cx + 18, cy + 16)
      ..quadraticBezierTo(cx + 46, cy + 20, cx + 56, size.height + 6)
      ..close();
    canvas.drawPath(shoulders, cloakPaint);

    // Cloak golden trim / brooch
    canvas.drawCircle(Offset(cx, cy + 26), 6, Paint()..color = accentColor);

    // 2. Neck & Warm Firelit Face
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy + 14), width: 16, height: 16),
      Paint()..color = const Color(0xFFF3C6A5),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 6), width: 46, height: 52),
      Paint()..color = const Color(0xFFFAD3B4),
    );

    // Subtle warm firelight cheek blush
    final blush = Paint()..color = const Color(0xFFE57373).withValues(alpha: 0.28);
    canvas.drawCircle(Offset(cx - 13, cy + 1), 5.5, blush);
    canvas.drawCircle(Offset(cx + 13, cy + 1), 5.5, blush);

    // 3. Expressive Eyes & Smile
    final eyePaint = Paint()..color = const Color(0xFF1F1D24);
    if (isPleased) {
      // Happy crescent eyes
      final happyEye = Paint()
        ..color = const Color(0xFF1F1D24)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCenter(center: Offset(cx - 9, cy - 7), width: 9, height: 7), math.pi, math.pi, false, happyEye);
      canvas.drawArc(Rect.fromCenter(center: Offset(cx + 9, cy - 7), width: 9, height: 7), math.pi, math.pi, false, happyEye);
    } else {
      canvas.drawCircle(Offset(cx - 9, cy - 8), 3.0, eyePaint);
      canvas.drawCircle(Offset(cx + 9, cy - 8), 3.0, eyePaint);
      // Eye catchlights
      canvas.drawCircle(Offset(cx - 8, cy - 9), 1.0, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(cx + 10, cy - 9), 1.0, Paint()..color = Colors.white);
    }

    // Smile
    final smilePaint = Paint()
      ..color = const Color(0xFF6B3E2E)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: isPleased ? 18 : 12, height: isPleased ? 12 : 6),
      0.15,
      math.pi - 0.3,
      false,
      smilePaint,
    );

    // 4. Archetype-Specific Headgear, Hair & Signature Details!
    switch (archetype) {
      case CharacterArchetype.knight:
        // Steel helmet dome + crimson plume + pointed silver goatee
        final helm = Path()
          ..moveTo(cx - 26, cy - 16)
          ..quadraticBezierTo(cx, cy - 48, cx + 26, cy - 16)
          ..close();
        canvas.drawPath(helm, Paint()..color = const Color(0xFFBDC3C7));
        canvas.drawLine(
          Offset(cx - 25, cy - 16),
          Offset(cx + 25, cy - 16),
          Paint()
            ..color = accentColor
            ..strokeWidth = 3.0,
        );
        // Crimson plume
        final plume = Path()
          ..moveTo(cx, cy - 34)
          ..quadraticBezierTo(cx + 18, cy - 48, cx + 24, cy - 28)
          ..quadraticBezierTo(cx + 10, cy - 30, cx, cy - 34)
          ..close();
        canvas.drawPath(plume, Paint()..color = const Color(0xFFC0392B));
        // Pointed goatee
        final beard = Path()
          ..moveTo(cx - 6, cy + 16)
          ..lineTo(cx, cy + 26)
          ..lineTo(cx + 6, cy + 16)
          ..close();
        canvas.drawPath(beard, Paint()..color = const Color(0xFFD5D8DC));
        break;

      case CharacterArchetype.gardenGirl:
        // Soft chestnut hair + Victorian bonnet + rose ribbon
        final hair = Path()
          ..moveTo(cx - 25, cy + 8)
          ..quadraticBezierTo(cx - 28, cy - 34, cx, cy - 34)
          ..quadraticBezierTo(cx + 28, cy - 34, cx + 25, cy + 8)
          ..quadraticBezierTo(cx + 22, cy - 16, cx, cy - 22)
          ..quadraticBezierTo(cx - 22, cy - 16, cx - 25, cy + 8)
          ..close();
        canvas.drawPath(hair, Paint()..color = const Color(0xFF6D4C41));
        // Bonnet brim + rose flower
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, cy - 18), width: 56, height: 34),
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = const Color(0xFFF5E6C8)
            ..strokeWidth = 6
            ..style = PaintingStyle.stroke,
        );
        canvas.drawCircle(Offset(cx + 18, cy - 26), 5.5, Paint()..color = const Color(0xFFE91E63));
        break;

      case CharacterArchetype.detective:
        // Iconic deerstalker cap + brim
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, cy - 16), width: 52, height: 36),
          math.pi,
          math.pi,
          true,
          Paint()..color = const Color(0xFF5D6D7E),
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy - 17), width: 62, height: 10),
          Paint()..color = const Color(0xFF34495E),
        );
        // Magnifying glass glint beside collar
        canvas.drawCircle(
          Offset(cx + 26, cy + 20),
          8,
          Paint()
            ..color = accentColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4,
        );
        break;

      case CharacterArchetype.mariner:
        // Sea-captain tricorne hat with gold trim
        final hat = Path()
          ..moveTo(cx - 32, cy - 16)
          ..quadraticBezierTo(cx, cy - 42, cx + 32, cy - 16)
          ..close();
        canvas.drawPath(hat, Paint()..color = const Color(0xFF154360));
        canvas.drawLine(
          Offset(cx - 30, cy - 16),
          Offset(cx + 30, cy - 16),
          Paint()
            ..color = accentColor
            ..strokeWidth = 3.0,
        );
        break;

      case CharacterArchetype.regencyLady:
        // Elegant Regency curls + pearl headband
        final curls = Paint()..color = const Color(0xFF4E342E);
        canvas.drawCircle(Offset(cx - 21, cy - 10), 10, curls);
        canvas.drawCircle(Offset(cx + 21, cy - 10), 10, curls);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy - 26), width: 44, height: 18), curls);
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, cy - 18), width: 44, height: 22),
          math.pi + 0.2,
          math.pi - 0.4,
          false,
          Paint()
            ..color = const Color(0xFFFFF8E1)
            ..strokeWidth = 2.6
            ..style = PaintingStyle.stroke,
        );
        break;

      case CharacterArchetype.gothicLord:
        // High dramatic upturned collar + swept dark hair
        final collar = Path()
          ..moveTo(cx - 34, cy + 20)
          ..lineTo(cx - 26, cy - 8)
          ..lineTo(cx - 14, cy + 16)
          ..close();
        final collarR = Path()
          ..moveTo(cx + 34, cy + 20)
          ..lineTo(cx + 26, cy - 8)
          ..lineTo(cx + 14, cy + 16)
          ..close();
        canvas.drawPath(collar, Paint()..color = const Color(0xFF210B2C));
        canvas.drawPath(collarR, Paint()..color = const Color(0xFF210B2C));
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, cy - 18), width: 48, height: 28),
          math.pi,
          math.pi,
          true,
          Paint()..color = const Color(0xFF1A1625),
        );
        break;

      case CharacterArchetype.woodland:
        // Cozy explorer cap + warm woodland scarf
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, cy - 17), width: 50, height: 30),
          math.pi,
          math.pi,
          true,
          Paint()..color = const Color(0xFF2E7D32),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 18), width: 42, height: 11), const Radius.circular(6)),
          Paint()..color = const Color(0xFFD95B30),
        );
        break;

      case CharacterArchetype.sage:
        // Flowing silver-brown scholar hair + golden laurel crown
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, cy - 17), width: 50, height: 30),
          math.pi,
          math.pi,
          true,
          Paint()..color = const Color(0xFF5D4037),
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, cy - 20), width: 48, height: 18),
          math.pi + 0.15,
          math.pi - 0.3,
          false,
          Paint()
            ..color = AppColors.antiqueGold
            ..strokeWidth = 3.2
            ..style = PaintingStyle.stroke,
        );
        break;
    }

    // Subtle animated firelight sheen across the lower portrait
    final sheenAlpha = 0.10 + 0.06 * math.sin(flicker * 2 * math.pi);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFFFF9800).withValues(alpha: sheenAlpha),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45)),
    );
  }

  @override
  bool shouldRepaint(covariant _CharacterPortraitPainter oldDelegate) =>
      oldDelegate.isPleased != isPleased || oldDelegate.flicker != flicker;
}
