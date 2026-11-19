import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/sound_service.dart';
import 'duo_button.dart';
import 'quixote_avatar.dart';
import 'quixote_mascot.dart';

class GuideDialog extends StatelessWidget {
  final String title;
  final String message;
  final String primaryButtonText;
  final VoidCallback onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;
  final VoidCallback? onClose;
  final QuixoteMood mood;

  const GuideDialog({
    super.key,
    required this.title,
    required this.message,
    required this.primaryButtonText,
    required this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.onClose,
    this.mood = QuixoteMood.proud,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String message,
    required String primaryButtonText,
    required VoidCallback onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    QuixoteMood mood = QuixoteMood.proud,
  }) {
    SoundService.instance.play(Sfx.guide);
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: GuideDialog(
          title: title,
          message: message,
          primaryButtonText: primaryButtonText,
          onPrimaryPressed: () {
            Navigator.of(ctx).pop();
            onPrimaryPressed();
          },
          secondaryButtonText: secondaryButtonText,
          onSecondaryPressed: secondaryButtonText != null
              ? () {
                  Navigator.of(ctx).pop();
                  onSecondaryPressed?.call();
                }
              : null,
          onClose: () => Navigator.of(ctx).pop(),
          mood: mood,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      alignment: Alignment.bottomCenter,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomLeft,
        children: [
          // Main Dialogue Card with soft organic corners
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? (isDark ? AppColors.darkSurface : const Color(0xFFFDFBF7)),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.antiqueGold.withValues(alpha: 0.55),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: Eyebrow + Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_stories_rounded,
                          size: 14,
                          color: AppColors.streakOrange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'A WORD FROM YOUR GUIDE',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.streakOrange,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                    if (onClose != null)
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.dividerColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  title,
                  style: AppTypography.displaySmall.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),

                // Message Body
                Text(
                  message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 14.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),

                // Primary Button (Deep Forest Pill with arrow)
                SizedBox(
                  width: double.infinity,
                  child: DuoButton(
                    text: '$primaryButtonText  ->',
                    onPressed: onPrimaryPressed,
                    variant: DuoButtonVariant.primary,
                  ),
                ),

                // Secondary Action Button (Soft Outline)
                if (secondaryButtonText != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: DuoButton(
                      text: secondaryButtonText!,
                      onPressed: onSecondaryPressed,
                      variant: DuoButtonVariant.outline,
                    ),
                  ),
                ],

                // Space for character avatar anchor
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Speech Bubble Pointer pointing to Don Quixote
          Positioned(
            left: 56,
            bottom: 16,
            child: CustomPaint(
              size: const Size(20, 12),
              painter: _SpeechTailPainter(
                color: theme.cardTheme.color ?? (isDark ? AppColors.darkSurface : const Color(0xFFFDFBF7)),
                borderColor: AppColors.antiqueGold.withValues(alpha: 0.55),
              ),
            ),
          ),

          // Living 3D Animated Don Quixote Mascot Overlapping the Bottom-Left
          Positioned(
            left: 12,
            bottom: -22,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                QuixoteMascot(
                  size: 96,
                  expression: _mapMoodToExpression(mood),
                  showSpeechBubble: false,
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.antiqueGold, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'QUEST GUIDE',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.parchmentCream,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static QuixoteExpression _mapMoodToExpression(QuixoteMood mood) {
    switch (mood) {
      case QuixoteMood.inquiring:
        return QuixoteExpression.thinking;
      case QuixoteMood.triumphant:
        return QuixoteExpression.triumphant;
      case QuixoteMood.caution:
        return QuixoteExpression.vigilant;
      case QuixoteMood.proud:
        return QuixoteExpression.idle;
      case QuixoteMood.sad:
        return QuixoteExpression.sad;
    }
  }
}

class _SpeechTailPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _SpeechTailPainter({
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
