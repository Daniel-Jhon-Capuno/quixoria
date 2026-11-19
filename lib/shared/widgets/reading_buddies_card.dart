import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/community_service.dart';
import '../../core/state/app_state.dart';
import '../../models/friend_streak.dart';
import 'follow_action_helper.dart';
import 'themed_card.dart';

/// Reading Buddies card showing ONLY real Supabase mutual followers
/// (users you follow who ALSO follow you back).
class ReadingBuddiesCard extends StatelessWidget {
  const ReadingBuddiesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = state.activeThemePreset.effectivePrimary(isDarkMode: isDark);
    final myHandle = AuthService.instance.accountKey.trim().isNotEmpty
        ? AuthService.instance.accountKey
        : state.profile.email;

    return ListenableBuilder(
      listenable: CommunityService.instance,
      builder: (context, _) {
        final community = CommunityService.instance;
        final mutualHandles = community.mutualHandles;

        // Only display buddies who are real mutual followers in Supabase
        final buddies = state.friendStreaks.where((b) {
          final norm = CommunityService.normalizeHandle(b.handle);
          return mutualHandles.contains(norm);
        }).toList();

        // Include any real mutual from Supabase not yet materialized in state
        final existingHandles =
            buddies.map((b) => CommunityService.normalizeHandle(b.handle)).toSet();
        for (final h in mutualHandles) {
          if (!existingHandles.contains(h)) {
            buddies.add(
              FriendStreak(
                id: 'mutual_$h',
                name: community.displayNameForHandle(h),
                handle: '@$h',
                streakDays: 1,
                youReadToday: false,
                friendReadToday: false,
              ),
            );
          }
        }

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
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.people_alt_rounded,
                      color: accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reading Buddies',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Mutual Followers • ${buddies.length} connected',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (buddies.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.handshake_outlined,
                        color: accent.withValues(alpha: 0.8),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No mutual Reading Buddies yet. Follow real scholars in the Community Feed or Leaderboard — once they follow you back, you\'ll appear here together!',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11.5,
                            height: 1.38,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...buddies.map(
                  (buddy) => _buildBuddyRow(
                    context,
                    state,
                    buddy,
                    accent,
                    isDark,
                    myHandle,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBuddyRow(
    BuildContext context,
    AppState state,
    FriendStreak buddy,
    Color accent,
    bool isDark,
    String myHandle,
  ) {
    final theme = Theme.of(context);
    final canNudge = state.canNudgeBuddy(buddy);
    final nudgedToday = !buddy.friendReadToday && !canNudge;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: buddy.isBothCompleteToday
              ? accent.withValues(alpha: 0.5)
              : theme.dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: accent.withValues(alpha: 0.18),
            child: Text(
              buddy.name.isNotEmpty ? buddy.name[0].toUpperCase() : 'S',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: accent,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        buddy.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.streakOrange.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            size: 12,
                            color: AppColors.streakOrange,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${buddy.streakDays}d',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.streakOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  buddy.isBothCompleteToday
                      ? 'Mutual Buddy • Both read today!'
                      : 'Mutual Buddy • ${buddy.handle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (buddy.friendReadToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Done ✓',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.successGreen,
                ),
              ),
            )
          else if (nudgedToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Nudged',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            )
          else
            InkWell(
              onTap: () {
                final ok = state.nudgeReadingBuddy(buddy.id);
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Nudged ${buddy.name} to keep your shared streak alive!'),
                      backgroundColor: accent,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Nudge',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Unfollow Buddy',
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(
              Icons.person_remove_outlined,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
            onPressed: () {
              FollowActionHelper.toggleFollowWithConfirm(
                context,
                myHandle: myHandle,
                targetHandle: buddy.handle,
                displayName: buddy.name,
              );
            },
          ),
        ],
      ),
    );
  }
}
