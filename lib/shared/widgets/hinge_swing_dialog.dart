import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/sound_service.dart';

/// A modal dialog that animates with a 3D pendulum hinge swing.
/// Swings down from its top edge like a wooden tavern sign or hanging parchment scroll,
/// and swings back up into the rafters when dismissed or confirmed.
class HingeSwingDeleteDialog extends StatelessWidget {
  final String title;
  final String noteTitle;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;

  const HingeSwingDeleteDialog({
    super.key,
    required this.title,
    required this.noteTitle,
    required this.message,
    required this.onConfirm,
    this.confirmText = 'Discard Scroll',
    this.cancelText = 'Keep Scroll',
  });

  /// Opens the dialog with the 3D top-hinge pendulum swing animation.
  static Future<bool?> show({
    required BuildContext context,
    required String noteTitle,
    required VoidCallback onConfirm,
  }) {
    SoundService.instance.play(Sfx.dialog);
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Discard Scroll Dialog',
      barrierColor: Colors.black.withValues(alpha: 0.58),
      transitionDuration: const Duration(milliseconds: 440),
      pageBuilder: (ctx, anim, secondaryAnim) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        // Forward swing has bounce/overshoot (easeOutBack); dismissal swings back up (easeInBack)
        final curve = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInBack,
        );

        final swingAngle = (-1.0 + curve.value) * (math.pi / 2.1);
        final opacity = anim.value.clamp(0.0, 1.0);

        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 6 * curve.value,
            sigmaY: 6 * curve.value,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Transform(
                alignment: Alignment.topCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0018) // 3D Perspective depth
                  ..rotateX(swingAngle),
                child: Opacity(
                  opacity: opacity,
                  child: Material(
                    color: Colors.transparent,
                    child: HingeSwingDeleteDialog(
                      title: 'Discard this Scroll?',
                      noteTitle: noteTitle,
                      message:
                          'Dost thou truly wish to consign this wisdom to the ashes of oblivion? This deed cannot be undone.',
                      confirmText: 'Discard Scroll',
                      cancelText: 'Keep Scroll',
                      onConfirm: () {
                        Navigator.of(ctx).pop(true);
                        onConfirm();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = theme.cardTheme.color ?? (isDark ? const Color(0xFF1E2420) : const Color(0xFFFDFBF7));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Realistic Brass / Gold Hinge Brackets on top edge
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHingeBracket(),
              _buildHingeBracket(),
            ],
          ),
        ),

        // Hanging Parchment Plaque Card
        Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.antiqueGold.withValues(alpha: 0.65),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Icon Badge
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.energyRed.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.energyRed.withValues(alpha: 0.4),
                      width: 1.4,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.delete_forever_rounded,
                      color: AppColors.energyRed,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Dialog Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Note Title Snippet pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.antiqueGold.withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    '“$noteTitle”',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.quote.copyWith(
                      color: theme.colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Explanatory Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          side: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          cancelText,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.energyRed,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: onConfirm,
                        child: Text(
                          confirmText,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHingeBracket() {
    return Container(
      width: 22,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFFC59A3F), // Antique Brass
        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
        border: Border.all(color: const Color(0xFF6B4E1A), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF3E2D12),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
