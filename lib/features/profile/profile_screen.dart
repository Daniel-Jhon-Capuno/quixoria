import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/ambience_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/community_service.dart';
import '../../core/services/crash_reporter.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';
import '../../models/user_profile.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/follow_action_helper.dart';
import '../../shared/widgets/framed_mascot_avatar.dart';
import '../../shared/widgets/guide_dialog.dart';
import '../../shared/widgets/loading_dialog.dart';
import '../../shared/widgets/notification_center_sheet.dart';
import '../../shared/widgets/profile_analytics_and_trophies.dart';
import '../../shared/widgets/profile_banner_painter.dart';
import '../../shared/widgets/profile_style_sheet.dart';
import '../../shared/widgets/profile_trophy_shelf.dart';
import '../../shared/widgets/scholar_hierarchy_card.dart';
import '../../shared/widgets/quixote_avatar.dart';
import '../../shared/widgets/reading_buddies_card.dart';
import '../../shared/widgets/reward_celebration.dart';
import '../../shared/widgets/share_card_sheet.dart';
import '../../shared/widgets/streak_overview_card.dart';
import '../../shared/widgets/sun_moon_toggle.dart';
import '../../shared/widgets/themed_card.dart';
import '../../shared/widgets/offline_warning_dialog.dart';
import '../../shared/widgets/whats_new_sheet.dart';
import '../events/seasonal_event_sheet.dart';
import '../reader/ambience_soundscape_sheet.dart';
import '../special_nodes/mistake_dojo_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const ProfileScreen({super.key, this.onNavigateTab});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    final theme = Theme.of(context);
    final isDark = state.isDarkMode || theme.brightness == Brightness.dark || theme.scaffoldBackgroundColor.computeLuminance() < 0.38;
    final textColor = isDark ? const Color(0xFFFDFBF7) : const Color(0xFF1A1C19);
    final subtitleColor = isDark ? const Color(0xFFC5CEC8) : const Color(0xFF5A625C);

    final primary = theme.colorScheme.primary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final subtleBorder = theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.45);
    final scholarXp = ScholarHierarchy.computeScholarXp(state);
    final currentTier = ScholarHierarchy.currentTierForXp(scholarXp);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Profile',
          style: AppTypography.displaySmall.copyWith(
            color: textColor,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          // Animated Sun / Moon Quick Theme Mode Toggle
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: SunMoonToggleButton(
              size: 21,
              padding: EdgeInsets.all(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'Share Profile Card',
              child: InkWell(
                key: const Key('profile_share_card_button'),
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  HapticService.instance.light();
                  ShareCardSheet.showProfileCard(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: subtleBorder, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: subtleBorder.withValues(alpha: 0.55),
                        offset: const Offset(0, 2.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.ios_share_rounded,
                    color: primary,
                    size: 21,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Tooltip(
              message: 'Settings',
              child: InkWell(
                key: const Key('profile_settings_button'),
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  HapticService.instance.light();
                  _openSettingsPage(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: subtleBorder, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: subtleBorder.withValues(alpha: 0.55),
                        offset: const Offset(0, 2.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    color: primary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Dimensional Duolingo-Style Hero Identity Card
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [const Color(0xFF23262E), const Color(0xFF1A1C22)]
                        : [Colors.white, const Color(0xFFF7F4EC)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: currentTier.color.withValues(alpha: isDark ? 0.55 : 0.4),
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: currentTier.color.withValues(alpha: isDark ? 0.35 : 0.22),
                      offset: const Offset(0, 4.5),
                      blurRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Rich Illustrated Scenic Banner (Customizable via Profile Style -> Banners!)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 110,
                      child: Stack(
                        children: [
                          ProfileBannerBackground(
                            bannerId: profile.equippedBannerId,
                            height: 110,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.42),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.38),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(currentTier.icon, size: 13, color: const Color(0xFFFFE066)),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Tier ${currentTier.roman} • ${currentTier.title}',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Foreground identity content with elevated glowing avatar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 48, 18, 20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF23262E) : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: currentTier.color.withValues(alpha: 0.42),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: FramedMascotAvatar(
                              frame: state.equippedFrame,
                              size: 88,
                              showMascot: true,
                              avatarIconId: profile.equippedAvatarIconId,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            profile.name,
                            textAlign: TextAlign.center,
                            style: AppTypography.displaySmall.copyWith(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            profile.email,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              color: subtitleColor,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      state.equippedTitle.badgeColor,
                                      Color.alphaBlend(
                                        Colors.black.withValues(alpha: 0.22),
                                        state.equippedTitle.badgeColor,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: state.equippedTitle.badgeColor.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(state.equippedTitle.icon, size: 14, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text(
                                      profile.readerRank,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (profile.isPremium)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFD15C), Color(0xFFD4A338)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.stars_rounded, size: 14, color: Color(0xFF1F1600)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'CABALLERO PASS',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: const Color(0xFF1F1600),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (profile.hasEarnedTop1Percent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFE066), Color(0xFFFFB703), Color(0xFFF59E0B)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFB703).withValues(alpha: 0.45),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.workspace_premium_rounded,
                                          size: 14, color: Color(0xFF1F1600)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'TOP 1% CHAMPION',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: const Color(0xFF1F1600),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Clickable Following / Followers counts (opens Followers & Following sheet)
                          ListenableBuilder(
                            listenable: CommunityService.instance,
                            builder: (context, _) {
                              final followingCount = CommunityService.instance.following.length;
                              final followersCount = CommunityService.instance.followers.length;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.035),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: subtleBorder.withValues(alpha: 0.7),
                                    width: 1.4,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          HapticService.instance.light();
                                          _showFollowsModalSheet(context, initialTab: 0);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Column(
                                            children: [
                                              Text(
                                                '$followingCount',
                                                style: AppTypography.titleMedium.copyWith(
                                                  color: primary,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              Text(
                                                'Following',
                                                style: AppTypography.labelSmall.copyWith(
                                                  color: subtitleColor,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 1.2,
                                      height: 28,
                                      color: subtleBorder.withValues(alpha: 0.7),
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          HapticService.instance.light();
                                          _showFollowsModalSheet(context, initialTab: 1);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Column(
                                            children: [
                                              Text(
                                                '$followersCount',
                                                style: AppTypography.titleMedium.copyWith(
                                                  color: primary,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              Text(
                                                'Followers',
                                                style: AppTypography.labelSmall.copyWith(
                                                  color: subtitleColor,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DuoButton(
                                  text: 'Edit',
                                  icon: Icons.edit_rounded,
                                  variant: DuoButtonVariant.outline,
                                  height: 48,
                                  onPressed: () => _openEditProfileSheet(context, state),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DuoButton(
                                  text: 'Style',
                                  icon: Icons.checkroom_rounded,
                                  variant: DuoButtonVariant.gold,
                                  height: 48,
                                  onPressed: () {
                                    HapticService.instance.light();
                                    ProfileStyleSheet.show(context);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 2. Scholar Hierarchy & Rank Ladder
              _buildProfileSectionHeader(
                title: 'Scholar Hierarchy',
                trailing: '8 Ranks',
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
              const SizedBox(height: 10),
              const ScholarHierarchyCard(),

              const SizedBox(height: 14),

              // Quick Action Row: Seasonal Event & Mistake Dojo (theme-connected)
              Row(
                children: [
                  Expanded(
                    child: _buildQuickFeatureTile(
                      key: const Key('profile_seasonal_event_btn'),
                      icon: SeasonalEventSheet.currentSeasonMeta().icon,
                      color: Color.lerp(primary, state.activeThemePreset.accent, 0.38) ?? primary,
                      title: 'Seasonal Event',
                      subtitle: '${SeasonalEventSheet.currentSeasonMeta().daysLeft}d left',
                      cardBg: cardBg,
                      borderColor: subtleBorder,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      onTap: () {
                        HapticService.instance.light();
                        SeasonalEventSheet.show(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickFeatureTile(
                      key: const Key('profile_mistake_dojo_btn'),
                      icon: Icons.fitness_center_rounded,
                      color: primary,
                      title: 'Mistake Dojo',
                      subtitle: 'Quick review',
                      cardBg: cardBg,
                      borderColor: subtleBorder,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      onTap: () {
                        HapticService.instance.light();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const MistakeDojoScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // 3. Duolingo-Style Overview Stats (Crisp 2x2 Grid + Secondary Strip)
              _buildProfileSectionHeader(
                title: 'Overview',
                trailing: '${profile.dailyGoalMinutes}m daily goal',
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildDuoOverviewCard(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: AppColors.streakOrange,
                      value: '${profile.streakDays}',
                      label: 'Day streak',
                      cardBg: cardBg,
                      borderColor: subtleBorder,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDuoOverviewCard(
                      icon: Icons.bolt_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      value: '${profile.weeklyXp}',
                      label: 'Weekly XP',
                      cardBg: cardBg,
                      borderColor: subtleBorder,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildDuoOverviewCard(
                      icon: Icons.diamond_rounded,
                      iconColor: AppColors.gemCyan,
                      value: '${profile.gems}',
                      label: 'Gems vault',
                      cardBg: cardBg,
                      borderColor: subtleBorder,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDuoOverviewCard(
                      icon: Icons.auto_stories_rounded,
                      iconColor: primary,
                      value: '${profile.booksCompleted}',
                      label: 'Books',
                      cardBg: cardBg,
                      borderColor: subtleBorder,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Secondary Segmented Metrics Strip
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: subtleBorder, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: subtleBorder.withValues(alpha: 0.5),
                      offset: const Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildCompactMetric(
                      value: '${profile.answerStreak}',
                      label: 'Perfect',
                      color: state.activeThemePreset.successColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                    ),
                    _buildMetricDivider(subtleBorder),
                    _buildCompactMetric(
                      value: '${profile.levelsCompleted}',
                      label: 'Levels',
                      color: AppColors.antiqueGold,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                    ),
                    _buildMetricDivider(subtleBorder),
                    _buildCompactMetric(
                      value: '${profile.notesSaved}',
                      label: 'Notes',
                      color: primary,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                    ),
                    _buildMetricDivider(subtleBorder),
                    _buildCompactMetric(
                      value: '${profile.dailyMinutesReadToday}m',
                      label: 'Today',
                      color: AppColors.streakOrange,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 3.5 Automatic Weekly Streak & Milestones Card
              _buildProfileSectionHeader(
                title: 'Reading Streak',
                trailing: 'Best: ${profile.longestStreak}d',
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
              const SizedBox(height: 10),
              const StreakOverviewCard(),

              const SizedBox(height: 16),

              // 3b. Reading Buddies (Shared Friend Streaks + 1-Tap Nudge)
              const ReadingBuddiesCard(),

              const SizedBox(height: 16),

              // 3c. Pinned Trophy Showcase Shelf (Up to 3 Pinned Badges)
              const ProfileTrophyShelfCard(),

              const SizedBox(height: 22),

              // 4. Activity Heatmap
              _buildProfileSectionHeader(
                title: 'Activity',
                trailing: '30 days',
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
              const SizedBox(height: 10),
              const ReadingStatsHeatmapCard(),

              const SizedBox(height: 22),

              // 5. Achievements & Medals
              _buildProfileSectionHeader(
                title: 'Achievements',
                trailing: '${state.achievements.where((a) => a.isUnlocked).length}/${state.achievements.length}',
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
              const SizedBox(height: 10),
              const AchievementsTrophyCaseCard(),

              const SizedBox(height: 22),

              // 6. Books Progress
              _buildProfileSectionHeader(
                title: 'Books',
                trailing: '${state.catalog.where((b) => b.isOwned).length} owned',
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
              const SizedBox(height: 10),
              _buildBookMasteryShelf(
                state: state,
                cardBg: cardBg,
                borderColor: subtleBorder,
                primary: primary,
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFeatureTile({
    Key? key,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
    required VoidCallback onTap,
  }) {
    final deeper = Color.alphaBlend(Colors.black.withValues(alpha: 0.28), color);
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, deeper],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: Color.alphaBlend(Colors.black.withValues(alpha: 0.45), color),
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSectionHeader({
    required String title,
    required String trailing,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const Spacer(),
          Text(
            trailing,
            style: AppTypography.labelSmall.copyWith(
              color: subtitleColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuoOverviewCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(iconColor.withValues(alpha: 0.11), cardBg),
            cardBg,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: iconColor.withValues(alpha: 0.38), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.24),
            offset: const Offset(0, 3.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iconColor,
                  Color.alphaBlend(Colors.black.withValues(alpha: 0.22), iconColor),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: subtitleColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetric({
    required String value,
    required String label,
    required Color color,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: subtitleColor,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricDivider(Color color) {
    return Container(width: 1, height: 26, color: color);
  }

  Widget _buildBookMasteryShelf({
    required AppState state,
    required Color cardBg,
    required Color borderColor,
    required Color primary,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final owned = state.catalog.where((b) => b.isOwned).take(4).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.5),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < owned.length; i++) ...[
            if (i > 0) Divider(height: 18, color: borderColor.withValues(alpha: 0.6)),
            Builder(
              builder: (_) {
                final book = owned[i];
                final completed = book.questLevels.where((l) => l.isCompleted).length;
                final total = book.questLevels.length;
                final pct = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu_book_rounded, size: 16, color: primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSmall.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '$completed/$total',
                          style: AppTypography.labelSmall.copyWith(
                            color: primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 7,
                        backgroundColor: borderColor.withValues(alpha: 0.4),
                        valueColor: AlwaysStoppedAnimation<Color>(primary),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _openSettingsPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (settingsCtx) {
          return Consumer<AppState>(
            builder: (ctx, state, _) {
              final theme = Theme.of(ctx);
              final isDark = state.isDarkMode ||
                  theme.brightness == Brightness.dark ||
                  theme.scaffoldBackgroundColor.computeLuminance() < 0.38;
              final textColor = isDark ? const Color(0xFFFDFBF7) : const Color(0xFF1A1C19);
              final subtitleColor = isDark ? const Color(0xFFC5CEC8) : const Color(0xFF5A625C);
              final profile = state.profile;

              return Scaffold(
                backgroundColor: theme.scaffoldBackgroundColor,
                appBar: AppBar(
                  backgroundColor: theme.scaffoldBackgroundColor,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                  title: Text(
                    'Settings',
                    style: AppTypography.displaySmall.copyWith(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  actions: const [
                    Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: SunMoonToggleButton(
                        size: 20,
                        padding: EdgeInsets.all(9),
                      ),
                    ),
                  ],
                ),
                body: SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (profile.email.toLowerCase().contains('guest.scholar')) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.streakOrange.withValues(alpha: isDark ? 0.18 : 0.12),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: AppColors.streakOrange.withValues(alpha: 0.65),
                                width: 2.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: AppColors.streakOrange, size: 22),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Guest Account Warning',
                                        style: AppTypography.titleSmall.copyWith(
                                          color: textColor,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Guest accounts are deleted permanently if you uninstall the app. Sign in with a real account to save your progress in the cloud.',
                                  style: AppTypography.bodySmall.copyWith(color: subtitleColor),
                                ),
                                const SizedBox(height: 12),
                                DuoButton(
                                  text: 'Sign In / Create Real Account',
                                  icon: Icons.verified_user_rounded,
                                  variant: DuoButtonVariant.primary,
                                  height: 46,
                                  onPressed: () => _showSignOutWarningDialog(ctx, state),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Categorized Settings & Customizations
                        _buildSettingsCategories(ctx, theme, state, profile),
                        const SizedBox(height: 18),

                        // Live Phone Reminders & Test Pop-Up Card
                        ThemedCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.16),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.notifications_active_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Phone Pop-Up Reminders',
                                          style: AppTypography.titleSmall.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: textColor,
                                          ),
                                        ),
                                        Text(
                                          '7:00 AM • 1:00 PM • 9:30 PM + daily nudges (${NotificationService().resolvedTimeZoneName})',
                                          style: AppTypography.bodySmall.copyWith(
                                            fontSize: 11.5,
                                            color: subtitleColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Refresh Phone Reminder Schedule',
                                    icon: Icon(Icons.sync_rounded, color: theme.colorScheme.primary, size: 20),
                                    onPressed: () async {
                                      await NotificationService().requestPermissions();
                                      await NotificationService().scheduleDailyStreakReminders(
                                        userName: profile.name,
                                        streakDays: profile.streakDays,
                                        activeBook: state.activeLiterature.title,
                                      );
                                      final count = await NotificationService().pendingNotificationCount();
                                      if (!ctx.mounted) return;
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text('Phone reminders active! $count alerts scheduled in local time.'),
                                          backgroundColor: AppColors.successGreen,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              DuoButton(
                                text: 'Test Phone Pop-Up (5s)',
                                icon: Icons.notifications_active_outlined,
                                variant: DuoButtonVariant.primary,
                                height: 42,
                                onPressed: () async {
                                  final granted = await NotificationService().scheduleTestNotificationIn(
                                    delay: const Duration(seconds: 5),
                                    userName: profile.name,
                                    activeBook: state.activeLiterature.title,
                                  );
                                  if (!ctx.mounted) return;
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        granted
                                            ? 'Pop-up scheduled! Minimize or lock your phone — it will arrive in 5 seconds.'
                                            : 'Please allow Quixoria notifications in your phone Settings, then tap Test again.',
                                      ),
                                      backgroundColor: granted ? AppColors.successGreen : AppColors.streakOrange,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Cloud Backup & Restore Card
                        ThemedCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.cloud_done_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Cloud Backup & Restore',
                                          style: AppTypography.labelLarge.copyWith(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          (!AuthService.instance.isAuthenticated || AuthService.instance.accountKey == 'guest')
                                              ? 'Guest mode is device-only. Sign in to save Caballero Pass, cosmetics, gems & streak to the cloud.'
                                              : 'Caballero Pass, cosmetics, books, themes, gems & streak auto-sync to your cloud account.',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: subtitleColor,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (AuthService.instance.isAuthenticated && AuthService.instance.accountKey != 'guest') ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DuoButton(
                                        text: 'Backup Now',
                                        icon: Icons.cloud_upload_rounded,
                                        variant: DuoButtonVariant.primary,
                                        height: 40,
                                        onPressed: () async {
                                          final ok = await state.flushCloudSync();
                                          if (!ctx.mounted) return;
                                          ScaffoldMessenger.of(ctx).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                ok
                                                    ? 'Cloud backup saved! Your Caballero Pass, purchases, gems & streak are safe.'
                                                    : 'Could not reach cloud right now. Your progress is still saved on this device.',
                                              ),
                                              backgroundColor: ok ? AppColors.successGreen : AppColors.streakOrange,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: DuoButton(
                                        text: 'Restore Save',
                                        icon: Icons.cloud_download_rounded,
                                        variant: DuoButtonVariant.outline,
                                        height: 40,
                                        onPressed: () async {
                                          final restored = await state.pullCloudProgress();
                                          if (!ctx.mounted) return;
                                          ScaffoldMessenger.of(ctx).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                restored
                                                    ? 'Cloud save restored! Caballero Pass, items, gems & streak are synced.'
                                                    : 'No newer cloud backup found for this account yet.',
                                              ),
                                              backgroundColor: restored ? AppColors.successGreen : AppColors.streakOrange,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSettingsCategories(BuildContext context, ThemeData theme, AppState state, UserProfile profile) {
    final themeAccent = state.activeThemePreset.effectivePrimary(isDarkMode: state.isDarkMode);
    return _buildCardSection(
      title: 'Preferences',
      theme: theme,
      children: [
        _buildMenuTile(
          icon: Icons.touch_app_rounded,
          iconColor: themeAccent,
          title: 'Interaction',
          subtitle: 'Reader & companion',
          badgeText: state.isReaderMode ? 'Reader' : null,
          onTap: () => _openInteractionMenu(context),
        ),
        Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
        _buildMenuTile(
          icon: Icons.volume_up_rounded,
          iconColor: themeAccent,
          title: 'Sounds and Vibrations',
          subtitle: 'Audio, music & haptics',
          badgeText: (state.soundEffectsEnabled && state.musicEnabled) ? 'On' : null,
          onTap: () => _openSoundsMenu(context),
        ),
        Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
        _buildMenuTile(
          icon: Icons.palette_rounded,
          iconColor: themeAccent,
          title: 'Appearance',
          subtitle: state.activeThemePreset.name,
          badgeText: state.isDarkMode ? 'Dark' : 'Light',
          onTap: () => _openAppearanceMenu(context),
        ),
        Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
        _buildMenuTile(
          icon: Icons.text_fields_rounded,
          iconColor: themeAccent,
          title: 'Fonts and Styles',
          subtitle: 'Typography & readability',
          badgeText: state.isDyslexicFont ? 'Lexend' : 'Serif',
          onTap: () => _openFontsMenu(context),
        ),
        Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
        _buildMenuTile(
          icon: Icons.person_rounded,
          iconColor: themeAccent,
          title: 'Profiles',
          subtitle: '${profile.dailyGoalMinutes}m goal • ${profile.difficulty}',
          onTap: () => _openProfilesMenu(context),
        ),
        Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
        _buildMenuTile(
          icon: Icons.more_horiz_rounded,
          iconColor: themeAccent,
          title: 'And Other Things',
          subtitle: 'Alerts, creed & reset',
          onTap: () => _openOtherThingsMenu(context),
        ),
        Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
        _buildMenuTile(
          icon: Icons.auto_stories_rounded,
          iconColor: themeAccent,
          title: 'About Quixoria',
          subtitle: 'Features & roadmap',
          badgeText: 'v2.0',
          onTap: () => _openAboutQuixoriaMenu(context),
        ),
        Divider(height: 1, indent: 56, color: theme.dividerColor.withValues(alpha: 0.3)),
        _buildMenuTile(
          icon: Icons.auto_awesome_rounded,
          iconColor: themeAccent,
          title: 'What\'s New',
          subtitle: 'Latest update highlights & bug fixes',
          badgeText: 'NEW',
          onTap: () => WhatsNewSheet.show(context, markSeenOnClose: true),
        ),
        Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
        _buildMenuTile(
          icon: Icons.logout_rounded,
          iconColor: AppColors.energyRed,
          title: 'Sign Out / Log Out',
          subtitle: 'Switch or exit account',
          onTap: () => _showSignOutWarningDialog(context, state),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withValues(alpha: 0.42), width: 1.4),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (badgeText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: iconColor.withOpacity(0.3), width: 0.8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11.5,
              color: theme.colorScheme.onSurface.withOpacity(0.68),
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          onTap: () {
            HapticService.instance.light();
            onTap();
          },
        );
      },
    );
  }

  Future<void> _showFluidSettingsMenu({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Widget> Function(BuildContext sheetContext, AppState state) childrenBuilder,
  }) {
    HapticService.instance.selection();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (sheetContext) {
        return Consumer<AppState>(
          builder: (context, state, _) {
            final theme = Theme.of(context);
            final liveAccent = state.activeThemePreset.effectivePrimary(isDarkMode: state.isDarkMode);
            final sheetAccent = iconColor == AppColors.energyRed ? iconColor : liveAccent;

            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0.92, end: 1.0),
              builder: (animContext, scale, child) {
                return Transform.scale(
                  scale: scale,
                  alignment: Alignment.bottomCenter,
                  child: child,
                );
              },
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
                  ),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border.all(
                      color: sheetAccent.withValues(alpha: 0.50),
                      width: 1.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 36,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Smooth drag pill
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 8),
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: sheetAccent.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 280),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: sheetAccent.withValues(alpha: 0.16),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: sheetAccent.withValues(alpha: 0.42), width: 1.4),
                                ),
                                child: Icon(icon, color: sheetAccent, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: AppTypography.titleMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    Text(
                                      subtitle,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.65),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: theme.dividerColor.withOpacity(0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.close_rounded, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.8)),
                                ),
                                onPressed: () => Navigator.of(sheetContext).pop(),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, thickness: 1, color: theme.dividerColor.withOpacity(0.3)),
                        // Dynamic scrollable body
                        Flexible(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: childrenBuilder(sheetContext, state),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openInteractionMenu(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    _showFluidSettingsMenu(
      context: context,
      title: 'Interaction',
      subtitle: 'Reader mode, network status & knight companion',
      icon: Icons.touch_app_rounded,
      iconColor: accent,
      childrenBuilder: (sheetContext, state) {
        final theme = Theme.of(sheetContext);
        return [
          _buildCardSection(
            title: 'Reading Experience & Controls',
            theme: theme,
            children: [
              _buildSwitchTile(
                icon: Icons.chrome_reader_mode_rounded,
                title: 'Focus Reader Mode',
                subtitle: 'Distraction-free margins, clean canvas & hidden quest chrome',
                value: state.isReaderMode,
                onChanged: (val) => state.toggleReaderMode(val),
                activeColor: theme.colorScheme.primary,
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor),
              _buildSwitchTile(
                icon: state.isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                title: state.isOnline ? 'Realm Connected (Online)' : 'Offline Reading Mode',
                subtitle: state.isOnline
                    ? 'Full gem rewards, cloud sync & streak progression enabled'
                    : 'Reading & notes active; gems and streak progression paused',
                value: state.isOnline,
                onChanged: (val) => state.toggleOnlineStatus(val),
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCardSection(
            title: 'Don Quixote AI Reading Companion',
            theme: theme,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.forum_rounded, color: theme.colorScheme.primary, size: 20),
                ),
                title: Text('Ask Don Quixote Settings', style: AppTypography.titleSmall),
                subtitle: Text(
                  state.hasGeminiApiKey
                      ? 'Connected • Unlimited Answers Ready'
                      : 'Built-in Library Wisdom Active (Tap to enter Gemini API key)',
                  style: AppTypography.bodySmall.copyWith(
                    color: state.hasGeminiApiKey ? const Color(0xFF4CAF50) : AppColors.antiqueGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showGeminiApiKeyDialog(context, state);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCardSection(
            title: 'Knight Induction Walkthrough',
            theme: theme,
            children: [
              ListTile(
                leading: Icon(Icons.explore_outlined, color: theme.colorScheme.primary),
                title: Text('Replay Guided Adventure Tour', style: AppTypography.titleSmall),
                subtitle: const Text('Review tips on books, socratic counsel, and quests', style: TextStyle(fontSize: 11.5)),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  state.restartGuidedTour();
                  widget.onNavigateTab?.call(0);
                },
              ),
            ],
          ),
        ];
      },
    );
  }

  void _openSoundsMenu(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    _showFluidSettingsMenu(
      context: context,
      title: 'Sounds and Vibrations',
      subtitle: 'Audio effects, classical lute music & haptics',
      icon: Icons.volume_up_rounded,
      iconColor: accent,
      childrenBuilder: (sheetContext, state) {
        final theme = Theme.of(sheetContext);
        return [
          _buildCardSection(
            title: 'Audio Sensory Toggles',
            theme: theme,
            children: [
              _buildSwitchTile(
                icon: Icons.volume_up_rounded,
                title: 'Sound Effects (Audio)',
                subtitle: 'Chimes, coin jingling, page flips & victory fanfare',
                value: state.soundEffectsEnabled,
                onChanged: (val) => state.toggleSoundEffects(val),
                activeColor: theme.colorScheme.primary,
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor),
              _buildSwitchTile(
                icon: Icons.music_note_rounded,
                title: 'Atmospheric Music',
                subtitle: 'Classical Spanish lute, strings, and winds',
                value: state.musicEnabled,
                onChanged: (val) => state.toggleMusic(val),
                activeColor: theme.colorScheme.primary,
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor),
              ListTile(
                leading: Icon(Icons.spatial_audio_rounded, color: theme.colorScheme.primary),
                title: const Text('Reading Ambience Soundscapes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text('Active atmosphere: ${AmbienceService.instance.currentTrack.title}', style: const TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () {
                  HapticService.instance.light();
                  AmbienceSoundscapeSheet.show(sheetContext);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCardSection(
            title: 'Tactile Physical Feedback',
            theme: theme,
            children: [
              _buildSwitchTile(
                icon: Icons.vibration_rounded,
                title: 'Haptic Vibration',
                subtitle: 'Physical kick on answers, quest nodes & reward celebrations',
                value: state.hapticsEnabled,
                onChanged: (val) => state.toggleHaptics(val),
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
        ];
      },
    );
  }

  void _openAppearanceMenu(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    _showFluidSettingsMenu(
      context: context,
      title: 'Appearance',
      subtitle: 'Day & night modes, realm themes & historical grimoires',
      icon: Icons.palette_rounded,
      iconColor: accent,
      childrenBuilder: (sheetContext, state) {
        final theme = Theme.of(sheetContext);
        return [
          _buildCardSection(
            title: 'Day / Night Luminescence',
            theme: theme,
            children: [
              _buildSwitchTile(
                icon: Icons.dark_mode_rounded,
                title: 'Dark Mode',
                subtitle: state.isDarkMode
                    ? 'Obsidian Midnight Knight active'
                    : 'Antique Parchment Cream active',
                value: state.isDarkMode,
                onChanged: (val) => state.toggleDarkMode(val),
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCardSection(
            title: 'Historical Realm Themes & Grimoires',
            theme: theme,
            children: [
              _buildThemeGrimoiresContent(sheetContext, theme, state),
            ],
          ),
        ];
      },
    );
  }

  void _openFontsMenu(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    _showFluidSettingsMenu(
      context: context,
      title: 'Fonts and Styles',
      subtitle: 'Typography, dyslexia accessibility & readability',
      icon: Icons.text_fields_rounded,
      iconColor: accent,
      childrenBuilder: (sheetContext, state) {
        final theme = Theme.of(sheetContext);
        final isLexend = state.isDyslexicFont;
        return [
          _buildCardSection(
            title: 'Accessible Reading Typography',
            theme: theme,
            children: [
              _buildSwitchTile(
                icon: Icons.font_download_rounded,
                title: 'Dyslexia-Friendly Font',
                subtitle: isLexend
                    ? 'Lexend accessible typography active'
                    : 'Classical EB Garamond serif active',
                value: state.isDyslexicFont,
                onChanged: (val) => state.toggleDyslexicFont(val),
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCardSection(
            title: 'Live Typography Preview',
            theme: theme,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isLexend ? Icons.spellcheck_rounded : Icons.auto_stories_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isLexend ? 'Lexend Open Typography' : 'EB Garamond Classical Serif',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        '“To dream the impossible dream, to fight the unbeatable foe, to bear with unbearable sorrow, to run where the brave dare not go.”\n\n— Miguel de Cervantes, Don Quixote de la Mancha',
                        style: TextStyle(
                          fontFamily: isLexend ? 'Lexend' : null,
                          fontSize: 14,
                          height: 1.6,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLexend
                          ? 'Lexend was scientifically designed with wide character apertures and distinct bottom weights to minimize visual crowd and assist readers with dyslexia.'
                          : 'Classical EB Garamond delivers authentic Renaissance and golden-age literary warmth for immersive long-form reading.',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.68),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ];
      },
    );
  }

  void _openProfilesMenu(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    _showFluidSettingsMenu(
      context: context,
      title: 'Profiles',
      subtitle: 'Knight dossier, daily reading goals & literary tastes',
      icon: Icons.person_rounded,
      iconColor: accent,
      childrenBuilder: (sheetContext, state) {
        final theme = Theme.of(sheetContext);
        final profile = state.profile;
        return [
          _buildCardSection(
            title: 'Knight Dossier & Objectives',
            theme: theme,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.badge_rounded, color: theme.colorScheme.primary, size: 20),
                ),
                title: Text('Call-Sign / Knight Name', style: AppTypography.titleSmall),
                subtitle: Text(profile.name, style: AppTypography.bodySmall),
                trailing: const Icon(Icons.edit_rounded, size: 18),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openEditProfileSheet(context, state);
                },
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor),
              ListTile(
                leading: Icon(Icons.flag_outlined, color: theme.colorScheme.primary),
                title: Text('Daily Reading Goal', style: AppTypography.titleSmall),
                subtitle: Text('${profile.dailyGoalMinutes} minutes per day', style: AppTypography.bodySmall),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showGoalDialog(context, state);
                },
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor),
              ListTile(
                leading: Icon(Icons.school_outlined, color: theme.colorScheme.primary),
                title: Text('Reading Difficulty', style: AppTypography.titleSmall),
                subtitle: Text(profile.difficulty, style: AppTypography.bodySmall),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openEditProfileSheet(context, state);
                },
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor),
              ListTile(
                leading: Icon(Icons.category_outlined, color: theme.colorScheme.primary),
                title: Text('Preferred Literary Genres', style: AppTypography.titleSmall),
                subtitle: Text(profile.preferredGenres.join(', '), style: AppTypography.bodySmall),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openEditProfileSheet(context, state);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCardSection(
            title: 'Chivalric Honors Summary',
            theme: theme,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const QuixoteAvatar(
                      mood: QuixoteMood.triumphant,
                      size: 48,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.readerRank,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.antiqueGold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${profile.levelsCompleted} Levels Cleared • ${profile.streakDays} Day Flame • ${profile.booksCompleted} Masterworks',
                            style: AppTypography.bodySmall.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCardSection(
            title: 'Account Session',
            theme: theme,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.energyRed.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded, color: AppColors.energyRed, size: 20),
                ),
                title: Text('Sign Out / Log Out', style: AppTypography.titleSmall.copyWith(color: AppColors.energyRed)),
                subtitle: Text(
                  AuthService.instance.userEmail.isNotEmpty
                      ? 'Currently signed in as ${AuthService.instance.userEmail}'
                      : 'Signed in as Guest Scholar (${profile.name})',
                  style: AppTypography.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _showSignOutWarningDialog(context, state),
              ),
            ],
          ),
        ];
      },
    );
  }

  void _openOtherThingsMenu(BuildContext context) {
    final parentTheme = Theme.of(context);
    _showFluidSettingsMenu(
      context: context,
      title: 'And Other Things',
      subtitle: 'Offline rules, alerts, creed, legal & data reset',
      icon: Icons.more_horiz_rounded,
      iconColor: parentTheme.colorScheme.primary,
      childrenBuilder: (sheetContext, state) {
        final theme = Theme.of(sheetContext);
        return [
          _buildCardSection(
            title: 'Realm Alerts & Offline Policy',
            theme: theme,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.wifi_off_rounded, color: theme.colorScheme.primary, size: 20),
                ),
                title: Text('Offline Rewards & Rules Notice', style: AppTypography.titleSmall),
                subtitle: const Text('Review paused items (gems, streaks) vs reading availability', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  OfflineWarningDialog.show(sheetContext);
                },
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor),
              ListTile(
                leading: Icon(Icons.notifications_active_outlined, color: theme.colorScheme.primary),
                title: Text('Guild Notifications & Alerts', style: AppTypography.titleSmall),
                subtitle: Text(
                  '${state.notifications.length} alerts (${state.notifications.where((n) => !n.isRead).length} unread)',
                  style: AppTypography.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => NotificationCenterSheet.show(sheetContext, state),
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor),
              ListTile(
                leading: Icon(Icons.notifications_none_rounded, color: theme.colorScheme.primary),
                title: Text('Daily Reading Reminders', style: AppTypography.titleSmall),
                subtitle: Text('7:30 PM (Evening Quill)', style: AppTypography.bodySmall),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _showDailyReminderDialog(sheetContext, state),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCardSection(
            title: 'Guild Lore & Legal Scrolls',
            theme: theme,
            children: [
              ListTile(
                leading: Icon(Icons.help_outline_rounded, color: theme.colorScheme.primary),
                title: Text('Chronicles of Quixoria', style: AppTypography.titleSmall),
                subtitle: Text('The Creed of the Errant Reader', style: AppTypography.bodySmall),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  GuideDialog.show(
                    context: sheetContext,
                    title: 'The Quixoria Creed',
                    message:
                        'To dream the impossible dream, to read the classic lines of time, and to conquer each chapter step by step!',
                    primaryButtonText: 'Amen, Sir Knight',
                    onPrimaryPressed: () {},
                  );
                },
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor),
              ListTile(
                leading: Icon(Icons.shield_outlined, color: theme.colorScheme.primary),
                title: Text('Privacy Policy & Data Protection', style: AppTypography.titleSmall),
                subtitle: Text('Local-first storage • Zero third-party tracking', style: AppTypography.bodySmall),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _showLegalDocumentSheet(
                  sheetContext,
                  title: 'Privacy Policy',
                  body: _privacyPolicyText,
                ),
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor),
              ListTile(
                leading: Icon(Icons.gavel_rounded, color: theme.colorScheme.primary),
                title: Text('Terms of Service', style: AppTypography.titleSmall),
                subtitle: Text('Public-domain texts, usage rules & reader rights', style: AppTypography.bodySmall),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _showLegalDocumentSheet(
                  sheetContext,
                  title: 'Terms of Service',
                  body: _termsOfServiceText,
                ),
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor),
              ListTile(
                leading: Icon(Icons.bug_report_outlined, color: theme.colorScheme.primary),
                title: Text('Diagnostics & Crash Log', style: AppTypography.titleSmall),
                subtitle: Text(
                  '${CrashReporter.instance.records.length} on-device error records captured',
                  style: AppTypography.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _showCrashLogSheet(sheetContext),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_forever_rounded, color: AppColors.energyRed),
              label: const Text('Reset & Delete All Local Data', style: TextStyle(color: AppColors.energyRed)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.energyRed),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _confirmResetAllData(context, state);
              },
            ),
          ),
        ];
      },
    );
  }

  Widget _buildThemeGrimoiresContent(BuildContext context, ThemeData theme, AppState state) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  state.activeThemePreset.icon,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active: ${state.activeThemePreset.name}',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      state.activeThemePreset.eraTag,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.68),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'EQUIPPED',
                  style: AppTypography.labelSmall.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Equip or unlock historical presets:',
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.78),
            ),
          ),
          const SizedBox(height: 10),

          // Horizontal carousel of themes
          SizedBox(
            height: 195,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: state.themePresets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final preset = state.themePresets[i];
                final isEquipped = preset.id == state.activeThemePresetId;

                return Container(
                  width: 170,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: preset.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isEquipped ? AppColors.antiqueGold : preset.border,
                      width: isEquipped ? 2 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(preset.icon, size: 22, color: preset.primary),
                          if (isEquipped)
                            Icon(Icons.check_circle, size: 16, color: theme.colorScheme.primary)
                          else if (preset.isOwned)
                            Icon(Icons.inventory_2_outlined, size: 16, color: theme.colorScheme.primary)
                          else
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.diamond_outlined, size: 12, color: AppColors.gemCyan),
                                const SizedBox(width: 3),
                                Text(
                                  '${preset.gemPrice}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: preset.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        preset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: preset.textPrimary,
                        ),
                      ),
                      Text(
                        preset.eraTag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 10,
                          color: preset.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 5 swatches
                      Row(
                        children: [
                          _buildMiniDot(preset.primary),
                          const SizedBox(width: 3),
                          _buildMiniDot(preset.secondary),
                          const SizedBox(width: 3),
                          _buildMiniDot(preset.background),
                          const SizedBox(width: 3),
                          _buildMiniDot(preset.surface),
                          const SizedBox(width: 3),
                          _buildMiniDot(preset.accent),
                        ],
                      ),
                      const Spacer(),
                      // Action Button
                      if (isEquipped) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Equipped',
                              style: AppTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ] else if (preset.isOwned && preset.isDownloaded) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: preset.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              await QuixoriaLoadingDialog.show(
                                context,
                                title: 'Manifesting ${preset.name}',
                                message: 'Adapting interface architecture, stonework accents, and grimoire typography to ${preset.name}...',
                                task: Future.delayed(const Duration(milliseconds: 900), () => state.applyThemePreset(preset.id)),
                              );
                              if (context.mounted) {
                                RewardCelebrationOverlay.showCelebration(
                                  context,
                                  celebrationType: CelebrationType.gems,
                                );
                              }
                            },
                            child: const Text('Equip', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ] else if (preset.isOwned && !preset.isDownloaded) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              side: BorderSide(color: preset.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => state.downloadThemePreset(preset.id),
                            child: const Text('Download', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: AppColors.antiqueGold,
                              foregroundColor: isDark ? const Color(0xFF121212) : theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              if (state.profile.gems >= preset.gemPrice) {
                                GuideDialog.show(
                                  context: context,
                                  title: 'Acquire Grimoire Preset?',
                                  message:
                                      'Wilt thou spend 💎 ${preset.gemPrice} gems to unlock "${preset.name}"?',
                                  primaryButtonText: 'Confirm & Unlock',
                                  secondaryButtonText: 'Keep My Gems',
                                  mood: QuixoteMood.inquiring,
                                  onPrimaryPressed: () {
                                    state.buyThemePreset(preset.id);
                                    state.downloadThemePreset(preset.id);
                                    RewardCelebrationOverlay.showCelebration(
                                      context,
                                      celebrationType: CelebrationType.gems,
                                    );
                                  },
                                );
                              } else {
                                widget.onNavigateTab?.call(3);
                              }
                            },
                            child: Text(
                              state.profile.gems >= preset.gemPrice ? 'Unlock' : 'Get in Bazaar',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Link to Bazaar
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: const Icon(Icons.storefront_rounded, size: 16),
              label: const Text('Browse All Themes in Literary Bazaar'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
              onPressed: () => widget.onNavigateTab?.call(3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniDot(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withOpacity(0.15), width: 1),
      ),
    );
  }





  Widget _buildCardSection({
    required String title,
    required ThemeData theme,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Material(
          color: theme.colorScheme.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            side: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.28),
              width: 1.4,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
  }) {
    return Builder(
      builder: (ctx) {
        final t = Theme.of(ctx);
        return SwitchListTile.adaptive(
          secondary: Icon(icon, color: activeColor ?? t.colorScheme.primary),
          title: Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              color: t.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: t.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          activeColor: activeColor ?? t.colorScheme.primary,
          activeTrackColor: (activeColor ?? t.colorScheme.primary).withValues(alpha: 0.42),
          value: value,
          onChanged: onChanged,
        );
      },
    );
  }

  void _showGoalDialog(BuildContext context, AppState state) {
    int selected = state.profile.dailyGoalMinutes;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color ?? AppColors.parchmentCream,
          title: Text('Adjust Daily Reading Goal', style: AppTypography.titleLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [10, 15, 20, 30].map((mins) {
              return RadioListTile<int>(
                title: Text('$mins minutes / day'),
                value: mins,
                groupValue: selected,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (val) {
                  if (val != null) {
                    state.updateUserProfile(dailyGoalMinutes: val);
                    Navigator.pop(ctx);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _openEditProfileSheet(BuildContext context, AppState state) {
    final theme = Theme.of(context);
    final profile = state.profile;
    final nameCtrl = TextEditingController(text: profile.name);
    final emailCtrl = TextEditingController(text: profile.email);
    String selectedRank = profile.readerRank;
    String selectedDifficulty = profile.difficulty;

    final rankOptions = [
      'Apprentice Hidalgo',
      'Knight Errant of La Mancha',
      'Sage of the Round Table',
      'Master of Sagas',
      'Grand Inquisitor',
    ];

    final difficultyOptions = [
      'Apprentice',
      'Journeyman',
      'Master Caballero',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color ?? AppColors.parchmentCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Knight’s Dossier',
                          style: AppTypography.titleLarge.copyWith(fontSize: 20),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Name
                    Text(
                      'Knight’s Name',
                      style: AppTypography.labelMedium.copyWith(color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        hintText: 'Enter your name or knightly title',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        prefixIcon: Icon(Icons.person_outline_rounded, color: theme.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Honorific Rank
                    Text(
                      'Knightly Honorific / Rank',
                      style: AppTypography.labelMedium.copyWith(color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: rankOptions.map((rank) {
                        final isSel = selectedRank == rank;
                        return ChoiceChip(
                          label: Text(rank),
                          selected: isSel,
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: theme.scaffoldBackgroundColor,
                          labelStyle: TextStyle(
                            color: isSel ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => selectedRank = rank);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    Text(
                      'Cloud Sync Email',
                      style: AppTypography.labelMedium.copyWith(color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        hintText: 'your-email@realm.com',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        prefixIcon: Icon(Icons.mail_outline_rounded, color: theme.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reading Difficulty
                    Text(
                      'Reading Difficulty',
                      style: AppTypography.labelMedium.copyWith(color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: difficultyOptions.map((diff) {
                        final isSel = selectedDifficulty == diff;
                        return ChoiceChip(
                          label: Text(diff),
                          selected: isSel,
                          selectedColor: AppColors.antiqueGold,
                          backgroundColor: theme.scaffoldBackgroundColor,
                          labelStyle: TextStyle(
                            color: isSel ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => selectedDifficulty = diff);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    DuoButton(
                      text: 'Save Dossier Updates',
                      icon: Icons.check_circle_rounded,
                      variant: DuoButtonVariant.primary,
                      onPressed: () {
                        state.updateUserProfile(
                          name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : null,
                          email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                          readerRank: selectedRank,
                          difficulty: selectedDifficulty,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Knight’s Dossier successfully recorded in the scrolls!'),
                            backgroundColor: theme.colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static const String _privacyPolicyText = '''
Quixoria Privacy Policy (Local-First Edition)

1. Data Stored on Your Device
Quixoria stores your reading progress, completed levels, streaks, gems, marginalia notes, Spaced-Repetition Word Bank cards, and accessibility preferences locally on your device using Android/iOS SharedPreferences.

2. Zero Third-Party Tracking
Quixoria does not sell, rent, or share your personal data with advertisers or data brokers. No analytics or behavioural tracking SDKs are active in this build.

3. Crash & Diagnostic Logs
Uncaught application errors are recorded in an on-device diagnostic buffer (up to 30 entries) so you can inspect or copy them if you contact support. They are never uploaded automatically.

4. Your Right to Delete Data
You can permanently erase all locally stored profile data, notes, vocabulary progress, and diagnostics at any time using the "Reset & Delete All Local Data" button at the bottom of your Profile screen, or by uninstalling the application.
''';

  static const String _termsOfServiceText = '''
Quixoria Terms of Service

1. Purpose of the Application
Quixoria is an educational literary reading companion designed to help readers explore classic literature through chapters, recall quizzes, and spaced-repetition vocabulary cards.

2. Literary Texts & Intellectual Property
Classic literary works included in Quixoria (such as Don Quixote, The Secret Garden, The Wind in the Willows, Alice in Wonderland, and The Time Machine) are adaptations of public-domain texts. Quixoria's original UI, custom illustrations, study questions, and code remain protected copyright.

3. Virtual Currency & In-App Items
Gems, Golden Keys, Streak Freezes, and the Caballero Pass are virtual in-app progression items designed to support your reading journey.

4. Acceptable Use
You agree to use Quixoria for personal educational and reading enjoyment.
''';

  void _showDailyReminderDialog(BuildContext context, AppState state) {
    final theme = Theme.of(context);
    final schedules = const [
      ('Morning Expedition', '8:00 AM', Icons.wb_sunny_outlined),
      ('Afternoon Study', '4:00 PM', Icons.light_mode_outlined),
      ('Evening Quill', '7:30 PM', Icons.auto_stories_rounded),
      ('Night Watch', '9:30 PM', Icons.nights_stay_outlined),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: AppColors.antiqueGold, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Daily Reading Reminder Schedule',
                    style: AppTypography.titleLarge.copyWith(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Choose when Quixoria should remind you to read and protect your daily campfire streak.',
                style: AppTypography.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 14),
              for (final item in schedules)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Icon(item.$3, color: AppColors.antiqueGold),
                  title: Text(item.$1, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text(item.$2, style: AppTypography.bodySmall),
                  trailing: const Icon(Icons.check_circle_outline_rounded, color: AppColors.antiqueGold, size: 20),
                  onTap: () {
                    Navigator.pop(ctx);
                    NotificationService().scheduleDailyStreakReminders(
                      userName: state.profile.name,
                      streakDays: state.profile.streakDays,
                      activeBook: state.activeLiterature.title,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Phone reminders updated (${item.$1}).'),
                        backgroundColor: theme.colorScheme.primary,
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showLegalDocumentSheet(BuildContext context, {required String title, required String body}) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.45,
          expand: false,
          builder: (_, scrollCtrl) {
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  body.trim(),
                  style: AppTypography.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                    height: 1.55,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCrashLogSheet(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final records = CrashReporter.instance.records;
            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (_, scrollCtrl) {
                return ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Diagnostics & Crash Log',
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        if (records.isNotEmpty)
                          TextButton.icon(
                            icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: AppColors.energyRed),
                            label: const Text('Clear', style: TextStyle(color: AppColors.energyRed)),
                            onPressed: () async {
                              await CrashReporter.instance.clear();
                              setModalState(() {});
                            },
                          ),
                      ],
                    ),
                    Text(
                      'On-device error log (${records.length} entries). Stored locally only.',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (records.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(Icons.verified_rounded, size: 48, color: state.activeThemePreset.successColor),
                            const SizedBox(height: 10),
                            Text(
                              'No crashes or uncaught errors recorded.',
                              style: AppTypography.titleSmall.copyWith(color: theme.colorScheme.onSurface),
                            ),
                          ],
                        ),
                      )
                    else
                      for (final r in records) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '[${r.source.toUpperCase()}] ${r.time.toIso8601String().substring(0, 19)}',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.energyRed,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded, size: 16),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: r.toShareableText()));
                                      ScaffoldMessenger.of(modalCtx).showSnackBar(
                                        const SnackBar(content: Text('Copied diagnostic entry to clipboard')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                r.error,
                                style: AppTypography.bodySmall.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showGeminiApiKeyDialog(BuildContext context, AppState state) {
    final controller = TextEditingController(text: state.geminiApiKey);
    bool isTesting = false;
    String? testResult;
    bool? testSuccess;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E26) : AppColors.parchmentWarm,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.antiqueGold, width: 1.2),
              ),
              title: Row(
                children: [
                  const Icon(Icons.forum_rounded, color: AppColors.antiqueGold, size: 22),
                  const SizedBox(width: 8),
                  Text('Don Quixote Reading Companion', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Don Quixote is thy friendly reading partner! He loves answering questions, explaining tricky words, and sharing advice on chapters.',
                      style: AppTypography.bodySmall.copyWith(height: 1.45),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Note: Sir Quixote always works offline with his built-in library wisdom. An optional companion key gives him unlimited answers for every story.',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      obscureText: true,
                      style: AppTypography.bodySmall,
                      decoration: InputDecoration(
                        labelText: 'Companion Knowledge Key (Optional)',
                        hintText: 'AIzaSy...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => setDialogState(() => controller.clear()),
                        ),
                      ),
                    ),
                    if (testResult != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            testSuccess == true ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                            size: 16,
                            color: testSuccess == true ? Colors.green : AppColors.energyRed,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              testResult!,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: testSuccess == true ? Colors.green : AppColors.energyRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (state.hasGeminiApiKey)
                  TextButton(
                    onPressed: () {
                      state.setGeminiApiKey('');
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Companion key cleared. Reverted to built-in library wisdom.')),
                      );
                    },
                    child: const Text('Clear Key', style: TextStyle(color: AppColors.energyRed)),
                  ),
                TextButton(
                  onPressed: isTesting
                      ? null
                      : () async {
                          final key = controller.text.trim();
                          if (key.isEmpty) {
                            setDialogState(() {
                              testResult = 'Please enter an API key first.';
                              testSuccess = false;
                            });
                            return;
                          }
                          setDialogState(() {
                            isTesting = true;
                            testResult = 'Connecting with Don Quixote...';
                            testSuccess = null;
                          });
                          final valid = await GeminiService.instance.validateApiKey(key);
                          setDialogState(() {
                            isTesting = false;
                            testSuccess = valid;
                            testResult = valid ? 'Connected! Don Quixote is ready to answer any question.' : 'Unable to connect. Check key or internet connection.';
                          });
                        },
                  child: isTesting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Test Companion Connection'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.antiqueGold,
                    foregroundColor: const Color(0xFF121212),
                  ),
                  onPressed: () {
                    final key = controller.text.trim();
                    state.setGeminiApiKey(key);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(key.isNotEmpty
                            ? 'Settings saved! Don Quixote now has unlimited answers.'
                            : 'Using Don Quixote’s built-in library wisdom.'),
                      ),
                    );
                  },
                  child: const Text('Save & Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmResetAllData(BuildContext context, AppState state) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        title: Text(
          'Reset All Local Data?',
          style: AppTypography.titleLarge.copyWith(color: AppColors.energyRed),
        ),
        content: Text(
          'This will wipe your saved progress, streaks, gems, notes, and Word Bank cards from this device and restore Quixoria to a fresh install state.',
          style: AppTypography.bodyMedium.copyWith(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.energyRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await state.resetAllData();
              await CrashReporter.instance.clear();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All local data has been reset to defaults.'),
                  ),
                );
              }
            },
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // ABOUT QUIXORIA & ROADMAP
  // ============================================================================

  void _openAboutQuixoriaMenu(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    _showFluidSettingsMenu(
      context: context,
      title: 'About Quixoria',
      subtitle: 'The grand vision, realm features, and upcoming scholar roadmaps',
      icon: Icons.auto_stories_rounded,
      iconColor: accent,
      childrenBuilder: (sheetContext, state) {
        final theme = Theme.of(sheetContext);
        final isDark = theme.brightness == Brightness.dark;

        return [
          // Brand Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF263228), const Color(0xFF1B221C)]
                    : [const Color(0xFFFFF9ED), const Color(0xFFF7EED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.antiqueGold.withOpacity(0.55),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.antiqueGold.withOpacity(0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const QuixoteAvatar(size: 76, mood: QuixoteMood.proud),
                const SizedBox(height: 12),
                Text(
                  'QUIXORIA',
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: AppColors.antiqueGold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The Chivalric Literature Companion',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.antiqueGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Grand Hidalgo Edition • Version 2.0.0',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.antiqueGold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '“To dream the impossible dream, to read the classic lines of time, and to conquer each chapter step by step!”',
                  textAlign: TextAlign.center,
                  style: AppTypography.quote.copyWith(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    height: 1.45,
                    color: theme.colorScheme.onSurface.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 1: The Chivalric Mission
          _buildCardSection(
            title: '1. Our Noble Mission',
            theme: theme,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Classical literature holds humanity’s deepest wisdom, philosophy, and imagination. Yet for young scholars and busy minds, archaic vocabulary, sprawling paragraphs, and intimidating book sizes often stand as insurmountable barriers.\n\n'
                  'Quixoria transforms daunting masterworks into engaging, bite-sized Duolingo-style reading expeditions. Each classic is carefully structured into digestible 3-to-5 minute chapters paired with contextual comprehension quizzes, vocabulary word banks, and real-time guidance from Don Quixote himself.',
                  style: AppTypography.bodySmall.copyWith(fontSize: 12, height: 1.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section 2: What We Have (Current Features)
          _buildCardSection(
            title: '2. Realm Arsenal (Features Live Today)',
            theme: theme,
            children: [
              _buildAboutFeatureTile(
                theme: theme,
                icon: Icons.menu_book_rounded,
                iconColor: AppColors.antiqueGold,
                title: 'Curated Public-Domain Canon',
                desc: 'Full pedagogical chapters from Don Quixote, Frankenstein, The Odyssey, The Prophet, Pride and Prejudice, The Time Machine, and Sherlock Holmes.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
                theme: theme,
                icon: Icons.shield_rounded,
                iconColor: AppColors.gemCyan,
                title: 'Interactive 3D Mascot Companion',
                desc: 'A responsive Don Quixote companion with 7 emotive expressions (idle, happy, excited, thinking, sad, determined, confident) providing hints and celebration.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
                theme: theme,
                icon: Icons.alt_route_rounded,
                iconColor: AppColors.deepForest,
                title: 'Winding Skill Path & Level Map',
                desc: 'A visual zigzag journey of nodes with bouncing active milestones, unread task badges, and checkpoint evaluations.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
                theme: theme,
                icon: Icons.psychology_rounded,
                iconColor: AppColors.vermillion,
                title: 'Pedagogical Exercise Engine',
                desc: 'Interactive Cloze deletion tests, contextual matching pairs, word bank mastery, and Socratic comprehension queries.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
                theme: theme,
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.vermillion,
                title: 'Campfire Habit Streaks',
                desc: 'Daily reading habits preserved with streak freezes, midnight extinguishing warnings, and gem-based rekindling.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
                theme: theme,
                icon: Icons.music_note_rounded,
                iconColor: AppColors.gemCyan,
                title: 'Atmospheric Lo-Fi Soundscapes',
                desc: '4 continuous ambient soundscapes: Classical Lute, Knight’s Hearth, Rainy Library, and Ancient Scriptorium.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
                theme: theme,
                icon: Icons.wifi_off_rounded,
                iconColor: AppColors.antiqueGold,
                title: 'Real-Time Offline-First Engine',
                desc: 'Read anywhere with zero connectivity; automated real-time network detection auto-dismisses warnings when Wi-Fi returns.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
                theme: theme,
                icon: Icons.accessibility_new_rounded,
                iconColor: AppColors.deepForest,
                title: 'Inclusive Reader Accessibility',
                desc: 'Dyslexia-friendly Lexend typography, Obsidian Dark Mode, Parchment Light Mode, and customizable font scaling.',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section 3: The Grand Horizon (Upcoming Plans)
          _buildCardSection(
            title: '3. The Grand Horizon (Future Roadmap)',
            theme: theme,
            children: [
              _buildAboutFeatureTile(
                theme: theme,
                icon: Icons.cloud_sync_rounded,
                iconColor: AppColors.gemCyan,
                title: 'Cloud Synchronization & Firebase Backup',
                desc: 'Seamless multi-device cloud saves, letting you switch between phones, tablets, and desktop without losing a single line.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
                theme: theme,
                icon: Icons.sports_kabaddi_rounded,
                iconColor: AppColors.vermillion,
                title: 'Literary Jousts & Guild Tournaments',
                desc: 'Weekly scholar leagues, multiplayer comprehension battles, and guild cooperative reading milestones with friends.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
                theme: theme,
                icon: Icons.record_voice_over_rounded,
                iconColor: AppColors.antiqueGold,
                title: 'Theatrical Voiced Storybook Narration',
                desc: 'Full-cast voice recordings and character dialogue dramatization for rich auditory immersion.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
                theme: theme,
                icon: Icons.rate_review_outlined,
                iconColor: AppColors.deepForest,
                title: 'Scholars’ Marginalia Exchange',
                desc: 'Leave thoughtful notes in chapter margins and discover reflections written by readers worldwide.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
                theme: theme,
                icon: Icons.castle_rounded,
                iconColor: AppColors.antiqueGold,
                title: 'Expanded World Canon Library',
                desc: 'Expanding to Dante’s Divine Comedy, Shakespeare’s Hamlet, Jane Eyre, Moby Dick, and ancient epics from Gilgamesh to the Aeneid.',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Credits Footer Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite_rounded, color: AppColors.vermillion, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Crafted with knightly pride and literary devotion. May thy adventures through classical literature be forever bold!',
                    style: AppTypography.bodySmall.copyWith(fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  Widget _buildAboutFeatureTile({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall.copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: theme.colorScheme.onSurface.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SIGN OUT & LOG OUT WARNING POP-UP DIALOG
  // ============================================================================

  void _showSignOutWarningDialog(BuildContext context, AppState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E2620) : const Color(0xFFFFFBF2);
    final userEmail = AuthService.instance.userEmail.isNotEmpty
        ? AuthService.instance.userEmail
        : state.profile.name;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: dialogBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.antiqueGold.withOpacity(0.55),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mascot Caution Avatar
                const QuixoteAvatar(size: 64, mood: QuixoteMood.caution),
                const SizedBox(height: 14),

                Text(
                  'Depart the Realm?',
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.antiqueGold,
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  'Thou art about to sign out from thy scholar account ($userEmail). Before thou leavest, heed Don Quixote’s warning:',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 12.5,
                    height: 1.45,
                    color: theme.colorScheme.onSurface.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 14),

                // Bullet points of warning
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.antiqueGold.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSignOutWarningBullet('Thy reading progress, earned gems, and notes will remain safely stored on this device.'),
                      const SizedBox(height: 6),
                      _buildSignOutWarningBullet('Daily reading streak timers will continue to advance until thou returnest.'),
                      const SizedBox(height: 6),
                      _buildSignOutWarningBullet('Thou wilt be returned to the gates where email verification or passphrase log-in is required to enter.'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Buttons: Cancel (Stay) vs Proceed (Sign Out)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(color: theme.dividerColor.withOpacity(0.6)),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(dialogCtx).pop(); // Stay in settings
                        },
                        child: Text(
                          'Cancel (Stay)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.energyRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                        ),
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          SoundService.instance.play(Sfx.tap);
                          Navigator.of(dialogCtx).pop(); // Dismiss warning dialog
                          // Dismiss modal sheet if open
                          Navigator.of(context).maybePop();
                          // Logout and reset auth state
                          await state.logout();
                        },
                        child: const Text(
                          'Proceed (Sign Out)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFollowsModalSheet(BuildContext context, {int initialTab = 0}) {
    final state = context.read<AppState>();
    final myHandle = CommunityService.normalizeHandle(
      state.profile.email.isNotEmpty ? state.profile.email : state.profile.name,
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FollowsListSheet(
        myHandle: myHandle,
        initialTab: initialTab,
      ),
    );
  }

  Widget _buildSignOutWarningBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: AppColors.antiqueGold, fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11.5, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _FollowsListSheet extends StatefulWidget {
  final String myHandle;
  final int initialTab;

  const _FollowsListSheet({
    required this.myHandle,
    this.initialTab = 0,
  });

  @override
  State<_FollowsListSheet> createState() => _FollowsListSheetState();
}

class _FollowsListSheetState extends State<_FollowsListSheet> {
  late int _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    CommunityService.instance.init(widget.myHandle);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF17191E) : const Color(0xFFFAF8F4);
    final cardBg = isDark ? const Color(0xFF21242B) : Colors.white;
    final border = theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.45);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1C19);
    final textMuted = isDark ? Colors.white70 : const Color(0xFF5A625C);
    final primary = theme.colorScheme.primary;

    return ListenableBuilder(
      listenable: CommunityService.instance,
      builder: (context, _) {
        final followingList = CommunityService.instance.following.toList()..sort();
        final followersList = CommunityService.instance.followers.toList()..sort();
        final activeList = _tab == 0 ? followingList : followersList;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: border, width: 2.0),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                  child: Row(
                    children: [
                      Icon(Icons.people_alt_rounded, color: primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Fellow Scholars',
                        style: AppTypography.titleLarge.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: textMuted),
                      ),
                    ],
                  ),
                ),
                // 2-Tab Switcher: Following | Followers
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border, width: 1.6),
                    ),
                    child: Row(
                      children: [
                        _tabBtn('Following (${followingList.length})', 0, primary, textMuted),
                        _tabBtn('Followers (${followersList.length})', 1, primary, textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: activeList.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _tab == 0 ? Icons.person_search_rounded : Icons.diversity_3_rounded,
                                  size: 46,
                                  color: primary.withValues(alpha: 0.55),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _tab == 0
                                      ? 'You are not following any scholars yet'
                                      : 'No followers yet',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.titleSmall.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _tab == 0
                                      ? 'Visit the Community Feed to follow friends by username or email!'
                                      : 'Post in the Community Feed so fellow readers can discover and follow you.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall.copyWith(color: textMuted),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                          itemCount: activeList.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final handle = activeList[i];
                            final isFollowing = CommunityService.instance.following.contains(handle);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: border, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: primary.withValues(alpha: 0.16),
                                    child: Text(
                                      handle.isNotEmpty ? handle[0].toUpperCase() : '?',
                                      style: AppTypography.titleSmall.copyWith(
                                        color: primary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '@$handle',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.titleSmall.copyWith(
                                            color: textPrimary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          isFollowing ? 'Following' : 'Follows you',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: textMuted,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 104,
                                    child: DuoButton(
                                      text: isFollowing ? 'Unfollow' : 'Follow',
                                      variant: isFollowing
                                          ? DuoButtonVariant.outline
                                          : DuoButtonVariant.primary,
                                      height: 36,
                                      onPressed: () {
                                        FollowActionHelper.toggleFollowWithConfirm(
                                          context,
                                          myHandle: widget.myHandle,
                                          targetHandle: handle,
                                        );
                                      },
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
      },
    );
  }

  Widget _tabBtn(String label, int index, Color primary, Color textMuted) {
    final active = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.instance.light();
          setState(() => _tab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: active ? Colors.white : textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

