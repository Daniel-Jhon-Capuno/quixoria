import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quixoria/core/state/app_state.dart';
import 'package:quixoria/shared/widgets/profile_trophy_shelf.dart';
import 'package:quixoria/shared/widgets/whats_new_sheet.dart';

void main() {
  group('Boss Chapter Battles, Trophy Shelf & What\'s New', () {
    test('recordBossVictory unlocks trophy once, auto-pins, and awards bonus XP/gems', () {
      final state = AppState();
      final startXp = state.profile.weeklyXp;
      final startGems = state.profile.gems;

      final first = state.recordBossVictory(
        literatureId: 'don_quixote',
        literatureTitle: 'Don Quixote',
        comboBonusXp: 80,
        comboBonusGems: 55,
      );

      expect(first, isTrue);
      expect(state.hasDefeatedBossForBook('don_quixote'), isTrue);
      expect(state.pinnedTrophyIds, contains('boss_don_quixote'));
      expect(state.profile.weeklyXp, startXp + 80);
      expect(state.profile.gems, startGems + 55);

      // Replaying boss battle should not duplicate trophy
      final second = state.recordBossVictory(
        literatureId: 'don_quixote',
        literatureTitle: 'Don Quixote',
        comboBonusXp: 50,
        comboBonusGems: 40,
      );
      expect(second, isFalse);
      expect(state.defeatedBossBooks.where((e) => e == 'don_quixote').length, 1);
    });

    test('togglePinTrophy enforces max 3 pinned trophies and supports unpinning', () {
      final state = AppState();
      state.togglePinTrophy('t1');
      state.togglePinTrophy('t2');
      state.togglePinTrophy('t3');
      expect(state.pinnedTrophyIds, ['t1', 't2', 't3']);

      // Pinning a 4th replaces oldest ('t1')
      state.togglePinTrophy('t4');
      expect(state.pinnedTrophyIds, ['t2', 't3', 't4']);

      // Unpinning 't3' removes it
      state.togglePinTrophy('t3');
      expect(state.pinnedTrophyIds, ['t2', 't4']);
    });

    test('shouldShowWhatsNew flips to false after markWhatsNewSeen', () {
      final state = AppState();
      expect(state.shouldShowWhatsNew, isTrue);
      state.markWhatsNewSeen();
      expect(state.shouldShowWhatsNew, isFalse);
    });

    testWidgets('ProfileTrophyShelfCard and WhatsNewSheet render cleanly', (tester) async {
      final state = AppState();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    ProfileTrophyShelfCard(),
                    WhatsNewSheet(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Trophy Showcase Shelf'), findsOneWidget);
      expect(find.text('The Realm Has Evolved!'), findsOneWidget);
      expect(find.text('Boss Chapter Battles & Quiz Combos'), findsOneWidget);
    });
  });
}
