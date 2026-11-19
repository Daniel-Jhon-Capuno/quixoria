import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/network_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';
import 'duo_button.dart';
import 'quixote_avatar.dart';

/// A modal dialog that informs the reader of the consequences of offline mode.
/// Clearly enumerates what rewards are paused (in bullet format) and what remains
/// fully readable and available offline.
///
/// Features real-time detection: if Wi-Fi / internet connects while this dialog
/// is displayed, it automatically dismisses itself in real-time!
class OfflineWarningDialog extends StatefulWidget {
  final VoidCallback? onDismiss;
  final VoidCallback? onGoOnline;

  const OfflineWarningDialog({
    super.key,
    this.onDismiss,
    this.onGoOnline,
  });

  static bool _isShowing = false;
  static bool get isShowing => _isShowing;

  static Future<T?> show<T>(BuildContext context) async {
    if (_isShowing) return null;
    _isShowing = true;
    try {
      SoundService.instance.play(Sfx.dialog);
      return await showDialog<T>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (ctx) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: OfflineWarningDialog(
              onDismiss: () {
                if (Navigator.of(ctx).canPop()) {
                  Navigator.of(ctx).pop();
                }
              },
              onGoOnline: () {
                Provider.of<AppState>(ctx, listen: false).toggleOnlineStatus(true);
                if (Navigator.of(ctx).canPop()) {
                  Navigator.of(ctx).pop();
                }
              },
            ),
          ),
        ),
      );
    } finally {
      _isShowing = false;
    }
  }

  @override
  State<OfflineWarningDialog> createState() => _OfflineWarningDialogState();
}

class _OfflineWarningDialogState extends State<OfflineWarningDialog> {
  StreamSubscription<bool>? _networkSub;
  bool _isCheckingNetwork = false;
  bool _connectionRestored = false;
  bool _hasDismissed = false;

  @override
  void initState() {
    super.initState();
    _networkSub = NetworkMonitorService.instance.onConnectivityChanged.listen((isOnline) {
      if (isOnline && mounted) {
        _handleAutoDismissOnConnected();
      }
    });
  }

  @override
  void dispose() {
    _networkSub?.cancel();
    super.dispose();
  }

  void _handleAutoDismissOnConnected() {
    if (_hasDismissed) return;
    _hasDismissed = true;
    setState(() {
      _connectionRestored = true;
    });
    SoundService.instance.play(Sfx.reward);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final appState = Provider.of<AppState>(context, listen: false);
      appState.toggleOnlineStatus(true);
      if (widget.onGoOnline != null) {
        widget.onGoOnline!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    });
  }

  Future<void> _manualRetry() async {
    setState(() => _isCheckingNetwork = true);
    final online = await NetworkMonitorService.instance.checkConnection();
    if (!mounted) return;
    setState(() => _isCheckingNetwork = false);

    if (online) {
      _handleAutoDismissOnConnected();
    } else {
      SoundService.instance.play(Sfx.tap);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Still offline. Please check your Wi-Fi or mobile data settings.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color ?? (isDark ? const Color(0xFF1E2620) : const Color(0xFFFDFBF7));

    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxWidth: 440,
        maxHeight: screenHeight * 0.85,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: _connectionRestored
              ? AppColors.successGreen
              : AppColors.antiqueGold.withValues(alpha: 0.6),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Real-time Connection Restored Banner
          if (_connectionRestored)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: const BoxDecoration(
                color: AppColors.successGreen,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Wi-Fi Restored! Resuming Adventure...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Header with Don Quixote & Close 'X' Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const QuixoteAvatar(
                  size: 54,
                  mood: QuixoteMood.caution,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.streakOrange.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.streakOrange.withValues(alpha: 0.5),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off_rounded, color: AppColors.streakOrange, size: 13),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'OFFLINE MODE',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.streakOrange,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                  fontSize: 9.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'No Realm Wi-Fi Detected',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  onPressed: widget.onDismiss ?? () => Navigator.of(context).pop(),
                  tooltip: 'Dismiss Warning',
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Text(
              'Thou art exploring beyond the reach of the Realm Network. Thou mayest proceed in offline mode, but certain honours and mechanics shall be paused:',
              style: AppTypography.bodySmall.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                height: 1.4,
              ),
            ),
          ),

          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),

          // Scrollable list of consequences
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'REWARDS & FUNCTIONS PAUSED:',
                    style: AppTypography.labelSmall.copyWith(
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.bold,
                      color: AppColors.vermillion,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildBulletItem(
                    icon: Icons.diamond_outlined,
                    iconColor: AppColors.gemCyan,
                    title: 'No Gem Bounties or Level Coins',
                    desc: 'Completing quests or reading sessions will not award gems until reconnected to the realm.',
                    theme: theme,
                  ),
                  _buildBulletItem(
                    icon: Icons.local_fire_department_outlined,
                    iconColor: AppColors.streakOrange,
                    title: 'Daily Streak Progression Paused',
                    desc: 'Thy campfire streak counter shall not advance without realm cloud synchronization.',
                    theme: theme,
                  ),
                  _buildBulletItem(
                    icon: Icons.quiz_outlined,
                    iconColor: AppColors.energyRed,
                    title: 'Quizzes Locked (Reading Only)',
                    desc: 'Interactive comprehension quizzes are locked while offline; only reading chapters remain open.',
                    theme: theme,
                  ),
                  _buildBulletItem(
                    icon: Icons.leaderboard_outlined,
                    iconColor: AppColors.antiqueGold,
                    title: 'Chivalric League Standing Frozen',
                    desc: 'Weekly XP earned offline will not post to the Knightly Leaderboard standings.',
                    theme: theme,
                  ),
                  _buildBulletItem(
                    icon: Icons.vpn_key_outlined,
                    iconColor: AppColors.goldenKey,
                    title: 'Vault Keys & Bazaar Purchases',
                    desc: 'Golden key redemptions, new book purchases, and grimoire downloads require the Royal Archive.',
                    theme: theme,
                  ),

                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.successGreen.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: AppColors.successGreen, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'WHAT REMAINS ACTIVE FOR THEE:',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.successGreen,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Unrestricted reading of all unlocked books & literature chapters.\n'
                          '• Full access to personal marginalia notes, bookmarks & quotes.\n'
                          '• Practice Grove review with cached vocabulary flashcards.\n'
                          '• On-device local progress saving to continue seamlessly.',
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                            height: 1.45,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),

          // Bottom Action Buttons: Read Offline & Retry Connection
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: widget.onDismiss ?? () => Navigator.of(context).pop(),
                    child: const Text(
                      'Proceed Offline',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DuoButton(
                    text: _isCheckingNetwork ? 'Checking...' : 'Retry Wi-Fi',
                    icon: _isCheckingNetwork ? Icons.hourglass_top_rounded : Icons.refresh_rounded,
                    onPressed: _isCheckingNetwork ? null : _manualRetry,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: AppTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
