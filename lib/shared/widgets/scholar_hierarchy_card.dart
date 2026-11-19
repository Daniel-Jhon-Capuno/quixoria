import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/haptic_service.dart';
import '../../core/state/app_state.dart';

class ScholarRankTier {
  final int level;
  final String roman;
  final String title;
  final String motto;
  final int minXp;
  final IconData icon;
  final Color color;

  const ScholarRankTier({
    required this.level,
    required this.roman,
    required this.title,
    required this.motto,
    required this.minXp,
    required this.icon,
    required this.color,
  });
}

/// 8-Tier Literary Scholar Hierarchy for the Profile Tab.
class ScholarHierarchy {
  static const List<ScholarRankTier> tiers = [
    ScholarRankTier(
      level: 1,
      roman: 'I',
      title: 'Novice Page',
      motto: 'First steps across the threshold of classic literature.',
      minXp: 0,
      icon: Icons.menu_book_rounded,
      color: Color(0xFF78909C),
    ),
    ScholarRankTier(
      level: 2,
      roman: 'II',
      title: 'Wandering Squire',
      motto: 'Carrying lantern and quill along winding story roads.',
      minXp: 150,
      icon: Icons.explore_rounded,
      color: Color(0xFF2E7D32),
    ),
    ScholarRankTier(
      level: 3,
      roman: 'III',
      title: 'Ink Apprentice',
      motto: 'Gathering words, quotes, and wisdom from distant realms.',
      minXp: 400,
      icon: Icons.edit_note_rounded,
      color: Color(0xFF0284C7),
    ),
    ScholarRankTier(
      level: 4,
      roman: 'IV',
      title: 'Guild Chronicler',
      motto: 'Trusted steward of chapters, parleys, and reflections.',
      minXp: 800,
      icon: Icons.history_edu_rounded,
      color: Color(0xFF7C3AED),
    ),
    ScholarRankTier(
      level: 5,
      roman: 'V',
      title: 'Keeper of Lore',
      motto: 'Commanding deep mastery of themes and vocabulary.',
      minXp: 1400,
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFDB2777),
    ),
    ScholarRankTier(
      level: 6,
      roman: 'VI',
      title: 'Knight-Errant',
      motto: 'Undaunted champion of trials, duels, and gatekeepers.',
      minXp: 2200,
      icon: Icons.shield_rounded,
      color: Color(0xFFEA580C),
    ),
    ScholarRankTier(
      level: 7,
      roman: 'VII',
      title: 'Grand Archivist',
      motto: 'Curator of entire libraries and unbroken reading flames.',
      minXp: 3500,
      icon: Icons.account_balance_rounded,
      color: Color(0xFFC28E1C),
    ),
    ScholarRankTier(
      level: 8,
      roman: 'VIII',
      title: 'Sovereign of Letters',
      motto: 'Crowned luminary of Quixoria’s highest literary order.',
      minXp: 5000,
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFFE11D48),
    ),
  ];

  /// Computes a holistic Scholar Prestige XP from all reading, quiz, streak,
  /// quote card, note, and lexicon activity.
  static int computeScholarXp(AppState state) {
    final p = state.profile;
    return p.weeklyXp +
        (p.levelsCompleted * 65) +
        (p.booksCompleted * 250) +
        (p.streakDays * 25) +
        (p.notesSaved * 15) +
        (state.quoteCards.length * 20) +
        (state.vocabDeck.length * 10);
  }

  static ScholarRankTier currentTierForXp(int xp) {
    ScholarRankTier current = tiers.first;
    for (final tier in tiers) {
      if (xp >= tier.minXp) {
        current = tier;
      }
    }
    return current;
  }

  static ScholarRankTier? nextTierForXp(int xp) {
    for (final tier in tiers) {
      if (xp < tier.minXp) return tier;
    }
    return null;
  }
}

/// Duolingo-style crisp bordered Scholar Hierarchy Card with live progress bar
/// and tap-to-open Full Hierarchy Ladder sheet.
class ScholarHierarchyCard extends StatelessWidget {
  const ScholarHierarchyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final textPrimary = isDark ? const Color(0xFFFDFBF7) : const Color(0xFF1A1C19);
    final textMuted = isDark ? const Color(0xFFBFC8C2) : const Color(0xFF5A625C);

