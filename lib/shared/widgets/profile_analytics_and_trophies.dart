import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/state/app_state.dart';
import 'reward_celebration.dart';
import 'themed_card.dart';

/// Reading Analytics & 30-Day Activity Heatmap Card for the Profile screen.
class ReadingStatsHeatmapCard extends StatelessWidget {
  const ReadingStatsHeatmapCard({super.key});

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activity = state.profile.activityByDay;

    final today = DateTime.now();
    final last30Days = List<DateTime>.generate(
      30,
      (i) => DateTime(today.year, today.month, today.day).subtract(Duration(days: 29 - i)),
    );

    return ThemedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statTile(
                'Chapters',
                '${state.totalChaptersRead}',
                Icons.menu_book_rounded,
                AppColors.antiqueGold,
                theme,
              ),
              const SizedBox(width: 8),
              _statTile(
                'Accuracy',
                '${state.quizAccuracyPercent.round()}%',
                Icons.verified_rounded,
                AppColors.successGreen,
                theme,
              ),
              const SizedBox(width: 8),
              _statTile(
                'Words',
                '${state.masteredWordsCount}',
                Icons.spellcheck_rounded,
                AppColors.practiceBlue,
                theme,
              ),
              const SizedBox(width: 8),
              _statTile(
                'Books',
                '${state.profile.booksCompleted}',
                Icons.vpn_key_rounded,
                AppColors.streakOrange,
                theme,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '30-Day Streak Grid',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Less',
                    style: TextStyle(fontSize: 9.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                  ),
                  const SizedBox(width: 4),
                  for (final alpha in [0.12, 0.35, 0.65, 1.0])
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: alpha < 0.2
                            ? (isDark ? Colors.white12 : Colors.black12)
                            : theme.colorScheme.primary.withValues(alpha: alpha),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Text(
                    'More',
                    style: TextStyle(fontSize: 9.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
            ),
            itemCount: last30Days.length,
            itemBuilder: (context, idx) {
              final day = last30Days[idx];
              final count = activity[_dayKey(day)] ?? 0;
              final isToday = idx == last30Days.length - 1;

              Color cellColor;
              if (count == 0) {
                cellColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.07);
              } else if (count <= 2) {
                cellColor = theme.colorScheme.primary.withValues(alpha: 0.38);
              } else if (count <= 4) {
                cellColor = theme.colorScheme.primary.withValues(alpha: 0.70);
              } else {
                cellColor = theme.colorScheme.primary;
              }

              return Tooltip(
                message: '${day.month}/${day.day}: $count activities',
                child: Container(
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(5),
                    border: isToday
                        ? Border.all(color: AppColors.antiqueGold, width: 1.5)
                        : null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Unlockable Reading Achievements & Trophy Case with Claimable Gem Rewards.
class AchievementsTrophyCaseCard extends StatefulWidget {
  const AchievementsTrophyCaseCard({super.key});

  @override
  State<AchievementsTrophyCaseCard> createState() => _AchievementsTrophyCaseCardState();
}

class _AchievementsTrophyCaseCardState extends State<AchievementsTrophyCaseCard> {
  bool _showAll = false;
  String _filter = 'all'; // 'all', 'unlocked', 'locked'
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final allItems = state.achievements;
    final unclaimedCount = state.unclaimedAchievementsCount;

    final filtered = allItems.where((a) {
      if (_filter == 'unlocked' && !a.isUnlocked) return false;
      if (_filter == 'locked' && a.isUnlocked) return false;
      if (_search.trim().isNotEmpty) {
        final q = _search.trim().toLowerCase();
        return a.title.toLowerCase().contains(q) ||
            a.description.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    final visibleItems =
        (_showAll || _search.isNotEmpty || _filter != 'all')
            ? filtered
            : filtered.take(3).toList();

    return ThemedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Smart Search & Filter Strip
          TextField(
            key: const Key('achievements_search_input'),
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Search medals & achievements…',
              prefixIcon: Icon(Icons.search_rounded, size: 18, color: theme.colorScheme.primary),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final entry in [('all', 'All'), ('unlocked', 'Unlocked'), ('locked', 'Locked')])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(entry.$2, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    selected: _filter == entry.$1,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => setState(() => _filter = entry.$1),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (unclaimedCount > 0) ...[
            Row(
              children: [
                const Icon(Icons.military_tech_rounded, color: AppColors.antiqueGold, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$unclaimedCount ready to claim',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.antiqueGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          for (final ach in visibleItems)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ach.isUnlocked
                    ? ach.accentColor.withValues(alpha: 0.10)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ach.canClaim
                      ? AppColors.antiqueGold
                      : (ach.isUnlocked
                          ? ach.accentColor.withValues(alpha: 0.4)
                          : theme.dividerColor.withValues(alpha: 0.45)),
                  width: ach.canClaim ? 1.6 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ach.isUnlocked
                          ? ach.accentColor
                          : theme.colorScheme.onSurface.withValues(alpha: 0.14),
                    ),
                    child: Icon(
                      ach.icon,
                      size: 21,
                      color: ach.isUnlocked
                          ? Colors.white
                          : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ach.title,
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ach.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ach.progress,
                            minHeight: 5,
                            backgroundColor: theme.dividerColor.withValues(alpha: 0.35),
                            valueColor: AlwaysStoppedAnimation<Color>(ach.accentColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (ach.canClaim)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.antiqueGold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        final claimed = state.claimAchievement(ach.id);
                        if (claimed) {
                          RewardCelebrationOverlay.instance?.launchFlight(gems: ach.gemReward);
                        }
                      },
                      child: Text(
                        '+${ach.gemReward}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                    )
                  else if (ach.isClaimed)
                    const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 22)
                  else
                    Column(
                      children: [
                        Text(
                          '${ach.currentCount}/${ach.targetCount}',
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                        Text(
                          '+${ach.gemReward}💎',
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          if (filtered.length > 3 && _search.isEmpty && _filter == 'all')
            Center(
              child: TextButton.icon(
                icon: Icon(_showAll ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18),
                label: Text(_showAll ? 'Show Less' : 'View All ${filtered.length} Medals'),
                onPressed: () => setState(() => _showAll = !_showAll),
              ),
            ),
        ],
      ),
    );
  }
}
