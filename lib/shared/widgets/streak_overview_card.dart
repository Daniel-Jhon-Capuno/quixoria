import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/streak_service.dart';
import '../../core/state/app_state.dart';
import 'duo_button.dart';
import 'quixoria_dialog.dart';
import 'reward_celebration.dart';

/// Rich, motivating Weekly Streak, Daily Goal Progress, Freeze & Milestones Card.
/// 100% automatic — never asks the user to tap/claim their streak; reflects real
/// reading & quiz activity, local calendar days, freezes, repair window, and records.
class StreakOverviewCard extends StatelessWidget {
  const StreakOverviewCard({super.key});

  static Future<void> showSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF17191E) : const Color(0xFFFAF8F4);
        final border = theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.45);
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: border, width: 2.0),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const StreakOverviewCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final border = theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.45);
    final textPrimary = isDark ? const Color(0xFFFDFBF7) : const Color(0xFF1A1C19);
    final textMuted = isDark ? const Color(0xFFC5CEC8) : const Color(0xFF5A625C);

    final status = state.streakStatus;
    final week = state.weeklyStreakCalendar;
    final canRepair = state.canRepairStreak;
    final goalPct = profile.dailyGoalMinutes > 0
        ? (profile.dailyMinutesReadToday / profile.dailyGoalMinutes).clamp(0.0, 1.0)
        : 0.0;
    final isActiveToday = status == StreakStatus.activeToday;

    final Color flameColor = switch (status) {
      StreakStatus.activeToday => AppColors.streakOrange,
      StreakStatus.atRiskToday => const Color(0xFFF59E0B),
      StreakStatus.broken => Colors.blueGrey,
      StreakStatus.fresh => AppColors.antiqueGold,
    };

    final String statusHeadline = switch (status) {
      StreakStatus.activeToday => 'Flame Secured Today!',
      StreakStatus.atRiskToday => 'Flame At Risk Today',
      StreakStatus.broken => 'Campfire Went Cold',
      StreakStatus.fresh => 'Start Your Reading Flame',
    };

    final String statusSubtitle = switch (status) {
      StreakStatus.activeToday => 'Your streak extended automatically. See you tomorrow!',
      StreakStatus.atRiskToday => 'Finish a chapter, quiz, or daily reading goal before midnight.',
      StreakStatus.broken => 'Complete a chapter today to rekindle, or repair your streak below.',
      StreakStatus.fresh => 'Finish a level or hit your daily reading goal to begin Day 1.',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: flameColor.withValues(alpha: isActiveToday ? 0.65 : 0.4),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: flameColor.withValues(alpha: isActiveToday ? 0.22 : 0.12),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Dynamic Flame Status Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      flameColor,
                      Color.alphaBlend(Colors.black.withValues(alpha: 0.25), flameColor),
                    ],
                  ),
                  boxShadow: isActiveToday
                      ? [
                          BoxShadow(
                            color: flameColor.withValues(alpha: 0.45),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  status == StreakStatus.atRiskToday
                      ? Icons.local_fire_department_outlined
                      : Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${profile.streakDays} Day${profile.streakDays == 1 ? '' : 's'}',
                          style: AppTypography.titleLarge.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: flameColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              statusHeadline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: flameColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusSubtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Live Daily Goal Progress Bar (fills automatically with activity)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border.withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isActiveToday ? Icons.check_circle_rounded : Icons.schedule_rounded,
                      size: 15,
                      color: isActiveToday ? AppColors.successGreen : flameColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isActiveToday ? 'Daily Goal Reached ✓' : 'Today’s Reading Goal',
                        style: AppTypography.labelMedium.copyWith(
                          color: isActiveToday ? AppColors.successGreen : textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${profile.dailyMinutesReadToday}/${profile.dailyGoalMinutes} min',
                      style: AppTypography.labelSmall.copyWith(
                        color: textMuted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: isActiveToday ? 1.0 : goalPct,
                    minHeight: 7,
                    backgroundColor: border.withValues(alpha: 0.45),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isActiveToday ? AppColors.successGreen : flameColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. Weekly Calendar (Mon–Sun: Completed / Frozen / Missed / Today / Future)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: week.map((d) => _buildWeekDayPill(d, textPrimary, textMuted, border)).toList(),
          ),

          const SizedBox(height: 14),

          // 4. Records & Freeze Stats Row
          Row(
            children: [
              _statBox('Longest', '${profile.longestStreak}d', Icons.emoji_events_rounded, AppColors.antiqueGold, isDark, textPrimary, textMuted),
              const SizedBox(width: 8),
              _statBox('Total Days', '${profile.totalDaysRead}', Icons.calendar_month_rounded, theme.colorScheme.primary, isDark, textPrimary, textMuted),
              const SizedBox(width: 8),
              _statBox('Freezes', '${profile.streakFreezes}/3', Icons.ac_unit_rounded, AppColors.gemCyan, isDark, textPrimary, textMuted),
            ],
          ),

          // 5. Fair 48-Hour Streak Repair Option (only when broken within 48h)
          if (canRepair) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.streakOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.streakOrange.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Repair Your ${profile.repairableStreakDays}-Day Streak?',
                    style: AppTypography.titleSmall.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Within 48 hours of a break, you can restore your streak for ${StreakService.repairGemCost} Gems.',
                    style: AppTypography.bodySmall.copyWith(color: textMuted, fontSize: 11.5),
                  ),
                  const SizedBox(height: 10),
                  DuoButton(
                    text: profile.gems >= StreakService.repairGemCost
                        ? 'Repair Streak (${StreakService.repairGemCost} 💎)'
                        : 'Need ${StreakService.repairGemCost - profile.gems} more gems',
                    icon: Icons.build_rounded,
                    variant: profile.gems >= StreakService.repairGemCost
                        ? DuoButtonVariant.gold
                        : DuoButtonVariant.outline,
                    height: 40,
                    onPressed: profile.gems >= StreakService.repairGemCost
                        ? () async {
                            final ok = await showPurchaseConfirmDialog(
                              context: context,
                              itemName: 'Streak Repair (${profile.repairableStreakDays} Days)',
                              priceLabel: '${StreakService.repairGemCost} Gems',
                              icon: Icons.local_fire_department_rounded,
                              description: 'Restore your ${profile.repairableStreakDays}-day reading streak immediately.',
                              accentColor: AppColors.streakOrange,
                            );
                            if (!ok || !context.mounted) return;
                            if (state.repairBrokenStreakWithGems()) {
                              RewardCelebrationOverlay.showCelebration(
                                context,
                                celebrationType: CelebrationType.gems,
                              );
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // 6. Automatic Milestones Strip (3, 7, 14, 30, 100 days)
          Text(
            'AUTOMATIC STREAK MILESTONES',
            style: AppTypography.labelSmall.copyWith(
              color: textMuted,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: StreakService.milestones.map((m) {
                final unlocked = profile.claimedStreakMilestones.contains(m.days) ||
                    profile.longestStreak >= m.days;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: unlocked
                        ? AppColors.antiqueGold.withValues(alpha: 0.18)
                        : border.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: unlocked ? AppColors.antiqueGold : border.withValues(alpha: 0.5),
                      width: unlocked ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${m.days}d',
                        style: TextStyle(
                          color: unlocked ? AppColors.antiqueGold : textMuted,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        unlocked ? '✓ Earned' : '+${m.gemReward}💎',
                        style: TextStyle(
                          color: unlocked ? AppColors.successGreen : textMuted,
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDayPill(
    WeeklyStreakDay day,
    Color textPrimary,
    Color textMuted,
    Color border,
  ) {
    Color circleBg;
    Color circleBorder;
    Widget iconWidget;

    switch (day.state) {
      case WeeklyDayState.completed:
        circleBg = AppColors.streakOrange;
        circleBorder = AppColors.streakOrange;
        iconWidget = const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 17);
        break;
      case WeeklyDayState.frozen:
        circleBg = AppColors.gemCyan;
        circleBorder = AppColors.gemCyan;
        iconWidget = const Icon(Icons.ac_unit_rounded, color: Colors.white, size: 16);
        break;
      case WeeklyDayState.missed:
        circleBg = border.withValues(alpha: 0.2);
        circleBorder = border.withValues(alpha: 0.5);
        iconWidget = Icon(Icons.close_rounded, color: textMuted.withValues(alpha: 0.6), size: 15);
        break;
      case WeeklyDayState.todayPending:
        circleBg = const Color(0xFFF59E0B).withValues(alpha: 0.14);
        circleBorder = const Color(0xFFF59E0B);
        iconWidget = const Icon(Icons.local_fire_department_outlined, color: Color(0xFFF59E0B), size: 16);
        break;
      case WeeklyDayState.future:
        circleBg = Colors.transparent;
        circleBorder = border.withValues(alpha: 0.4);
        iconWidget = const SizedBox.shrink();
        break;
    }

    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: circleBg,
            shape: BoxShape.circle,
            border: Border.all(
              color: circleBorder,
              width: day.isToday ? 2.2 : 1.5,
            ),
          ),
          child: Center(child: iconWidget),
        ),
        const SizedBox(height: 5),
        Text(
          day.shortLabel,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: day.isToday ? FontWeight.w900 : FontWeight.w700,
            color: day.isToday ? textPrimary : textMuted,
          ),
        ),
      ],
    );
  }

  Widget _statBox(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
