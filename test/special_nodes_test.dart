import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quixoria/core/state/app_state.dart';
import 'package:quixoria/data/mock_literature_data.dart';
import 'package:quixoria/data/special_nodes_data.dart';
import 'package:quixoria/features/special_nodes/campfire_parley_screen.dart';
import 'package:quixoria/features/special_nodes/quote_shrine_screen.dart';
import 'package:quixoria/features/special_nodes/word_match_blitz_screen.dart';
import 'package:quixoria/models/quest_level.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Catalog books are enriched with all 6 special Quest Map node types', () {
    final catalog = MockLiteratureData.getInitialCatalog();
    expect(catalog.length, greaterThanOrEqualTo(40));

    final secretGarden = catalog.firstWhere((b) => b.id == 'lit_secret_garden');
    final types = secretGarden.questLevels.map((l) => l.type).toSet();

    expect(types, contains(LevelType.campfireParley));
    expect(types, contains(LevelType.treasureChest));
    expect(types, contains(LevelType.lightningDuel));
    expect(types, contains(LevelType.quoteShrine));
    expect(types, contains(LevelType.wordMatchBlitz));
    expect(types, contains(LevelType.zoneGatekeeper));
  });

  testWidgets('CampfireParleyScreen renders portrait, choices, and awards rewards', (tester) async {
    final appState = AppState();
    final book = appState.catalog.firstWhere((b) => b.id == 'lit_secret_garden');
    final parleyLevel = book.questLevels.firstWhere((l) => l.type == LevelType.campfireParley);

    final beforeGems = appState.profile.gems;
    final beforeXp = appState.profile.weeklyXp;

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: MaterialApp(
          home: CampfireParleyScreen(
            literature: book,
            level: parleyLevel,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('CAMPFIRE PARLEY'), findsOneWidget);
    expect(find.text('LISTENING'), findsOneWidget);

    // Tap the first choice card by its actual label
    final scenario = SpecialNodesData.parleyForBook(book);
    final firstChoice = find.text(scenario.choices.first.label);
    await tester.ensureVisible(firstChoice);
    await tester.tap(firstChoice);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('INSPIRED'), findsOneWidget);

    final claimBtn = find.text('Claim Bounty & Continue');
    await tester.ensureVisible(claimBtn);
    await tester.tap(claimBtn);
    await tester.pump(const Duration(milliseconds: 250));

    expect(appState.profile.gems, greaterThan(beforeGems));
    expect(appState.profile.weeklyXp, greaterThan(beforeXp));
  });

  testWidgets('QuoteShrineScreen and WordMatchBlitzScreen render cleanly', (tester) async {
    final appState = AppState();
    final book = appState.catalog.firstWhere((b) => b.id == 'lit_secret_garden');
    final shrineLevel = book.questLevels.firstWhere((l) => l.type == LevelType.quoteShrine);
    final blitzLevel = book.questLevels.firstWhere((l) => l.type == LevelType.wordMatchBlitz);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: MaterialApp(
          home: QuoteShrineScreen(literature: book, level: shrineLevel),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('FAMOUS QUOTE SHRINE'), findsOneWidget);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: MaterialApp(
          home: WordMatchBlitzScreen(literature: book, level: blitzLevel),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('WORD MATCH BLITZ'), findsOneWidget);
  });
}
