import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';

class _SeasonalMilestone {
  final String id;
  final String title;
  final int current;
  final int target;
  final int gemReward;
  final IconData icon;

  const _SeasonalMilestone({
    required this.id,
    required this.title,
    required this.current,
    required this.target,
    required this.gemReward,
    required this.icon,
  });

  bool get isComplete => current >= target;
  double get progress => (current / target).clamp(0.0, 1.0);
}

/// Monthly / Seasonal Reading Event with a 5-step claimable reward track.
class SeasonalEventSheet extends StatefulWidget {
  const SeasonalEventSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SeasonalEventSheet(),
    );
  }

  static ({String id, String name, IconData icon, Color color, int daysLeft})
      currentSeasonMeta() {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysLeft = (endOfMonth.day - now.day).clamp(1, 31);
    final m = now.month;
    if (m >= 3 && m <= 5) {
      return (
        id: 'spring_${now.year}',
        name: 'Sakura Poetry Sprint',
        icon: Icons.local_florist_rounded,
        color: const Color(0xFFDB2777),
        daysLeft: daysLeft,
      );
    }
    if (m >= 6 && m <= 8) {
      return (
        id: 'summer_${now.year}',
        name: 'Sunlit Odyssey Event',
        icon: Icons.wb_sunny_rounded,
        color: const Color(0xFFEA580C),
        daysLeft: daysLeft,
      );
    }
    if (m >= 9 && m <= 11) {
      return (
        id: 'autumn_${now.year}',
        name: 'Midnight Lantern Event',
        icon: Icons.nights_stay_rounded,
        color: const Color(0xFF7C3AED),
        daysLeft: daysLeft,
      );
    }
    return (
      id: 'winter_${now.year}',
      name: 'Frostfire Chronicle',
      icon: Icons.ac_unit_rounded,
      color: const Color(0xFF0284C7),
      daysLeft: daysLeft,
    );
  }

  @override
  State<SeasonalEventSheet> createState() => _SeasonalEventSheetState();
}

class _SeasonalEventSheetState extends State<SeasonalEventSheet> {
  final Set<String> _claimedIds = {};

  @override
  void initState() {
    super.initState();
    _loadClaimed();
  }

  Future<void> _loadClaimed() async {
    final meta = SeasonalEventSheet.currentSeasonMeta();
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('seasonal_claimed_${meta.id}') ?? const [];
    if (!mounted) return;
    setState(() => _claimedIds.addAll(saved));
  }

  Future<void> _claim(AppState state, _SeasonalMilestone m) async {
    if (!m.isComplete || _claimedIds.contains(m.id)) return;
    final meta = SeasonalEventSheet.currentSeasonMeta();
    SoundService.instance.play(Sfx.reward);
    HapticService.instance.light();
    state.addGems(m.gemReward);
    state.addLeaderboardXp(30);
    setState(() => _claimedIds.add(m.id));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('seasonal_claimed_${meta.id}', _claimedIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final meta = SeasonalEventSheet.currentSeasonMeta();
    final sheetBg = isDark ? const Color(0xFF17191E) : const Color(0xFFFAF8F4);
    final cardBg = isDark ? const Color(0xFF21242B) : Colors.white;
    final border = theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.45);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1C19);
    final textMuted = isDark ? Colors.white70 : const Color(0xFF5A625C);

    final milestones = [
      _SeasonalMilestone(
        id: 'step_1',
        title: 'Read 1 Chapter',
        current: state.totalChaptersRead,
        target: 1,
        gemReward: 25,
        icon: Icons.auto_stories_rounded,
      ),
      _SeasonalMilestone(
        id: 'step_2',
        title: 'Complete 2 Levels',
        current: state.profile.levelsCompleted,
        target: 2,
        gemReward: 35,
        icon: Icons.flag_rounded,
      ),
      _SeasonalMilestone(
        id: 'step_3',
        title: 'Reach 3-Day Streak',
        current: state.profile.streakDays,
        target: 3,
        gemReward: 45,
        icon: Icons.local_fire_department_rounded,
      ),
      _SeasonalMilestone(
        id: 'step_4',
        title: 'Save 2 Words or Quotes',
        current: state.vocabDeck.length + state.quoteCards.length,
        target: 2,
        gemReward: 50,
        icon: Icons.format_quote_rounded,
      ),
      _SeasonalMilestone(
        id: 'step_5',
        title: 'Earn 150 Weekly XP',
        current: state.profile.weeklyXp,
        target: 150,
        gemReward: 100,
        icon: Icons.workspace_premium_rounded,
      ),
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: meta.color.withValues(alpha: 0.55), width: 2.0),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Seasonal Event Header Banner
            Container(
              margin: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    meta.color,
                    Color.alphaBlend(Colors.black.withValues(alpha: 0.25), meta.color),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(meta.icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meta.name,
                          style: AppTypography.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${meta.daysLeft}d left • 5 Event Rewards',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),

            // 5-Step Event Track
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                itemCount: milestones.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, idx) {
                  final m = milestones[idx];
                  final claimed = _claimedIds.contains(m.id);
                  final canClaim = m.isComplete && !claimed;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: canClaim ? AppColors.antiqueGold : border,
                        width: canClaim ? 2.2 : 1.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: (m.isComplete ? meta.color : border).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            m.icon,
                            color: m.isComplete ? meta.color : textMuted,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.title,
                                style: AppTypography.titleSmall.copyWith(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: m.progress,
                                  minHeight: 7,
                                  backgroundColor: border.withValues(alpha: 0.35),
                                  valueColor: AlwaysStoppedAnimation<Color>(meta.color),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (claimed)
                          const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 24)
                        else if (canClaim)
                          ElevatedButton(
                            onPressed: () => _claim(state, m),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.antiqueGold,
                              foregroundColor: const Color(0xFF1F1600),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('+${m.gemReward}💎'),
                          )
                        else
                          Text(
                            '${m.current}/${m.target}',
                            style: AppTypography.labelSmall.copyWith(
                              color: textMuted,
                              fontWeight: FontWeight.w800,
                            ),
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
  }
}
