import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/community_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/state/app_state.dart';
import '../../models/cosmetic_item.dart';
import 'duo_button.dart';
import 'follow_action_helper.dart';
import 'framed_mascot_avatar.dart';
import 'themed_card.dart';

class ShowcaseTrophy {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String rarity;

  const ShowcaseTrophy({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.rarity = 'RARE',
  });
}

class ProfileTrophyCatalog {
  static List<ShowcaseTrophy> unlockedFor(AppState state) {
    final p = state.profile;
    final list = <ShowcaseTrophy>[];

    if (p.hasEarnedTop1Percent) {
      list.add(const ShowcaseTrophy(
        id: 'top_1_champion',
        title: 'Top 1% Champion',
        subtitle: 'Reached Apex Rank #1 on the Global Leaderboard',
        icon: Icons.workspace_premium_rounded,
        color: Color(0xFFD4A338),
        rarity: 'MYTHIC',
      ));
    }

    for (final bookId in p.defeatedBossBooks) {
      final title = state.catalog
              .where((b) => b.id == bookId)
              .map((b) => b.title)
              .firstOrNull ??
          'Classic Tome';
      list.add(ShowcaseTrophy(
        id: 'boss_$bookId',
        title: 'Boss Slayer',
        subtitle: 'Conquered $title Boss Battle',
        icon: Icons.shield_rounded,
        color: const Color(0xFFDC2626),
        rarity: 'LEGENDARY',
      ));
    }

    if (p.longestStreak >= 30 || p.streakDays >= 30) {
      list.add(const ShowcaseTrophy(
        id: 'streak_30',
        title: 'Eternal Flame',
        subtitle: '30+ Day Reading Streak',
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFEA580C),
        rarity: 'EPIC',
      ));
    } else if (p.longestStreak >= 7 || p.streakDays >= 7) {
      list.add(const ShowcaseTrophy(
        id: 'streak_7',
        title: 'Flame Keeper',
        subtitle: '7+ Day Reading Streak',
        icon: Icons.local_fire_department_rounded,
        color: AppColors.streakOrange,
        rarity: 'RARE',
      ));
    }

    if (p.booksCompleted >= 5) {
      list.add(const ShowcaseTrophy(
        id: 'books_5',
        title: 'Grand Archivist',
        subtitle: 'Completed 5+ Literary Works',
        icon: Icons.auto_stories_rounded,
        color: Color(0xFF7C3AED),
        rarity: 'EPIC',
      ));
    } else if (p.booksCompleted >= 1) {
      list.add(const ShowcaseTrophy(
        id: 'books_1',
        title: 'Tome Conqueror',
        subtitle: 'Completed First Classic Book',
        icon: Icons.menu_book_rounded,
        color: AppColors.successGreen,
        rarity: 'RARE',
      ));
    }

    if (p.weeklyXp >= 1000) {
      list.add(const ShowcaseTrophy(
        id: 'xp_1000',
        title: 'Millennium Scholar',
        subtitle: 'Earned 1,000+ Weekly XP',
        icon: Icons.bolt_rounded,
        color: AppColors.practiceBlue,
        rarity: 'EPIC',
      ));
    }

    if (p.goldenKeys >= 1) {
      list.add(ShowcaseTrophy(
        id: 'golden_key',
        title: 'Keymaster',
        subtitle: '${p.goldenKeys} Golden Key${p.goldenKeys == 1 ? '' : 's'} Forged',
        icon: Icons.vpn_key_rounded,
        color: AppColors.antiqueGold,
        rarity: 'LEGENDARY',
      ));
    }

    // Always-available starter crest so every scholar has a trophy to display
    list.add(const ShowcaseTrophy(
      id: 'founding_scholar',
      title: 'Knight Errant',
      subtitle: 'Enlisted in the Realm of Quixoria',
      icon: Icons.military_tech_rounded,
      color: Color(0xFF0D9488),
      rarity: 'CLASSIC',
    ));

    return list;
  }

  static List<ShowcaseTrophy> pinnedOrDefault(AppState state) {
    final unlocked = unlockedFor(state);
    final byId = {for (final t in unlocked) t.id: t};
    final result = <ShowcaseTrophy>[];

    for (final id in state.pinnedTrophyIds) {
      final t = byId[id];
      if (t != null && !result.any((e) => e.id == t.id)) {
        result.add(t);
      }
    }
    for (final t in unlocked) {
      if (result.length >= 3) break;
      if (!result.any((e) => e.id == t.id)) {
        result.add(t);
      }
    }
    return result.take(3).toList();
  }
}

