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
  forest,
  celestial,
  sakura,
  atlantis,
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
  // Optional rich custom dark-mode palette (falls back to cohesive dark tint if omitted)
  final Color? darkPrimary;
  final Color? darkSecondary;
  final Color? darkBackground;
  final Color? darkSurface;
  final Color? darkSurfaceElevated;
  final Color? darkBorder;
  final Color? darkAccent;
  final ThemeInterfaceStyle interfaceStyle;
  /// Optional living-map biome key ('emerald_woods', 'sakura_koi', 'savannah', 'arctic_aurora', 'coral_lagoon')
  final String? biomeId;
  /// Short feature tags shown in the Themes Shop (e.g. 'Full Oak Trees', 'Deer & Fireflies')
  final List<String> mapFeatures;
  bool isOwned;
  bool isDownloaded;
  double downloadProgress;

  bool get isLivingBiome => biomeId != null && biomeId!.isNotEmpty;

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
    this.darkPrimary,
    this.darkSecondary,
    this.darkBackground,
    this.darkSurface,
    this.darkSurfaceElevated,
    this.darkBorder,
    this.darkAccent,
    this.interfaceStyle = ThemeInterfaceStyle.classic,
    this.biomeId,
    this.mapFeatures = const [],
    this.isOwned = false,
    this.isDownloaded = false,
    this.downloadProgress = 0.0,
  });

  /// High-contrast primary accent color for icons, borders, and active controls
  /// in either light or dark mode.
  Color effectivePrimary({required bool isDarkMode}) {
    if (!isDarkMode) return primary;
    if (darkPrimary != null) return darkPrimary!;
    // Ensure dark-mode primary is always vibrant and legible on dark surfaces
    return primary.computeLuminance() < 0.22 ? accent : primary;
  }

  ThemeData toThemeData({bool isDarkMode = false}) {
    final effectiveBackground = isDarkMode
        ? (darkBackground ?? const Color(0xFF121417))
        : background;
    final effectiveSurface = isDarkMode
        ? (darkSurface ?? const Color(0xFF1C1F24))
        : surface;
    final effectiveSurfaceElevated = isDarkMode
        ? (darkSurfaceElevated ?? const Color(0xFF252930))
        : surfaceElevated;
    final effectiveBorder = isDarkMode
        ? (darkBorder ?? const Color(0xFF333842))
        : border;
    final resolvedPrimary = effectivePrimary(isDarkMode: isDarkMode);
    final resolvedSecondary = isDarkMode ? (darkSecondary ?? secondary) : secondary;

    final isDark = isDarkMode;

    final effectiveTextPrimary = isDark
        ? const Color(0xFFF5F3F8)
        : (textPrimary.computeLuminance() < 0.35 ? textPrimary : const Color(0xFF1A1C19));
    final effectiveTextSecondary = isDark
        ? const Color(0xFFB5B0C2)
        : (textSecondary.computeLuminance() < 0.55 ? textSecondary : const Color(0xFF5A625C));

    // Duolingo-inspired rounded, healthy typography (Nunito) with clear weight hierarchy
    final TextStyle headingBase = GoogleFonts.nunito(
      fontWeight: FontWeight.w900,
      letterSpacing: -0.25,
    );
    final TextStyle bodyBase = GoogleFonts.nunito(
      fontWeight: FontWeight.w600,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: effectiveBackground,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: resolvedPrimary,
        onPrimary: isDark ? effectiveBackground : Colors.white,
        secondary: resolvedSecondary,
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
        displaySmall: headingBase.copyWith(fontSize: 22, fontWeight: FontWeight.w800, color: effectiveTextPrimary),
        titleLarge: headingBase.copyWith(fontSize: 19, fontWeight: FontWeight.w800, color: effectiveTextPrimary),
        titleMedium: bodyBase.copyWith(fontSize: 16.5, fontWeight: FontWeight.w800, color: effectiveTextPrimary),
        titleSmall: bodyBase.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700, color: effectiveTextPrimary),
        bodyLarge: bodyBase.copyWith(fontSize: 17.5, color: effectiveTextPrimary),
        bodyMedium: bodyBase.copyWith(fontSize: 15, color: effectiveTextSecondary),
        bodySmall: bodyBase.copyWith(fontSize: 13, color: effectiveTextSecondary),
        labelLarge: bodyBase.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800, color: resolvedPrimary),
        labelMedium: bodyBase.copyWith(fontSize: 12.5, fontWeight: FontWeight.w800, color: effectiveTextPrimary),
        labelSmall: bodyBase.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: effectiveTextSecondary),
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
          borderRadius: BorderRadius.circular(interfaceStyle == ThemeInterfaceStyle.cozy ? 28 : 24),
          side: BorderSide(
            color: effectiveBorder,
            width: 2.0,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: resolvedPrimary,
          foregroundColor: isDark ? effectiveBackground : Colors.white,
          elevation: 2,
          side: id == 'theme_the_la_mancha'
              ? BorderSide(color: effectiveBorder, width: 2.0)
              : BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(interfaceStyle == ThemeInterfaceStyle.cozy ? 26 : 20),
          ),
          textStyle: headingBase.copyWith(fontSize: 15.5, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: resolvedPrimary,
          side: BorderSide(color: resolvedPrimary, width: 2.0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(interfaceStyle == ThemeInterfaceStyle.cozy ? 26 : 20),
          ),
          textStyle: bodyBase.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: effectiveSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: effectiveBorder, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: effectiveBorder, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: resolvedPrimary, width: 2.2),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: BorderSide(color: effectiveBorder, width: 1.8),
        labelStyle: bodyBase.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: effectiveTextPrimary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: effectiveSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: effectiveBorder,
        thickness: 1.5,
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
  /// zero green/blue in Pink theme, and pure harmony in Medieval/Plague/Cozy/new realms.
  Color get successColor {
    if (interfaceStyle == ThemeInterfaceStyle.snowy) {
      return const Color(0xFF00A8CC);
    }
    if (id == 'theme_cute_meadow' || interfaceStyle == ThemeInterfaceStyle.sakura) {
      return const Color(0xFFE91E63);
    }
    if (interfaceStyle == ThemeInterfaceStyle.medieval) {
      return const Color(0xFFD4A338);
    }
    if (interfaceStyle == ThemeInterfaceStyle.plague) {
      return const Color(0xFFC77DFF);
    }
    if (interfaceStyle == ThemeInterfaceStyle.cozy) {
      return const Color(0xFFE28442);
    }
    if (interfaceStyle == ThemeInterfaceStyle.celestial) {
      return const Color(0xFF5B7FFF);
    }
    if (interfaceStyle == ThemeInterfaceStyle.atlantis) {
      return const Color(0xFF14B8A6);
    }
    return primary;
  }
}
