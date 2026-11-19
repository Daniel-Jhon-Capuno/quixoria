import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/state/app_state.dart';
import '../../models/literature.dart';
import '../../models/quest_level.dart';
import 'duo_button.dart';
import 'offline_warning_dialog.dart';

/// Authentic Duolingo-style Level Preview Card.
/// Opens when any level node on the winding path is tapped, displaying the
/// level's title, chapter context, learning objective, gem rewards, and a chunky 3D START button.
class DuoLevelPreviewSheet extends StatelessWidget {
  final Literature literature;
  final QuestLevel level;
  final VoidCallback onStart;

  const DuoLevelPreviewSheet({
    super.key,
    required this.literature,
    required this.level,
    required this.onStart,
  });

  static void show(
    BuildContext context, {
    required Literature literature,
    required QuestLevel level,
    required VoidCallback onStart,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DuoLevelPreviewSheet(
        literature: literature,
        level: level,
        onStart: () {
          Navigator.pop(ctx);
          onStart();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color badgeColor;
    IconData badgeIcon;

    switch (level.type) {
      case LevelType.read:
        badgeColor = theme.colorScheme.primary;
        badgeIcon = Icons.auto_stories_rounded;
        break;
      case LevelType.recall:
        badgeColor = AppColors.antiqueGold;
        badgeIcon = Icons.psychology_rounded;
        break;
      case LevelType.practice:
        badgeColor = AppColors.practiceBlue;
        badgeIcon = Icons.fitness_center_rounded;
        break;
      case LevelType.analysis:
        badgeColor = const Color(0xFF8E24AA);
        badgeIcon = Icons.visibility_rounded;
        break;
      case LevelType.finalTest:
        badgeColor = AppColors.vermillion;
        badgeIcon = Icons.military_tech_rounded;
        break;
      case LevelType.treasureChest:
        badgeColor = const Color(0xFFD4A338);
        badgeIcon = Icons.inventory_2_rounded;
        break;
      case LevelType.lightningDuel:
        badgeColor = const Color(0xFF0EA5E9);
        badgeIcon = Icons.bolt_rounded;
        break;
      case LevelType.campfireParley:
        badgeColor = const Color(0xFFEA580C);
        badgeIcon = Icons.local_fire_department_rounded;
        break;
      case LevelType.quoteShrine:
        badgeColor = const Color(0xFF8B5CF6);
        badgeIcon = Icons.format_quote_rounded;
        break;
      case LevelType.wordMatchBlitz:
        badgeColor = const Color(0xFF0D9488);
        badgeIcon = Icons.extension_rounded;
        break;
      case LevelType.zoneGatekeeper:
        badgeColor = const Color(0xFFE11D48);
        badgeIcon = Icons.fort_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: AppColors.antiqueGold.withValues(alpha: 0.6),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle pill
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header Row: Section Unit & Reward Gem Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: isDark ? 0.35 : 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 14, color: badgeColor),
                    const SizedBox(width: 5),
                    Text(
                      'UNIT ${(level.chapterIndex) + 1} • LEVEL ${level.levelNumber}',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark ? const Color(0xFFF5EFE6) : badgeColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              // Gem Reward Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gemCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gemCyan.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.diamond_rounded, size: 14, color: AppColors.gemCyan),
                    const SizedBox(width: 4),
                    Text(
                      '+${level.gemsReward} GEMS',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.gemCyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Level Title
          Text(
            level.title,
            style: AppTypography.displaySmall.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),

          // Literature & Chapter Context
          Text(
            '${literature.title} • Chapter ${(level.chapterIndex) + 1}',
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 12),

          // Descriptive Goal
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.explore_outlined,
                  size: 20,
                  color: AppColors.antiqueGold,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.description,
                        style: AppTypography.bodySmall.copyWith(
                          height: 1.45,
                          fontSize: 12.5,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school_rounded, size: 12, color: badgeColor),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Literacy Focus: ${level.literacyPurpose}',
                                style: AppTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFF5EFE6) : badgeColor,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Duolingo-style Chunky 3D Action Button
          Builder(
            builder: (ctx) {
              final appState = Provider.of<AppState>(ctx, listen: true);
              final isOffline = !appState.isOnline;
              final isQuiz = level.type != LevelType.read && !level.isSpecialNode;

              if (level.isLocked) {
                return DuoButton(
                  text: 'Locked • Conquer Level ${level.levelNumber - 1} First',
                  icon: Icons.lock_outline_rounded,
                  variant: DuoButtonVariant.outline,
                  height: 52,
                  onPressed: () {},
                );
              } else if (isOffline && isQuiz) {
                return Column(
                  children: [
                    DuoButton(
                      text: 'Quiz Locked (Wi-Fi Required)',
                      icon: Icons.wifi_off_rounded,
                      variant: DuoButtonVariant.outline,
                      height: 52,
                      onPressed: () {
                        Navigator.pop(ctx);
                        OfflineWarningDialog.show(context);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reading chapters are available offline, but quizzes require realm Wi-Fi.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                        color: AppColors.streakOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              } else if (level.isCompleted) {
                return DuoButton(
                  text: 'Practice Again (+5 Gems)',
                  icon: Icons.replay_rounded,
                  variant: DuoButtonVariant.gold,
                  height: 52,
                  onPressed: onStart,
                );
              } else {
                String ctaText;
                IconData ctaIcon;
                switch (level.type) {
                  case LevelType.read:
                    ctaText = 'START READING';
                    ctaIcon = Icons.auto_stories_rounded;
                    break;
                  case LevelType.treasureChest:
                    ctaText = 'OPEN TREASURE CHEST';
                    ctaIcon = Icons.inventory_2_rounded;
                    break;
                  case LevelType.lightningDuel:
                    ctaText = 'ENTER LIGHTNING DUEL';
                    ctaIcon = Icons.bolt_rounded;
                    break;
                  case LevelType.campfireParley:
                    ctaText = 'JOIN CAMPFIRE PARLEY';
                    ctaIcon = Icons.local_fire_department_rounded;
                    break;
                  case LevelType.quoteShrine:
                    ctaText = 'RESTORE QUOTE SHRINE';
                    ctaIcon = Icons.format_quote_rounded;
                    break;
                  case LevelType.wordMatchBlitz:
                    ctaText = 'START WORD BLITZ';
                    ctaIcon = Icons.extension_rounded;
                    break;
                  case LevelType.zoneGatekeeper:
                    ctaText = 'CHALLENGE GATEKEEPER';
                    ctaIcon = Icons.fort_rounded;
                    break;
                  default:
                    ctaText = 'START QUEST (+${level.gemsReward} GEMS)';
                    ctaIcon = Icons.play_arrow_rounded;
                    break;
                }
                return DuoButton(
                  text: ctaText,
                  icon: ctaIcon,
                  variant: DuoButtonVariant.primary,
                  height: 52,
                  onPressed: onStart,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
