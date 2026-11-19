import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';
import '../models/app_theme_preset.dart';

class MockThemePresets {
  static List<AppThemePreset> getPresets() {
    return [
      // 1. Classic La Mancha (Default, Free)
      AppThemePreset(
        id: 'theme_classic',
        name: 'Classic La Mancha',
        description: 'Antique parchment, deep Spanish forest green, and Cervantes gold.',
        eraTag: 'Renaissance Spain',
        icon: Icons.auto_stories_rounded,
        gemPrice: 0,
        primary: const Color(0xFF1E382B),
        secondary: const Color(0xFF7D9D8B),
        background: const Color(0xFFFAF6EE),
        surface: const Color(0xFFFFFFFF),
        surfaceElevated: const Color(0xFFF3ECE0),
        border: const Color(0xFFE5DFD3),
        textPrimary: const Color(0xFF1A1C19),
        textSecondary: const Color(0xFF5A625C),
        accent: const Color(0xFFD4A338),
        interfaceStyle: ThemeInterfaceStyle.classic,
        isOwned: true,
        isDownloaded: true,
        downloadProgress: 1.0,
      ),

      // The La Mancha (Cream White FFFDD0 60%, Terracotta Orange 30%, Obsidian Black Outlines)
      AppThemePreset(
        id: 'theme_the_la_mancha',
        name: 'The La Mancha',
        description: 'Sun-drenched cream white plains (60%), rich terracotta orange clay (30%), and deep obsidian black outlines.',
        eraTag: 'La Mancha Horizon',
        icon: Icons.shield_moon_rounded,
        gemPrice: 0,
        primary: AppColors.laManchaTerracotta, // Terracotta orange (30%)
        secondary: AppColors.laManchaTerracottaDark, // Deep terracotta orange
        background: AppColors.laManchaCreamWhite, // Cream White #FFFDD0 (60%)
        surface: AppColors.laManchaCreamWhite, // Cream White card surface
        surfaceElevated: const Color(0xFFFAF7C8), // Elevated warm cream
        border: AppColors.laManchaObsidianBlack, // Obsidian black outline
        textPrimary: AppColors.laManchaObsidianBlack, // Obsidian black text
        textSecondary: const Color(0xFF3E4148), // Smoky obsidian slate
        accent: const Color(0xFFE2725B), // Radiant terracotta orange
        interfaceStyle: ThemeInterfaceStyle.classic,
        isOwned: true,
        isDownloaded: true,
        downloadProgress: 1.0,
      ),

      // 2. Medieval Fortress & Heraldry (Red / Crimson Family)
      AppThemePreset(
        id: 'theme_medieval',
        name: 'Medieval Citadel',
        description: 'Weathered stone fortress, heraldic crimson, and iron battlements.',
        eraTag: 'Feudal 13th Century',
        icon: Icons.fort_rounded,
        gemPrice: 150,
        primary: const Color(0xFF991B2D), // Royal heraldic crimson red
        secondary: const Color(0xFFBA2D42), // Deep wine red
        background: const Color(0xFFFDF7F7), // Castle stone with warm red tone
        surface: const Color(0xFFFFFFFF),
        surfaceElevated: const Color(0xFFFCEBEB),
        border: const Color(0xFFE8C2C8),
        textPrimary: const Color(0xFF2B1015),
        textSecondary: const Color(0xFF6B474D),
        accent: const Color(0xFFD4A338), // Brass shield gold
        interfaceStyle: ThemeInterfaceStyle.medieval,
        isOwned: false,
        isDownloaded: false,
        downloadProgress: 0.0,
      ),

      // 3. The Black Plague Grimoire (Gothic Obsidian & Dark Violet)
      AppThemePreset(
        id: 'theme_plague',
        name: 'The Black Plague Grimoire',
        description: 'Eerie raven obsidian, apothecary plum, and sinister bone-white.',
        eraTag: '1347 Pandemic Lore',
        icon: Icons.coronavirus_outlined,
        gemPrice: 250,
        primary: const Color(0xFF7B2CBF), // Deep gothic amethyst
        secondary: const Color(0xFF9D4EDD), // Radiant plum
        background: const Color(0xFF0F0E14), // Pure crypt obsidian
        surface: const Color(0xFF191724), // Obsidian stone
        surfaceElevated: const Color(0xFF232032),
        border: const Color(0xFF38334E),
        textPrimary: const Color(0xFFF5F3F8), // Bone white
        textSecondary: const Color(0xFFA099B2),
        accent: const Color(0xFFC77DFF), // Glowing violet
        interfaceStyle: ThemeInterfaceStyle.plague,
        isOwned: false,
        isDownloaded: false,
        downloadProgress: 0.0,
      ),

      // 4. Cozy Hearth & Spiced Tea (Warm Amber & Cinnamon Family)
      AppThemePreset(
        id: 'theme_cozy',
        name: 'Cozy Hearth & Library',
        description: 'Roaring fireplace, roasted chestnut, spiced cinnamon, and steaming chamomile tea.',
        eraTag: 'Victorian Fireside',
        icon: Icons.fireplace_rounded,
        gemPrice: 200,
        primary: const Color(0xFF8B3A1A), // Rich chestnut amber
        secondary: const Color(0xFFC05822), // Spiced cinnamon
        background: const Color(0xFFFCF6ED), // Warm fireside cream
        surface: const Color(0xFFFFFBF7),
        surfaceElevated: const Color(0xFFF5E8D3),
        border: const Color(0xFFE8D3BC),
        textPrimary: const Color(0xFF2C180E),
        textSecondary: const Color(0xFF6E5140),
        accent: const Color(0xFFE28442),
        interfaceStyle: ThemeInterfaceStyle.cozy,
        isOwned: false,
        isDownloaded: false,
        downloadProgress: 0.0,
      ),

      // 5. Enchanted Winter Frost (Glacial Ice Blue Family - Absolutely No Green)
      AppThemePreset(
        id: 'theme_snowy',
        name: 'Enchanted Winter Frost',
        description: 'Glacial ice, frosted pines, sapphire northern lights, and crystalline snow.',
        eraTag: 'Nordic Winter Fable',
        icon: Icons.ac_unit_rounded,
        gemPrice: 200,
        primary: const Color(0xFF1B4965), // Glacial deep sapphire
        secondary: const Color(0xFF2980B9), // Azure ice
        background: const Color(0xFFF0F6FA), // Snowy frost white-blue
        surface: const Color(0xFFFFFFFF),
        surfaceElevated: const Color(0xFFDDEAF4),
        border: const Color(0xFFBCE0F0),
        textPrimary: const Color(0xFF0B192C),
        textSecondary: const Color(0xFF3D5A74),
        accent: const Color(0xFF00A8CC), // Crystalline frost cyan
        interfaceStyle: ThemeInterfaceStyle.snowy,
        isOwned: false,
        isDownloaded: false,
        downloadProgress: 0.0,
      ),

      // 6. Pastoral Fairytale Blossom (Wild Rose Pink Family - Absolutely No Green, No Blue)
      AppThemePreset(
        id: 'theme_cute_meadow',
        name: 'Fairytale Rose Blossom',
        description: 'Soft blushing wildflowers, rose petals, fairy lanterns, and sweet blossom silk.',
        eraTag: 'Enchanted Storybook',
        icon: Icons.local_florist_rounded,
        gemPrice: 180,
        primary: const Color(0xFFC24168), // Wild rose pink
        secondary: const Color(0xFFD85A82), // Soft petal blush
        background: const Color(0xFFFFF0F4), // Delicate blossom pink
        surface: const Color(0xFFFFFFFF),
        surfaceElevated: const Color(0xFFFFE1E8),
        border: const Color(0xFFF7BCCB),
        textPrimary: const Color(0xFF3B121E),
        textSecondary: const Color(0xFF7A4553),
        accent: const Color(0xFFE91E63), // Radiant magenta rose
        interfaceStyle: ThemeInterfaceStyle.classic,
        isOwned: false,
        isDownloaded: false,
        downloadProgress: 0.0,
      ),
    ];
  }
}
