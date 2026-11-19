import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';
import '../../models/cosmetic_item.dart';
import '../../models/profile_avatar_icon.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/framed_mascot_avatar.dart';
import '../../shared/widgets/profile_banner_painter.dart';
import '../../shared/widgets/quixoria_dialog.dart';
import '../../shared/widgets/reward_celebration.dart';

/// Rich Cosmetics Boutique tab inside the Shop featuring static & animated
/// Profile Icons, Avatar Borders, Profile Backgrounds, and Scholar Titles —
/// with live try-on preview, 5000-gem animated tiers, insufficient-gems
/// guidance, confirmation dialogs, and persistent Provider/Supabase ownership.
class CosmeticsShopTab extends StatefulWidget {
  const CosmeticsShopTab({super.key});

  @override
  State<CosmeticsShopTab> createState() => _CosmeticsShopTabState();
}

class _CosmeticsShopTabState extends State<CosmeticsShopTab> {
  int _section = 0; // 0 = Borders, 1 = Backgrounds, 2 = Icons, 3 = Titles
  bool _animatedOnly = false;

  // Live try-on preview overrides (null = show currently equipped)
  String? _previewFrameId;
  String? _previewBannerId;
  String? _previewIconId;

  bool get _isPreviewing =>
      _previewFrameId != null || _previewBannerId != null || _previewIconId != null;

