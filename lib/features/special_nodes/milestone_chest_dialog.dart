import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/difficulty_quiz_engine.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';
import '../../models/literature.dart';
import '../../models/quest_level.dart';
import '../../shared/widgets/animated_reward_chest.dart';

/// Interactive Milestone Treasure Chest modal dialog on the Quest Map.
/// Tap the gleaming checkpoint chest to crack it open for bonus Gems,
/// +1 Energy Heart, and Leaderboard XP.
class MilestoneChestDialog extends StatefulWidget {
  final Literature literature;
  final QuestLevel level;

  const MilestoneChestDialog({
    super.key,
    required this.literature,
    required this.level,
  });

  static Future<void> show(
    BuildContext context, {
    required Literature literature,
    required QuestLevel level,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Milestone Chest',
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, _, _) => MilestoneChestDialog(
        literature: literature,
        level: level,
      ),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.86, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<MilestoneChestDialog> createState() => _MilestoneChestDialogState();
}

class _MilestoneChestDialogState extends State<MilestoneChestDialog> {
  bool _isOpened = false;
  late final bool _alreadyCompleted;

  @override
  void initState() {
    super.initState();
    _alreadyCompleted = widget.level.isCompleted;
  }

  QuizRewardOutcome get _outcome => QuizRewardOutcome(
        chestRarity: _alreadyCompleted ? ChestRarity.common : ChestRarity.rare,
        gemsEarned: _alreadyCompleted ? 15 : 45,
        leaderboardXpEarned: _alreadyCompleted ? 10 : 30,
        bonusHearts: 1,
        difficultyMultiplier: 1.0,
        difficultyLabel: 'Milestone Bounty',
      );

  void _handleOpen(Offset? _) {
    if (_isOpened) return;
    final state = context.read<AppState>();
    final outcome = _outcome;

    SoundService.instance.play(Sfx.reward);
    state.triggerHaptic();

    state.addGems(outcome.gemsEarned);
    state.addLeaderboardXp(outcome.leaderboardXpEarned);
    state.restoreEnergy(outcome.bonusHearts);
    state.completeQuestLevel(
      literatureId: widget.literature.id,
      levelId: widget.level.id,
      isPerfectScore: true,
    );

    setState(() => _isOpened = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1E28) : const Color(0xFFFAF8F4);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E222B);
    final textMuted = isDark ? Colors.white70 : const Color(0xFF5D6576);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width.clamp(300.0, 410.0) - 32,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFD4A338).withValues(alpha: 0.55),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4A338).withValues(alpha: 0.25),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4A338).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFD4A338).withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.inventory_2_rounded,
                          size: 14,
                          color: Color(0xFFD4A338),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'MILESTONE TREASURE',
                          style: AppTypography.labelSmall.copyWith(
                            color: const Color(0xFFD4A338),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: textMuted),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.level.title,
                textAlign: TextAlign.center,
                style: AppTypography.displaySmall.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isOpened
                    ? 'You unlocked the ${widget.literature.title} checkpoint cache!'
                    : 'A gilded traveler’s cache awaits along your journey.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: textMuted),
              ),
              const SizedBox(height: 16),
              AnimatedRewardChest(
                outcome: _outcome,
                isOpened: _isOpened,
                onOpenChest: _handleOpen,
              ),
              const SizedBox(height: 16),
              if (_isOpened)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.explore_rounded, size: 18),
                    label: const Text('RETURN TO MAP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.antiqueGold,
                      foregroundColor: const Color(0xFF1F1600),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
