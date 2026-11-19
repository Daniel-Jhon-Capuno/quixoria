import 'quiz_question.dart';

enum LevelType {
  read,
  recall,
  practice,
  analysis,
  finalTest,
  treasureChest,   // 🎁 Milestone Checkpoint Chest
  lightningDuel,   // ⚡ 45-Second Timed Vocab & Trivia Duel
  campfireParley,  // 🎭 In-Character Story Choice & Moral Dilemma
  quoteShrine,     // 📜 Unscramble Iconic Quote -> Mint Aesthetic Quote Card
  wordMatchBlitz,  // 🦉 Tactile 5-Pair Literary Word Match Blitz
  zoneGatekeeper,  // 🏰 Zone Mini-Boss Guarding Transition Between Zones
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

  bool get isSpecialNode =>
      type == LevelType.treasureChest ||
      type == LevelType.lightningDuel ||
      type == LevelType.campfireParley ||
      type == LevelType.quoteShrine ||
      type == LevelType.wordMatchBlitz ||
      type == LevelType.zoneGatekeeper;

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
      case LevelType.treasureChest:
        return 'Milestone Chest';
      case LevelType.lightningDuel:
        return 'Lightning Duel';
      case LevelType.campfireParley:
        return 'Campfire Parley';
      case LevelType.quoteShrine:
        return 'Quote Shrine';
      case LevelType.wordMatchBlitz:
        return 'Word Match Blitz';
      case LevelType.zoneGatekeeper:
        return 'Zone Gatekeeper';
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
      case LevelType.treasureChest:
        return 'Checkpoint Bounty & Reading Momentum Reward';
      case LevelType.lightningDuel:
        return 'Rapid Lexical Recall & Instinctive Comprehension';
      case LevelType.campfireParley:
        return 'Character Empathy, Ethics & Narrative Perspective';
      case LevelType.quoteShrine:
        return 'Syntax Craft & Iconic Literary Memorization';
      case LevelType.wordMatchBlitz:
        return 'Associative Vocabulary & Semantic Mapping';
      case LevelType.zoneGatekeeper:
        return 'Zone Mastery Trial & Boss Synthesis';
    }
  }
}
