import 'package:flutter/material.dart';

enum CosmeticRarity { common, rare, epic, legendary }

/// Motion style for animated glowing avatar borders.
enum AvatarBorderMotion {
  none,
  pulsingGlow,
  rotatingGradient,
  shimmeringGold,
  flickeringEmber,
  moonlightWave,
  enchantedVines,
  orbitingSparkles,
  inkSwirl,
  petalOrbit,
  frostShimmer,
}

extension CosmeticRarityExt on CosmeticRarity {
  String get label {
    switch (this) {
      case CosmeticRarity.common:
        return 'COMMON';
      case CosmeticRarity.rare:
        return 'RARE';
      case CosmeticRarity.epic:
        return 'EPIC';
      case CosmeticRarity.legendary:
        return 'LEGENDARY';
    }
  }

  Color get color {
    switch (this) {
      case CosmeticRarity.common:
        return const Color(0xFF7D8C82);
      case CosmeticRarity.rare:
        return const Color(0xFF2980B9);
      case CosmeticRarity.epic:
        return const Color(0xFF9B59B6);
      case CosmeticRarity.legendary:
        return const Color(0xFFD4A338);
    }
  }
}

class AvatarFrame {
  final String id;
  final String name;
  final String description;
  final int gemPrice;
  final CosmeticRarity rarity;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final IconData emblemIcon;
  final bool hasGlow;
  final AvatarBorderMotion motion;

  bool get isAnimated => motion != AvatarBorderMotion.none;

  const AvatarFrame({
    required this.id,
    required this.name,
    required this.description,
    required this.gemPrice,
    required this.rarity,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.emblemIcon,
    this.hasGlow = false,
    this.motion = AvatarBorderMotion.none,
  });
}

class ScholarTitle {
  final String id;
  final String title;
  final String description;
  final int gemPrice;
  final CosmeticRarity rarity;
  final Color badgeColor;
  final IconData icon;

  const ScholarTitle({
    required this.id,
    required this.title,
    required this.description,
    required this.gemPrice,
    required this.rarity,
    required this.badgeColor,
    required this.icon,
  });
}