    final xp = ScholarHierarchy.computeScholarXp(state);
    final current = ScholarHierarchy.currentTierForXp(xp);
    final next = ScholarHierarchy.nextTierForXp(xp);
    final themeAccent = state.activeThemePreset.effectivePrimary(isDarkMode: isDark);
    final badgeAccent = state.activeThemePreset.accent;

    final double progress;
    final String progressLabel;
    if (next == null) {
      progress = 1.0;
      progressLabel = 'MAX RANK ATTAINED • $xp XP';
    } else {
      final span = (next.minXp - current.minXp).clamp(1, 999999);
      progress = ((xp - current.minXp) / span).clamp(0.0, 1.0);
      final remaining = next.minXp - xp;
      progressLabel = '$remaining XP to ${next.title}';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(themeAccent.withValues(alpha: isDark ? 0.18 : 0.10), cardBg),
            cardBg,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: themeAccent.withValues(alpha: isDark ? 0.6 : 0.48),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: themeAccent.withValues(alpha: isDark ? 0.34 : 0.24),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
          BoxShadow(
            color: themeAccent.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            HapticService.instance.light();
            _showHierarchyLadderSheet(context, xp, current);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // Rank Emblem Crest (theme-connected)
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            themeAccent,
                            Color.alphaBlend(Colors.black.withValues(alpha: 0.25), themeAccent),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: badgeAccent.withValues(alpha: 0.7),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: themeAccent.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(current.icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: themeAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'TIER ${current.roman} OF VIII',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: themeAccent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$xp XP',
                                style: AppTypography.labelMedium.copyWith(
                                  color: badgeAccent,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            current.title,
                            style: AppTypography.titleLarge.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Segmented XP Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.25),
                    valueColor: AlwaysStoppedAnimation<Color>(themeAccent),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        progressLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Hierarchy',
                          style: AppTypography.labelSmall.copyWith(
                            color: themeAccent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, size: 16, color: themeAccent),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHierarchyLadderSheet(
    BuildContext context,
    int xp,
    ScholarRankTier current,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF16191D) : const Color(0xFFFAF8F4);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1C19);
    final textMuted = isDark ? Colors.white70 : const Color(0xFF5A625C);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.82,
          ),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: AppColors.antiqueGold.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 14, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.antiqueGold.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.military_tech_rounded,
                          color: AppColors.antiqueGold,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scholar Hierarchy',
                              style: AppTypography.titleLarge.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '$xp XP',
                              style: AppTypography.bodySmall.copyWith(color: textMuted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: Icon(Icons.close_rounded, color: textMuted),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.35)),
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                    itemCount: ScholarHierarchy.tiers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, idx) {
                      // Display highest rank at the top like a true hierarchy!
                      final tier = ScholarHierarchy.tiers[ScholarHierarchy.tiers.length - 1 - idx];
                      final isUnlocked = xp >= tier.minXp;
                      final isCurrent = tier.level == current.level;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? tier.color.withValues(alpha: isDark ? 0.22 : 0.12)
                              : (isDark
                                  ? Colors.white.withValues(alpha: isUnlocked ? 0.06 : 0.03)
                                  : Colors.white.withValues(alpha: isUnlocked ? 0.95 : 0.55)),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isCurrent
                                ? tier.color
                                : (isUnlocked
                                    ? tier.color.withValues(alpha: 0.35)
                                    : theme.dividerColor.withValues(alpha: 0.35)),
                            width: isCurrent ? 2.0 : 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isUnlocked
                                    ? tier.color
                                    : theme.dividerColor.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                isUnlocked ? tier.icon : Icons.lock_outline_rounded,
                                color: isUnlocked ? Colors.white : textMuted,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Tier ${tier.roman} • ${tier.title}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.titleSmall.copyWith(
                                            color: isUnlocked ? textPrimary : textMuted,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      if (isCurrent) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: tier.color,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'CURRENT',
                                            style: AppTypography.labelSmall.copyWith(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${tier.minXp} XP',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isUnlocked ? tier.color : textMuted,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Icon(
                                  isUnlocked
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 16,
                                  color: isUnlocked ? AppColors.successGreen : textMuted.withValues(alpha: 0.4),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
