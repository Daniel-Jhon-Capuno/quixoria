import 'package:flutter_test/flutter_test.dart';
import 'package:quixoria/data/mock_literature_data.dart';
import 'package:quixoria/models/quest_level.dart';

void main() {
  group('Catalog Distinct Levels & Pedagogical Chapter Structure Tests', () {
    test('Every book has distinct counts of levels and chapters starting with Read level', () {
      final catalog = MockLiteratureData.getInitialCatalog();
      expect(catalog.isNotEmpty, isTrue);

      final levelCounts = <int>{};

      for (final book in catalog) {
        // Collect level counts across the catalog
        levelCounts.add(book.questLevels.length);

        // Verify each chapter starts with a Read level
        for (int chIdx = 0; chIdx < book.chapters.length; chIdx++) {
          final chapterLevels = book.questLevels.where((l) => l.chapterIndex == chIdx).toList();
          if (chapterLevels.isNotEmpty) {
            expect(
              chapterLevels.first.type,
              equals(LevelType.read),
              reason: '${book.title} Chapter ${chIdx + 1} must start with a reading session',
            );
          }
        }

        // Verify the last level of catalog books is a culminating Grand Apex Exam
        if (book.questLevels.length > 5) {
          expect(
            book.questLevels.last.type,
            equals(LevelType.finalTest),
            reason: '${book.title} final level should be finalTest',
          );
        }
      }

      // Verify that books possess distinct level counts across the library (not uniform)
      expect(levelCounts.length, greaterThanOrEqualTo(5),
          reason: 'Different book scopes must have distinct counts of levels (e.g. 11, 16, 21, 26, 31)');
    });
  });
}
