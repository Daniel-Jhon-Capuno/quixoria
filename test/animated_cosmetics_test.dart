import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quixoria/core/state/app_state.dart';
import 'package:quixoria/features/shop/cosmetics_shop_tab.dart';
import 'package:quixoria/models/cosmetic_item.dart';
import 'package:quixoria/models/profile_avatar_icon.dart';
import 'package:quixoria/models/user_profile.dart';
import 'package:quixoria/shared/widgets/profile_banner_painter.dart';
import 'package:quixoria/shared/widgets/share_card_sheet.dart';

void main() {
  group('Animated Cosmetics Catalog & Ownership Logic', () {
    test('Catalog includes 10 animated borders, 10 animated backgrounds, and 10 animated icons at 5000 gems each', () {
      final animBorders = CosmeticCatalog.frames.where((f) => f.isAnimated).toList();
      final animBanners = ProfileBannerCatalog.banners.where((b) => b.isAnimated).toList();
      final animIcons = ProfileAvatarIconCatalog.all.where((i) => i.isAnimated).toList();

      expect(animBorders.length, 10);
      expect(animBanners.length, 10);
      expect(animIcons.length, 10);

      for (final b in animBorders) {
        expect(b.gemPrice, 5000);
      }
      for (final bg in animBanners) {
        expect(bg.gemPrice, 5000);
      }
      for (final ic in animIcons) {
        expect(ic.gemPrice, 5000);
      }
    });

    test('5000-gem purchase deducts gems, persists in JSON, and enforces single equipped item per category', () {
      final state = AppState();
      final initialGems = state.profile.gems;
      expect(initialGems, lessThan(5000));

      // Cannot buy without 5000 gems
      expect(state.purchaseAvatarFrame('frame_anim_pulsing_halo'), isFalse);
      expect(state.purchaseProfileBanner('banner_anim_fireflies'), isFalse);
      expect(state.purchaseAvatarIcon('avatar_anim_quill'), isFalse);

      // Grant enough gems for all three
      state.addGems(15000);
      final beforeGems = state.profile.gems;

      expect(state.purchaseAvatarFrame('frame_anim_pulsing_halo'), isTrue);
      expect(state.purchaseProfileBanner('banner_anim_fireflies'), isTrue);
      expect(state.purchaseAvatarIcon('avatar_anim_quill'), isTrue);

      expect(state.profile.gems, beforeGems - 15000);
      expect(state.isFrameOwned('frame_anim_pulsing_halo'), isTrue);
      expect(state.isBannerOwned('banner_anim_fireflies'), isTrue);
      expect(state.isAvatarIconOwned('avatar_anim_quill'), isTrue);

      expect(state.profile.equippedFrameId, 'frame_anim_pulsing_halo');
      expect(state.profile.equippedBannerId, 'banner_anim_fireflies');
      expect(state.profile.equippedAvatarIconId, 'avatar_anim_quill');

      // JSON round-trip persistence check
      final restored = UserProfile.fromJson(state.profile.toJson());
      expect(restored.equippedFrameId, 'frame_anim_pulsing_halo');
      expect(restored.equippedBannerId, 'banner_anim_fireflies');
      expect(restored.equippedAvatarIconId, 'avatar_anim_quill');
      expect(restored.ownedFrameIds, contains('frame_anim_pulsing_halo'));
      expect(restored.ownedBannerIds, contains('banner_anim_fireflies'));
      expect(restored.ownedAvatarIconIds, contains('avatar_anim_quill'));
    });

    testWidgets('CosmeticsShopTab shows Animated filter, Preview mode, and disabled Buy with missing gem count', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = AppState();
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: const MaterialApp(
            home: Scaffold(body: CosmeticsShopTab()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      // Filter to Animated (5,000 gems)
      await tester.tap(find.text('✨ Animated (5,000 💎)'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Candlelight Pulse'), findsOneWidget);
      expect(find.text('Buy for 5000 gems'), findsWidgets);
      expect(find.textContaining('more gems'), findsWidgets);

      // Tap Preview on the first animated border
      await tester.tap(find.text('Preview').first);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('✨ LIVE PREVIEW'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      // Reset preview cleanly
      await tester.tap(find.text('Reset'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('CURRENTLY EQUIPPED'), findsOneWidget);
    });

    testWidgets('ShareCardSheet renders Profile Milestone Card with style switcher and PNG export button', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = AppState();
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
            home: Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ShareCardSheet.showProfileCard(ctx),
                  child: const Text('Open Share'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Share'));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Share Profile Milestone Card'), findsOneWidget);
      expect(find.text('Share Card Image (PNG)'), findsOneWidget);
      expect(find.text('Obsidian Gold'), findsOneWidget);
      expect(find.text('Parchment'), findsOneWidget);
      expect(find.text('Royal Forest'), findsOneWidget);
    });
  });
}
