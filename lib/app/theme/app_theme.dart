import 'package:flutter/material.dart';
import '../../shared/widgets/blur_dissolve_transition.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.parchmentCream,
      colorScheme: const ColorScheme.light(
        primary: AppColors.deepForest,
        onPrimary: AppColors.parchmentCream,
        secondary: AppColors.sageGreen,
        onSecondary: Colors.white,
        tertiary: AppColors.vermillion,
        onTertiary: Colors.white,
        surface: AppColors.surfaceCard,
        onSurface: AppColors.inkDark,
        onSurfaceVariant: AppColors.inkMedium,
        surfaceContainerHighest: AppColors.parchmentWarm,
        outline: AppColors.borderLight,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.inkDark),
        displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.inkDark),
        displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.inkDark),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.inkDark),
        titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.inkDark),
        titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.inkDark),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.inkDark),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.inkMedium),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.inkLight),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.deepForest),
        labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.inkDark),
        labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.inkLight),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.parchmentCream,
        foregroundColor: AppColors.inkDark,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepForest,
          foregroundColor: AppColors.parchmentCream,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.parchmentCream,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepForest,
          side: const BorderSide(color: AppColors.deepForest, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.parchmentCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
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

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkAccentGold,
        onPrimary: AppColors.darkBackground,
        secondary: Color(0xFFB8B8B8),
        onSecondary: Colors.black,
        tertiary: AppColors.vermillion,
        onTertiary: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        onSurfaceVariant: AppColors.darkTextSecondary,
        surfaceContainerHighest: AppColors.darkSurfaceElevated,
        outline: AppColors.darkBorder,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.darkTextPrimary),
        displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.darkTextPrimary),
        displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.darkTextPrimary),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.darkTextPrimary),
        titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.darkTextPrimary),
        titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.darkTextPrimary),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.darkTextPrimary),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.darkTextSecondary),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.darkAccentGold),
        labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.darkTextPrimary),
        labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.darkTextSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkAccentGold,
          foregroundColor: AppColors.darkBackground,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.darkBackground,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkAccentGold,
          side: const BorderSide(color: AppColors.darkAccentGold, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.darkAccentGold,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
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
}
