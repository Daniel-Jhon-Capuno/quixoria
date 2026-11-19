import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';

enum DuoButtonVariant {
  primary,
  gold,
  vermillion,
  blue,
  outline,
}

class DuoButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final DuoButtonVariant variant;
  final double? width;
  final double height;
  final bool isFullWidth;
  final bool isLoading;

  const DuoButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.variant = DuoButtonVariant.primary,
    this.width,
    this.height = 54,
    this.isFullWidth = true,
    this.isLoading = false,
  });

  @override
  State<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends State<DuoButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onPressed == null || widget.isLoading) return;
    HapticService.instance.light();
    SoundService.instance.play(Sfx.tap);
    setState(() => _isPressed = true);
  }

  void _handleTap() {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = false);
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(context, widget.variant);
    const double bevelDepth = 4.5;

    final child = GestureDetector(
      onTapDown: _handleTapDown,
      onTap: _handleTap,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(
          top: _isPressed ? bevelDepth : 0,
          bottom: _isPressed ? 0 : bevelDepth,
        ),
        decoration: BoxDecoration(
          color: colors.face,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border, width: 2.0),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: colors.bevel,
                    offset: const Offset(0, bevelDepth),
                    blurRadius: 0,
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: widget.height - bevelDepth,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading) ...[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.text),
                  ),
                ),
                const SizedBox(width: 10),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon, color: colors.text, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.isLoading ? 'Please wait...' : widget.text,
                    maxLines: 1,
                    style: AppTypography.titleMedium.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.isFullWidth) {
      return SizedBox(width: double.infinity, child: child);
    } else if (widget.width != null) {
      return SizedBox(width: widget.width, child: child);
    }
    return child;
  }

  _ButtonColors _getColors(BuildContext context, DuoButtonVariant variant) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;

    switch (variant) {
      case DuoButtonVariant.primary:
        return _ButtonColors(
          face: primary,
          bevel: Color.alphaBlend(Colors.black.withValues(alpha: isDark ? 0.45 : 0.35), primary),
          border: Color.alphaBlend(Colors.black.withValues(alpha: isDark ? 0.25 : 0.18), primary),
          text: onPrimary,
        );
      case DuoButtonVariant.gold:
        return _ButtonColors(
          face: AppColors.antiqueGold,
          bevel: const Color(0xFF8E660E),
          border: const Color(0xFFB58823),
          text: const Color(0xFF1F1600),
        );
      case DuoButtonVariant.vermillion:
        return _ButtonColors(
          face: AppColors.vermillion,
          bevel: const Color(0xFF8F2915),
          border: const Color(0xFFA63920),
          text: Colors.white,
        );
      case DuoButtonVariant.blue:
        const accent = AppColors.practiceBlue;
        return _ButtonColors(
          face: accent,
          bevel: Color.alphaBlend(Colors.black.withValues(alpha: 0.35), accent),
          border: Color.alphaBlend(Colors.black.withValues(alpha: 0.18), accent),
          text: Colors.white,
        );
      case DuoButtonVariant.outline:
        return _ButtonColors(
          face: isDark ? const Color(0xFF1E1E1E) : theme.colorScheme.surface,
          bevel: isDark ? const Color(0xFF141414) : theme.dividerColor,
          border: primary,
          text: primary,
        );
    }
  }
}

class _ButtonColors {
  final Color face;
  final Color bevel;
  final Color border;
  final Color text;

  _ButtonColors({
    required this.face,
    required this.bevel,
    required this.border,
    required this.text,
  });
}
