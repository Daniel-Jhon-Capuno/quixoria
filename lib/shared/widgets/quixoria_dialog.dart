import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'duo_button.dart';

/// Displays any dialog with a smooth spring-scale + fade animation so windows
/// never snap onto the screen abruptly.
Future<T?> showQuixoriaDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dialog',
    barrierColor: Colors.black.withValues(alpha: 0.62),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, _) => builder(ctx),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Animated purchase confirmation prompt before buying any Shop item,
/// Gems pack, Guild Pass, Theme, Book, Frame, Banner, Title, or Avatar Icon.
Future<bool> showPurchaseConfirmDialog({
  required BuildContext context,
  required String itemName,
  required String priceLabel,
  required IconData icon,
  String? description,
  Color accentColor = AppColors.antiqueGold,
}) async {
  final result = await showQuixoriaDialog<bool>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final isDark = theme.brightness == Brightness.dark;
      final bg = isDark ? const Color(0xFF1C1F26) : const Color(0xFFFAF8F4);
      final textPrimary = isDark ? Colors.white : const Color(0xFF1A1C19);
      final textMuted = isDark ? Colors.white70 : const Color(0xFF5A625C);

      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(ctx).size.width.clamp(290.0, 390.0) - 36,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: accentColor, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.38),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.16),
                    border: Border.all(color: accentColor.withValues(alpha: 0.55), width: 2.0),
                  ),
                  child: Icon(icon, color: accentColor, size: 30),
                ),
                const SizedBox(height: 14),
                Text(
                  'Confirm Purchase',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Would you like to unlock "$itemName" for $priceLabel?',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: textMuted),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(color: textMuted),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DuoButton(
                        text: 'Cancel',
                        variant: DuoButtonVariant.outline,
                        height: 46,
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DuoButton(
                        text: 'Buy Now',
                        icon: Icons.shopping_bag_rounded,
                        variant: DuoButtonVariant.gold,
                        height: 46,
                        onPressed: () => Navigator.of(ctx).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return result == true;
}

/// Animated celebratory confirmation popup for Shop purchases (Gems,
/// Caballero Guild Pass, Themes, Books, Cosmetics, and Energy).
Future<void> showPurchaseCelebrationDialog({
  required BuildContext context,
  required String title,
  required String subtitle,
  required IconData icon,
  Color accentColor = AppColors.antiqueGold,
  String buttonText = 'Awesome!',
}) {
  return showQuixoriaDialog<void>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final isDark = theme.brightness == Brightness.dark;
      final bg = isDark ? const Color(0xFF1C1F26) : const Color(0xFFFAF8F4);
      final textPrimary = isDark ? Colors.white : const Color(0xFF1A1C19);
      final textMuted = isDark ? Colors.white70 : const Color(0xFF5A625C);

      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(ctx).size.width.clamp(290.0, 390.0) - 36,
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: accentColor, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.35),
                  offset: const Offset(0, 4.5),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor,
                        Color.alphaBlend(Colors.black.withValues(alpha: 0.25), accentColor),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.42),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.displaySmall.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: textMuted),
                ),
                const SizedBox(height: 20),
                DuoButton(
                  text: buttonText,
                  variant: DuoButtonVariant.gold,
                  height: 48,
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
