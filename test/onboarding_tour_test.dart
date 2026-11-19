import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quixoria/core/state/app_state.dart';
import 'package:quixoria/features/onboarding/onboarding_screen.dart';
import 'package:quixoria/shared/widgets/quixote_guided_tour_overlay.dart';

void main() {
  testWidgets('OnboardingScreen Step 6 presents 3 tailored candidate books and confirmation dialog', (tester) async {
    final appState = AppState();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: MaterialApp(
          home: OnboardingScreen(onFinish: () {}),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    // Step through the 6 preference steps to Step 6 (Candidate Selection)
    for (int i = 0; i < 6; i++) {
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 400));
      if (i == 5) {
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    // Now on Step 5 (Candidate Selection)
    expect(find.text('Choose Thy Starter Masterwork'), findsOneWidget);
    expect(find.text('Confirm Starter Masterwork (+100 Gems)'), findsOneWidget);

    // Verify multiple candidate books are visible
    expect(find.textContaining('MATCH'), findsWidgets);

    // Tap Confirm button
    await tester.tap(find.text('Confirm Starter Masterwork (+100 Gems)'));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify confirmation dialog popped up
    expect(find.text('Huzzah, Valiant Scholar!'), findsOneWidget);
    expect(find.text('Enter Quixoria & Tour Realm'), findsOneWidget);

    // Confirm choice
    await tester.tap(find.text('Enter Quixoria & Tour Realm'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(appState.hasCompletedOnboarding, isTrue);
  });

  testWidgets('QuixoteGuidedTourOverlay steps through all 7 tips (including Library, Notes, Bazaar) and finishes with adventure confirmation', (tester) async {
    bool tourFinished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuixoteGuidedTourOverlay(
            onFinishTour: () {
              tourFinished = true;
            },
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Step 1: Quest Trail
    expect(find.text('Thy Winding Literary Odyssey'), findsOneWidget);
    expect(find.text('START HERE'), findsOneWidget);

    // Step 2: Vitality & Coffers
    await tester.tap(find.text('Next Tip'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Streaks, Energy & Radiant Gems'), findsOneWidget);
    expect(find.text('ROYAL COFFERS'), findsOneWidget);

    // Step 3: Daily Guild Bounties
    await tester.tap(find.text('Next Tip'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Daily Quests & Scholar Leagues'), findsOneWidget);
    expect(find.text('DAILY DISPATCHES'), findsOneWidget);

    // Step 4: Library (Athenaeum)
    await tester.tap(find.text('Next Tip'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('The Great Library & Tomes'), findsOneWidget);
    expect(find.text('THE LIBRARY'), findsOneWidget);

    // Step 5: Notes & Word Bank (Scriptorium)
    await tester.tap(find.text('Next Tip'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Thy Scriptorium & Word Bank'), findsOneWidget);
    expect(find.text('NOTES & WORDS'), findsOneWidget);

    // Step 6: Bazaar
    await tester.tap(find.text('Next Tip'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('The Royal Bazaar & Treasures'), findsOneWidget);
    expect(find.text('THE BAZAAR'), findsOneWidget);

    // Step 7: Sanctuary & Settings
    await tester.tap(find.text('Next Tip'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Knightly Profile & Sanctuary'), findsOneWidget);
    expect(find.text('SETTINGS & PROFILE'), findsOneWidget);

    // Step 8: Finale Ready Dialog
    await tester.tap(find.text('Next Tip'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Art Thou Ready for Adventure?'), findsOneWidget);
    expect(find.text('Begin My Literary Quest (+100 Gems)'), findsOneWidget);

    // Tap Begin Quest
    await tester.tap(find.text('Begin My Literary Quest (+100 Gems)'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tourFinished, isTrue);
  });

  testWidgets('QuixoteGuidedTourOverlay Back button navigates in reverse and Skip Tour completes early', (tester) async {
    bool tourFinished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuixoteGuidedTourOverlay(
            onFinishTour: () {
              tourFinished = true;
            },
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Initially at Step 1: Quest Trail
    expect(find.text('START HERE'), findsOneWidget);

    // Advance to Step 2
    await tester.tap(find.text('Next Tip'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ROYAL COFFERS'), findsOneWidget);

    // Press Back button to return to Step 1
    expect(find.text('Back'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('START HERE'), findsOneWidget);

    // Press Skip Tour
    expect(find.text('Skip Tour'), findsOneWidget);
    await tester.tap(find.text('Skip Tour'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tourFinished, isTrue);
  });
}
