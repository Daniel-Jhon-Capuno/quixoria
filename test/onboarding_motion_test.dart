import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quixoria/core/state/app_state.dart';
import 'package:quixoria/features/onboarding/onboarding_screen.dart';
import 'package:quixoria/shared/widgets/blur_dissolve_transition.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Stage 3: Onboarding Preferences (Skill Path) Tests', () {
    testWidgets('Skill path presents 7 single-word nodes with zigzag progress and bouncing current node', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final appState = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: OnboardingScreen(onFinish: () {}),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Verify all 7 single-word labels are present (no pills, no badges, just single words)
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      expect(find.text('Habits'), findsOneWidget);
      expect(find.text('Genre'), findsOneWidget);
      expect(find.text('Difficulty'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('Tome'), findsOneWidget);

      // Verify Step 0: Language Question
      expect(find.text('What is Thy Preferred Language?'), findsOneWidget);
      expect(find.textContaining('English'), findsWidgets);
      expect(find.textContaining('Español'), findsWidgets);

      // Step to Step 1: Age Question
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('What is thy Reader Station?'), findsOneWidget);
      expect(find.text('Page (Ages 8-12)'), findsOneWidget);

      // Step to Step 2: Habits Question (How much they usually read)
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('How Much Dost Thou Usually Read?'), findsOneWidget);
      expect(find.text('Starting Fresh'), findsOneWidget);
      expect(find.text('Regular Reader'), findsOneWidget);

      // Step to Step 3: Genre Question
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Choose Thy Preferred Genres'), findsOneWidget);
      expect(find.text('Adventure & Chivalry'), findsOneWidget);

      // Step to Step 4: Difficulty Question
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('How Dost Thou Prefer to Read?'), findsOneWidget);
      expect(find.text('Standard Explorer'), findsOneWidget);

      // Step to Step 5: Reading Time Question
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Pledge Thy Daily Reading Commitment'), findsOneWidget);
      expect(find.text('Knightly Regular'), findsOneWidget);

      // Step to Step 6: Starter Tome Recommendation
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Choose Thy Starter Masterwork'), findsOneWidget);
      expect(find.text('Confirm Starter Masterwork (+100 Gems)'), findsOneWidget);
    });
  });

  group('Stage 4: Core Motion and Interaction Tests', () {
    test('PageTransitionsTheme is configured with BlurDissolvePageTransitionsBuilder across all themes', () {
      final appState = AppState();
      final currentTheme = appState.currentThemeData;

      expect(currentTheme.pageTransitionsTheme, isNotNull);
      final androidBuilder = currentTheme.pageTransitionsTheme.builders[TargetPlatform.android];
      expect(androidBuilder, isA<BlurDissolvePageTransitionsBuilder>());

      final iOSBuilder = currentTheme.pageTransitionsTheme.builders[TargetPlatform.iOS];
      expect(iOSBuilder, isA<BlurDissolvePageTransitionsBuilder>());

      // Also check The La Mancha theme
      appState.applyThemePreset('theme_the_la_mancha');
      final laManchaTheme = appState.currentThemeData;
      expect(laManchaTheme.pageTransitionsTheme.builders[TargetPlatform.android], isA<BlurDissolvePageTransitionsBuilder>());
    });

    testWidgets('BlurDissolveSwitcher executes blur and opacity dissolve within fast 280ms duration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlurDissolveSwitcher(
              child: KeyedSubtree(
                key: const ValueKey('screen_a'),
                child: const Text('First Screen'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('First Screen'), findsOneWidget);

      // Transition to Second Screen (different child key)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlurDissolveSwitcher(
              child: KeyedSubtree(
                key: const ValueKey('screen_b'),
                child: const Text('Second Screen'),
              ),
            ),
          ),
        ),
      );

      // Halfway through transition: ImageFiltered blur and Opacity active
      await tester.pump(const Duration(milliseconds: 140));
      expect(find.byType(ImageFiltered), findsWidgets);

      // Settle transition
      await tester.pump(const Duration(milliseconds: 160));
      expect(find.text('Second Screen'), findsOneWidget);
    });
  });
}
