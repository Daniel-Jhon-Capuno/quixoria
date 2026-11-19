import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/community_service.dart';
import '../../core/state/app_state.dart';
import '../../models/app_notification.dart';
import 'follow_action_helper.dart';

class NotificationCenterSheet extends StatelessWidget {
  final AppState state;

  const NotificationCenterSheet({super.key, required this.state});

  static void show(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NotificationCenterSheet(state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifications = state.notifications;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? AppColors.parchmentCream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Clean Header Row (No Demo Banners or Extra Clutter)
          Row(
            children: [
              const Icon(Icons.notifications_rounded, color: AppColors.antiqueGold, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Notifications',
                  style: AppTypography.titleLarge.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (notifications.any((n) => !n.isRead)) ...[
                InkWell(
                  onTap: () => state.markAllNotificationsRead(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Mark read',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (notifications.isNotEmpty)
                InkWell(
                  onTap: () => state.clearNotifications(),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Notifications List or Clean Empty State
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 46,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No notifications',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final notif = notifications[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: notif.isRead
                              ? theme.cardTheme.color
                              : AppColors.goldLight.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: notif.isRead ? AppColors.borderLight : AppColors.borderGold,
                            width: notif.isRead ? 1 : 1.3,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildIcon(context, notif.type),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notif.title,
                                          style: AppTypography.titleSmall.copyWith(
                                            fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        notif.timeAgo,
                                        style: AppTypography.labelSmall.copyWith(
                                          color: AppColors.inkLight,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (notif.relatedWorkTitle != null) ...[
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.sageLight.withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        notif.relatedWorkTitle!,
                                        style: AppTypography.labelSmall.copyWith(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    notif.message,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.inkMedium,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (notif.type == NotificationType.legendaryChestReward &&
                                      notif.isClaimable) ...[
                                    const SizedBox(height: 10),
                                    if (!notif.isClaimed && !state.profile.hasClaimedTop1Chest)
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFFFB703),
                                            foregroundColor: const Color(0xFF1F1600),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                          ),
                                          icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                                          label: const Text(
                                            'Open Legendary Chest & Claim',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                          onPressed: () {
                                            final claimed = state.claimTop1LegendaryChest();
                                            if (claimed && context.mounted) {
                                              _showLegendaryChestDialog(context);
                                            }
                                          },
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.successGreen.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: AppColors.successGreen.withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle_rounded,
                                              size: 14,
                                              color: AppColors.successGreen,
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              'Legendary Chest Claimed!',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.successGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                  if (notif.type == NotificationType.newFollower &&
                                      notif.actorHandle != null &&
                                      notif.actorHandle!.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    ListenableBuilder(
                                      listenable: CommunityService.instance,
                                      builder: (context, _) {
                                        final community = CommunityService.instance;
                                        final handle = notif.actorHandle!;
                                        final isNowFollowing = community.isFollowing(handle);
                                        final myHandle = AuthService.instance.accountKey.trim().isNotEmpty
                                            ? AuthService.instance.accountKey
                                            : state.profile.email;

                                        if (isNowFollowing) {
                                          return Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.successGreen.withValues(alpha: 0.14),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: AppColors.successGreen.withValues(alpha: 0.4),
                                                  ),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.handshake_rounded,
                                                      size: 14,
                                                      color: AppColors.successGreen,
                                                    ),
                                                    SizedBox(width: 5),
                                                    Text(
                                                      'Reading Buddies ✓',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w800,
                                                        color: AppColors.successGreen,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Spacer(),
                                              TextButton(
                                                onPressed: () => state.removeNotification(notif.id),
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                  minimumSize: const Size(0, 28),
                                                ),
                                                child: Text(
                                                  'Dismiss',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }

                                        return Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: theme.colorScheme.primary,
                                                  foregroundColor: theme.colorScheme.onPrimary,
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                                                label: const Text(
                                                  'Follow Back',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                onPressed: () async {
                                                  await FollowActionHelper.toggleFollowWithConfirm(
                                                    context,
                                                    myHandle: myHandle,
                                                    targetHandle: handle,
                                                    displayName: community.displayNameForHandle(handle),
                                                  );
                                                  notif.isRead = true;
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'You and ${community.displayNameForHandle(handle)} are now mutual Reading Buddies!',
                                                        ),
                                                        backgroundColor: AppColors.successGreen,
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                side: BorderSide(
                                                  color: theme.dividerColor.withValues(alpha: 0.6),
                                                ),
                                              ),
                                              onPressed: () => state.removeNotification(notif.id),
                                              child: Text(
                                                'Remove',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ],
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
    );
  }

  Widget _buildIcon(BuildContext context, NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.lowEnergy:
        icon = Icons.battery_alert_rounded;
        color = AppColors.energyRed;
        break;
      case NotificationType.energyRestored:
        icon = Icons.battery_charging_full_rounded;
        color = state.activeThemePreset.successColor;
        break;
      case NotificationType.streakExpiring:
        icon = Icons.local_fire_department_rounded;
        color = AppColors.streakOrange;
        break;
      case NotificationType.streakLost:
        icon = Icons.nightlight_round;
        color = const Color(0xFF8E44AD);
        break;
      case NotificationType.streakRekindled:
        icon = Icons.whatshot_rounded;
        color = AppColors.streakOrange;
        break;
      case NotificationType.readingGoalAchieved:
        icon = Icons.timer_rounded;
        color = AppColors.antiqueGold;
        break;
      case NotificationType.expeditionReady:
        icon = Icons.explore_rounded;
        color = Theme.of(context).colorScheme.primary;
        break;
      case NotificationType.goldenKeyAwarded:
        icon = Icons.vpn_key_rounded;
        color = AppColors.antiqueGold;
        break;
      case NotificationType.marginaliaReflection:
        icon = Icons.edit_note_rounded;
        color = Theme.of(context).colorScheme.secondary;
        break;
      case NotificationType.literatureRecommendation:
        icon = Icons.auto_stories_rounded;
        color = Theme.of(context).colorScheme.primary;
        break;
      case NotificationType.themeEquipped:
        icon = Icons.palette_rounded;
        color = AppColors.antiqueGold;
        break;
      case NotificationType.offlineWarning:
        icon = Icons.wifi_off_rounded;
        color = AppColors.streakOrange;
        break;
      case NotificationType.leaderboardRankUp:
        icon = Icons.emoji_events_rounded;
        color = AppColors.antiqueGold;
        break;
      case NotificationType.legendaryChestReward:
        icon = Icons.card_giftcard_rounded;
        color = const Color(0xFFFFB703);
        break;
      case NotificationType.newFollower:
        icon = Icons.person_add_alt_1_rounded;
        color = Theme.of(context).colorScheme.primary;
        break;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  void _showLegendaryChestDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1F1C14) : const Color(0xFFFFFBF0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: const BorderSide(color: Color(0xFFFFB703), width: 2.0),
          ),
          contentPadding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE066), Color(0xFFFFB703), Color(0xFFD4A338)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB703).withValues(alpha: 0.55),
                      blurRadius: 22,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 40,
                  color: Color(0xFF1F1600),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Legendary Chest Opened!',
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFD4A338),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'All hail our Top 1% Leaderboard Champion! Your legendary rewards have been added to your account:',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 12.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),
              _rewardRow(ctx, Icons.favorite_rounded, AppColors.energyRed, '+5 Hearts (Energy)'),
              const SizedBox(height: 8),
              _rewardRow(ctx, Icons.diamond_rounded, AppColors.gemCyan, '+5,000 Gems'),
              const SizedBox(height: 8),
              _rewardRow(ctx, Icons.workspace_premium_rounded, const Color(0xFFFFB703),
                  'Title: Sovereign of the Realm'),
              const SizedBox(height: 8),
              _rewardRow(ctx, Icons.verified_rounded, AppColors.antiqueGold,
                  'Profile Badge: Top 1% Champion'),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB703),
                    foregroundColor: const Color(0xFF1F1600),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'Awesome!',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _rewardRow(BuildContext context, IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