/// Complete catalog of 16 collectible Avatar Frames and 20 Scholar Titles.
class CosmeticCatalog {
  static const List<AvatarFrame> frames = [
    AvatarFrame(
      id: 'frame_classic',
      name: 'Classic Parchment',
      description: 'Clean antique brass ring awarded to every new scholar.',
      gemPrice: 0,
      rarity: CosmeticRarity.common,
      primaryColor: Color(0xFFD4A338),
      secondaryColor: Color(0xFF8B6914),
      accentColor: Color(0xFFFAF8F4),
      emblemIcon: Icons.auto_stories_rounded,
    ),
    AvatarFrame(
      id: 'frame_golden_laurel',
      name: 'Golden Laurel',
      description: 'Triumphal wreath of sunlit gold for dedicated readers.',
      gemPrice: 120,
      rarity: CosmeticRarity.rare,
      primaryColor: Color(0xFFE5B842),
      secondaryColor: Color(0xFFB8860B),
      accentColor: Color(0xFFFFF3C4),
      emblemIcon: Icons.workspace_premium_rounded,
      hasGlow: true,
    ),
    AvatarFrame(
      id: 'frame_savannah_sun',
      name: 'Savannah Sun',
      description: 'Warm terracotta clay ring kissed by the La Mancha horizon.',
      gemPrice: 130,
      rarity: CosmeticRarity.rare,
      primaryColor: Color(0xFFD95B30),
      secondaryColor: Color(0xFFF39C12),
      accentColor: Color(0xFFFFE0B2),
      emblemIcon: Icons.wb_sunny_rounded,
    ),
    AvatarFrame(
      id: 'frame_emerald_vine',
      name: 'Secret Garden Vine',
      description: 'Twining ivy and forest emerald from Misselthwaite Manor.',
      gemPrice: 140,
      rarity: CosmeticRarity.rare,
      primaryColor: Color(0xFF27AE60),
      secondaryColor: Color(0xFF1E382B),
      accentColor: Color(0xFFC8E6C9),
      emblemIcon: Icons.eco_rounded,
    ),
    AvatarFrame(
      id: 'frame_frost_halo',
      name: 'Glacial Frost Halo',
      description: 'Crystalline Nordic ice ring shimmering with northern lights.',
      gemPrice: 150,
      rarity: CosmeticRarity.rare,
      primaryColor: Color(0xFF00A8CC),
      secondaryColor: Color(0xFF1B4965),
      accentColor: Color(0xFFE0F7FA),
      emblemIcon: Icons.ac_unit_rounded,
      hasGlow: true,
    ),
    AvatarFrame(
      id: 'frame_autumn_amber',
      name: 'Autumn Hearth',
      description: 'Roasted chestnut and glowing fireplace ember ring.',
      gemPrice: 150,
      rarity: CosmeticRarity.rare,
      primaryColor: Color(0xFFC05822),
      secondaryColor: Color(0xFF8B3A1A),
      accentColor: Color(0xFFFFCC80),
      emblemIcon: Icons.fireplace_rounded,
    ),
    AvatarFrame(
      id: 'frame_sakura_wreath',
      name: 'Sakura Blossom',
      description: 'Delicate wild rose and drifting cherry-blossom petals.',
      gemPrice: 160,
      rarity: CosmeticRarity.epic,
      primaryColor: Color(0xFFE91E63),
      secondaryColor: Color(0xFFF48FB1),
      accentColor: Color(0xFFFFF0F4),
      emblemIcon: Icons.local_florist_rounded,
      hasGlow: true,
    ),
    AvatarFrame(
      id: 'frame_cobalt_compass',
      name: 'Navigator’s Compass',
      description: 'Deep ocean sapphire rim for voyagers of classic seas.',
      gemPrice: 170,
      rarity: CosmeticRarity.epic,
      primaryColor: Color(0xFF2980B9),
      secondaryColor: Color(0xFF154360),
      accentColor: Color(0xFFAED6F1),
      emblemIcon: Icons.explore_rounded,
    ),
    AvatarFrame(
      id: 'frame_crimson_crest',
      name: 'Crimson Citadel',
      description: 'Feudal heraldic ruby and forged steel battlements.',
      gemPrice: 180,
      rarity: CosmeticRarity.epic,
      primaryColor: Color(0xFF991B2D),
      secondaryColor: Color(0xFF4A0E17),
      accentColor: Color(0xFFD4A338),
      emblemIcon: Icons.shield_rounded,
      hasGlow: true,
    ),
    AvatarFrame(
      id: 'frame_midnight_amethyst',
      name: 'Midnight Amethyst',
      description: 'Arcane violet glow brewed in the apothecary grimoire.',
      gemPrice: 200,
      rarity: CosmeticRarity.epic,
      primaryColor: Color(0xFF9D4EDD),
      secondaryColor: Color(0xFF3C096C),
      accentColor: Color(0xFFE0AAFF),
      emblemIcon: Icons.nights_stay_rounded,
      hasGlow: true,
    ),
    AvatarFrame(
      id: 'frame_rose_gold_filigree',
      name: 'Rose Gold Filigree',
      description: 'Intricate Regency metalwork spun from blush gold.',
      gemPrice: 220,
      rarity: CosmeticRarity.epic,
      primaryColor: Color(0xFFD48B8B),
      secondaryColor: Color(0xFFB76E79),
      accentColor: Color(0xFFFFE4E1),
      emblemIcon: Icons.diamond_rounded,
      hasGlow: true,
    ),
    AvatarFrame(
      id: 'frame_royal_velvet',
      name: 'Royal Velvet Seal',
      description: 'Imperial burgundy and gold filigree fit for a sovereign.',
      gemPrice: 230,
      rarity: CosmeticRarity.epic,
      primaryColor: Color(0xFF6A1B4D),
      secondaryColor: Color(0xFFD4A338),
      accentColor: Color(0xFFF8BBD0),
      emblemIcon: Icons.military_tech_rounded,
    ),
    AvatarFrame(
      id: 'frame_starlight_crown',
      name: 'Starlight Crown',
      description: 'Radiant midnight navy studded with celestial gold.',
      gemPrice: 250,
      rarity: CosmeticRarity.legendary,
      primaryColor: Color(0xFF1A237E),
      secondaryColor: Color(0xFFFFD54F),
      accentColor: Color(0xFFFFF8E1),
      emblemIcon: Icons.auto_awesome_rounded,
      hasGlow: true,
    ),
    AvatarFrame(
      id: 'frame_obsidian_flame',
      name: 'Obsidian Flame',
      description: 'Volcanic black steel wreathed in blazing amber fire.',
      gemPrice: 280,
      rarity: CosmeticRarity.legendary,
      primaryColor: Color(0xFFFF6D00),
      secondaryColor: Color(0xFF1A1A1D),
      accentColor: Color(0xFFFFD180),
      emblemIcon: Icons.local_fire_department_rounded,
      hasGlow: true,
    ),
    AvatarFrame(
      id: 'frame_celestial_eclipse',
      name: 'Solar Eclipse',
      description: 'Twin ring of shadow and golden corona in perfect balance.',
      gemPrice: 320,
      rarity: CosmeticRarity.legendary,
      primaryColor: Color(0xFFF5B041),
      secondaryColor: Color(0xFF1C1833),
      accentColor: Color(0xFFFEF9E7),
      emblemIcon: Icons.brightness_3_rounded,
      hasGlow: true,
    ),
    AvatarFrame(
      id: 'frame_archivist_prism',
      name: 'Grand Archivist Prism',
      description: 'Prismatic heirloom halo reserved for masters of literature.',
      gemPrice: 380,
      rarity: CosmeticRarity.legendary,
      primaryColor: Color(0xFF00BFA5),
      secondaryColor: Color(0xFF7B2CBF),
      accentColor: Color(0xFFFFD700),
      emblemIcon: Icons.stars_rounded,
      hasGlow: true,
    ),

    // === ANIMATED & GLOWING AVATAR BORDERS (5,000 GEMS EACH) ===
    AvatarFrame(
      id: 'frame_anim_pulsing_halo',
      name: 'Candlelight Pulse',
      description: 'Softly breathing amber-gold aura inspired by late-night reading.',
      gemPrice: 5000,
      rarity: CosmeticRarity.legendary,
      primaryColor: Color(0xFFFFB74D),
      secondaryColor: Color(0xFF9C4D00),
      accentColor: Color(0xFFFFF3C4),
      emblemIcon: Icons.light_mode_rounded,
      hasGlow: true,
      motion: AvatarBorderMotion.pulsingGlow,
    ),
    AvatarFrame(
      id: 'frame_anim_prismatic_ring',
      name: 'Archivist Aurora Ring',
      description: 'Smoothly rotating iridescent prism ring of celestial ink.',
      gemPrice: 5000,
      rarity: CosmeticRarity.legendary,
      primaryColor: Color(0xFF38BDF8),
      secondaryColor: Color(0xFFA855F7),
      accentColor: Color(0xFF34D399),
      emblemIcon: Icons.auto_awesome_rounded,
      hasGlow: true,
      motion: AvatarBorderMotion.rotatingGradient,
    ),
    AvatarFrame(
      id: 'frame_anim_shimmer_gold',
      name: 'Gilded Manuscript',
      description: 'Illuminated gold-leaf border with a calm sweeping metallic sheen.',
      gemPrice: 5000,
      rarity: CosmeticRarity.legendary,
      primaryColor: Color(0xFFE5B842),
      secondaryColor: Color(0xFF8C6214),
      accentColor: Color(0xFFFFFBE6),
      emblemIcon: Icons.workspace_premium_rounded,
      hasGlow: true,
      motion: AvatarBorderMotion.shimmeringGold,
    ),
    AvatarFrame(
      id: 'frame_anim_hearth_ember',
      name: 'Hearthfire Ember',
      description: 'Warm fireplace rim with gentle flickering sparks rising softly.',
      gemPrice: 5000,
      rarity: CosmeticRarity.legendary,
      primaryColor: Color(0xFFFF7043),
      secondaryColor: Color(0xFF5D190C),
      accentColor: Color(0xFFFFD180),
      emblemIcon: Icons.local_fire_department_rounded,
      hasGlow: true,
      motion: AvatarBorderMotion.flickeringEmber,
    ),
    AvatarFrame(
      id: 'frame_anim_moonlight_tide',
      name: 'Silver Moonlight',
      description: 'Calm lunar silver-blue wave shimmering gently like moonlit ink.',
      gemPrice: 5000,
      rarity: CosmeticRarity.legendary,
      primaryColor: Color(0xFF93C5FD),
      secondaryColor: Color(0xFF1E3A8A),
      accentColor: Color(0xFFEFF6FF),
      emblemIcon: Icons.nights_stay_rounded,
      hasGlow: true,
      motion: AvatarBorderMotion.moonlightWave,
    ),
    AvatarFrame(
      id: 'frame_anim_enchanted_vines',
      name: 'Enchanted Ivy',
      description: 'Living emerald vines with softly glowing dew-buds orbiting calmly.',
      gemPrice: 5000,
      rarity: CosmeticRarity.legendary,
      primaryColor: Color(0xFF34D399),
      secondaryColor: Color(0xFF064E3B),
      accentColor: Color(0xFFD1FAE5),
      emblemIcon: Icons.eco_rounded,
      hasGlow: true,
      motion: AvatarBorderMotion.enchantedVines,
    ),
    AvatarFrame(
      id: 'frame_anim_orbiting_sparkles',
      name: 'Starlight Orbit',
      description: 'Delicate golden stardust sparkles orbiting smoothly around your crest.',
      gemPrice: 5000,
      rarity: CosmeticRarity.legendary,
      primaryColor: Color(0xFFFBBF24),
      secondaryColor: Color(0xFF312E81),
      accentColor: Color(0xFFFEF9C3),
      emblemIcon: Icons.stars_rounded,
      hasGlow: true,
      motion: AvatarBorderMotion.orbitingSparkles,
    ),
    AvatarFrame(
      id: 'frame_anim_ink_nebula',
      name: 'Drifting Ink Nebula',
      description: 'Swirling indigo and amethyst calligraphy currents in slow motion.',
      gemPrice: 5000,
      rarity: CosmeticRarity.legendary,
      primaryColor: Color(0xFFC084FC),
      secondaryColor: Color(0xFF2E1065),
      accentColor: Color(0xFFF3E8FF),
      emblemIcon: Icons.brush_rounded,
      hasGlow: true,
      motion: AvatarBorderMotion.inkSwirl,
    ),
    AvatarFrame(
      id: 'frame_anim_sakura_breeze',
      name: 'Whispering Petals',
      description: 'Soft rose cherry-blossom petals drifting lazily around your portrait.',
      gemPrice: 5000,
      rarity: CosmeticRarity.legendary,
      primaryColor: Color(0xFFF472B6),
      secondaryColor: Color(0xFF831843),
      accentColor: Color(0xFFFCE7F3),
      emblemIcon: Icons.local_florist_rounded,
      hasGlow: true,
      motion: AvatarBorderMotion.petalOrbit,
    ),
    AvatarFrame(
      id: 'frame_anim_frost_aurora',
      name: 'Nordic Frost Shimmer',
      description: 'Crystalline glacial halo with calm glinting diamond points.',
      gemPrice: 5000,
      rarity: CosmeticRarity.legendary,
      primaryColor: Color(0xFF22D3EE),
      secondaryColor: Color(0xFF164E63),
      accentColor: Color(0xFFECFEFF),
      emblemIcon: Icons.ac_unit_rounded,
      hasGlow: true,
      motion: AvatarBorderMotion.frostShimmer,
    ),
  ];