/// Pinned Trophy Showcase Shelf displayed on the user's Profile screen.
class ProfileTrophyShelfCard extends StatelessWidget {
  const ProfileTrophyShelfCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unlocked = ProfileTrophyCatalog.unlockedFor(state);
    final displayed = ProfileTrophyCatalog.pinnedOrDefault(state);

    return ThemedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.antiqueGold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.antiqueGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trophy Showcase Shelf',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${unlocked.length} unlocked • Pin up to 3 for your Public Card',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  HapticService.instance.light();
                  _openPinTrophiesSheet(context);
                },
                icon: const Icon(Icons.push_pin_rounded, size: 15),
                label: const Text(
                  'Pin',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(3, (index) {
              final trophy = index < displayed.length ? displayed[index] : null;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  child: trophy != null
                      ? _buildTrophySlot(trophy, theme, isDark)
                      : _buildEmptySlot(context, theme, isDark),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophySlot(ShowcaseTrophy trophy, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            trophy.color.withValues(alpha: isDark ? 0.24 : 0.14),
            trophy.color.withValues(alpha: isDark ? 0.08 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: trophy.color.withValues(alpha: 0.5), width: 1.4),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: trophy.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(trophy.icon, color: trophy.color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            trophy.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: trophy.color.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              trophy.rarity,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                color: trophy.color,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlot(BuildContext context, ThemeData theme, bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openPinTrophiesSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.45),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              'Pin Slot',
              style: AppTypography.labelSmall.copyWith(
                fontSize: 10.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPinTrophiesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PinTrophiesSheet(),
    );
  }
}

class _PinTrophiesSheet extends StatelessWidget {
  const _PinTrophiesSheet();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final unlocked = ProfileTrophyCatalog.unlockedFor(state);
    final pinned = state.pinnedTrophyIds;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.72,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.push_pin_rounded, color: AppColors.antiqueGold, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pin Showcase Trophies',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Select up to 3 trophies (${pinned.length}/3 pinned)',
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: unlocked.length,
              itemBuilder: (context, idx) {
                final trophy = unlocked[idx];
                final isPinned = pinned.contains(trophy.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isPinned
                        ? trophy.color.withValues(alpha: 0.14)
                        : (theme.cardTheme.color ?? theme.colorScheme.surface),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPinned
                          ? trophy.color
                          : theme.dividerColor.withValues(alpha: 0.45),
                      width: isPinned ? 1.8 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    onTap: () {
                      HapticService.instance.light();
                      state.togglePinTrophy(trophy.id);
                    },
                    leading: CircleAvatar(
                      backgroundColor: trophy.color.withValues(alpha: 0.2),
                      child: Icon(trophy.icon, color: trophy.color, size: 20),
                    ),
                    title: Text(
                      trophy.title,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      trophy.subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                    trailing: Icon(
                      isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                      color: isPinned ? trophy.color : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Public Player Showcase Card opened when tapping any scholar on the Leaderboard.
class PublicPlayerCardSheet extends StatelessWidget {
  final String displayName;
  final String? targetHandle;
  final String scholarTitle;
  final String frameId;
  final int rank;
  final int weeklyXp;
  final int streakDays;
  final int booksCompleted;
  final int levelsCompleted;
  final bool isMe;

  const PublicPlayerCardSheet({
    super.key,
    required this.displayName,
    this.targetHandle,
    required this.scholarTitle,
    required this.frameId,
    required this.rank,
    required this.weeklyXp,
    required this.streakDays,
    required this.booksCompleted,
    required this.levelsCompleted,
    this.isMe = false,
  });

  static void show(
    BuildContext context, {
    required String displayName,
    String? targetHandle,
    required String scholarTitle,
    required String frameId,
    required int rank,
    required int weeklyXp,
    required int streakDays,
    required int booksCompleted,
    required int levelsCompleted,
    bool isMe = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PublicPlayerCardSheet(
        displayName: displayName,
        targetHandle: targetHandle,
        scholarTitle: scholarTitle,
        frameId: frameId,
        rank: rank,
        weeklyXp: weeklyXp,
        streakDays: streakDays,
        booksCompleted: booksCompleted,
        levelsCompleted: levelsCompleted,
        isMe: isMe,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final frame = CosmeticCatalog.frameById(frameId);
    final resolvedTarget = (targetHandle != null && targetHandle!.trim().isNotEmpty)
        ? targetHandle!.trim()
        : displayName.trim();
    final myHandle = AuthService.instance.accountKey.trim().isNotEmpty
        ? AuthService.instance.accountKey
        : state.profile.email;

    // Derive visible showcase badges for this scholar
    final badges = <ShowcaseTrophy>[];
    if (isMe) {
      badges.addAll(ProfileTrophyCatalog.pinnedOrDefault(state));
    } else {
      if (rank == 1) {
        badges.add(const ShowcaseTrophy(
          id: 'top_1',
          title: 'Top 1% Champion',
          subtitle: 'Apex Scholar',
          icon: Icons.workspace_premium_rounded,
          color: Color(0xFFD4A338),
          rarity: 'MYTHIC',
        ));
      }
      if (streakDays >= 7) {
        badges.add(ShowcaseTrophy(
          id: 'streak',
          title: '$streakDays-Day Flame',
          subtitle: 'Dedicated Reader',
          icon: Icons.local_fire_department_rounded,
          color: AppColors.streakOrange,
          rarity: 'EPIC',
        ));
      }
      if (booksCompleted >= 1) {
        badges.add(ShowcaseTrophy(
          id: 'books',
          title: '$booksCompleted Book${booksCompleted == 1 ? '' : 's'}',
          subtitle: 'Tome Conqueror',
          icon: Icons.menu_book_rounded,
          color: AppColors.successGreen,
          rarity: 'RARE',
        ));
      }
      if (badges.isEmpty) {
        badges.add(const ShowcaseTrophy(
          id: 'scholar',
          title: 'Knight Errant',
          subtitle: 'Quixoria Scholar',
          icon: Icons.military_tech_rounded,
          color: Color(0xFF0D9488),
          rarity: 'CLASSIC',
        ));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Banner + Avatar Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.72),
                      AppColors.antiqueGold.withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.antiqueGold.withValues(alpha: 0.7)),
                          ),
                          child: Text(
                            'RANK #$rank',
                            style: const TextStyle(
                              color: AppColors.antiqueGold,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        if (isMe)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.antiqueGold,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'YOUR CARD',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FramedMascotAvatar(
                      frame: frame,
                      size: 74,
                      monogram: displayName,
                      showMascot: false,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      scholarTitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4 Key Stats
              Row(
                children: [
                  _miniStat('Weekly XP', '$weeklyXp', Icons.bolt_rounded, AppColors.antiqueGold, theme, isDark),
                  const SizedBox(width: 8),
                  _miniStat('Streak', '${streakDays}d', Icons.local_fire_department_rounded, AppColors.streakOrange, theme, isDark),
                  const SizedBox(width: 8),
                  _miniStat('Books', '$booksCompleted', Icons.menu_book_rounded, AppColors.successGreen, theme, isDark),
                  const SizedBox(width: 8),
                  _miniStat('Levels', '$levelsCompleted', Icons.flag_rounded, AppColors.practiceBlue, theme, isDark),
                ],
              ),
              const SizedBox(height: 14),

              // Trophy Badges Row
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SHOWCASE TROPHIES',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: badges.take(3).map((b) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: b.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: b.color.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(b.icon, size: 15, color: b.color),
                        const SizedBox(width: 5),
                        Text(
                          b.title,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Action CTA: Real Supabase Follow / Mutual Reading Buddy Toggle
              if (!isMe)
                ListenableBuilder(
                  listenable: CommunityService.instance,
                  builder: (context, _) {
                    final community = CommunityService.instance;
                    final isFollowing = community.isFollowing(resolvedTarget);
                    final followsMe = community.isFollowedBy(resolvedTarget);
                    final isMutual = isFollowing && followsMe;

                    final String buttonLabel;
                    final IconData buttonIcon;
                    if (isMutual) {
                      buttonLabel = 'Mutual Reading Buddy ✓';
                      buttonIcon = Icons.handshake_rounded;
                    } else if (isFollowing) {
                      buttonLabel = 'Following (Waiting for Follow Back)';
                      buttonIcon = Icons.check_circle_outline_rounded;
                    } else if (followsMe) {
                      buttonLabel = 'Follow Back to Become Buddies';
                      buttonIcon = Icons.person_add_alt_1_rounded;
                    } else {
                      buttonLabel = 'Follow Scholar';
                      buttonIcon = Icons.person_add_alt_1_rounded;
                    }

                    return DuoButton(
                      text: buttonLabel,
                      icon: buttonIcon,
                      variant: isFollowing ? DuoButtonVariant.outline : DuoButtonVariant.primary,
                      onPressed: () async {
                        final err = await FollowActionHelper.toggleFollowWithConfirm(
                          context,
                          myHandle: myHandle,
                          targetHandle: resolvedTarget,
                          displayName: displayName,
                        );
                        if (err != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err)),
                          );
                        }
                      },
                    );
                  },
                )
              else
                DuoButton(
                  text: 'Close Showcase',
                  variant: DuoButtonVariant.outline,
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.14 : 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 9.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
