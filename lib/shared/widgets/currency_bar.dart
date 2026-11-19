import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/streak_service.dart';
import '../../core/state/app_state.dart';
import 'notification_center_sheet.dart';
import 'reward_celebration.dart';
import 'streak_overview_card.dart';
import 'sun_moon_toggle.dart';

class CurrencyBar extends StatelessWidget {
  final VoidCallback? onEnergyTap;
  final VoidCallback? onGemsTap;
  final VoidCallback? onKeysTap;

  static final GlobalKey streakKey = GlobalKey(debugLabel: 'currency_streak');
  static final GlobalKey energyKey = GlobalKey(debugLabel: 'currency_energy');
  static final GlobalKey gemsKey = GlobalKey(debugLabel: 'currency_gems');
  static final GlobalKey keysKey = GlobalKey(debugLabel: 'currency_keys');

  const CurrencyBar({
    super.key,
    this.onEnergyTap,
    this.onGemsTap,
    this.onKeysTap,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    final unreadCount = state.notifications.where((n) => !n.isRead).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? AppColors.parchmentCream,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.3), width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dynamic Automatic Streak Flame (Active / At Risk / Lost)
              Builder(
                builder: (_) {
                  final sStatus = state.streakStatus;
                  final flameIcon = sStatus == StreakStatus.activeToday
                      ? Icons.local_fire_department_rounded
                      : Icons.local_fire_department_outlined;
                  final flameColor = switch (sStatus) {
                    StreakStatus.activeToday => AppColors.streakOrange,
                    StreakStatus.atRiskToday => const Color(0xFFF59E0B),
                    StreakStatus.broken => AppColors.inkLight,
                    StreakStatus.fresh => AppColors.inkLight,
                  };
                  final tip = switch (sStatus) {
                    StreakStatus.activeToday =>
                      'Streak Active Today: ${profile.streakDays} days!',
                    StreakStatus.atRiskToday =>
                      'Streak At Risk (${profile.streakDays}d) — Complete a chapter or quiz today!',
                    StreakStatus.broken =>
                      'Campfire Cold — Tap to view weekly streak & repair options.',
                    StreakStatus.fresh =>
                      'Complete your first chapter or quiz to start your streak!',
                  };
                  return _BouncyCurrencyPill(
                    key: streakKey,
                    currencyType: RewardCurrencyType.streakFlame,
                    icon: flameIcon,
                    iconColor: flameColor,
                    value: '${profile.streakDays}',
                    tooltip: tip,
                    onTap: () => StreakOverviewCard.showSheet(context),
                  );
                },
              ),

              // Energy
              _BouncyCurrencyPill(
                key: energyKey,
                currencyType: RewardCurrencyType.heart,
                icon: Icons.favorite_rounded,
                iconColor: profile.isPremium ? AppColors.antiqueGold : AppColors.energyRed,
                value: profile.isPremium ? 'MAX' : '${profile.energy}/${profile.maxEnergy}',
                tooltip: profile.isPremium
                    ? 'Caballero Pass: Infinite Energy!'
                    : 'Energy: ${profile.energy}/${profile.maxEnergy}',
                onTap: onEnergyTap ?? () => _showEnergyRefillModal(context, state),
              ),

              // Gems
              _BouncyCurrencyPill(
                key: gemsKey,
                currencyType: RewardCurrencyType.gem,
                icon: Icons.diamond_rounded,
                iconColor: AppColors.gemCyan,
                value: '${profile.gems}',
                tooltip: 'Gem Balance: ${profile.gems}',
                onTap: onGemsTap,
              ),

              // Golden Key (Revealed when player possesses at least 1 key)
              if (profile.goldenKeys > 0)
                _BouncyCurrencyPill(
                  key: keysKey,
                  currencyType: RewardCurrencyType.key,
                  icon: Icons.key_rounded,
                  iconColor: AppColors.goldenKey,
                  value: '${profile.goldenKeys}',
                  tooltip: 'Golden Keys: ${profile.goldenKeys} (Use in Bazaar to unlock any masterwork)',
                  onTap: onKeysTap,
                ),

              // Animated Sun / Moon Day-Night Mode Toggle
              const SunMoonToggleButton(
                size: 17,
                padding: EdgeInsets.all(6),
              ),

              // Notification Bell
              InkWell(
                onTap: () => NotificationCenterSheet.show(context, state),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 22,
                        color: isDark ? AppColors.antiqueGold : Theme.of(context).colorScheme.primary,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -3,
                          top: -3,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.energyRed,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                            child: Center(
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Offline Banner Warning
        if (!state.isOnline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            color: const Color(0xFFD35400),
            child: Row(
              children: [
                const Icon(Icons.cloud_off_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Offline Reading Mode: You can read & take notes, but rewards and streaks are paused.',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => state.toggleOnlineStatus(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Go Online',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showEnergyRefillModal(BuildContext context, AppState state) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Icon(Icons.favorite_rounded, size: 48, color: AppColors.energyRed),
              const SizedBox(height: 12),
              Text('Energy Hearts', style: AppTypography.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Energy replenishes 1 heart every 30 minutes, or you can restore your vigor immediately with gems.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.diamond_rounded, size: 16, color: AppColors.gemCyan),
                    label: const Text('Refill (50 Gems)'),
                    onPressed: state.profile.gems >= 50 && state.profile.energy < state.profile.maxEnergy
                        ? () {
                            state.spendGems(50);
                            state.restoreEnergy(state.profile.maxEnergy);
                            Navigator.pop(ctx);
                          }
                        : null,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.antiqueGold,
                      foregroundColor: AppColors.inkDark,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A tactile, responsive currency counter pill that springs / bounces
/// when flying currency items land on it.
class _BouncyCurrencyPill extends StatefulWidget {
  final RewardCurrencyType? currencyType;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String tooltip;
  final VoidCallback? onTap;

  const _BouncyCurrencyPill({
    super.key,
    required this.currencyType,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.tooltip,
    this.onTap,
  });

  @override
  State<_BouncyCurrencyPill> createState() => _BouncyCurrencyPillState();
}

class _BouncyCurrencyPillState extends State<_BouncyCurrencyPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.26).chain(CurveTween(curve: Curves.easeOutQuad)), weight: 45),
      TweenSequenceItem(tween: Tween<double>(begin: 1.26, end: 1.0).chain(CurveTween(curve: Curves.easeInQuad)), weight: 55),
    ]).animate(_bounceController);

    RewardCelebrationOverlay.onCurrencyArrived.addListener(_onArrival);
  }

  void _onArrival() {
    if (widget.currencyType != null &&
        RewardCelebrationOverlay.onCurrencyArrived.value == widget.currencyType) {
      if (mounted) {
        _bounceController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    RewardCelebrationOverlay.onCurrencyArrived.removeListener(_onArrival);
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: widget.tooltip,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 18, color: widget.iconColor),
                const SizedBox(width: 5),
                Text(
                  widget.value,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
