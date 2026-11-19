import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state.dart';
import '../../models/app_theme_preset.dart';

/// A dynamic thematic container that completely transforms its geometry,
/// borders, rivets, and shadow styles based on the active [ThemeInterfaceStyle].
class ThemedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Color? customBackgroundColor;
  final bool showBattlementHeader;
  final String? battlementTitle;

  const ThemedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.customBackgroundColor,
    this.showBattlementHeader = false,
    this.battlementTitle,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final style = state.activeThemePreset.interfaceStyle;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget content = child;

    // Optional Castellated Medieval Banner Header
    if (showBattlementHeader && battlementTitle != null) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBattlementBanner(context, state.activeThemePreset, isDark),
          Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ],
      );
    } else if (padding != null) {
      content = Padding(padding: padding!, child: child);
    }

    BoxDecoration decoration;
    double cornerRadius = 24;

    final preset = state.activeThemePreset;
    switch (style) {
      case ThemeInterfaceStyle.medieval:
        cornerRadius = 24;
        decoration = BoxDecoration(
          color: customBackgroundColor ?? (theme.cardTheme.color ?? theme.colorScheme.surface),
          borderRadius: BorderRadius.circular(cornerRadius),
          border: Border.all(
            color: isDark ? preset.secondary : preset.primary,
            width: 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? preset.secondary : preset.primary).withValues(alpha: 0.28),
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              offset: const Offset(0, 6),
              blurRadius: 12,
            ),
          ],
        );
        break;

      case ThemeInterfaceStyle.plague:
        cornerRadius = 24;
        decoration = BoxDecoration(
          color: customBackgroundColor ?? (theme.cardTheme.color ?? theme.colorScheme.surface),
          borderRadius: BorderRadius.circular(cornerRadius),
          border: Border.all(
            color: preset.accent.withValues(alpha: 0.85),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: preset.accent.withValues(alpha: 0.3),
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
            BoxShadow(
              color: preset.primary.withValues(alpha: 0.3),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        );
        break;

      case ThemeInterfaceStyle.cozy:
        cornerRadius = 28;
        decoration = BoxDecoration(
          color: customBackgroundColor ?? (theme.cardTheme.color ?? theme.colorScheme.surface),
          borderRadius: BorderRadius.circular(cornerRadius),
          border: Border.all(
            color: isDark ? preset.secondary : preset.border,
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? preset.secondary : preset.border).withValues(alpha: 0.55),
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        );
        break;

      case ThemeInterfaceStyle.snowy:
        cornerRadius = 26;
        decoration = BoxDecoration(
          color: customBackgroundColor ?? (theme.cardTheme.color ?? theme.colorScheme.surface),
          borderRadius: BorderRadius.circular(cornerRadius),
          border: Border.all(
            color: isDark ? preset.secondary : preset.border,
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? preset.secondary : preset.border).withValues(alpha: 0.5),
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
            BoxShadow(
              color: preset.accent.withValues(alpha: 0.14),
              blurRadius: 14,
            ),
          ],
        );
        break;

      case ThemeInterfaceStyle.forest:
      case ThemeInterfaceStyle.celestial:
      case ThemeInterfaceStyle.sakura:
      case ThemeInterfaceStyle.atlantis:
        cornerRadius = 26;
        final liveAccent = preset.effectivePrimary(isDarkMode: isDark);
        final borderTint = isDark
            ? liveAccent.withValues(alpha: 0.55)
            : preset.border;
        decoration = BoxDecoration(
          color: customBackgroundColor ?? (theme.cardTheme.color ?? theme.colorScheme.surface),
          borderRadius: BorderRadius.circular(cornerRadius),
          border: Border.all(
            color: borderTint,
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: liveAccent.withValues(alpha: isDark ? 0.28 : 0.20),
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
            BoxShadow(
              color: (isDark ? liveAccent : Colors.black).withValues(alpha: isDark ? 0.16 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        );
        break;

      case ThemeInterfaceStyle.classic:
        cornerRadius = 26;
        decoration = BoxDecoration(
          color: customBackgroundColor ?? (theme.cardTheme.color ?? theme.colorScheme.surface),
          borderRadius: BorderRadius.circular(cornerRadius),
          border: Border.all(
            color: preset.accent.withValues(alpha: 0.72),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: preset.accent.withValues(alpha: 0.28),
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        );
        break;
    }

    final cardBgColor = decoration.color ?? (theme.cardTheme.color ?? theme.colorScheme.surface);
    final cardIsDark = state.isDarkMode || isDark || cardBgColor.computeLuminance() < 0.38;
    final cardTextColor = cardIsDark ? const Color(0xFFFDFBF7) : const Color(0xFF1A1C19);

    content = DefaultTextStyle.merge(
      style: TextStyle(color: cardTextColor),
      child: content,
    );

    Widget cardWidget = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: decoration,
      child: Stack(
        children: [
          content,

          // Medieval Citadel: 4 Forged Iron Rivets at card corners!
          if (style == ThemeInterfaceStyle.medieval) ...[
            _buildIronRivet(top: 8, left: 8),
            _buildIronRivet(top: 8, right: 8),
            _buildIronRivet(bottom: 8, left: 8),
            _buildIronRivet(bottom: 8, right: 8),
          ],

          // Plague Grimoire: Toxic Alchemical Glyphs in corners
          if (style == ThemeInterfaceStyle.plague) ...[
            _buildAlchemicalGlyph(top: 6, right: 6),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cornerRadius),
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  Widget _buildIronRivet({double? top, double? bottom, double? left, double? right}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFFE8D4A2), Color(0xFF6B5838), Color(0xFF2E2415)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 1.5,
              offset: const Offset(0.5, 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlchemicalGlyph({double? top, double? right}) {
    return Positioned(
      top: top,
      right: right,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: const Icon(
          Icons.change_history_rounded,
          size: 11,
          color: Color(0xFF52A36B),
        ),
      ),
    );
  }

  Widget _buildBattlementBanner(BuildContext context, AppThemePreset preset, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: preset.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        children: [
          Icon(preset.icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              battlementTitle!.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
