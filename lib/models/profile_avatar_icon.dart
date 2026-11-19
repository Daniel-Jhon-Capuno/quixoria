import 'package:flutter/material.dart';

/// Motion style for animated magical profile icons.
enum AvatarIconMotion {
  none,
  floatingQuill,
  glowingBook,
  swayingBookmark,
  warmLantern,
  tinyFlame,
  lunarGlow,
  compassDrift,
  flutterWings,
  hourglassShimmer,
  orbitingStar,
}

class ProfileAvatarIconItem {
  final String id;
  final String name;
  final String glyph; // Rich visual emoji/emblem (or 'mascot' for Don Quixote)
  final int gemPrice;
  final List<Color> bgGradient;
  final Color accentColor;
  final bool isMascot;
  final AvatarIconMotion motion;
  final String? customDescription;

  bool get isAnimated => motion != AvatarIconMotion.none;

  const ProfileAvatarIconItem({
    required this.id,
    required this.name,
    required this.glyph,
    required this.gemPrice,
    required this.bgGradient,
    required this.accentColor,
    this.isMascot = false,
    this.motion = AvatarIconMotion.none,
    this.customDescription,
  });

  String get rarityLabel => isAnimated
      ? 'ANIMATED'
      : gemPrice == 0
          ? 'STARTER'
          : gemPrice >= 140
              ? 'LEGENDARY'
              : gemPrice >= 90
                  ? 'EPIC'
                  : 'RARE';

  Color get rarityColor => isAnimated
      ? const Color(0xFFE5B842)
      : gemPrice == 0
          ? const Color(0xFF10B981)
          : gemPrice >= 140
              ? const Color(0xFFD4A338)
              : gemPrice >= 90
                  ? const Color(0xFF9B59B6)
                  : const Color(0xFF3B82F6);

  String get description =>
      customDescription ??
      (isMascot
          ? 'Classic Knight Errant portrait'
          : (gemPrice == 0
              ? 'Free starter scholar emblem'
              : 'Collectible $name profile emblem'));
}

