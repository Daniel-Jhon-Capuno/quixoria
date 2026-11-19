import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/theme/app_colors.dart';
import '../shared/widgets/blur_dissolve_transition.dart';

enum ThemeInterfaceStyle {
  classic,
  medieval,
  plague,
  cozy,
  snowy,
}

class AppThemePreset {
  final String id;
  final String name;
  final String description;
  final String eraTag;
  final IconData icon;
  final int gemPrice;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final ThemeInterfaceStyle interfaceStyle;
  bool isOwned;
  bool isDownloaded;
  double downloadProgress;

  AppThemePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.eraTag,
    this.icon = Icons.auto_stories_rounded,
    required this.gemPrice,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    this.interfaceStyle = ThemeInterfaceStyle.classic,
    this.isOwned = false,
    this.isDownloaded = false,
    this.downloadProgress = 0.0,
  });

  ThemeData toThemeData({bool isDarkMode = false}) {
    final effectiveBackground = isDarkMode
        ? const Color(0xFF121212)
        : background;
    final effectiveSurface = isDarkMode
        ? const Color(0xFF1E1E1E)
        : surface;
    final effectiveSurfaceElevated = isDarkMode
        ? const Color(0xFF262626)
        : surfaceElevated;
    final effectiveBorder = isDarkMode
        ? const Color(0xFF333333)
        : border;

    final isDark = isDarkMode || effectiveBackground.computeLuminance() < 0.35;

    final effectiveTextPrimary = isDark
        ? const Color(0xFFF5F5F5)
        : (textPrimary.computeLuminance() < 0.35 ? textPrimary : const Color(0xFF1A1C19));
    final effectiveTextSecondary = isDark
        ? const Color(0xFFAAAAAA)
        : (textSecondary.computeLuminance() < 0.55 ? textSecondary : const Color(0xFF5A625C));

    // Typography customization per Interface Style
    TextStyle headingBase;
    TextStyle bodyBase;

    switch (interfaceStyle) {
      case ThemeInterfaceStyle.medieval:
        headingBase = GoogleFonts.lora(fontWeight: FontWeight.bold);
        bodyBase = GoogleFonts.plusJakartaSans();
        break;
      case ThemeInterfaceStyle.plague:
        headingBase = GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold);
        bodyBase = GoogleFonts.plusJakartaSans();
        break;
      case ThemeInterfaceStyle.cozy:
        headingBase = GoogleFonts.lora(fontWeight: FontWeight.bold);
        bodyBase = GoogleFonts.lora();
        break;
      case ThemeInterfaceStyle.snowy:
        headingBase = GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold);
        bodyBase = GoogleFonts.plusJakartaSans();
        break;
      case ThemeInterfaceStyle.classic:
        headingBase = GoogleFonts.lora(fontWeight: FontWeight.bold);
        bodyBase = GoogleFonts.plusJakartaSans();
        break;
    }

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: effectiveBackground,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: isDark ? effectiveBackground : Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        error: AppColors.energyRed,
        onError: Colors.white,
        surface: effectiveSurface,
        onSurface: effectiveTextPrimary,
        onSurfaceVariant: effectiveTextSecondary,
        outline: effectiveBorder,
        surfaceContainerHighest: effectiveSurfaceElevated,
      ),
      textTheme: TextTheme(
        displayLarge: headingBase.copyWith(fontSize: 32, color: effectiveTextPrimary),
        displayMedium: headingBase.copyWith(fontSize: 26, color: effectiveTextPrimary),
        displaySmall: headingBase.copyWith(fontSize: 22, color: effectiveTextPrimary),
        titleLarge: headingBase.copyWith(fontSize: 20, color: effectiveTextPrimary),
        titleMedium: bodyBase.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: effectiveTextPrimary),
        titleSmall: bodyBase.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: effectiveTextPrimary),
        bodyLarge: bodyBase.copyWith(fontSize: 18, color: effectiveTextPrimary),
        bodyMedium: bodyBase.copyWith(fontSize: 15, color: effectiveTextSecondary),
        bodySmall: bodyBase.copyWith(fontSize: 13, color: effectiveTextSecondary),
        labelLarge: bodyBase.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: primary),
        labelMedium: bodyBase.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: effectiveTextPrimary),
        labelSmall: bodyBase.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: effectiveTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: effectiveBackground,
        foregroundColor: effectiveTextPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: effectiveSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(interfaceStyle == ThemeInterfaceStyle.cozy ? 28 : 22),
          side: BorderSide(
            color: effectiveBorder,
            width: id == 'theme_the_la_mancha' ? 1.6 : (interfaceStyle == ThemeInterfaceStyle.medieval ? 2.0 : 1.2),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark ? effectiveBackground : Colors.white,
          elevation: 2,
          side: id == 'theme_the_la_mancha'
              ? BorderSide(color: effectiveBorder, width: 1.5)
              : BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(interfaceStyle == ThemeInterfaceStyle.cozy ? 26 : 18),
          ),
          textStyle: headingBase.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(interfaceStyle == ThemeInterfaceStyle.cozy ? 26 : 18),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: effectiveSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: effectiveBorder,
        thickness: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: BlurDissolvePageTransitionsBuilder(),
          TargetPlatform.iOS: BlurDissolvePageTransitionsBuilder(),
          TargetPlatform.windows: BlurDissolvePageTransitionsBuilder(),
          TargetPlatform.macOS: BlurDissolvePageTransitionsBuilder(),
          TargetPlatform.linux: BlurDissolvePageTransitionsBuilder(),
          TargetPlatform.fuchsia: BlurDissolvePageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Theme-compliant success color that guarantees zero green in Snowy/Ice theme,
  /// zero green/blue in Pink theme, and pure harmony in Medieval/Plague/Cozy.
  Color get successColor {
    if (interfaceStyle == ThemeInterfaceStyle.snowy) {
      return const Color(0xFF00A8CC); // Pure Frost Cyan (Zero Green in Snowy)
    }
    if (id == 'theme_cute_meadow') {
      return const Color(0xFFE91E63); // Pure Rose Magenta (Zero Green/Blue in Pink)
    }
    if (interfaceStyle == ThemeInterfaceStyle.medieval) {
      return const Color(0xFFD4A338); // Royal Gold (Zero Green in Medieval)
    }
    if (interfaceStyle == ThemeInterfaceStyle.plague) {
      return const Color(0xFFC77DFF); // Lavender Amethyst (Zero Green in Plague)
    }
    if (interfaceStyle == ThemeInterfaceStyle.cozy) {
      return const Color(0xFFE28442); // Hearth Amber (Zero Green in Cozy)
    }
    return primary;
  }
}
