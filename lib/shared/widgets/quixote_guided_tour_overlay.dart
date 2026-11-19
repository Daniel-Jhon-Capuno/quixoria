import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/sound_service.dart';
import 'duo_button.dart';
import 'quixote_mascot.dart';
import 'reward_celebration.dart';

enum ArrowDirection {
  up,
  down,
  left,
  right,
}

class QuixoteGuidedTourOverlay extends StatefulWidget {
  final VoidCallback onFinishTour;

  const QuixoteGuidedTourOverlay({super.key, required this.onFinishTour});

  @override
  State<QuixoteGuidedTourOverlay> createState() => _QuixoteGuidedTourOverlayState();
}

class _QuixoteGuidedTourOverlayState extends State<QuixoteGuidedTourOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _bobController;

  static const int _totalSteps = 8;

  @override
  void initState() {
    super.initState();
    SoundService.instance.play(Sfx.guide);
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _bobController.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.lightImpact();
    SoundService.instance.play(Sfx.tap);
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _finish();
    }
  }

  void _previous() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      SoundService.instance.play(Sfx.tap);
      setState(() => _currentStep--);
    }
  }

  void _finish() {
    HapticFeedback.heavyImpact();
    SoundService.instance.play(Sfx.reward);
    RewardCelebrationOverlay.openChest(
      context,
      gems: 100,
      hearts: 1,
    );
    widget.onFinishTour();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final topPadding = media.padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Semi-transparent Dimmed Backdrop with Tap protection
          Positioned.fill(
            child: GestureDetector(
              onTap: () {}, // absorb taps outside
              child: Container(
                color: Colors.black.withValues(alpha: 0.68),
              ),
            ),
          ),

          // Dynamic Step Content (Pointer Arrow + Don Quixote Dialogue Card)
          _buildStepLayer(size, topPadding, isDark),

          // Skip button on top right (rendered on top layer)
          if (_currentStep < _totalSteps - 1)
            Positioned(
              top: topPadding + 10,
              right: 16,
              child: SafeArea(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                  label: const Text(
                    'Skip Tour',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _finish,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepLayer(Size size, double topPadding, bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildStep1QuestTrail(size, topPadding, isDark);
      case 1:
        return _buildStep2CurrencyBar(size, topPadding, isDark);
      case 2:
        return _buildStep3DailyQuests(size, topPadding, isDark);
      case 3:
        return _buildStep4Library(size, topPadding, isDark);
      case 4:
        return _buildStep5Notes(size, topPadding, isDark);
      case 5:
        return _buildStep6Bazaar(size, topPadding, isDark);
      case 6:
        return _buildStep7SanctuarySettings(size, topPadding, isDark);
      case 7:
      default:
        return _buildStep8ReadyFinale(size, isDark);
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 1: The Winding Quest Trail
  // ---------------------------------------------------------------------------
  Widget _buildStep1QuestTrail(Size size, double topPadding, bool isDark) {
    final arrowX = size.width * 0.50;
    final arrowY = size.height * 0.44;

    return Stack(
      children: [
        // Arrow pointing down toward active level node
        Positioned(
          left: arrowX - 24,
          top: arrowY - 60,
          child: _AnimatedPointer(
            controller: _bobController,
            direction: ArrowDirection.down,
            label: 'START HERE',
          ),
        ),

        // Don Quixote Dialogue Box placed above
        Positioned(
          left: 20,
          right: 20,
          top: arrowY - 260,
          child: _buildDialogueBox(
            tag: 'STEP 1 OF 7 • THE CHIVALRIC TRAIL',
            title: 'Thy Winding Literary Odyssey',
            body:
                '“Behold thy sacred path! Follow this winding trail step by step. Every chapter begins with an engaging reading passage, followed by interactive recall and deductive challenges!”',
            mascotPose: MascotPose.greeting,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: Vitality & Coffers (Top Bar)
  // ---------------------------------------------------------------------------
  Widget _buildStep2CurrencyBar(Size size, double topPadding, bool isDark) {
    final arrowX = size.width * 0.52;
    final arrowY = topPadding + 62;

    return Stack(
      children: [
        // Arrow pointing UP toward Currency Bar
        Positioned(
          left: arrowX - 24,
          top: arrowY + 8,
          child: _AnimatedPointer(
            controller: _bobController,
            direction: ArrowDirection.up,
            label: 'ROYAL COFFERS',
          ),
        ),

        // Don Quixote Dialogue Box placed below
        Positioned(
          left: 20,
          right: 20,
          top: arrowY + 85,
          child: _buildDialogueBox(
            tag: 'STEP 2 OF 7 • VITALITY & GEMS',
            title: 'Streaks, Energy & Radiant Gems',
            body:
                '“At the crest of the realm lies thy vitality! The Flame tracks thy unbroken daily streak, Hearts fuel thy quests, and Radiant Gems unlock rare masterworks and realm themes in the Bazaar!”',
            mascotPose: MascotPose.encouraging,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: Daily Guild Dispatches
  // ---------------------------------------------------------------------------
  Widget _buildStep3DailyQuests(Size size, double topPadding, bool isDark) {
    final arrowX = size.width * 0.28;
    final arrowY = topPadding + 98;

    return Stack(
      children: [
        // Arrow pointing UP toward Daily Quests Pill
        Positioned(
          left: arrowX - 24,
          top: arrowY + 12,
          child: _AnimatedPointer(
            controller: _bobController,
            direction: ArrowDirection.up,
            label: 'DAILY DISPATCHES',
          ),
        ),

        // Don Quixote Dialogue Box placed below
        Positioned(
          left: 20,
          right: 20,
          top: arrowY + 90,
          child: _buildDialogueBox(
            tag: 'STEP 3 OF 7 • GUILD BOUNTIES',
            title: 'Daily Quests & Scholar Leagues',
            body:
                '“Check thy Guild Dispatches each day! Conquering short reading goals before the midnight bell awards bonus gems and elevates thy standing in the Weekly Scholar Leagues!”',
            mascotPose: MascotPose.idle,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 4: The Athenaeum (Library Tab)
  // ---------------------------------------------------------------------------
  Widget _buildStep4Library(Size size, double topPadding, bool isDark) {
    final arrowX = size.width * 0.30;
    final arrowY = size.height - 68;

    return Stack(
      children: [
        // Arrow pointing DOWN toward Library tab
        Positioned(
          left: (arrowX - 40).clamp(12.0, size.width - 95.0),
          top: arrowY - 60,
          child: _AnimatedPointer(
            controller: _bobController,
            direction: ArrowDirection.down,
            label: 'THE LIBRARY',
          ),
        ),

        // Don Quixote Dialogue Box placed above bottom bar
        Positioned(
          left: 20,
          right: 20,
          bottom: 130,
          child: _buildDialogueBox(
            tag: 'STEP 4 OF 7 • THE ATHENAEUM',
            title: 'The Great Library & Tomes',
            body:
                '“Enter the Athenaeum to explore the great classical canon! Switch thy active reading journey, browse timeless masterworks from Cervantes to Homer, or download offline to read under the stars!”',
            mascotPose: MascotPose.reading,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 5: The Scriptorium (Notes & Word Bank Tab)
  // ---------------------------------------------------------------------------
  Widget _buildStep5Notes(Size size, double topPadding, bool isDark) {
    final arrowX = size.width * 0.50;
    final arrowY = size.height - 68;

    return Stack(
      children: [
        // Arrow pointing DOWN toward Notes tab
        Positioned(
          left: (arrowX - 44).clamp(12.0, size.width - 95.0),
          top: arrowY - 60,
          child: _AnimatedPointer(
            controller: _bobController,
            direction: ArrowDirection.down,
            label: 'NOTES & WORDS',
          ),
        ),

        // Don Quixote Dialogue Box placed above bottom bar
        Positioned(
          left: 20,
          right: 20,
          bottom: 130,
          child: _buildDialogueBox(
            tag: 'STEP 5 OF 7 • THE SCRIPTORIUM',
            title: 'Thy Scriptorium & Word Bank',
            body:
                '“Record thy knightly epiphanies! Here reside thy saved chapter annotations, memorable quotes, and the Spaced Repetition (SRS) Word Bank to permanently master literary vocabulary!”',
            mascotPose: MascotPose.encouraging,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 6: The Royal Bazaar (Shop Tab)
  // ---------------------------------------------------------------------------
  Widget _buildStep6Bazaar(Size size, double topPadding, bool isDark) {
    final arrowX = size.width * 0.70;
    final arrowY = size.height - 68;

    return Stack(
      children: [
        // Arrow pointing DOWN toward Bazaar tab
        Positioned(
          left: (arrowX - 40).clamp(12.0, size.width - 95.0),
          top: arrowY - 60,
          child: _AnimatedPointer(
            controller: _bobController,
            direction: ArrowDirection.down,
            label: 'THE BAZAAR',
          ),
        ),

        // Don Quixote Dialogue Box placed above bottom bar
        Positioned(
          left: 20,
          right: 20,
          bottom: 130,
          child: _buildDialogueBox(
            tag: 'STEP 6 OF 7 • THE ROYAL BAZAAR',
            title: 'The Royal Bazaar & Treasures',
            body:
                '“Spend thy hard-won Radiant Gems here! Acquire legendary themes like The La Mancha, heroic outfits for thy companion Don Quixote, soothing reading ambiences, and streak shields!”',
            mascotPose: MascotPose.celebration,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 7: Sanctuary Tabs & Settings (Profile Tab)
  // ---------------------------------------------------------------------------
  Widget _buildStep7SanctuarySettings(Size size, double topPadding, bool isDark) {
    final arrowX = size.width * 0.90;
    final arrowY = size.height - 68;

    return Stack(
      children: [
        // Arrow pointing DOWN toward Settings / Profile bottom tab
        Positioned(
          left: (arrowX - 52).clamp(12.0, size.width - 105.0),
          top: arrowY - 60,
          child: _AnimatedPointer(
            controller: _bobController,
            direction: ArrowDirection.down,
            label: 'SETTINGS & PROFILE',
          ),
        ),

        // Don Quixote Dialogue Box placed above bottom bar
        Positioned(
          left: 20,
          right: 20,
          bottom: 130,
          child: _buildDialogueBox(
            tag: 'STEP 7 OF 7 • REALM SANCTUARY',
            title: 'Knightly Profile & Sanctuary',
            body:
                '“Calibrate thy reading preferences, adjust sound and haptic sensations, review thy reading stats and achievements, or manage thy knightly account enlistment!”',
            mascotPose: MascotPose.idle,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 8: Ready Finale Screen
  // ---------------------------------------------------------------------------
  Widget _buildStep8ReadyFinale(Size size, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B221E) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.antiqueGold, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.antiqueGold.withValues(alpha: 0.35),
                blurRadius: 36,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hero Don Quixote
              const QuixoteMascot(
                size: 96,
                poseOverride: MascotPose.celebration,
                showSpeechBubble: false,
                interactive: false,
              ),
              const SizedBox(height: 14),

              // Laurel badge
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
                      'KNIGHTHOOD INITIATION COMPLETE',
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
              const SizedBox(height: 14),

              Text(
                'Art Thou Ready for Adventure?',
                textAlign: TextAlign.center,
                style: AppTypography.displayMedium.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.antiqueGold,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                '“The windmills turn, the pages flutter, and a universe of classic wisdom awaits thee! Thy starting bounty of +100 Radiant Gems is bestowed upon thee.”',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 13,
                  height: 1.45,
                  color: isDark ? Colors.white70 : AppColors.inkDark.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 22),

              DuoButton(
                text: 'Begin My Literary Quest (+100 Gems)',
                icon: Icons.explore_rounded,
                variant: DuoButtonVariant.gold,
                onPressed: _finish,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dialogue Box Component with Step Indicators & Next Button
  // ---------------------------------------------------------------------------
  Widget _buildDialogueBox({
    required String tag,
    required String title,
    required String body,
    required MascotPose mascotPose,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2621) : const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.antiqueGold, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.antiqueGold.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Mascot Avatar & Tag
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.antiqueGold.withValues(alpha: 0.2),
                  border: Border.all(color: AppColors.antiqueGold, width: 1.4),
                ),
                child: const Center(
                  child: Icon(Icons.castle_rounded, color: AppColors.antiqueGold, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag,
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.antiqueGold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Speech text
          Text(
            body,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12.5,
              height: 1.45,
              color: isDark ? Colors.white.withValues(alpha: 0.85) : AppColors.inkDark.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16),

          // Footer: Step dots & Next Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dots
              Row(
                children: List.generate(7, (i) {
                  final active = i == _currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 5),
                    width: active ? 16 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: active ? AppColors.antiqueGold : Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),

              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentStep > 0) ...[
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _previous,
                      child: const Text('Back', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.antiqueGold,
                      foregroundColor: AppColors.inkDark,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.inkDark),
                    label: const Text(
                      'Next Tip',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _next,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated Pointing Arrow Widget
// ---------------------------------------------------------------------------

class _AnimatedPointer extends StatelessWidget {
  final AnimationController controller;
  final ArrowDirection direction;
  final String label;

  const _AnimatedPointer({
    required this.controller,
    required this.direction,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final bob = math.sin(controller.value * math.pi * 2) * 8.0;

        Offset translation;
        IconData icon;

        switch (direction) {
          case ArrowDirection.up:
            translation = Offset(0, -bob);
            icon = Icons.keyboard_double_arrow_up_rounded;
            break;
          case ArrowDirection.down:
            translation = Offset(0, bob);
            icon = Icons.keyboard_double_arrow_down_rounded;
            break;
          case ArrowDirection.left:
            translation = Offset(-bob, 0);
            icon = Icons.keyboard_double_arrow_left_rounded;
            break;
          case ArrowDirection.right:
            translation = Offset(bob, 0);
            icon = Icons.keyboard_double_arrow_right_rounded;
            break;
        }

        return Transform.translate(
          offset: translation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (direction == ArrowDirection.up) ...[
                Icon(icon, size: 30, color: AppColors.antiqueGold),
                const SizedBox(height: 2),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.antiqueGold,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.antiqueGold.withValues(alpha: 0.75),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: Color(0xFF121212),
                  ),
                ),
              ),
              if (direction == ArrowDirection.down) ...[
                const SizedBox(height: 2),
                Icon(icon, size: 30, color: AppColors.antiqueGold),
              ],
            ],
          ),
        );
      },
    );
  }
}
