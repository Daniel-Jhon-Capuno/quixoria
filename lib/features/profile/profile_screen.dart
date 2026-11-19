import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/ambience_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/crash_reporter.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';
import '../../models/user_profile.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/guide_dialog.dart';
import '../../shared/widgets/loading_dialog.dart';
import '../../shared/widgets/notification_center_sheet.dart';
import '../../shared/widgets/quixote_avatar.dart';
import '../../shared/widgets/quixote_mascot.dart';
import '../../shared/widgets/reward_celebration.dart';
import '../../shared/widgets/themed_card.dart';
import '../../shared/widgets/offline_warning_dialog.dart';
import '../reader/ambience_soundscape_sheet.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const ProfileScreen({super.key, this.onNavigateTab});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isAchievementsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    final theme = Theme.of(context);
    final isDark = state.isDarkMode || theme.brightness == Brightness.dark || theme.scaffoldBackgroundColor.computeLuminance() < 0.38;
    final textColor = isDark ? const Color(0xFFFDFBF7) : const Color(0xFF1A1C19);
    final subtitleColor = isDark ? const Color(0xFFC5CEC8) : const Color(0xFF5A625C);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Knight’s Dossier',
          style: AppTypography.displaySmall.copyWith(
            color: theme.colorScheme.primary,
            fontSize: 24,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            children: [
              // User Avatar & Rank Card (Themed with Iron Rivets/Glow/Parchment)
              ThemedCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                child: Column(
                  children: [
                    const QuixoteMascot(
                      size: 88,
                      expression: QuixoteExpression.idle,
                      showSpeechBubble: false,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.name,
                      style: AppTypography.titleLarge.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.email,
                      style: AppTypography.bodySmall.copyWith(
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        profile.readerRank,
                        style: AppTypography.labelSmall.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (profile.isPremium) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.antiqueGold,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars_rounded, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              'CABALLERO PASS MEMBER',
                              style: AppTypography.labelSmall.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    // Edit Profile Action
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit Dossier'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: const BorderSide(color: AppColors.antiqueGold, width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => _openEditProfileSheet(context, state),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // On-Device Persistence Banner
              ThemedCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.save_rounded, color: theme.colorScheme.primary, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'On-Device Persistence Active',
                            style: AppTypography.labelLarge.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Streaks, gems, completed quests, Word Bank cards, and notes are automatically saved to this device.',
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
              ),
              const SizedBox(height: 20),

              // Quest Statistics Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatTile(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: AppColors.streakOrange,
                      value: '${profile.streakDays} Days',
                      label: 'Daily App Streak',
                      surfaceColor: theme.cardTheme.color,
                      borderColor: theme.dividerColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatTile(
                      icon: Icons.track_changes_rounded,
                      iconColor: state.activeThemePreset.successColor,
                      value: '${profile.answerStreak} Perfect',
                      label: 'Answer Streak',
                      surfaceColor: theme.cardTheme.color,
                      borderColor: theme.dividerColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatTile(
                      icon: Icons.auto_stories_rounded,
                      iconColor: theme.colorScheme.primary,
                      value: '${profile.booksCompleted}',
                      label: 'Works Mastered',
                      surfaceColor: theme.cardTheme.color,
                      borderColor: theme.dividerColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatTile(
                      icon: Icons.flag_rounded,
                      iconColor: AppColors.antiqueGold,
                      value: '${profile.levelsCompleted}',
                      label: 'Levels Conquered',
                      surfaceColor: theme.cardTheme.color,
                      borderColor: theme.dividerColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatTile(
                      icon: Icons.border_color_rounded,
                      iconColor: theme.colorScheme.primary,
                      value: '${profile.notesSaved}',
                      label: 'Notes Saved',
                      surfaceColor: theme.cardTheme.color,
                      borderColor: theme.dividerColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatTile(
                      icon: Icons.timer_rounded,
                      iconColor: theme.colorScheme.primary,
                      value: '${profile.dailyMinutesReadToday} min',
                      label: 'Read Today',
                      surfaceColor: theme.cardTheme.color,
                      borderColor: theme.dividerColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Chivalric Achievements & Honors Section
              _buildAchievementsSection(context, theme, state, profile),
              const SizedBox(height: 24),

              // Categorized Settings & Customizations Section
              _buildSettingsCategories(context, theme, state, profile),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCategories(BuildContext context, ThemeData theme, AppState state, UserProfile profile) {
    return _buildCardSection(
      title: 'Settings & Preferences',
      theme: theme,
      children: [
        _buildMenuTile(
          icon: Icons.touch_app_rounded,
          iconColor: AppColors.antiqueGold,
          title: 'Interaction',
          subtitle: 'Reader mode, offline reading & knight companion',
          badgeText: state.isReaderMode ? 'Reader Active' : null,
          onTap: () => _openInteractionMenu(context),
        ),
        Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
        _buildMenuTile(
          icon: Icons.volume_up_rounded,
          iconColor: AppColors.gemCyan,
          title: 'Sounds and Vibrations',
          subtitle: 'Audio effects, atmospheric lute music, ambience & haptics',
          badgeText: (state.soundEffectsEnabled && state.musicEnabled) ? 'All Audio On' : null,
          onTap: () => _openSoundsMenu(context),
        ),
        Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
        _buildMenuTile(
          icon: Icons.palette_rounded,
          iconColor: AppColors.antiqueGold,
          title: 'Appearance',
          subtitle: 'Day & night mode, active grimoire: ${state.activeThemePreset.name}',
          badgeText: state.isDarkMode ? 'Obsidian' : 'Parchment',
          onTap: () => _openAppearanceMenu(context),
        ),
        Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
        _buildMenuTile(
          icon: Icons.text_fields_rounded,
          iconColor: AppColors.deepForest,
          title: 'Fonts and Styles',
          subtitle: 'Typography preview, dyslexia-friendly Lexend & readability',
          badgeText: state.isDyslexicFont ? 'Lexend' : 'Classical Serif',
          onTap: () => _openFontsMenu(context),
        ),
        Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
        _buildMenuTile(
          icon: Icons.person_rounded,
          iconColor: AppColors.vermillion,
          title: 'Profiles',
          subtitle: '${profile.name} • ${profile.dailyGoalMinutes} min/day • ${profile.difficulty}',
          onTap: () => _openProfilesMenu(context),
        ),
        Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
        _buildMenuTile(
          icon: Icons.more_horiz_rounded,
          iconColor: theme.colorScheme.onSurface.withOpacity(0.65),
          title: 'And Other Things',
          subtitle: 'Offline rules notice, alerts, creed, legal & data reset',
          onTap: () => _openOtherThingsMenu(context),
        ),
        Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
        _buildMenuTile(
          icon: Icons.auto_stories_rounded,
          iconColor: AppColors.antiqueGold,
          title: 'About Quixoria',
          subtitle: 'Realm vision, complete features list & upcoming scholar roadmap',
          badgeText: 'v2.0',
          onTap: () => _openAboutQuixoriaMenu(context),
        ),
        Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
        _buildMenuTile(
          icon: Icons.logout_rounded,
          iconColor: AppColors.energyRed,
          title: 'Sign Out / Log Out',
          subtitle: 'Depart current crusade session and return to gates',
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
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withOpacity(0.25), width: 1.2),
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
            final isDark = theme.brightness == Brightness.dark;

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
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF181A1B) : const Color(0xFFFAF6EE),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
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
                              color: theme.dividerColor.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(0.14),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: iconColor.withOpacity(0.35), width: 1.2),
                                ),
                                child: Icon(icon, color: iconColor, size: 22),
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
    _showFluidSettingsMenu(
      context: context,
      title: 'Interaction',
      subtitle: 'Reader mode, network status & knight companion',
      icon: Icons.touch_app_rounded,
      iconColor: AppColors.antiqueGold,
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
                activeColor: state.activeThemePreset.successColor,
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
                    color: AppColors.antiqueGold.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.forum_rounded, color: AppColors.antiqueGold, size: 20),
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
    _showFluidSettingsMenu(
      context: context,
      title: 'Sounds and Vibrations',
      subtitle: 'Audio effects, classical lute music & haptics',
      icon: Icons.volume_up_rounded,
      iconColor: AppColors.gemCyan,
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
                leading: const Icon(Icons.spatial_audio_rounded, color: AppColors.antiqueGold),
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
    _showFluidSettingsMenu(
      context: context,
      title: 'Appearance',
      subtitle: 'Day & night modes, realm themes & historical grimoires',
      icon: Icons.palette_rounded,
      iconColor: AppColors.antiqueGold,
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
    _showFluidSettingsMenu(
      context: context,
      title: 'Fonts and Styles',
      subtitle: 'Typography, dyslexia accessibility & readability',
      icon: Icons.text_fields_rounded,
      iconColor: AppColors.deepForest,
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
    _showFluidSettingsMenu(
      context: context,
      title: 'Profiles',
      subtitle: 'Knight dossier, daily reading goals & literary tastes',
      icon: Icons.person_rounded,
      iconColor: AppColors.vermillion,
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
                    color: AppColors.vermillion.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.badge_rounded, color: AppColors.vermillion, size: 20),
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
      iconColor: parentTheme.colorScheme.onSurface.withOpacity(0.7),
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
                    color: AppColors.antiqueGold.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.wifi_off_rounded, color: AppColors.antiqueGold, size: 20),
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

  Widget _buildAchievementsSection(BuildContext context, ThemeData theme, AppState state, UserProfile profile) {
    final isDark = theme.brightness == Brightness.dark;
    final achievements = [
      _ChivalricAchievement(
        title: "Squire's Initiation",
        description: 'Conquer thy first quest level along the path of literature.',
        icon: Icons.military_tech_rounded,
        iconColor: AppColors.antiqueGold,
        currentProgress: profile.levelsCompleted,
        targetProgress: 1,
        progressLabel: '${profile.levelsCompleted}/1 Level',
        isUnlocked: profile.levelsCompleted >= 1,
      ),
      _ChivalricAchievement(
        title: 'Campfire Keeper',
        description: 'Maintain an unbroken daily reading streak for 3 days.',
        icon: Icons.local_fire_department_rounded,
        iconColor: AppColors.streakOrange,
        currentProgress: profile.streakDays,
        targetProgress: 3,
        progressLabel: '${profile.streakDays}/3 Days',
        isUnlocked: profile.streakDays >= 3,
      ),
      _ChivalricAchievement(
        title: 'Eternal Flame',
        description: 'Honor the literary crusade with a 7-day reading streak.',
        icon: Icons.whatshot_rounded,
        iconColor: const Color(0xFFFF5722),
        currentProgress: profile.streakDays,
        targetProgress: 7,
        progressLabel: '${profile.streakDays}/7 Days',
        isUnlocked: profile.streakDays >= 7,
      ),
      _ChivalricAchievement(
        title: 'Windmill Jouster',
        description: 'Triumph over 5 quest levels across classical works.',
        icon: Icons.shield_rounded,
        iconColor: theme.colorScheme.primary,
        currentProgress: profile.levelsCompleted,
        targetProgress: 5,
        progressLabel: '${profile.levelsCompleted}/5 Levels',
        isUnlocked: profile.levelsCompleted >= 5,
      ),
      _ChivalricAchievement(
        title: 'Master of Volumes',
        description: 'Master every chapter and quest within a classic grimoire.',
        icon: Icons.auto_stories_rounded,
        iconColor: const Color(0xFF673AB7),
        currentProgress: profile.booksCompleted,
        targetProgress: 1,
        progressLabel: '${profile.booksCompleted}/1 Work',
        isUnlocked: profile.booksCompleted >= 1,
      ),
      _ChivalricAchievement(
        title: 'Knight Commander',
        description: 'Conquer 3 complete literary masterpieces in thy library.',
        icon: Icons.workspace_premium_rounded,
        iconColor: const Color(0xFFE91E63),
        currentProgress: profile.booksCompleted,
        targetProgress: 3,
        progressLabel: '${profile.booksCompleted}/3 Works',
        isUnlocked: profile.booksCompleted >= 3,
      ),
      _ChivalricAchievement(
        title: 'Word Hoard',
        description: 'Save 5 marginalia annotations or vocabulary words.',
        icon: Icons.menu_book_rounded,
        iconColor: theme.colorScheme.primary,
        currentProgress: profile.notesSaved,
        targetProgress: 5,
        progressLabel: '${profile.notesSaved}/5 Saved',
        isUnlocked: profile.notesSaved >= 5,
      ),
      _ChivalricAchievement(
        title: 'Treasury of Quixoria',
        description: 'Amass 500 radiant gems in thy royal coffers.',
        icon: Icons.diamond_rounded,
        iconColor: AppColors.gemCyan,
        currentProgress: profile.gems,
        targetProgress: 500,
        progressLabel: '${profile.gems}/500 Gems',
        isUnlocked: profile.gems >= 500,
      ),
      _ChivalricAchievement(
        title: 'Golden Key Bearer',
        description: 'Possess a Golden Key to claim any grand grimoire.',
        icon: Icons.vpn_key_rounded,
        iconColor: AppColors.antiqueGold,
        currentProgress: profile.goldenKeys > 0 ? 1 : 0,
        targetProgress: 1,
        progressLabel: '${profile.goldenKeys}/1 Key',
        isUnlocked: profile.goldenKeys > 0 || profile.booksCompleted >= 1,
      ),
      _ChivalricAchievement(
        title: 'Glacial Shield',
        description: 'Equip a Streak Freeze to protect thy midnight campfire.',
        icon: Icons.ac_unit_rounded,
        iconColor: const Color(0xFF29B6F6),
        currentProgress: profile.streakFreezes > 0 ? 1 : 0,
        targetProgress: 1,
        progressLabel: '${profile.streakFreezes}/1 Freeze',
        isUnlocked: profile.streakFreezes > 0,
      ),
    ];

    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final progressFraction = achievements.isNotEmpty ? unlockedCount / achievements.length : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chivalric Trophy Hall & Honors',
                style: AppTypography.titleSmall.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.antiqueGold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.antiqueGold, width: 1),
                ),
                child: Text(
                  '$unlockedCount / ${achievements.length} Badges',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? AppColors.antiqueGold : theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Trophy Hall Container with Accordion Dropdown & Fullscreen Modal Options
        ThemedCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _isAchievementsExpanded = !_isAchievementsExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.antiqueGold.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.antiqueGold.withValues(alpha: 0.6)),
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: AppColors.antiqueGold, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'The Knight\'s Sanctuary',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$unlockedCount of ${achievements.length} chivalric honors conquered (${(progressFraction * 100).toInt()}%)',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11.5,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isAchievementsExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutBack,
                      child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.antiqueGold, size: 26),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: 7,
                  backgroundColor: theme.dividerColor.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.antiqueGold),
                ),
              ),
              const SizedBox(height: 14),

              AnimatedCrossFade(
                firstChild: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          for (int i = 0; i < 3 && i < achievements.length; i++) ...[
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: achievements[i].isUnlocked
                                    ? achievements[i].iconColor.withValues(alpha: 0.18)
                                    : theme.dividerColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: achievements[i].isUnlocked
                                      ? achievements[i].iconColor
                                      : theme.dividerColor.withValues(alpha: 0.35),
                                  width: achievements[i].isUnlocked ? 1.5 : 1.0,
                                ),
                              ),
                              child: Icon(
                                achievements[i].icon,
                                size: 16,
                                color: achievements[i].isUnlocked
                                    ? achievements[i].iconColor
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.antiqueGold),
                      label: const Text(
                        'Expand List',
                        style: TextStyle(color: AppColors.antiqueGold, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.antiqueGold.withValues(alpha: 0.14),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _isAchievementsExpanded = true);
                      },
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Open Blurred Hall of Honors',
                      icon: const Icon(Icons.fullscreen_rounded, size: 20, color: AppColors.antiqueGold),
                      onPressed: () => _openAchievementsTrophyRoom(context, theme, achievements, isDark),
                    ),
                  ],
                ),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 24),
                    for (int i = 0; i < achievements.length; i++) ...[
                      _buildAchievementRow(theme, achievements[i], isDark),
                      if (i < achievements.length - 1)
                        Divider(
                          height: 1,
                          indent: 64,
                          color: theme.dividerColor.withValues(alpha: 0.4),
                        ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.expand_less_rounded, size: 16, color: AppColors.antiqueGold),
                          label: const Text('Collapse List', style: TextStyle(color: AppColors.antiqueGold, fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isAchievementsExpanded = false);
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.open_in_full_rounded, size: 15, color: AppColors.antiqueGold),
                          label: const Text('Trophy Room Window', style: TextStyle(color: AppColors.antiqueGold, fontSize: 11, fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.antiqueGold.withValues(alpha: 0.14),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _openAchievementsTrophyRoom(context, theme, achievements, isDark),
                        ),
                      ],
                    ),
                  ],
                ),
                crossFadeState: _isAchievementsExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 280),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openAchievementsTrophyRoom(
    BuildContext context,
    ThemeData theme,
    List<_ChivalricAchievement> achievements,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.78,
              maxChildSize: 0.94,
              minChildSize: 0.5,
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
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.antiqueGold.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.emoji_events_rounded, color: AppColors.antiqueGold, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Royal Hall of Chivalric Honors',
                                style: AppTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'All chivalric achievements & laurels conquered throughout thy literary voyage',
                                style: AppTypography.bodySmall.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    for (int i = 0; i < achievements.length; i++) ...[
                      _buildAchievementRow(theme, achievements[i], isDark),
                      if (i < achievements.length - 1)
                        Divider(
                          height: 1,
                          indent: 64,
                          color: theme.dividerColor.withValues(alpha: 0.4),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementRow(ThemeData theme, _ChivalricAchievement item, bool isDark) {
    final progressFraction = (item.currentProgress / item.targetProgress).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Unique Achievement Icon Badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.isUnlocked
                  ? item.iconColor.withValues(alpha: isDark ? 0.22 : 0.12)
                  : (isDark ? const Color(0xFF2C2C2C) : AppColors.parchmentWarm),
              border: Border.all(
                color: item.isUnlocked
                    ? item.iconColor
                    : (isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.borderLight),
                width: item.isUnlocked ? 2.0 : 1.2,
              ),
              boxShadow: item.isUnlocked
                  ? [
                      BoxShadow(
                        color: item.iconColor.withValues(alpha: isDark ? 0.35 : 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                item.icon,
                size: 24,
                color: item.isUnlocked
                    ? item.iconColor
                    : (isDark ? Colors.white38 : AppColors.inkLight),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title, Description, Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: item.isUnlocked
                              ? (isDark ? Colors.white : AppColors.inkDark)
                              : (isDark ? Colors.white54 : AppColors.inkMedium),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (item.isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.antiqueGold,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 12, color: theme.colorScheme.primary),
                            const SizedBox(width: 3),
                            Text(
                              'UNLOCKED',
                              style: AppTypography.labelSmall.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        item.progressLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark ? const Color(0xFFDCD6CD) : AppColors.inkLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? const Color(0xFF9E9E9E) : AppColors.inkLight,
                    fontSize: 11.5,
                  ),
                ),
                if (!item.isUnlocked) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressFraction,
                      minHeight: 5,
                      backgroundColor: isDark ? const Color(0xFF2C2C2C) : AppColors.parchmentWarm,
                      valueColor: AlwaysStoppedAnimation<Color>(item.iconColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    Color? surfaceColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor ?? AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Builder(
            builder: (ctx) {
              final sTheme = Theme.of(ctx);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: sTheme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(
                      color: sTheme.colorScheme.onSurface.withOpacity(0.68),
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
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
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            side: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
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
          activeTrackColor: AppColors.antiqueGold.withOpacity(0.5),
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
                    state.triggerExpeditionReady();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Daily reading reminder scheduled for ${item.$2} (${item.$1}).'),
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
    _showFluidSettingsMenu(
      context: context,
      title: 'About Quixoria',
      subtitle: 'The grand vision, realm features, and upcoming scholar roadmaps',
      icon: Icons.auto_stories_rounded,
      iconColor: AppColors.antiqueGold,
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

class _ChivalricAchievement {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final int currentProgress;
  final int targetProgress;
  final String progressLabel;
  final bool isUnlocked;

  const _ChivalricAchievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.currentProgress,
    required this.targetProgress,
    required this.progressLabel,
    required this.isUnlocked,
  });
}
