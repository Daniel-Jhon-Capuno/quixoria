import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';

/// Smoothly animated Sun / Moon toggle button for switching between Light Mode
/// and Dark Mode directly from any header bar, in sync with Settings.
class SunMoonToggleButton extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry padding;

  const SunMoonToggleButton({
    super.key,
    this.size = 21,
    this.padding = const EdgeInsets.all(9),
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final theme = Theme.of(context);
        final isDark = state.isDarkMode;
        final accent = state.activeThemePreset.effectivePrimary(isDarkMode: isDark);
        final surfaceColor = theme.colorScheme.surface;
        final borderColor = accent.withValues(alpha: isDark ? 0.50 : 0.35);

        return Tooltip(
          message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          child: InkWell(
            key: const Key('sun_moon_theme_toggle'),
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              HapticService.instance.selection();
              SoundService.instance.play(Sfx.tap);
              state.toggleDarkMode(!isDark);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeInOutCubic,
              padding: padding,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF9FA8DA) : const Color(0xFFF59E0B))
                        .withValues(alpha: isDark ? 0.22 : 0.20),
                    blurRadius: 10,
                    spreadRadius: 0.5,
                  ),
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.45),
                    offset: const Offset(0, 2.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final rotate = Tween<double>(begin: 0.72, end: 1.0).animate(animation);
                  return RotationTransition(
                    turns: rotate,
                    child: ScaleTransition(
                      scale: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    ),
                  );
                },
                child: isDark
                    ? Icon(
                        Icons.nightlight_round,
                        key: const ValueKey('moon_icon'),
                        size: size,
                        color: const Color(0xFFFDE68A),
                      )
                    : Icon(
                        Icons.wb_sunny_rounded,
                        key: const ValueKey('sun_icon'),
                        size: size,
                        color: const Color(0xFFF59E0B),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