  static const List<ScholarTitle> titles = [
    ScholarTitle(
      id: 'title_apex_sovereign',
      title: 'Sovereign of the Realm',
      description: 'Exclusive Legendary Title awarded to Top 1% / #1 Leaderboard Champions.',
      gemPrice: 99999,
      rarity: CosmeticRarity.legendary,
      badgeColor: Color(0xFFFFB703),
      icon: Icons.workspace_premium_rounded,
    ),
    ScholarTitle(
      id: 'title_knight_errant',
      title: 'Knight Errant of Letters',
      description: 'The classic rank bestowed upon every Quixoria traveler.',
      gemPrice: 0,
      rarity: CosmeticRarity.common,
      badgeColor: Color(0xFF1E382B),
      icon: Icons.shield_rounded,
    ),
    ScholarTitle(
      id: 'title_squire_of_ink',
      title: 'Squire of Ink',
      description: 'An eager apprentice armed with quill and curiosity.',
      gemPrice: 60,
      rarity: CosmeticRarity.common,
      badgeColor: Color(0xFF5D6D7E),
      icon: Icons.edit_rounded,
    ),
    ScholarTitle(
      id: 'title_page_turner',
      title: 'Swift Page Turner',
      description: 'For readers who can never stop at just one chapter.',
      gemPrice: 80,
      rarity: CosmeticRarity.common,
      badgeColor: Color(0xFF2E86C1),
      icon: Icons.menu_book_rounded,
    ),
    ScholarTitle(
      id: 'title_windmill_tilter',
      title: 'Windmill Tilter',
      description: 'Boldly charging into grand adventures across La Mancha.',
      gemPrice: 90,
      rarity: CosmeticRarity.common,
      badgeColor: Color(0xFFD95B30),
      icon: Icons.wind_power_rounded,
    ),
    ScholarTitle(
      id: 'title_keeper_of_tomes',
      title: 'Keeper of Tomes',
      description: 'Guardian of timeless manuscripts and classic shelves.',
      gemPrice: 100,
      rarity: CosmeticRarity.rare,
      badgeColor: Color(0xFF7D5A2B),
      icon: Icons.library_books_rounded,
    ),
    ScholarTitle(
      id: 'title_midnight_reader',
      title: 'Midnight Reader',
      description: 'Prefers reading by glowing candlelight under the stars.',
      gemPrice: 110,
      rarity: CosmeticRarity.rare,
      badgeColor: Color(0xFF283593),
      icon: Icons.nights_stay_rounded,
    ),
    ScholarTitle(
      id: 'title_fireside_storyteller',
      title: 'Fireside Storyteller',
      description: 'Warm hearth, spiced tea, and an unforgettable tale.',
      gemPrice: 110,
      rarity: CosmeticRarity.rare,
      badgeColor: Color(0xFF8B3A1A),
      icon: Icons.fireplace_rounded,
    ),
    ScholarTitle(
      id: 'title_savannah_wanderer',
      title: 'Savannah Wanderer',
      description: 'Roamer of sunlit mesas and distant literary horizons.',
      gemPrice: 115,
      rarity: CosmeticRarity.rare,
      badgeColor: Color(0xFFC85A32),
      icon: Icons.wb_sunny_rounded,
    ),
    ScholarTitle(
      id: 'title_rose_poet',
      title: 'Rose Garden Poet',
      description: 'Keeper of tender verses and blooming fairy meadows.',
      gemPrice: 120,
      rarity: CosmeticRarity.rare,
      badgeColor: Color(0xFFC24168),
      icon: Icons.local_florist_rounded,
    ),
    ScholarTitle(
      id: 'title_frost_voyager',
      title: 'Frostbound Voyager',
      description: 'Braves arctic peaks and northern lights in pursuit of lore.',
      gemPrice: 125,
      rarity: CosmeticRarity.rare,
      badgeColor: Color(0xFF1B4965),
      icon: Icons.ac_unit_rounded,
    ),
    ScholarTitle(
      id: 'title_emerald_botanist',
      title: 'Secret Garden Keeper',
      description: 'Holds the hidden key to Misselthwaite’s walled roses.',
      gemPrice: 130,
      rarity: CosmeticRarity.rare,
      badgeColor: Color(0xFF27AE60),
      icon: Icons.eco_rounded,
    ),
    ScholarTitle(
      id: 'title_wordsmith',
      title: 'Master Wordsmith',
      description: 'Commands a rich lexicon of arcane and poetic words.',
      gemPrice: 140,
      rarity: CosmeticRarity.epic,
      badgeColor: Color(0xFF8E44AD),
      icon: Icons.spellcheck_rounded,
    ),
    ScholarTitle(
      id: 'title_baker_street_sleuth',
      title: 'Baker Street Sleuth',
      description: 'Spots every subtle literary clue with Holmesian precision.',
      gemPrice: 145,
      rarity: CosmeticRarity.epic,
      badgeColor: Color(0xFF34495E),
      icon: Icons.search_rounded,
    ),
    ScholarTitle(
      id: 'title_mariner_of_classics',
      title: 'Mariner of Classics',
      description: 'Sailed the wine-dark sea and survived the Pequod’s chase.',
      gemPrice: 150,
      rarity: CosmeticRarity.epic,
      badgeColor: Color(0xFF1A5276),
      icon: Icons.sailing_rounded,
    ),
    ScholarTitle(
      id: 'title_chronicle_weaver',
      title: 'Chronicle Weaver',
      description: 'Curates notes, quotes, and timeless reflections.',
      gemPrice: 160,
      rarity: CosmeticRarity.epic,
      badgeColor: Color(0xFF117A65),
      icon: Icons.history_edu_rounded,
    ),
    ScholarTitle(
      id: 'title_socratic_sage',
      title: 'Socratic Sage',
      description: 'Seeks truth through dialogue, inquiry, and deep analysis.',
      gemPrice: 175,
      rarity: CosmeticRarity.epic,
      badgeColor: Color(0xFF6C3483),
      icon: Icons.psychology_rounded,
    ),
    ScholarTitle(
      id: 'title_keybearer',
      title: 'Golden Keybearer',
      description: 'Conqueror of full volumes and keeper of Golden Keys.',
      gemPrice: 190,
      rarity: CosmeticRarity.epic,
      badgeColor: Color(0xFFD4A338),
      icon: Icons.vpn_key_rounded,
    ),
    ScholarTitle(
      id: 'title_obsidian_alchemist',
      title: 'Obsidian Alchemist',
      description: 'Distills gothic mysteries into pure literary gold.',
      gemPrice: 210,
      rarity: CosmeticRarity.legendary,
      badgeColor: Color(0xFF5B2C6F),
      icon: Icons.science_rounded,
    ),
    ScholarTitle(
      id: 'title_grand_archivist',
      title: 'Grand Archivist',
      description: 'Supreme custodian of the entire Quixoria Royal Library.',
      gemPrice: 260,
      rarity: CosmeticRarity.legendary,
      badgeColor: Color(0xFF991B2D),
      icon: Icons.account_balance_rounded,
    ),
    ScholarTitle(
      id: 'title_sovereign_of_lore',
      title: 'Sovereign of Lore',
      description: 'Crowned monarch of classic literature and wisdom.',
      gemPrice: 320,
      rarity: CosmeticRarity.legendary,
      badgeColor: Color(0xFFB7950B),
      icon: Icons.workspace_premium_rounded,
    ),
    ScholarTitle(
      id: 'title_immortal_laureate',
      title: 'Immortal Laureate',
      description: 'A legendary name etched forever in the halls of Quixoria.',
      gemPrice: 400,
      rarity: CosmeticRarity.legendary,
      badgeColor: Color(0xFF0E6251),
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  static AvatarFrame frameById(String id) {
    return frames.firstWhere(
      (f) => f.id == id,
      orElse: () => frames.first,
    );
  }

  static ScholarTitle titleById(String id) {
    return titles.firstWhere(
      (t) => t.id == id,
      orElse: () => titles.first,
    );
  }
}