/// 20 selectable Profile Avatar Icons (6 free starters + 14 purchasable with Gems).
class ProfileAvatarIconCatalog {
  static const List<ProfileAvatarIconItem> all = [
    // Free Starter Icons
    ProfileAvatarIconItem(
      id: 'avatar_quixote',
      name: 'Don Quixote',
      glyph: 'mascot',
      gemPrice: 0,
      bgGradient: [Color(0xFFFAF3E0), Color(0xFFE7D3A3)],
      accentColor: Color(0xFFD4A338),
      isMascot: true,
    ),
    ProfileAvatarIconItem(
      id: 'avatar_butterfly',
      name: 'Monarch Butterfly',
      glyph: '🦋',
      gemPrice: 0,
      bgGradient: [Color(0xFF38BDF8), Color(0xFF1D4ED8)],
      accentColor: Color(0xFF38BDF8),
    ),
    ProfileAvatarIconItem(
      id: 'avatar_leaf',
      name: 'Emerald Leaf',
      glyph: '🍃',
      gemPrice: 0,
      bgGradient: [Color(0xFF34D399), Color(0xFF065F46)],
      accentColor: Color(0xFF10B981),
    ),
    ProfileAvatarIconItem(
      id: 'avatar_fish',
      name: 'Koi Fish',
      glyph: '🐠',
      gemPrice: 0,
      bgGradient: [Color(0xFF22D3EE), Color(0xFF0E7490)],
      accentColor: Color(0xFF06B6D4),
    ),
    ProfileAvatarIconItem(
      id: 'avatar_owl',
      name: 'Scholar Owl',
      glyph: '🦉',
      gemPrice: 0,
      bgGradient: [Color(0xFFA78BFA), Color(0xFF4C1D95)],
      accentColor: Color(0xFF8B5CF6),
    ),
    ProfileAvatarIconItem(
      id: 'avatar_cat',
      name: 'Velvet Cat',
      glyph: '🐱',
      gemPrice: 0,
      bgGradient: [Color(0xFFFBBF24), Color(0xFFB45309)],
      accentColor: Color(0xFFF59E0B),
    ),

    // Shop-Purchasable Icons
    ProfileAvatarIconItem(
      id: 'avatar_fox',
      name: 'Autumn Fox',
      glyph: '🦊',
      gemPrice: 60,
      bgGradient: [Color(0xFFFB923C), Color(0xFF9A3412)],
      accentColor: Color(0xFFEA580C),
    ),
    ProfileAvatarIconItem(
      id: 'avatar_sakura',
      name: 'Sakura Bloom',
      glyph: '🌸',
      gemPrice: 60,
      bgGradient: [Color(0xFFF9A8D4), Color(0xFFBE185D)],
      accentColor: Color(0xFFEC4899),
    ),
    ProfileAvatarIconItem(
      id: 'avatar_whale',
      name: 'Sapphire Whale',
      glyph: '🐳',
      gemPrice: 75,
      bgGradient: [Color(0xFF60A5FA), Color(0xFF1E3A8A)],
      accentColor: Color(0xFF3B82F6),
    ),
    ProfileAvatarIconItem(
      id: 'avatar_wolf',
      name: 'Silver Wolf',
      glyph: '🐺',
      gemPrice: 80,
      bgGradient: [Color(0xFF94A3B8), Color(0xFF1E293B)],
      accentColor: Color(0xFF64748B),
    ),
    ProfileAvatarIconItem(
      id: 'avatar_deer',
      name: 'Forest Stag',
      glyph: '🦌',
      gemPrice: 80,
      bgGradient: [Color(0xFF84CC16), Color(0xFF365314)],
      accentColor: Color(0xFF65A30D),
    ),
    ProfileAvatarIconItem(
      id: 'avatar_swan',
      name: 'Crystal Swan',
      glyph: '🦢',
      gemPrice: 90,
      bgGradient: [Color(0xFFBAE6FD), Color(0xFF0369A1)],
      accentColor: Color(0xFF0284C7),
    ),
    ProfileAvatarIconItem(
      id: 'avatar_moon',
      name: 'Crescent Moon',
      glyph: '🌙',
      gemPrice: 90,
      bgGradient: [Color(0xFF312E81), Color(0xFF0F172A)],
      accentColor: Color(0xFF818CF8),
    ),
    ProfileAvatarIconItem(
      id: 'avatar_quill',
      name: 'Golden Quill',
      glyph: '🪶',
      gemPrice: 100,
      bgGradient: [Color(0xFFFDE68A), Color(0xFF92400E)],
      accentColor: Color(0xFFD97706),
    ),
    ProfileAvatarIconItem(
      id: 'avatar_rose',
      name: 'Crimson Rose',
      glyph: '🌹',
      gemPrice: 100,
      bgGradient: [Color(0xFFFB7185), Color(0xFF881337)],
      accentColor: Color(0xFFE11D48),
    ),
    ProfileAvatarIconItem(
      id: 'avatar_lion',
      name: 'Sunburst Lion',
      glyph: '🦁',
      gemPrice: 120,
      bgGradient: [Color(0xFFFCD34D), Color(0xFFB45309)],
      accentColor: Color(0xFFD97706),
    ),
    ProfileAvatarIconItem(
      id: 'avatar_unicorn',
      name: 'Starlight Unicorn',
      glyph: '🦄',
      gemPrice: 140,
      bgGradient: [Color(0xFFE879F9), Color(0xFF6B21A8)],
      accentColor: Color(0xFFC026D3),
    ),
    ProfileAvatarIconItem(
      id: 'avatar_phoenix',
      name: 'Ember Phoenix',
      glyph: '🔥',
      gemPrice: 160,
      bgGradient: [Color(0xFFF97316), Color(0xFF991B1B)],
      accentColor: Color(0xFFEF4444),
    ),
    ProfileAvatarIconItem(
      id: 'avatar_dragon',
      name: 'Imperial Dragon',
      glyph: '🐉',
      gemPrice: 180,
      bgGradient: [Color(0xFF10B981), Color(0xFF064E3B)],
      accentColor: Color(0xFF059669),
    ),
    ProfileAvatarIconItem(
      id: 'avatar_crown',
      name: 'Sovereign Crown',
      glyph: '👑',
      gemPrice: 220,
      bgGradient: [Color(0xFFFDE047), Color(0xFF854D0E)],
      accentColor: Color(0xFFEAB308),
    ),

    // === ANIMATED MAGICAL PROFILE ICONS (5,000 GEMS EACH) ===
    ProfileAvatarIconItem(
      id: 'avatar_anim_quill',
      name: 'Enchanted Quill',
      glyph: '🪶',
      gemPrice: 5000,
      bgGradient: [Color(0xFF3B2F63), Color(0xFF1A1433)],
      accentColor: Color(0xFFFDE047),
      motion: AvatarIconMotion.floatingQuill,
      customDescription: 'A floating golden feather quill trailed by gentle ink sparkles.',
    ),
    ProfileAvatarIconItem(
      id: 'avatar_anim_glowing_book',
      name: 'Luminous Grimoire',
      glyph: '📖',
      gemPrice: 5000,
      bgGradient: [Color(0xFF1E3A5F), Color(0xFF0C1829)],
      accentColor: Color(0xFFFFD54F),
      motion: AvatarIconMotion.glowingBook,
      customDescription: 'An open illuminated tome breathing softly with warm golden light.',
    ),
    ProfileAvatarIconItem(
      id: 'avatar_anim_bookmark',
      name: 'Silk Bookmark',
      glyph: '🔖',
      gemPrice: 5000,
      bgGradient: [Color(0xFF7F1D1D), Color(0xFF3B0A0A)],
      accentColor: Color(0xFFFBBF24),
      motion: AvatarIconMotion.swayingBookmark,
      customDescription: 'A royal crimson-and-gold silk bookmark swaying in a calm breeze.',
    ),
    ProfileAvatarIconItem(
      id: 'avatar_anim_lantern',
      name: 'Scholar’s Lantern',
      glyph: '🏮',
      gemPrice: 5000,
      bgGradient: [Color(0xFF432818), Color(0xFF1B100A)],
      accentColor: Color(0xFFFFB74D),
      motion: AvatarIconMotion.warmLantern,
      customDescription: 'A cozy brass reading lantern gently swinging with a warm amber halo.',
    ),
    ProfileAvatarIconItem(
      id: 'avatar_anim_flame',
      name: 'Hearth Flame',
      glyph: '🕯️',
      gemPrice: 5000,
      bgGradient: [Color(0xFF4A1D12), Color(0xFF1C0A06)],
      accentColor: Color(0xFFFF9800),
      motion: AvatarIconMotion.tinyFlame,
      customDescription: 'A calm flickering candle flame casting peaceful golden light.',
    ),
    ProfileAvatarIconItem(
      id: 'avatar_anim_moon',
      name: 'Dreaming Crescent',
      glyph: '🌙',
      gemPrice: 5000,
      bgGradient: [Color(0xFF1E1B4B), Color(0xFF09081B)],
      accentColor: Color(0xFFFEF08A),
      motion: AvatarIconMotion.lunarGlow,
      customDescription: 'A serene golden crescent moon floating amidst twinkling stardust.',
    ),
    ProfileAvatarIconItem(
      id: 'avatar_anim_compass',
      name: 'Voyager’s Compass',
      glyph: '🧭',
      gemPrice: 5000,
      bgGradient: [Color(0xFF134E4A), Color(0xFF062523)],
      accentColor: Color(0xFF5EEAD4),
      motion: AvatarIconMotion.compassDrift,
      customDescription: 'An antique mariner’s compass gently oscillating toward new tales.',
    ),
    ProfileAvatarIconItem(
      id: 'avatar_anim_butterfly',
      name: 'Luminous Morpho',
      glyph: '🦋',
      gemPrice: 5000,
      bgGradient: [Color(0xFF0369A1), Color(0xFF082F49)],
      accentColor: Color(0xFF7DD3FC),
      motion: AvatarIconMotion.flutterWings,
      customDescription: 'A sapphire-glowing literary butterfly softly fluttering its wings.',
    ),
    ProfileAvatarIconItem(
      id: 'avatar_anim_hourglass',
      name: 'Timeless Hourglass',
      glyph: '⏳',
      gemPrice: 5000,
      bgGradient: [Color(0xFF422006), Color(0xFF1C0D02)],
      accentColor: Color(0xFFFCD34D),
      motion: AvatarIconMotion.hourglassShimmer,
      customDescription: 'A gilded scholar’s hourglass floating calmly with shimmering sand.',
    ),
    ProfileAvatarIconItem(
      id: 'avatar_anim_star_crown',
      name: 'Laureate Star',
      glyph: '✨',
      gemPrice: 5000,
      bgGradient: [Color(0xFF312E81), Color(0xFF110F33)],
      accentColor: Color(0xFFFDE047),
      motion: AvatarIconMotion.orbitingStar,
      customDescription: 'A radiant golden starlight crest encircled by softly orbiting motes.',
    ),
  ];

  static ProfileAvatarIconItem byId(String id) {
    return all.firstWhere((e) => e.id == id, orElse: () => all.first);
  }
}
