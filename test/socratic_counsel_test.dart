import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quixoria/core/services/gemini_service.dart';
import 'package:quixoria/core/state/app_state.dart';
import 'package:quixoria/features/reader/socratic_counsel_sheet.dart';

void main() {
  group('Socratic Counsel Quick Prompts & Gemini Integration Tests', () {
    test('GeminiService produces distinct chivalric responses for all 4 quick prompts', () async {
      const passage = 'You have been in Afghanistan, I perceive. How on earth did you know that?';
      const bookTitle = 'A Study in Scarlet';

      // 1. What does this mean?
      final r1 = await GeminiService.instance.consultDonQuixote(
        passage: passage,
        bookTitle: bookTitle,
        userQuestion: 'What does this mean?',
        isOnline: false,
      );
      expect(r1.text, contains('Sherlock Holmes deduced right away'));

      // 2. Explain tricky words
      final r2 = await GeminiService.instance.consultDonQuixote(
        passage: passage,
        bookTitle: bookTitle,
        userQuestion: 'Explain tricky words',
        isOnline: false,
      );
      expect(r2.text, contains('tricky words'));
      expect(r2.text, contains('Perceive'));
      expect(r2.text, contains('Afghanistan'));

      // 3. What would Don Quixote do?
      final r3 = await GeminiService.instance.consultDonQuixote(
        passage: passage,
        bookTitle: bookTitle,
        userQuestion: 'What would Don Quixote do?',
        isOnline: false,
      );
      expect(r3.text, contains('Rocinante'));
      expect(r3.text, contains('courage conquers fear'));

      // 4. Tell me what happens next!
      final r4 = await GeminiService.instance.consultDonQuixote(
        passage: passage,
        bookTitle: bookTitle,
        userQuestion: 'Tell me what happens next',
        isOnline: false,
      );
      expect(r4.text, contains('thrill of the unfolding quest'));
    });

    testWidgets('SocraticCounselSheet renders all 4 quick prompts and clicking each updates active question and response', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final appState = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      SocraticCounselSheet.show(
                        context,
                        passage: 'Sherlock Holmes perceived the truth through deduction.',
                        bookTitle: 'A Study in Scarlet',
                        chapterTitle: 'Chapter 1: Mr. Sherlock Holmes',
                        literatureId: 'study_in_scarlet',
                      );
                    },
                    child: const Text('Open Sheet'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Check all 4 quick prompt buttons are rendered
      expect(find.text('💡 What does this mean?'), findsOneWidget);
      expect(find.text('🔍 Explain tricky words'), findsOneWidget);
      expect(find.text('⚔️ What would Don Quixote do?'), findsOneWidget);
      expect(find.text('📖 Tell me what happens next!'), findsOneWidget);

      // Initially 'What does this mean?' is active
      expect(find.text('Question: "What does this mean?"'), findsOneWidget);

      // Click '🔍 Explain tricky words'
      await tester.tap(find.text('🔍 Explain tricky words'));
      await tester.pumpAndSettle();

      // Verify active question updated
      expect(find.text('Question: "Explain tricky words"'), findsOneWidget);
      expect(find.textContaining('Mastering these words'), findsOneWidget);

      // Click '⚔️ What would Don Quixote do?'
      await tester.tap(find.text('⚔️ What would Don Quixote do?'));
      await tester.pumpAndSettle();

      // Verify active question updated
      expect(find.text('Question: "What would Don Quixote do?"'), findsOneWidget);
      expect(find.textContaining('Rocinante'), findsOneWidget);

      // Click '📖 Tell me what happens next!'
      await tester.tap(find.text('📖 Tell me what happens next!'));
      await tester.pumpAndSettle();

      // Verify active question updated
      expect(find.text('Question: "Tell me what happens next"'), findsOneWidget);
      expect(find.textContaining('thrill of the unfolding quest'), findsOneWidget);

      // Click 'Save Advice to Notes'
      expect(find.text('Save Advice to Notes'), findsOneWidget);
      await tester.tap(find.text('Save Advice to Notes'));
      await tester.pumpAndSettle();

      expect(find.text('Inscribed in Thy Notes ✓'), findsOneWidget);
      expect(appState.notes.any((n) => n.title == 'Don Quixote’s Advice'), isTrue);
    });
  });
}