  void _clearPreview() {
    HapticService.instance.light();
    setState(() {
      _previewFrameId = null;
      _previewBannerId = null;
      _previewIconId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;

    final previewFrame = _previewFrameId != null
        ? CosmeticCatalog.frameById(_previewFrameId!)
        : state.equippedFrame;
    final previewBannerId = _previewBannerId ?? state.profile.equippedBannerId;
    final previewIconId = _previewIconId ?? state.profile.equippedAvatarIconId;
    final equippedTitle = state.equippedTitle;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Profile Preview Card (Banner + Animated Border + Animated Icon + Title)
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _isPreviewing
                    ? AppColors.antiqueGold
                    : previewFrame.primaryColor.withValues(alpha: 0.55),
                width: _isPreviewing ? 2.2 : 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: previewFrame.primaryColor.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ProfileBannerBackground(
                    bannerId: previewBannerId,
                    height: 108,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.48),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isPreviewing
                                    ? AppColors.antiqueGold
                                    : Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              _isPreviewing ? '✨ LIVE PREVIEW' : 'CURRENTLY EQUIPPED',
                              style: const TextStyle(
                                fontSize: 9.5,
                                letterSpacing: 0.7,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (_isPreviewing)
                            GestureDetector(
                              onTap: _clearPreview,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Reset',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.52),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.gemCyan.withValues(alpha: 0.65)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.diamond_rounded, size: 13, color: AppColors.gemCyan),
                                const SizedBox(width: 4),
                                Text(
                                  '${state.profile.gems}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: cardBg,
                              shape: BoxShape.circle,
                            ),
                            child: FramedMascotAvatar(
                              frame: previewFrame,
                              size: 64,
                              showMascot: true,
                              avatarIconId: previewIconId,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.profile.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: equippedTitle.badgeColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(equippedTitle.icon, size: 12, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          equippedTitle.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4-Way Category Switch: Borders | Backgrounds | Icons | Titles
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _segBtn(theme, 'Borders', 0),
                _segBtn(theme, 'Banners', 1),
                _segBtn(theme, 'Icons', 2),
                _segBtn(theme, 'Titles', 3),
              ],
            ),
          ),

          // Filter Pill Row: All vs Animated Only (for Borders, Banners, Icons)
          if (_section != 3) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _filterChip(
                  label: 'All Styles',
                  selected: !_animatedOnly,
                  theme: theme,
                  onTap: () => setState(() => _animatedOnly = false),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: '✨ Animated (5,000 💎)',
                  selected: _animatedOnly,
                  theme: theme,
                  onTap: () => setState(() => _animatedOnly = true),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          if (_section == 0)
            _buildFramesGrid(context, state, theme, isDark)
          else if (_section == 1)
            _buildBannersList(context, state, theme, isDark)
          else if (_section == 2)
            _buildIconsGrid(context, state, theme, isDark)
          else
            _buildTitlesList(context, state, theme),
        ],
      ),
    );
  }

  Widget _segBtn(ThemeData theme, String label, int idx) {
    final active = _section == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.instance.light();
          setState(() => _section = idx);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: active
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticService.instance.light();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.antiqueGold.withValues(alpha: 0.22)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.antiqueGold
                : theme.dividerColor.withValues(alpha: 0.4),
            width: selected ? 1.6 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: selected
                ? AppColors.antiqueGold
                : theme.colorScheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }

  /// Shared Buy / Equip / Insufficient-Gems + Preview action block.
  Widget _buildCosmeticActions({
    required BuildContext context,
    required bool owned,
    required bool equipped,
    required bool isPreviewed,
    required int gemPrice,
    required int userGems,
    required VoidCallback onPreview,
    required VoidCallback onEquip,
    required Future<void> Function() onBuy,
  }) {
    final canAfford = userGems >= gemPrice;
    final missing = (gemPrice - userGems).clamp(0, gemPrice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!equipped)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SizedBox(
              height: 28,
              child: OutlinedButton.icon(
                onPressed: onPreview,
                icon: Icon(
                  isPreviewed ? Icons.visibility_rounded : Icons.visibility_outlined,
                  size: 13,
                ),
                label: Text(
                  isPreviewed ? 'Previewing' : 'Preview',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: isPreviewed ? AppColors.antiqueGold : null,
                  side: BorderSide(
                    color: isPreviewed
                        ? AppColors.antiqueGold
                        : Theme.of(context).dividerColor.withValues(alpha: 0.6),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                ),
              ),
            ),
          ),
        DuoButton(
          text: equipped
              ? 'Equipped'
              : owned
                  ? 'Equip'
                  : 'Buy for $gemPrice gems',
          variant: equipped
              ? DuoButtonVariant.outline
              : owned
                  ? DuoButtonVariant.primary
                  : (canAfford ? DuoButtonVariant.gold : DuoButtonVariant.outline),
          height: 36,
          onPressed: equipped
              ? null
              : owned
                  ? onEquip
                  : (canAfford ? () => onBuy() : null),
        ),
        if (!owned && !canAfford)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Need $missing more gems',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: AppColors.streakOrange,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFramesGrid(BuildContext context, AppState state, ThemeData theme, bool isDark) {
    final frames = _animatedOnly
        ? CosmeticCatalog.frames.where((f) => f.isAnimated).toList()
        : CosmeticCatalog.frames;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: frames.length,
      itemBuilder: (context, index) {
        final frame = frames[index];
        final owned = state.isFrameOwned(frame.id);
        final equipped = state.profile.equippedFrameId == frame.id;
        final isPreviewed = _previewFrameId == frame.id;

        return Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: equipped || isPreviewed
                  ? AppColors.antiqueGold
                  : frame.primaryColor.withValues(alpha: 0.4),
              width: equipped || isPreviewed ? 2.2 : 1.4,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (frame.isAnimated ? AppColors.antiqueGold : frame.rarity.color)
                          .withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      frame.isAnimated ? '✨ ANIMATED' : frame.rarity.label,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: frame.isAnimated ? AppColors.antiqueGold : frame.rarity.color,
                      ),
                    ),
                  ),
                  if (equipped)
                    const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.antiqueGold),
                ],
              ),
              FramedMascotAvatar(
                frame: frame,
                size: 56,
                showMascot: true,
                avatarIconId: _previewIconId ?? state.profile.equippedAvatarIconId,
              ),
              Column(
                children: [
                  Text(
                    frame.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    frame.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 9.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
              _buildCosmeticActions(
                context: context,
                owned: owned,
                equipped: equipped,
                isPreviewed: isPreviewed,
                gemPrice: frame.gemPrice,
                userGems: state.profile.gems,
                onPreview: () {
                  HapticService.instance.light();
                  setState(() => _previewFrameId = frame.id);
                },
                onEquip: () {
                  HapticService.instance.light();
                  SoundService.instance.play(Sfx.tap);
                  state.equipAvatarFrame(frame.id);
                  setState(() => _previewFrameId = null);
                },
                onBuy: () async {
                  final confirmed = await showPurchaseConfirmDialog(
                    context: context,
                    itemName: '${frame.name} Border',
                    priceLabel: '${frame.gemPrice} Gems',
                    icon: frame.emblemIcon,
                    description: frame.description,
                    accentColor: frame.primaryColor,
                  );
                  if (!confirmed || !context.mounted) return;
                  if (state.purchaseAvatarFrame(frame.id)) {
                    setState(() => _previewFrameId = null);
                    SoundService.instance.play(Sfx.purchase);
                    RewardCelebrationOverlay.showCelebration(
                      context,
                      celebrationType: CelebrationType.gems,
                    );
                    await showPurchaseCelebrationDialog(
                      context: context,
                      title: 'Avatar Border Unlocked!',
                      subtitle: '${frame.name} is now equipped on your profile.',
                      icon: frame.emblemIcon,
                      accentColor: frame.primaryColor,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBannersList(BuildContext context, AppState state, ThemeData theme, bool isDark) {
    final banners = _animatedOnly
        ? ProfileBannerCatalog.banners.where((b) => b.isAnimated).toList()
        : ProfileBannerCatalog.banners;

    return Column(
      children: banners.map((item) {
        final owned = state.isBannerOwned(item.id);
        final equipped = state.profile.equippedBannerId == item.id;
        final isPreviewed = _previewBannerId == item.id;
        final canAfford = state.profile.gems >= item.gemPrice;
        final missing = (item.gemPrice - state.profile.gems).clamp(0, item.gemPrice);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: equipped || isPreviewed
                  ? AppColors.antiqueGold
                  : item.accentColor.withValues(alpha: 0.4),
              width: equipped || isPreviewed ? 2.2 : 1.4,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  ProfileBannerBackground(bannerId: item.id, height: 84),
                  Positioned(
                    top: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.52),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.isAnimated ? '✨ ANIMATED' : 'SCENIC',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: item.isAnimated ? AppColors.antiqueGold : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(item.icon, size: 18, color: item.accentColor),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (!equipped)
                          TextButton.icon(
                            onPressed: () {
                              HapticService.instance.light();
                              setState(() => _previewBannerId = item.id);
                            },
                            icon: Icon(
                              isPreviewed ? Icons.visibility_rounded : Icons.visibility_outlined,
                              size: 14,
                            ),
                            label: Text(isPreviewed ? 'Previewing' : 'Preview'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.description,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DuoButton(
                      text: equipped
                          ? 'Equipped'
                          : owned
                              ? 'Equip'
                              : 'Buy for ${item.gemPrice} gems',
                      variant: equipped
                          ? DuoButtonVariant.outline
                          : owned
                              ? DuoButtonVariant.primary
                              : (canAfford ? DuoButtonVariant.gold : DuoButtonVariant.outline),
                      height: 40,
                      onPressed: equipped
                          ? null
                          : owned
                              ? () {
                                  HapticService.instance.light();
                                  SoundService.instance.play(Sfx.tap);
                                  state.equipProfileBanner(item.id);
                                  setState(() => _previewBannerId = null);
                                }
                              : (canAfford
                                  ? () async {
                                      final confirmed = await showPurchaseConfirmDialog(
                                        context: context,
                                        itemName: '${item.name} Background',
                                        priceLabel: '${item.gemPrice} Gems',
                                        icon: item.icon,
                                        description: item.description,
                                        accentColor: item.accentColor,
                                      );
                                      if (!confirmed || !context.mounted) return;
                                      if (state.purchaseProfileBanner(item.id)) {
                                        setState(() => _previewBannerId = null);
                                        SoundService.instance.play(Sfx.purchase);
                                        RewardCelebrationOverlay.showCelebration(
                                          context,
                                          celebrationType: CelebrationType.gems,
                                        );
                                        await showPurchaseCelebrationDialog(
                                          context: context,
                                          title: 'Background Unlocked!',
                                          subtitle: '${item.name} is now active behind your profile.',
                                          icon: item.icon,
                                          accentColor: item.accentColor,
                                        );
                                      }
                                    }
                                  : null),
                    ),
                    if (!owned && !canAfford)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Center(
                          child: Text(
                            'Need $missing more gems',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.streakOrange,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIconsGrid(BuildContext context, AppState state, ThemeData theme, bool isDark) {
    final icons = _animatedOnly
        ? ProfileAvatarIconCatalog.all.where((i) => i.isAnimated).toList()
        : ProfileAvatarIconCatalog.all;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final item = icons[index];
        final owned = state.isAvatarIconOwned(item.id);
        final equipped = state.profile.equippedAvatarIconId == item.id;
        final isPreviewed = _previewIconId == item.id;

        return Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: equipped || isPreviewed
                  ? AppColors.antiqueGold
                  : item.accentColor.withValues(alpha: 0.4),
              width: equipped || isPreviewed ? 2.2 : 1.4,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.rarityColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.isAnimated ? '✨ ANIMATED' : item.rarityLabel,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: item.rarityColor,
                      ),
                    ),
                  ),
                  if (equipped)
                    const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.antiqueGold),
                ],
              ),
              FramedMascotAvatar(
                frame: _previewFrameId != null
                    ? CosmeticCatalog.frameById(_previewFrameId!)
                    : state.equippedFrame,
                size: 56,
                showMascot: true,
                avatarIconId: item.id,
              ),
              Column(
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 9.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
              _buildCosmeticActions(
                context: context,
                owned: owned,
                equipped: equipped,
                isPreviewed: isPreviewed,
                gemPrice: item.gemPrice,
                userGems: state.profile.gems,
                onPreview: () {
                  HapticService.instance.light();
                  setState(() => _previewIconId = item.id);
                },
                onEquip: () {
                  HapticService.instance.light();
                  SoundService.instance.play(Sfx.tap);
                  state.equipAvatarIcon(item.id);
                  setState(() => _previewIconId = null);
                },
                onBuy: () async {
                  final confirmed = await showPurchaseConfirmDialog(
                    context: context,
                    itemName: '${item.name} Profile Icon',
                    priceLabel: '${item.gemPrice} Gems',
                    icon: Icons.auto_awesome_rounded,
                    description: item.description,
                    accentColor: item.accentColor,
                  );
                  if (!confirmed || !context.mounted) return;
                  if (state.purchaseAvatarIcon(item.id)) {
                    setState(() => _previewIconId = null);
                    SoundService.instance.play(Sfx.purchase);
                    RewardCelebrationOverlay.showCelebration(
                      context,
                      celebrationType: CelebrationType.gems,
                    );
                    await showPurchaseCelebrationDialog(
                      context: context,
                      title: '${item.name} Unlocked!',
                      subtitle: 'Your new profile icon is now equipped and visible to other scholars.',
                      icon: Icons.auto_awesome_rounded,
                      accentColor: item.accentColor,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitlesList(BuildContext context, AppState state, ThemeData theme) {
    return Column(
      children: CosmeticCatalog.titles.map((item) {
        final owned = state.isTitleOwned(item.id);
        final equipped = state.profile.equippedTitleId == item.id;
        final canAfford = state.profile.gems >= item.gemPrice;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: equipped
                  ? AppColors.antiqueGold
                  : item.badgeColor.withValues(alpha: 0.35),
              width: equipped ? 2.0 : 1.3,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: item.rarity.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            item.rarity.label,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: item.rarity.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 104,
                child: DuoButton(
                  text: equipped
                      ? 'Equipped'
                      : owned
                          ? 'Equip'
                          : '${item.gemPrice} 💎',
                  variant: equipped
                      ? DuoButtonVariant.outline
                      : owned
                          ? DuoButtonVariant.primary
                          : (canAfford ? DuoButtonVariant.gold : DuoButtonVariant.outline),
                  height: 36,
                  onPressed: equipped
                      ? null
                      : owned
                          ? () {
                              HapticService.instance.light();
                              state.equipScholarTitle(item.id);
                            }
                          : (canAfford
                              ? () async {
                                  final confirmed = await showPurchaseConfirmDialog(
                                    context: context,
                                    itemName: '"${item.title}" Title',
                                    priceLabel: '${item.gemPrice} Gems',
                                    icon: item.icon,
                                    description: item.description,
                                    accentColor: item.badgeColor,
                                  );
                                  if (!confirmed || !context.mounted) return;
                                  if (state.purchaseScholarTitle(item.id)) {
                                    SoundService.instance.play(Sfx.purchase);
                                    await showPurchaseCelebrationDialog(
                                      context: context,
                                      title: 'Title Unlocked!',
                                      subtitle: '"${item.title}" is now proudly displayed on your profile.',
                                      icon: item.icon,
                                      accentColor: item.badgeColor,
                                    );
                                  }
                                }
                              : null),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
