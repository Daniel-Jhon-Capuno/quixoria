import 'package:flutter_test/flutter_test.dart';
import 'package:quixoria/core/services/learning_session_engine.dart';
import 'package:quixoria/data/mock_literature_data.dart';
import 'package:quixoria/models/quest_level.dart';
import 'package:quixoria/models/quiz_question.dart';

void main() {
  group('LearningSessionEngine Duolingo-style Session Generation Tests', () {
    final book = MockLiteratureData.getInitialCatalog().first; // The Secret Garden
    final recallLevel = book.questLevels.firstWhere((l) => l.type == LevelType.recall);

    test('Assembles session with diverse interactive exercise types', () {
      final session = LearningSessionEngine.instance.assembleSession(
        work: book,
        level: recallLevel,
        difficulty: 'Standard Explorer (Unabridged classics with vocabulary support)',
      );

      expect(session.isNotEmpty, isTrue);
      expect(session.length, greaterThanOrEqualTo(5));

      // Verifies presence of interactive types beyond plain multiple choice
      final hasCloze = session.any((q) => q.type == QuizType.cloze);
      final hasReorder = session.any((q) => q.type == QuizType.reorder);
      final hasMatching = session.any((q) => q.type == QuizType.matching);
      final hasRoleplay = session.any((q) => q.type == QuizType.roleplay);
      final hasMCQ = session.any((q) => q.type == QuizType.multipleChoice);

      expect(hasCloze || hasReorder || hasMatching || hasRoleplay, isTrue);
      expect(hasMCQ, isTrue);
    });

    test('Adapts exercise difficulty for "Gentle Stroll" with hints and simplified choices', () {
      final gentleSession = LearningSessionEngine.instance.assembleSession(
        work: book,
        level: recallLevel,
        difficulty: 'Gentle Stroll (Focus on enjoyment; generous hints)',
      );

      // Cloze exercises in gentle stroll should have hints attached and reduced bank size
      final cloze = gentleSession.firstWhere((q) => q.type == QuizType.cloze);
      expect(cloze.contextHint, isNotNull);
      expect(cloze.wordBank!.length, lessThanOrEqualTo(3));
    });

    test('Adapts exercise difficulty for "Master Scholar" with advanced distractors', () {
      final scholarSession = LearningSessionEngine.instance.assembleSession(
        work: book,
        level: recallLevel,
        difficulty: 'Master Scholar (Rigorous trial: uncompromising questions)',
      );

      final cloze = scholarSession.firstWhere((q) => q.type == QuizType.cloze);
      expect(cloze.wordBank!.length, greaterThanOrEqualTo(4));
    });

    test('Generates book-specific matching pairs reflecting real book lore', () {
      final session = LearningSessionEngine.instance.assembleSession(
        work: book,
        level: recallLevel,
        difficulty: 'Standard Explorer',
      );

      final matching = session.firstWhere((q) => q.type == QuizType.matching);
      expect(matching.matchingPairs, isNotNull);
      expect(matching.matchingPairs!.containsKey('Ayah'), isTrue);
      expect(matching.matchingPairs!.containsKey('Misselthwaite'), isTrue);
    });

    test('Injects spaced-repetition Cloze exercises prioritizing missed vocabulary words', () {
      final session = LearningSessionEngine.instance.assembleSession(
        work: book,
        level: recallLevel,
        difficulty: 'Standard Explorer',
        missedWords: ['tyrannical', 'cholera'],
      );

      final reinforcedCloze = session.firstWhere(
        (q) => q.type == QuizType.cloze && (q.prompt.contains('tyrannical') || q.targetWord == 'tyrannical'),
      );
      expect(reinforcedCloze, isNotNull);
      expect(reinforcedCloze.prompt, contains('Spaced-Repetition'));
      expect(reinforcedCloze.explanation, contains('Reinforcing "tyrannical"'));
    });

    test('Never injects words from another book (e.g. "Ayah" into The Prophet)', () {
      final catalog = MockLiteratureData.getInitialCatalog();
      final prophet = catalog.firstWhere(
        (b) => b.id == 'lit_the_prophet',
        orElse: () => catalog.firstWhere((b) => !b.title.toLowerCase().contains('secret garden')),
      );
      final level = prophet.questLevels.firstWhere(
        (l) => l.type == LevelType.recall,
        orElse: () => prophet.questLevels.first,
      );
      final session = LearningSessionEngine.instance.assembleSession(
        work: prophet,
        level: level,
        difficulty: 'Standard Explorer',
        missedWords: ['Ayah', 'Misselthwaite', 'Rocinante'],
      );

      for (final q in session) {
        final blob = [
          q.prompt,
          q.clozeSentence ?? '',
          q.targetWord ?? '',
          ...(q.wordBank ?? const <String>[]),
          ...q.options,
          ...(q.matchingPairs?.keys ?? const <String>[]),
          ...(q.matchingPairs?.values ?? const <String>[]),
        ].join(' ');
        expect(blob.contains('Ayah'), isFalse, reason: 'Leaked Secret Garden word into ${prophet.title}: ${q.id}');
        expect(blob.contains('Misselthwaite'), isFalse);
        expect(blob.contains('Rocinante'), isFalse);
      }
      expect(session.any((q) => q.id.contains('_sr_')), isFalse);
    });

    test('Spaced-repetition cloze uses the book\'s own sentence', () {
      final session = LearningSessionEngine.instance.assembleSession(
        work: book,
        level: recallLevel,
        difficulty: 'Standard Explorer',
        missedWords: ['tyrannical'],
      );
      final sr = session.firstWhere((q) => q.id.contains('_sr_'));
      final bookText = book.chapters.map((c) => c.content).join(' ') + book.description;
      final restored = sr.clozeSentence!.replaceFirst('________', sr.targetWord!);
      expect(bookText.contains(restored), isTrue);
    });

    test('Generates book-specific matching pairs and roleplay dilemmas across major masterworks', () {
      final catalog = MockLiteratureData.getInitialCatalog();
      for (final testBook in catalog) {
        final level = testBook.questLevels.firstWhere(
          (l) => l.type == LevelType.recall,
          orElse: () => testBook.questLevels.first,
        );
        final session = LearningSessionEngine.instance.assembleSession(
          work: testBook,
          level: level,
          difficulty: 'Standard Explorer',
        );

        expect(session.isNotEmpty, isTrue);
        final hasRoleplay = session.any((q) => q.type == QuizType.roleplay);
        expect(hasRoleplay, isTrue);
        final roleplay = session.firstWhere((q) => q.type == QuizType.roleplay);
        expect(roleplay.characterSpeaker, isNotNull);
        expect(roleplay.characterSpeaker!.isNotEmpty, isTrue);
      }
    });
  });
}
