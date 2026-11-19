import 'package:flutter_test/flutter_test.dart';
import 'package:quixoria/core/services/persistence_service.dart';
import 'package:quixoria/core/state/app_state.dart';
import 'package:quixoria/models/cosmetic_item.dart';
import 'package:quixoria/models/profile_avatar_icon.dart';
import 'package:quixoria/shared/widgets/profile_banner_painter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cloud & Reinstall Persistence Round-Trip', () {
    test(
      'preserves Caballero Pass, animated cosmetics, books, themes, gems & streak across reinstall',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs1 = await PersistenceService.create();

        // 1. User plays, activates Caballero Pass, buys animated cosmetics, themes, books, and builds streak
        final original = AppState(prefs1);
        original.activatePremiumSubscription('Caballero Annual');
        original.addGems(50000);

        final animFrame = CosmeticCatalog.frames.firstWhere((f) => f.isAnimated);
        final animBanner = ProfileBannerCatalog.banners.firstWhere((b) => b.isAnimated);
        final animIcon = ProfileAvatarIconCatalog.all.firstWhere((i) => i.isAnimated);

        expect(original.purchaseAvatarFrame(animFrame.id), isTrue);
        expect(original.purchaseProfileBanner(animBanner.id), isTrue);
        expect(original.purchaseAvatarIcon(animIcon.id), isTrue);

        original.equipAvatarFrame(animFrame.id);
        original.equipProfileBanner(animBanner.id);
        original.equipAvatarIcon(animIcon.id);

        // Unlock a paid book and a paid theme
        final paidBook = original.catalog.firstWhere((b) => !b.isOwned);
        expect(original.purchaseLiteratureWithGems(paidBook.id), isTrue);

        final paidTheme = original.themePresets.firstWhere((t) => !t.isOwned);
        expect(original.buyThemePreset(paidTheme.id), isTrue);

        // Record reading activity to extend streak
        original.logReadingMinutes(10);

        final savedSnapshot = original.toPersistableJson();
        final expectedGems = original.profile.gems;
        final expectedStreak = original.profile.streakDays;

        // 2. Simulate full uninstall -> fresh device -> cloud payload arrives & is saved locally
        SharedPreferences.setMockInitialValues({});
        final prefs2 = await PersistenceService.create();
        await prefs2.saveState(savedSnapshot);

        // 3. Boot a brand-new AppState from the restored cloud snapshot
        final restored = AppState(prefs2);

        // Verify Caballero Pass (isPremium)
        expect(restored.profile.isPremium, isTrue);

        // Verify gems & streak
        expect(restored.profile.gems, expectedGems);
        expect(restored.profile.streakDays, expectedStreak);
        expect(restored.profile.streakDays, greaterThanOrEqualTo(1));

        // Verify all animated cosmetics owned & equipped
        expect(restored.profile.ownedFrameIds, contains(animFrame.id));
        expect(restored.profile.ownedBannerIds, contains(animBanner.id));
        expect(restored.profile.ownedAvatarIconIds, contains(animIcon.id));
        expect(restored.profile.equippedFrameId, animFrame.id);
        expect(restored.profile.equippedBannerId, animBanner.id);
        expect(restored.profile.equippedAvatarIconId, animIcon.id);

        // Verify owned book & theme
        expect(
          restored.catalog.firstWhere((b) => b.id == paidBook.id).isOwned,
          isTrue,
        );
        expect(
          restored.themePresets.firstWhere((t) => t.id == paidTheme.id).isOwned,
          isTrue,
        );
      },
    );
  });
}
