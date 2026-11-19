import 'quiz_question.dart';

enum LevelType {
  read,
  recall,
  practice,
  analysis,
  finalTest,
}

class QuestLevel {
  final String id;
  final String literatureId;
  final int levelNumber;
  final String title;
  final String description;
  final LevelType type;
  final int gemsReward;
  final int energyCost;
  final int chapterIndex;
  final int estimatedMinutes;
  final List<QuizQuestion>? customQuestions;
  bool isCompleted;
  bool isLocked;

  QuestLevel({
    required this.id,
    required this.literatureId,
    required this.levelNumber,
    required this.title,
    required this.description,
    required this.type,
    this.gemsReward = 25,
    this.energyCost = 1,
    this.chapterIndex = 0,
    this.estimatedMinutes = 4,
    this.customQuestions,
    this.isCompleted = false,
    this.isLocked = true,
  });

  String get typeLabel {
    switch (type) {
      case LevelType.read:
        return 'Read';
      case LevelType.recall:
        return 'Recall Quiz';
      case LevelType.practice:
        return 'Vocabulary & Practice';
      case LevelType.analysis:
        return 'Inference & Subtext';
      case LevelType.finalTest:
        return 'Final Assessment';
    }
  }

  String get literacyPurpose {
    switch (type) {
      case LevelType.read:
        return 'Reading Stamina & Deep Literary Immersion';
      case LevelType.recall:
        return 'Literal Comprehension & Factual Chronology';
      case LevelType.practice:
        return 'Lexical Mastery & Context Clues';
      case LevelType.analysis:
        return 'Inferential Deduction & Character Psychology';
      case LevelType.finalTest:
        return 'Thematic Synthesis & Critical Evaluation';
    }
  }
}
