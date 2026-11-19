import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/haptic_service.dart';
import '../../core/state/app_state.dart';
import 'duo_button.dart';

class _WhatsNewFeature {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _WhatsNewFeature({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}

/// Sleek "What's New" update sheet shown automatically once after an app update,
/// and also accessible anytime from Settings.
class WhatsNewSheet extends StatelessWidget {
  const WhatsNewSheet({super.key});

  static const List<_WhatsNewFeature> _features = [
    _WhatsNewFeature(
      icon: Icons.shield_rounded,
      color: Color(0xFFDC2626),
      title: 'Boss Chapter Battles & Quiz Combos',
      description:
          'Conquer Boss Encounters with live HP bars, Critical Hits, 2x–5x XP combo multipliers, and unlockable Book Boss Trophies.',
    ),
    _WhatsNewFeature(
      icon: Icons.emoji_events_rounded,
      color: AppColors.antiqueGold,
      title: 'Profile Trophy Shelf & Public Cards',
      description:
          'Pin your top 3 trophies on your Profile and tap any scholar on the Leaderboard to inspect their card and add them as a buddy.',
    ),
    _WhatsNewFeature(
      icon: Icons.storefront_rounded,
      color: Color(0xFF0D9488),
      title: 'Overhauled Bazaar & Live Map Preview',
      description:
          'Larger Theme & Living Biome showcase cards with full-screen Day/Night map previews, Featured Book Spotlights, and Daily Gem Chests.',
    ),
    _WhatsNewFeature(
      icon: Icons.people_alt_rounded,
      color: AppColors.streakOrange,
      title: 'Reading Buddies & Bug Fixes',
      description:
          'Shared friend streaks with 1-tap Nudges, fixed quiz question counter & progress edge cases, and smoother cloud/UI stability.',
    ),
  ];

  static Future<void> show(BuildContext context, {bool markSeenOnClose = true}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WhatsNewSheet(),
    );
    if (markSeenOnClose && context.mounted) {
      context.read<AppState>().markWhatsNewSeen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.84,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
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
            const SizedBox(height: 14),

            // Hero Header Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                      AppColors.antiqueGold.withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.antiqueGold.withValues(alpha: 0.7),
                            ),
                          ),
                          child: const Text(
                            'WHAT\'S NEW • v${AppState.currentAppVersion}',
                            style: TextStyle(
                              color: AppColors.antiqueGold,
                              fontWeight: FontWeight.w900,
                              fontSize: 10.5,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'The Realm Has Evolved!',
                      style: AppTypography.displaySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here is everything freshly forged in your latest Quixoria update.',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Feature Highlights List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                itemCount: _features.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final item = _features[idx];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : theme.dividerColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(item.icon, color: item.color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.description,
                                style: AppTypography.bodySmall.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                                  height: 1.35,
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

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: DuoButton(
                text: 'Enter the Realm',
                icon: Icons.explore_rounded,
                variant: DuoButtonVariant.primary,
                onPressed: () {
                  HapticService.instance.medium();
                  context.read<AppState>().markWhatsNewSeen();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
