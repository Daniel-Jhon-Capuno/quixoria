import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/state/app_state.dart';
import '../../models/app_notification.dart';

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
    final userName = state.profile.name;
    final successColor = state.activeThemePreset.successColor;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? AppColors.parchmentCream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
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

          // Header Row
          Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: AppColors.antiqueGold, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Guild Dispatches & Alerts',
                      style: AppTypography.titleLarge.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Personalized chronicles for $userName',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.inkLight, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (notifications.any((n) => !n.isRead)) ...[
                const SizedBox(width: 6),
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
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Live Connectivity & Notification Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: state.isOnline
                  ? successColor.withValues(alpha: 0.12)
                  : AppColors.streakOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: state.isOnline ? successColor : AppColors.streakOrange,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        state.isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                        size: 18,
                        color: state.isOnline ? successColor : AppColors.streakOrange,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          state.isOnline
                              ? 'Connected • Real-Time Alerts Active'
                              : 'Offline Reading Mode',
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: state.isOnline ? successColor : AppColors.streakOrange,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (state.isOnline ? successColor : AppColors.streakOrange).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.isOnline ? 'LIVE' : 'OFFLINE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: state.isOnline ? successColor : AppColors.streakOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Notifications List
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.done_all_rounded, size: 40, color: AppColors.inkLight),
                        const SizedBox(height: 8),
                        Text(
                          'No alerts right now. Peace reigns in the realm.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
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
}