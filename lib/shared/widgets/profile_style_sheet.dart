import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';
import '../../models/cosmetic_item.dart';
import '../../models/profile_avatar_icon.dart';
import 'duo_button.dart';
import 'framed_mascot_avatar.dart';
import 'profile_banner_painter.dart';
import 'quixoria_dialog.dart';
import 'reward_celebration.dart';

/// Interactive Profile Style & Cosmetics Customizer opened directly from the
/// Profile card's "Style" button. Supports live try-on preview before buying,
/// static & animated 5,000-gem Profile Icons, Avatar Borders, Scenic Banners,
/// and Scholar Titles.
class ProfileStyleSheet extends StatefulWidget {
  const ProfileStyleSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfileStyleSheet(),
    );
  }

  @override
  State<ProfileStyleSheet> createState() => _ProfileStyleSheetState();
}

class _ProfileStyleSheetState extends State<ProfileStyleSheet> {
  int _tab = 0; // 0 = Icons, 1 = Frames, 2 = Banners, 3 = Titles
  String? _previewIconId;
  String? _previewFrameId;
  String? _previewBannerId;

  bool get _isPreviewing =>
      _previewIconId != null || _previewFrameId != null || _previewBannerId != null;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF17191E) : const Color(0xFFFAF8F4);
    final cardBg = isDark ? const Color(0xFF21242B) : Colors.white;
    final border = theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.45);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1C19);
    final textMuted = isDark ? Colors.white70 : const Color(0xFF5A625C);
    final primary = theme.colorScheme.primary;

    final previewFrame = _previewFrameId != null
        ? CosmeticCatalog.frameById(_previewFrameId!)
        : state.equippedFrame;
    final previewBannerId = _previewBannerId ?? state.profile.equippedBannerId;
    final previewIconId = _previewIconId ?? state.profile.equippedAvatarIconId;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: border, width: 2.0),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Text(
                    'Profile Style',
                    style: AppTypography.titleLarge.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  if (_isPreviewing)
                    TextButton(
                      onPressed: () => setState(() {
                        _previewIconId = null;
                        _previewFrameId = null;
                        _previewBannerId = null;
                      }),
                      child: const Text('Reset Preview'),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.gemCyan.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.gemCyan.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond_rounded, size: 15, color: AppColors.gemCyan),
                        const SizedBox(width: 4),
                        Text(
                          '${state.profile.gems}',
                          style: AppTypography.labelMedium.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: textMuted),
                  ),
                ],
              ),
            ),

            // Live Scenic Banner + Animated Avatar Icon + Animated Frame + Title Preview
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _isPreviewing ? AppColors.antiqueGold : border,
                  width: 2.0,
                ),
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
                      height: 98,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: cardBg,
                            shape: BoxShape.circle,
                          ),
                          child: FramedMascotAvatar(
                            frame: previewFrame,
                            size: 66,
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
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: state.equippedTitle.badgeColor,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(state.equippedTitle.icon, size: 13, color: Colors.white),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        state.equippedTitle.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.labelSmall.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
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
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 4-Way Segmented Switch: Icons, Frames, Banners, Titles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border, width: 1.8),
                ),
                child: Row(
                  children: [
                    _tabPill('Icons', 0, primary, textMuted),
                    _tabPill('Frames', 1, primary, textMuted),
                    _tabPill('Banners', 2, primary, textMuted),
                    _tabPill('Titles', 3, primary, textMuted),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Grid / List
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _tab == 0
                    ? _buildIconsGrid(context, state, cardBg, border, textPrimary, primary)
                    : _tab == 1
                        ? _buildFramesGrid(context, state, cardBg, border, textPrimary, textMuted, primary)
                        : _tab == 2
                            ? _buildBannersGrid(context, state, cardBg, border, textPrimary, primary)
                            : _buildTitlesList(context, state, cardBg, border, textPrimary, textMuted, primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabPill(String label, int index, Color primary, Color textMuted) {
    final active = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.instance.light();
          setState(() => _tab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: active ? Colors.white : textMuted,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconsGrid(
    BuildContext context,
    AppState state,
    Color cardBg,
    Color border,
    Color textPrimary,
    Color primary,
  ) {
    final icons = ProfileAvatarIconCatalog.all;
    return GridView.builder(
      key: const ValueKey('icons_tab'),
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.70,
      ),
      itemCount: icons.length,
      itemBuilder: (ctx, i) {
        final item = icons[i];
        final isOwned = state.isAvatarIconOwned(item.id);
        final isEquipped = state.profile.equippedAvatarIconId == item.id;
        final isPreviewed = _previewIconId == item.id;
        final canAfford = state.profile.gems >= item.gemPrice;
        final missing = (item.gemPrice - state.profile.gems).clamp(0, item.gemPrice);

        return GestureDetector(
          onTap: () {
            HapticService.instance.light();
            setState(() => _previewIconId = item.id);
          },
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isEquipped || isPreviewed ? AppColors.antiqueGold : border,
                width: isEquipped || isPreviewed ? 2.4 : 1.8,
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
                        borderRadius: BorderRadius.circular(7),
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
                    if (isEquipped)
                      const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.antiqueGold),
                  ],
                ),
                FramedMascotAvatar(
                  frame: _previewFrameId != null
                      ? CosmeticCatalog.frameById(_previewFrameId!)
                      : state.equippedFrame,
                  size: 58,
                  showMascot: true,
                  avatarIconId: item.id,
                ),
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleSmall.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DuoButton(
                      text: isEquipped
                          ? 'Equipped'
                          : isOwned
                              ? 'Equip'
                              : 'Buy for ${item.gemPrice} gems',
                      variant: isEquipped
                          ? DuoButtonVariant.outline
                          : isOwned
                              ? DuoButtonVariant.primary
                              : (canAfford ? DuoButtonVariant.gold : DuoButtonVariant.outline),
                      height: 34,
                      onPressed: isEquipped
                          ? null
                          : isOwned
                              ? () {
                                  HapticService.instance.light();
                                  SoundService.instance.play(Sfx.tap);
                                  state.equipAvatarIcon(item.id);
                                  setState(() => _previewIconId = null);
                                }
                              : (canAfford
                                  ? () => _handleAvatarIconBuy(ctx, state, item)
                                  : null),
                    ),
                    if (!isOwned && !canAfford)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          'Need $missing more gems',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.streakOrange,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBannersGrid(
    BuildContext context,
    AppState state,
    Color cardBg,
    Color border,
    Color textPrimary,
    Color primary,
  ) {
    final banners = ProfileBannerCatalog.banners;
    return ListView.separated(
      key: const ValueKey('banners_tab'),
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      itemCount: banners.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final item = banners[i];
        final isOwned = state.isBannerOwned(item.id);
        final isEquipped = state.profile.equippedBannerId == item.id;
        final isPreviewed = _previewBannerId == item.id;
        final canAfford = state.profile.gems >= item.gemPrice;
        final missing = (item.gemPrice - state.profile.gems).clamp(0, item.gemPrice);

        return GestureDetector(
          onTap: () {
            HapticService.instance.light();
            setState(() => _previewBannerId = item.id);
          },
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isEquipped || isPreviewed ? AppColors.antiqueGold : border,
                width: isEquipped || isPreviewed ? 2.4 : 1.8,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Stack(
                  children: [
                    ProfileBannerBackground(bannerId: item.id, height: 82),
                    if (item.isAnimated)
                      Positioned(
                        top: 8,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '✨ ANIMATED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppColors.antiqueGold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(item.icon, size: 18, color: item.accentColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.name,
                              style: AppTypography.titleSmall.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (!isEquipped)
                            Text(
                              isPreviewed ? 'Previewing' : 'Tap to preview',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: isPreviewed ? AppColors.antiqueGold : primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DuoButton(
                        text: isEquipped
                            ? 'Equipped'
                            : isOwned
                                ? 'Equip'
                                : 'Buy for ${item.gemPrice} gems',
                        variant: isEquipped
                            ? DuoButtonVariant.outline
                            : isOwned
                                ? DuoButtonVariant.primary
                                : (canAfford ? DuoButtonVariant.gold : DuoButtonVariant.outline),
                        height: 38,
                        onPressed: isEquipped
                            ? null
                            : isOwned
                                ? () {
                                    HapticService.instance.light();
                                    SoundService.instance.play(Sfx.tap);
                                    state.equipProfileBanner(item.id);
                                    setState(() => _previewBannerId = null);
                                  }
                                : (canAfford
                                    ? () => _handleBannerBuy(ctx, state, item)
                                    : null),
                      ),
                      if (!isOwned && !canAfford)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Need $missing more gems',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.streakOrange,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFramesGrid(
    BuildContext context,
    AppState state,
    Color cardBg,
    Color border,
    Color textPrimary,
    Color textMuted,
    Color primary,
  ) {
    final frames = CosmeticCatalog.frames;
    return GridView.builder(
      key: const ValueKey('frames_tab'),
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.70,
      ),
      itemCount: frames.length,
      itemBuilder: (ctx, i) {
        final frame = frames[i];
        final isOwned = state.isFrameOwned(frame.id);
        final isEquipped = state.profile.equippedFrameId == frame.id;
        final isPreviewed = _previewFrameId == frame.id;
        final canAfford = state.profile.gems >= frame.gemPrice;
        final missing = (frame.gemPrice - state.profile.gems).clamp(0, frame.gemPrice);

        return GestureDetector(
          onTap: () {
            HapticService.instance.light();
            setState(() => _previewFrameId = frame.id);
          },
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isEquipped || isPreviewed ? AppColors.antiqueGold : border,
                width: isEquipped || isPreviewed ? 2.4 : 1.8,
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
                            .withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(7),
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
                    if (isEquipped)
                      const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.antiqueGold),
                  ],
                ),
                FramedMascotAvatar(
                  frame: frame,
                  size: 58,
                  showMascot: true,
                  avatarIconId: _previewIconId ?? state.profile.equippedAvatarIconId,
                ),
                Text(
                  frame.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleSmall.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DuoButton(
                      text: isEquipped
                          ? 'Equipped'
                          : isOwned
                              ? 'Equip'
                              : 'Buy for ${frame.gemPrice} gems',
                      variant: isEquipped
                          ? DuoButtonVariant.outline
                          : isOwned
                              ? DuoButtonVariant.primary
                              : (canAfford ? DuoButtonVariant.gold : DuoButtonVariant.outline),
                      height: 34,
                      onPressed: isEquipped
                          ? null
                          : isOwned
                              ? () {
                                  HapticService.instance.light();
                                  SoundService.instance.play(Sfx.tap);
                                  state.equipAvatarFrame(frame.id);
                                  setState(() => _previewFrameId = null);
                                }
                              : (canAfford
                                  ? () => _handleFrameBuy(ctx, state, frame)
                                  : null),
                    ),
                    if (!isOwned && !canAfford)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          'Need $missing more gems',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.streakOrange,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitlesList(
    BuildContext context,
    AppState state,
    Color cardBg,
    Color border,
    Color textPrimary,
    Color textMuted,
    Color primary,
  ) {
    final titles = CosmeticCatalog.titles;
    return ListView.separated(
      key: const ValueKey('titles_tab'),
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      itemCount: titles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final item = titles[i];
        final isOwned = state.isTitleOwned(item.id);
        final isEquipped = state.profile.equippedTitleId == item.id;
        final canAfford = state.profile.gems >= item.gemPrice;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isEquipped ? AppColors.antiqueGold : border,
              width: isEquipped ? 2.4 : 1.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.badgeColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(item.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 104,
                child: DuoButton(
                  text: isEquipped
                      ? 'Equipped'
                      : isOwned
                          ? 'Equip'
                          : '${item.gemPrice} 💎',
                  variant: isEquipped
                      ? DuoButtonVariant.outline
                      : isOwned
                          ? DuoButtonVariant.primary
                          : (canAfford ? DuoButtonVariant.gold : DuoButtonVariant.outline),
                  height: 36,
                  onPressed: isEquipped
                      ? null
                      : isOwned
                          ? () {
                              HapticService.instance.light();
                              SoundService.instance.play(Sfx.tap);
                              state.equipScholarTitle(item.id);
                            }
                          : (canAfford
                              ? () => _handleTitleBuy(ctx, state, item)
                              : null),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleAvatarIconBuy(
    BuildContext context,
    AppState state,
    ProfileAvatarIconItem item,
  ) async {
    final confirmed = await showPurchaseConfirmDialog(
      context: context,
      itemName: '${item.name} Icon',
      priceLabel: '${item.gemPrice} Gems',
      icon: Icons.auto_awesome_rounded,
      description: '${item.description} It will be equipped on your profile right away.',
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
        title: 'Profile Icon Unlocked!',
        subtitle: '${item.name} is now equipped as your signature emblem.',
        icon: Icons.auto_awesome_rounded,
        accentColor: item.accentColor,
      );
    }
  }

  Future<void> _handleBannerBuy(
    BuildContext context,
    AppState state,
    ProfileBannerItem item,
  ) async {
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
        subtitle: '${item.name} is now equipped on your Profile.',
        icon: item.icon,
        accentColor: item.accentColor,
      );
    }
  }

  Future<void> _handleFrameBuy(
    BuildContext context,
    AppState state,
    AvatarFrame frame,
  ) async {
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
        subtitle: '${frame.name} is now framing your profile icon.',
        icon: frame.emblemIcon,
        accentColor: frame.primaryColor,
      );
    }
  }

  Future<void> _handleTitleBuy(
    BuildContext context,
    AppState state,
    ScholarTitle item,
  ) async {
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
        title: 'Scholar Title Unlocked!',
        subtitle: '"${item.title}" is now displayed on your profile.',
        icon: item.icon,
        accentColor: item.badgeColor,
      );
    }
  }
}
