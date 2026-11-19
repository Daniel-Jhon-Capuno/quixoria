import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quixoria/core/services/narration_service.dart';
import 'package:quixoria/features/reader/narrator_model_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Natural Narrator Model Persona & Service Tests', () {
    test('NarratorPersona definitions and lookup', () {
      expect(NarratorPersona.values.length, 3);
      expect(NarratorPersona.grandKnight.id, 'grand_knight');
      expect(NarratorPersona.grandKnight.name, 'Sir Quixote');

      expect(NarratorPersona.gentleBard.id, 'gentle_bard');
      expect(NarratorPersona.gentleBard.name, 'Lady Dulcinea');

      expect(NarratorPersona.classicScholar.id, 'classic_scholar');
      expect(NarratorPersona.classicScholar.name, 'Royal Scholar');

      expect(NarratorPersona.fromId('gentle_bard'), NarratorPersona.gentleBard);
      expect(NarratorPersona.fromId('unknown_id'), NarratorPersona.grandKnight);
    });

    test('NarrationService switches persona and updates state', () async {
      final service = NarrationService.instance;
      await service.setPersona(NarratorPersona.gentleBard);
      expect(service.persona, NarratorPersona.gentleBard);

      await service.setPersona(NarratorPersona.classicScholar);
      expect(service.persona, NarratorPersona.classicScholar);

      await service.setPersona(NarratorPersona.grandKnight);
      expect(service.persona, NarratorPersona.grandKnight);
    });

    testWidgets('NarratorModelSheet renders all 3 personas and handles selection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => NarratorModelSheet.show(context),
                  child: const Text('Open Narrator Sheet'),
                );
              },
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Narrator Sheet'));
      await tester.pumpAndSettle();

      // Check title and descriptions
      expect(find.text('Natural Voice Narrators'), findsOneWidget);
      expect(find.text('Sir Quixote'), findsOneWidget);
      expect(find.text('Lady Dulcinea'), findsOneWidget);
      expect(find.text('Royal Scholar'), findsOneWidget);

      // Tap on Lady Dulcinea card
      await tester.tap(find.text('Lady Dulcinea'));
      await tester.pumpAndSettle();
      expect(NarrationService.instance.persona, NarratorPersona.gentleBard);

      // Tap on Royal Scholar card
      await tester.tap(find.text('Royal Scholar'));
      await tester.pumpAndSettle();
      expect(NarrationService.instance.persona, NarratorPersona.classicScholar);
    });
  });
}
