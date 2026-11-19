import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// A universal, Duolingo-fidelity animated loading popup for network sync,
/// theme installation, literature indexing, and simulated offline/online delays.
class QuixoriaLoadingDialog extends StatefulWidget {
  final String title;
  final String message;

  const QuixoriaLoadingDialog({
    super.key,
    required this.title,
    required this.message,
  });

  /// Shows the loading dialog and optionally awaits an async task before popping.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required String message,
    Future<T>? task,
    Duration? minDisplayTime,
  }) async {
    final dialogFuture = showGeneralDialog<T>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Loading',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8.0 * anim1.value,
            sigmaY: 8.0 * anim1.value,
          ),
          child: ScaleTransition(
            scale: curve,
            child: FadeTransition(
              opacity: anim1,
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return QuixoriaLoadingDialog(title: title, message: message);
      },
    );

    if (task != null) {
      final start = DateTime.now();
      try {
        final result = await task;
        if (minDisplayTime != null) {
          final elapsed = DateTime.now().difference(start);
          if (elapsed < minDisplayTime) {
            await Future.delayed(minDisplayTime - elapsed);
          }
        }
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop(result);
        }
        return result;
      } catch (e) {
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        rethrow;
      }
    }

    return dialogFuture;
  }

  @override
  State<QuixoriaLoadingDialog> createState() => _QuixoriaLoadingDialogState();
}

class _QuixoriaLoadingDialogState extends State<QuixoriaLoadingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 310,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? (isDark ? const Color(0xFF1B221E) : Colors.white),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.antiqueGold.withValues(alpha: 0.6),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.antiqueGold.withValues(alpha: 0.15),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title Name: QUIXORIA with elegant glowing underline
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final pulse = sin(_controller.value * pi * 2).abs();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'QUIXORIA',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            textAlign: TextAlign.center,
                            style: AppTypography.displayMedium.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3.5,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 48 + (pulse * 24),
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: AppColors.antiqueGold,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.antiqueGold.withValues(alpha: 0.5 * pulse),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: AppTypography.displaySmall.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              // Message Body
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 13,
                  height: 1.45,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 20),

              // Animated Shimmer Progress Bar (Duolingo style)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 7,
                  width: double.infinity,
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final barW = constraints.maxWidth;
                          final segmentW = barW * 0.4;
                          final left = ((barW + segmentW) * _controller.value) - segmentW;

                          return Stack(
                            children: [
                              Positioned(
                                left: left,
                                width: segmentW,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.antiqueGold.withValues(alpha: 0.2),
                                        AppColors.antiqueGold,
                                        theme.colorScheme.primary,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

