import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/community_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/state/app_state.dart';

/// Shared helper for following/unfollowing real Supabase scholars.
///
/// Rules:
/// - If you are unfollowing a **mutual** follower (both follow each other),
///   a confirmation dialog appears warning that they will also be removed
///   from Reading Buddies.
/// - If you are the **only** one following them (one-way follow), unfollowing
///   happens immediately with NO popup.
/// - Following a user happens immediately and syncs mutual Reading Buddies.
class FollowActionHelper {
  static Future<String?> toggleFollowWithConfirm(
    BuildContext context, {
    required String myHandle,
    required String targetHandle,
    String? displayName,
  }) async {
    final community = CommunityService.instance;
    final normTarget = CommunityService.normalizeHandle(targetHandle);
    final label = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : community.displayNameForHandle(normTarget);

    final isFollowing = community.isFollowing(normTarget);
    final isMutual = community.isMutual(normTarget);

    // Only prompt confirmation when unfollowing a MUTUAL Reading Buddy
    if (isFollowing && isMutual) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) {
          final theme = Theme.of(dialogCtx);
          return AlertDialog(
            backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.person_remove_rounded, color: AppColors.energyRed, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Unfollow $label?',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            content: Text(
              'You and $label follow each other as mutual Reading Buddies. Are you sure you want to unfollow them? They will be removed from your Reading Buddies list.',
              style: AppTypography.bodySmall.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.energyRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: const Text('Unfollow', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      );
      if (confirmed != true) return null;
    }

    HapticService.instance.light();
    final err = await community.toggleFollow(
      myHandle: myHandle,
      targetInput: normTarget,
    );
    if (context.mounted && err == null) {
      context.read<AppState>().syncMutualReadingBuddies(
            community.mutualHandles,
            community.displayNameForHandle,
          );
    }
    return err;
  }
}
