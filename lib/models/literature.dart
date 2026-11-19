import 'quest_level.dart';
import 'quiz_question.dart';

enum LiteratureType {
  novel,
  shortStory,
  poem,
  sonnet,
  classic,
}

extension LiteratureTypeExtension on LiteratureType {
  String get label {
    switch (this) {
      case LiteratureType.novel:
        return 'Novel';
      case LiteratureType.shortStory:
        return 'Short Story';
      case LiteratureType.poem:
        return 'Poem';
      case LiteratureType.sonnet:
        return 'Sonnet';
      case LiteratureType.classic:
        return 'Classic';
    }
  }
}

class Chapter {
  final String id;
  final int chapterNumber;
  final String title;
  final String content;
  final int estimatedMinutes;
  final String? quoteHighlight;
  final String? quoteContext;

  const Chapter({
    required this.id,
    required this.chapterNumber,
    required this.title,
    required this.content,
    this.estimatedMinutes = 5,
    this.quoteHighlight,
    this.quoteContext,
  });
}

class Literature {
  final String id;
  final String title;
  final String author;
  final String description;
  final LiteratureType type;
  final List<String> genres;
  final int gemCost;
  final int totalChapters;
  final List<Chapter> chapters;
  final List<QuestLevel> questLevels;
  final Map<int, List<QuizQuestion>> recallQuizzes;
  final Map<int, List<QuizQuestion>> practiceQuizzes;
  final List<QuizQuestion> finalExam;
  
  // Dynamic state attributes
  bool isOwned;
  int currentLevelIndex;
  int chaptersCompleted;
  int gemsEarned;

  Literature({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.type,
    required this.genres,
    required this.gemCost,
    required this.totalChapters,
    required this.chapters,
    required this.questLevels,
    this.recallQuizzes = const {},
    this.practiceQuizzes = const {},
    this.finalExam = const [],
    this.isOwned = false,
    this.currentLevelIndex = 0,
    this.chaptersCompleted = 0,
    this.gemsEarned = 0,
  });

  double get progressPercentage {
    if (questLevels.isEmpty) return 0.0;
    final completedCount = questLevels.where((l) => l.isCompleted).length;
    return (completedCount / questLevels.length).clamp(0.0, 1.0);
  }
}
