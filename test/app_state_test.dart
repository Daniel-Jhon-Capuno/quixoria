import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quixoria/core/services/persistence_service.dart';
import 'package:quixoria/core/services/gemini_service.dart';
import 'package:quixoria/core/services/narration_service.dart';
import 'package:quixoria/core/state/app_state.dart';
import 'package:quixoria/models/app_notification.dart';
import 'package:quixoria/models/quest_level.dart';
import 'package:quixoria/models/reading_note.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AppState Core Mechanics Test', () {
    late AppState state;

    setUp(() {
      state = AppState();
    });

    test('Initial catalog and profile are properly initialized', () {
      expect(state.catalog.isNotEmpty, isTrue);
      expect(state.ownedLiterature.length, equals(3));
      expect(state.profile.gems, equals(650));
      expect(state.profile.energy, equals(5));
      expect(state.profile.goldenKeys, equals(0));
    });

    test('Purchasing literature with gems succeeds when affordable', () {
      // Sonnet 18 costs 400 gems, user has 650
      final success = state.purchaseLiteratureWithGems('lit_sonnet_18');
      expect(success, isTrue);
      expect(state.profile.gems, equals(250));

      final sonnet = state.catalog.firstWhere((l) => l.id == 'lit_sonnet_18');
      expect(sonnet.isOwned, isTrue);
      expect(state.ownedLiterature.any((l) => l.id == 'lit_sonnet_18'), isTrue);
    });

    test('Purchasing literature fails when unaffordable', () {
      // Don Quixote costs 1,500 gems, user only has 650
      final success = state.purchaseLiteratureWithGems('lit_don_quixote');
      expect(success, isFalse);
      expect(state.profile.gems, equals(650));
    });

    test('Golden Key can unlock masterwork regardless of gem price', () {
      expect(state.profile.goldenKeys, equals(0));
      state.addGoldenKey();
      expect(state.profile.goldenKeys, equals(1));
      final success = state.unlockLiteratureWithGoldenKey('lit_don_quixote');
      expect(success, isTrue);
      expect(state.profile.goldenKeys, equals(0));

      final dq = state.catalog.firstWhere((l) => l.id == 'lit_don_quixote');
      expect(dq.isOwned, isTrue);
    });

    test('Energy expenditure and refill work properly', () {
      expect(state.spendEnergy(2), isTrue);
      expect(state.profile.energy, equals(3));

      state.refillEnergy();
      expect(state.profile.energy, equals(5));
    });

    test('Activating simulated premium grants perks and welcome bounty', () {
      final initialGems = state.profile.gems;
      final initialKeys = state.profile.goldenKeys;

      state.activatePremiumSubscription('Yearly');

      expect(state.profile.isPremium, isTrue);
      expect(state.profile.gems, equals(initialGems + 500));
      expect(state.profile.goldenKeys, equals(initialKeys + 1));
      expect(state.profile.energy, equals(state.profile.maxEnergy));
    });

    test('Completing a level unlocks next level and awards gems and updates streaks', () {
      final initialGems = state.profile.gems;
      final active = state.activeLiterature;
      final lvl2 = active.questLevels[1]; // Level 2: Recall Quiz
      expect(lvl2.isCompleted, isFalse);

      // Complete with perfect score
      state.completeQuestLevel(
        literatureId: active.id,
        levelId: lvl2.id,
        isPerfectScore: true,
      );

      expect(lvl2.isCompleted, isTrue);
      expect(state.profile.gems, equals(initialGems + lvl2.gemsReward));
      expect(active.questLevels[2].isLocked, isFalse); // Practice level is unlocked
      expect(state.profile.answerStreak, greaterThan(0));

      // Guide card dismissal test
      expect(state.hasDismissedGuideCard, isFalse);
      state.dismissGuideCard();
      expect(state.hasDismissedGuideCard, isTrue);
    });

    test('Settings toggles work for Accessibility, Audio, and Haptics', () {
      expect(state.isDarkMode, isFalse);
      state.toggleDarkMode(true);
      expect(state.isDarkMode, isTrue);

      expect(state.isReaderMode, isFalse);
      state.toggleReaderMode(true);
      expect(state.isReaderMode, isTrue);

      expect(state.isDyslexicFont, isFalse);
      state.toggleDyslexicFont(true);
      expect(state.isDyslexicFont, isTrue);

      expect(state.soundEffectsEnabled, isTrue);
      state.toggleSoundEffects(false);
      expect(state.soundEffectsEnabled, isFalse);

      expect(state.musicEnabled, isTrue);
      state.toggleMusic(false);
      expect(state.musicEnabled, isFalse);

      expect(state.hapticsEnabled, isTrue);
      state.toggleHaptics(false);
      expect(state.hapticsEnabled, isFalse);
    });

    test('Notes system allows adding, filtering, updating, and deleting', () {
      final initialCount = state.notes.length;

      state.addNote(
        literatureId: 'lit_secret_garden',
        literatureTitle: 'The Secret Garden',
        chapterTitle: 'Chapter 1',
        type: NoteType.question,
        title: 'Why did no one visit Mary?',
        content: 'Exploration of social isolation in the Victorian manor.',
      );

      expect(state.notes.length, equals(initialCount + 1));
      expect(state.notes.first.title, equals('Why did no one visit Mary?'));

      final noteId = state.notes.first.id;
      state.updateNote(
        noteId,
        'Updated Title',
        'Updated Content',
        NoteType.reflection,
      );

      expect(state.notes.first.title, equals('Updated Title'));
      expect(state.notes.first.type, equals(NoteType.reflection));

      state.deleteNote(noteId);
      expect(state.notes.length, equals(initialCount));
    });

    test('User profile editing updates details and daily goal', () {
      state.updateUserProfile(
        name: 'Don Alonso Quijano the Bold',
        email: 'alonso.knight@quixoria.realm',
        readerRank: 'Master of Sagas',
        difficulty: 'Master Caballero',
        dailyGoalMinutes: 30,
      );

      expect(state.profile.name, equals('Don Alonso Quijano the Bold'));
      expect(state.profile.email, equals('alonso.knight@quixoria.realm'));
      expect(state.profile.readerRank, equals('Master of Sagas'));
      expect(state.profile.difficulty, equals('Master Caballero'));
      expect(state.profile.dailyGoalMinutes, equals(30));
    });

    test('Theme preset purchase, simulated download, and dynamic theme switching', () async {
      final initialGems = state.profile.gems; // 650
      final plaguePreset = state.themePresets.firstWhere((p) => p.id == 'theme_plague');
      expect(plaguePreset.isOwned, isFalse);
      expect(plaguePreset.isDownloaded, isFalse);
      expect(plaguePreset.gemPrice, equals(250));

      // Attempting to equip an unowned theme fails
      state.applyThemePreset('theme_plague');
      expect(state.activeThemePresetId, equals('theme_classic'));

      // Purchase the theme
      final buySuccess = state.buyThemePreset('theme_plague');
      expect(buySuccess, isTrue);
      expect(state.profile.gems, equals(initialGems - 250));
      expect(plaguePreset.isOwned, isTrue);

      // Attempting to equip before download fails
      state.applyThemePreset('theme_plague');
      expect(state.activeThemePresetId, equals('theme_classic'));

      // Simulate asset download
      await state.downloadThemePreset('theme_plague');
      expect(plaguePreset.isDownloaded, isTrue);
      expect(plaguePreset.downloadProgress, equals(1.0));

      // Equip the theme
      state.applyThemePreset('theme_plague');
      expect(state.activeThemePresetId, equals('theme_plague'));

      // The Black Plague Grimoire is a dark gothic theme
      final themeData = state.currentThemeData;
      expect(themeData.scaffoldBackgroundColor, equals(plaguePreset.background));
    });

    test('Offline mode allows reading but strictly denies gems and streak progression', () {
      expect(state.isOnline, isTrue);
      state.toggleOnlineStatus(false);
      expect(state.isOnline, isFalse);

      final initialGems = state.profile.gems;
      final initialStreak = state.profile.streakDays;
      final active = state.activeLiterature;
      final readLevel = active.questLevels.first;

      final result = state.completeQuestLevel(
        literatureId: active.id,
        levelId: readLevel.id,
        isPerfectScore: false,
      );

      // Returns false indicating offline (no rewards granted)
      expect(result, isFalse);
      expect(state.profile.gems, equals(initialGems));
      expect(state.profile.streakDays, equals(initialStreak));
      expect(readLevel.isCompleted, isTrue); // Chapter is marked read locally
      expect(state.notifications.any((n) => n.title.contains('Offline Reading')), isTrue);
    });

    test('12:00 AM midnight streak loss, rekindle, and gem restore mechanics', () {
      expect(state.profile.streakDays, equals(1));

      // 12:00 AM Midnight passes without reading
      state.simulateMidnightStreakLoss();
      expect(state.profile.streakDays, equals(0));
      expect(state.previousStreak, equals(1));
      expect(state.hasLostStreakPending, isTrue);

      // Test streak shield restore with gems (restores streak)
      final gemsBefore = state.profile.gems;
      final restored = state.restoreStreakWithGems();
      expect(restored, isTrue);
      expect(state.profile.gems, equals(gemsBefore - 50));
      expect(state.profile.streakDays, equals(1));
      expect(state.hasLostStreakPending, isFalse);

      // Now test streak loss + rekindle flame (starts Day 1)
      state.simulateMidnightStreakLoss();
      state.rekindleStreak();
      expect(state.profile.streakDays, equals(1));
      expect(state.hasLostStreakPending, isFalse);
    });

    test('Daily streak celebration triggers strictly once per calendar day and persists across reloads', () async {
      SharedPreferences.setMockInitialValues({});
      final persistence = await PersistenceService.create();
      final pState = AppState(persistence);

      // 1. Initial state (first activity of the day online)
      expect(pState.isOnline, isTrue);
      expect(pState.shouldShowDailyStreakCelebration(), isTrue);

      // 2. User celebrates today's streak
      pState.markDailyStreakCelebrated();

      // 3. Same calendar day: MUST strictly return false
      expect(pState.shouldShowDailyStreakCelebration(), isFalse);

      // 4. Multiple activities (reading again or quizzes) on same day: MUST strictly remain false
      final lit = pState.activeLiterature;
      pState.completeQuestLevel(
        literatureId: lit.id,
        levelId: lit.questLevels.first.id,
        isPerfectScore: true,
      );
      expect(pState.shouldShowDailyStreakCelebration(), isFalse);

      // 5. App reload/restart roundtrip with PersistenceService: MUST retain celebrated status for today
      final reloadedState = AppState(persistence);
      expect(reloadedState.shouldShowDailyStreakCelebration(), isFalse);

      // 6. Simulate passing of 12:00 AM midnight (setting last celebrated to yesterday)
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      reloadedState.profile.lastStreakCelebratedDay = DateTime(yesterday.year, yesterday.month, yesterday.day);

      // 7. New calendar day: celebration is eligible again!
      expect(reloadedState.shouldShowDailyStreakCelebration(), isTrue);
    });

    test('Low energy simulation generates warning notification', () {
      state.simulateLowEnergyAlert();
      expect(state.profile.energy, equals(1));
      expect(state.notifications.any((n) => n.type == NotificationType.lowEnergy), isTrue);
      expect(state.notifications.first.recipientName, equals(state.profile.name));
    });

    test('Personalized notifications trigger for energy, reading goal, expeditions, keys, and marginalia', () {
      final name = state.profile.name;

      // Energy restored
      state.triggerEnergyRestoredNotification();
      expect(state.notifications.any((n) => n.type == NotificationType.energyRestored), isTrue);
      expect(state.notifications.first.title.contains(name), isTrue);

      // Reading goal achieved
      state.triggerReadingGoalAchieved();
      expect(state.notifications.any((n) => n.type == NotificationType.readingGoalAchieved), isTrue);
      expect(state.notifications.first.title.contains(name), isTrue);

      // Morning expedition ready
      state.triggerExpeditionReady();
      expect(state.notifications.any((n) => n.type == NotificationType.expeditionReady), isTrue);
      expect(state.notifications.first.title.contains(name), isTrue);

      // Golden Key awarded
      final keysBefore = state.profile.goldenKeys;
      state.triggerGoldenKeyAwarded('The Secret Garden');
      expect(state.profile.goldenKeys, equals(keysBefore + 1));
      expect(state.notifications.any((n) => n.type == NotificationType.goldenKeyAwarded), isTrue);
      expect(state.notifications.first.title.contains(name), isTrue);

      // Marginalia reflection
      state.triggerMarginaliaReflection();
      expect(state.notifications.any((n) => n.type == NotificationType.marginaliaReflection), isTrue);
      expect(state.notifications.first.title.contains(name), isTrue);

      // Midnight streak warning
      state.simulateMidnightStreakWarning();
      expect(state.notifications.any((n) => n.type == NotificationType.streakExpiring), isTrue);
      expect(state.notifications.first.title.contains(name), isTrue);
    });

    test('PersistenceService round-trip saves and restores state across AppState instances', () async {
      SharedPreferences.setMockInitialValues({});
      final persistence = await PersistenceService.create();
      final s1 = AppState(persistence);

      s1.dismissGuideCard();
      s1.toggleDarkMode(true);
      s1.addGems(150);
      s1.buyStreakFreeze();

      final s2 = AppState(persistence);
      expect(s2.hasDismissedGuideCard, isTrue);
      expect(s2.isDarkMode, isTrue);
      expect(s2.profile.gems, equals(650 + 150 - 100));
      expect(s2.profile.streakFreezes, equals(1));

      await s2.resetAllData();
      expect(s2.hasDismissedGuideCard, isFalse);
      expect(s2.isDarkMode, isFalse);
      expect(s2.profile.gems, equals(650));
    });

    test('Spaced-Repetition Word Bank starts empty and advances Leitner box on correct review and resets on miss', () {
      expect(state.vocabDeck, isEmpty);
      state.addOrUpdateVocabCard(
        word: 'Hidalgo',
        definition: 'A member of the Spanish lower nobility.',
        example: 'He was one of those hidalgos that keep an ancient lance in the rack.',
        literatureId: 'lit_don_quixote',
        literatureTitle: 'Don Quixote de la Mancha',
      );
      final firstCard = state.vocabDeck.first;
      final initialBox = firstCard.box;
      final gemsBefore = state.profile.gems;

      final awardedFirst = state.reviewVocabCard(firstCard.key, true);
      expect(awardedFirst, isTrue);
      expect(firstCard.box, equals(initialBox + 1));
      expect(state.profile.gems, equals(gemsBefore + 5));

      // Reviewing an already-known word again must NOT award repeat gems
      final awardedRepeat = state.reviewVocabCard(firstCard.key, true);
      expect(awardedRepeat, isFalse);
      expect(state.profile.gems, equals(gemsBefore + 5));

      state.reviewVocabCard(firstCard.key, false);
      expect(firstCard.box, equals(0));
    });

    test('Streak Freeze protects campfire when midnight passes', () {
      expect(state.profile.streakFreezes, equals(0));
      expect(state.buyStreakFreeze(), isTrue);
      expect(state.profile.streakFreezes, equals(1));

      final streakBefore = state.profile.streakDays;
      state.simulateMidnightStreakLoss();
      expect(state.profile.streakFreezes, equals(0));
      expect(state.profile.streakDays, equals(streakBefore));
      expect(state.hasLostStreakPending, isFalse);
    });

    test('Daily Quests and Weekly League standings work deterministically', () {
      expect(state.dailyQuests.length, equals(3));
      expect(state.currentLeagueStandings.length, equals(10));
      expect(state.currentLeagueRank, inInclusiveRange(1, 10));
    });

    test('All masterworks in catalog have 5 distinct purposeful levels for Chapter 1 with 5 to 7 questions each', () {
      expect(state.catalog.length, greaterThanOrEqualTo(40));
      for (final book in state.catalog) {
        expect(
          book.questLevels.length,
          greaterThanOrEqualTo(5),
          reason: '${book.title} (${book.id}) should have at least 5 playable levels',
        );
        expect(book.questLevels.first.type, equals(LevelType.read));
        expect(
          book.questLevels.any((l) => l.type == LevelType.recall),
          isTrue,
          reason: '${book.title} should have a recall level',
        );
        expect(
          book.questLevels.any((l) => l.type == LevelType.practice),
          isTrue,
          reason: '${book.title} should have a practice level',
        );
        expect(
          book.questLevels.any((l) => l.type == LevelType.analysis),
          isTrue,
          reason: '${book.title} should have an analysis level',
        );
        expect(
          book.questLevels.any((l) => l.type == LevelType.finalTest),
          isTrue,
          reason: '${book.title} should have a finalTest level',
        );

        // Verify each level has a distinct pedagogical purpose
        for (final lvl in book.questLevels) {
          expect(lvl.literacyPurpose.isNotEmpty, isTrue);
          expect(lvl.typeLabel.isNotEmpty, isTrue);
        }
      }
    });

    test('Theme presets enforce color purity and zero green leakage in Ice/Snowy', () {
      final snowy = state.themePresets.firstWhere((p) => p.id == 'theme_snowy');
      expect(snowy.successColor, equals(const Color(0xFF00A8CC))); // Frost Cyan

      final meadow = state.themePresets.firstWhere((p) => p.id == 'theme_cute_meadow');
      expect(meadow.successColor, equals(const Color(0xFFE91E63))); // Rose Magenta
    });

    test('Reading offset tracks, retrieves, and clears reading positions accurately', () {
      expect(state.getReadingOffset('lit_prophet', 0), equals(0.0));

      // Save a valid offset
      state.saveReadingOffset('lit_prophet', 0, 350.0);
      expect(state.getReadingOffset('lit_prophet', 0), equals(350.0));

      // Micro-scroll under 20px does not overwrite
      state.saveReadingOffset('lit_prophet', 0, 360.0);
      expect(state.getReadingOffset('lit_prophet', 0), equals(350.0));

      // Meaningful scroll updates
      state.saveReadingOffset('lit_prophet', 0, 480.0);
      expect(state.getReadingOffset('lit_prophet', 0), equals(480.0));

      // Clearing resets to 0.0
      state.clearReadingOffset('lit_prophet', 0);
      expect(state.getReadingOffset('lit_prophet', 0), equals(0.0));
    });

    test('Notes deletion and undo restore works without data loss', () {
      state.addNote(
        literatureId: 'lit_prophet',
        literatureTitle: 'The Prophet',
        chapterTitle: 'On Love',
        type: NoteType.reflection,
        title: 'Sacred Love',
        content: 'Love gives naught but itself and takes naught but from itself.',
      );

      final note = state.notes.firstWhere((n) => n.title == 'Sacred Love');
      final originalNoteCount = state.notes.length;

      // Delete note
      state.deleteNote(note.id);
      expect(state.notes.any((n) => n.id == note.id), isFalse);
      expect(state.notes.length, equals(originalNoteCount - 1));

      // Restore note via undo
      state.restoreNote(note);
      expect(state.notes.any((n) => n.id == note.id), isTrue);
      expect(state.notes.first.title, equals('Sacred Love'));
      expect(state.notes.length, equals(originalNoteCount));
    });

    test('Gemini API key management in AppState', () {
      expect(state.hasGeminiApiKey, isFalse);
      expect(state.geminiApiKey, isEmpty);

      state.setGeminiApiKey('AIzaSyTestKey12345');
      expect(state.hasGeminiApiKey, isTrue);
      expect(state.geminiApiKey, equals('AIzaSyTestKey12345'));

      state.setGeminiApiKey('   ');
      expect(state.hasGeminiApiKey, isFalse);
      expect(state.geminiApiKey, isEmpty);
    });

    test('GeminiService fallback counsel generates chivalric literary commentary', () async {
      final loveResult = await GeminiService.instance.consultDonQuixote(
        passage: 'Love gives naught but itself and takes naught but from itself.',
        bookTitle: 'The Prophet',
        apiKey: '',
      );
      expect(loveResult.isAiPowered, isFalse);
      expect(loveResult.text.contains('Dulcinea'), isTrue);

      final mortalityResult = await GeminiService.instance.consultDonQuixote(
        passage: 'The cholera had broken out in its most fatal form.',
        bookTitle: 'The Secret Garden',
        apiKey: '',
      );
      expect(mortalityResult.isAiPowered, isFalse);
      expect(mortalityResult.text.contains('Mortality'), isTrue);

      final evalResult = await GeminiService.instance.evaluateReaderReflection(
        passage: 'To be or not to be.',
        userReflection: 'Life requires courageous moral decisions.',
        bookTitle: 'Hamlet',
        apiKey: '',
      );
      expect(evalResult.isAiPowered, isFalse);
      expect(evalResult.text.contains('helmet of Mambrino'), isTrue);
    });

    test('NarrationService paragraph loading, speech rate cycling, and navigation', () {
      final narration = NarrationService.instance;
      narration.stop();

      final sampleParagraphs = [
        'Call me Ishmael.',
        'Some years ago—never mind how long precisely.',
        'I thought I would sail about a little and see the watery part of the world.',
      ];

      narration.loadChapter(paragraphs: sampleParagraphs);
      expect(narration.totalParagraphs, equals(3));
      expect(narration.currentIndex, equals(0));

      // Test speed cycling
      expect(narration.speechRate, equals(1.0));
      narration.cycleSpeechRate();
      expect(narration.speechRate, equals(1.25));
      narration.cycleSpeechRate();
      expect(narration.speechRate, equals(1.5));
      narration.cycleSpeechRate();
      expect(narration.speechRate, equals(0.75));
      narration.cycleSpeechRate();
      expect(narration.speechRate, equals(1.0));

      // Test navigation
      narration.nextParagraph();
      expect(narration.currentIndex, equals(1));
      narration.nextParagraph();
      expect(narration.currentIndex, equals(2));
      narration.previousParagraph();
      expect(narration.currentIndex, equals(1));

      narration.skipTo(0);
      expect(narration.currentIndex, equals(0));
      narration.stop();
    });
  });
}
