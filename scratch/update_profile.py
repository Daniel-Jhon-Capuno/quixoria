with open('lib/features/profile/profile_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add imports
old_import = "import '../../core/services/ambience_service.dart';"
new_import = """import '../../core/services/ambience_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/sound_service.dart';"""
assert old_import in content, "old_import not found"
content = content.replace(old_import, new_import, 1)

# 2. Add menu tiles to _buildSettingsCategories
old_categories_end = """        _buildMenuTile(
          icon: Icons.more_horiz_rounded,
          iconColor: theme.colorScheme.onSurface.withOpacity(0.65),
          title: 'And Other Things',
          subtitle: 'Offline rules notice, alerts, creed, legal & data reset',
          onTap: () => _openOtherThingsMenu(context),
        ),
      ],
    );"""

new_categories_end = """        _buildMenuTile(
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
    );"""
assert old_categories_end in content, "old_categories_end not found"
content = content.replace(old_categories_end, new_categories_end, 1)

# 3. Add Account Session with Sign Out to _openProfilesMenu
old_profile_card_end = """                          Text(
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
        ];"""

new_profile_card_end = """                          Text(
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
                    color: AppColors.energyRed.withOpacity(0.12),
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
                trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.energyRed),
                onTap: () {
                  _showSignOutWarningDialog(context, state);
                },
              ),
            ],
          ),
        ];"""
assert old_profile_card_end in content, "old_profile_card_end not found"
content = content.replace(old_profile_card_end, new_profile_card_end, 1)

# 4. Add _openAboutQuixoriaMenu and _showSignOutWarningDialog
new_methods = """
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
                icon: Icons.menu_book_rounded,
                iconColor: AppColors.antiqueGold,
                title: 'Curated Public-Domain Canon',
                desc: 'Full pedagogical chapters from Don Quixote, Frankenstein, The Odyssey, The Prophet, Pride and Prejudice, The Time Machine, and Sherlock Holmes.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
                icon: Icons.shield_rounded,
                iconColor: AppColors.gemCyan,
                title: 'Interactive 3D Mascot Companion',
                desc: 'A responsive Don Quixote companion with 7 emotive expressions (idle, happy, excited, thinking, sad, determined, confident) providing hints and celebration.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
                icon: Icons.alt_route_rounded,
                iconColor: AppColors.deepForest,
                title: 'Winding Skill Path & Level Map',
                desc: 'A visual zigzag journey of nodes with bouncing active milestones, unread task badges, and checkpoint evaluations.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
                icon: Icons.psychology_rounded,
                iconColor: AppColors.vermillion,
                title: 'Pedagogical Exercise Engine',
                desc: 'Interactive Cloze deletion tests, contextual matching pairs, word bank mastery, and Socratic comprehension queries.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.vermillion,
                title: 'Campfire Habit Streaks',
                desc: 'Daily reading habits preserved with streak freezes, midnight extinguishing warnings, and gem-based rekindling.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
                icon: Icons.music_note_rounded,
                iconColor: AppColors.gemCyan,
                title: 'Atmospheric Lo-Fi Soundscapes',
                desc: '4 continuous ambient soundscapes: Classical Lute, Knight’s Hearth, Rainy Library, and Ancient Scriptorium.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
                icon: Icons.wifi_off_rounded,
                iconColor: AppColors.antiqueGold,
                title: 'Real-Time Offline-First Engine',
                desc: 'Read anywhere with zero connectivity; automated real-time network detection auto-dismisses warnings when Wi-Fi returns.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
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
                icon: Icons.cloud_sync_rounded,
                iconColor: AppColors.gemCyan,
                title: 'Cloud Synchronization & Firebase Backup',
                desc: 'Seamless multi-device cloud saves, letting you switch between phones, tablets, and desktop without losing a single line.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
                icon: Icons.sports_kabaddi_rounded,
                iconColor: AppColors.vermillion,
                title: 'Literary Jousts & Guild Tournaments',
                desc: 'Weekly scholar leagues, multiplayer comprehension battles, and guild cooperative reading milestones with friends.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
                icon: Icons.record_voice_over_rounded,
                iconColor: AppColors.antiqueGold,
                title: 'Theatrical Voiced Storybook Narration',
                desc: 'Full-cast voice recordings and character dialogue dramatization for rich auditory immersion.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
                icon: Icons.rate_review_outlined,
                iconColor: AppColors.deepForest,
                title: 'Scholars’ Marginalia Exchange',
                desc: 'Leave thoughtful notes in chapter margins and discover reflections written by readers worldwide.',
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.3)),
              _buildAboutFeatureTile(
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
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
"""

content = content + "\n" + new_methods

with open('lib/features/profile/profile_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("ProfileScreen updated successfully!")
