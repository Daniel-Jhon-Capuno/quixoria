import 'dart:math';
import '../../models/quiz_question.dart';

enum QuizDifficultyTier { gentle, intermediate, scholarly }

enum ChestRarity { common, rare, legendary }

class QuizRewardOutcome {
  final ChestRarity chestRarity;
  final int gemsEarned;
  final int leaderboardXpEarned;
  final int bonusHearts;
  final double difficultyMultiplier;
  final String difficultyLabel;

  const QuizRewardOutcome({
    required this.chestRarity,
    required this.gemsEarned,
    required this.leaderboardXpEarned,
    required this.bonusHearts,
    required this.difficultyMultiplier,
    required this.difficultyLabel,
  });
}

/// Adapts quiz questions to the user's chosen difficulty level across all 42 books,
/// shuffles options & order to prevent positional memorization/cheating, and
/// calculates tiered Common / Rare / Legendary chest rewards & Leaderboard XP.
class DifficultyQuizEngine {
  static QuizDifficultyTier tierFromSetting(String setting) {
    final lower = setting.toLowerCase();
    if (lower.contains('gentle') || lower.contains('beginner') || lower.contains('page') || lower.contains('easy')) {
      return QuizDifficultyTier.gentle;
    }
    if (lower.contains('scholar') ||
        lower.contains('advanced') ||
        lower.contains('hard') ||
        lower.contains('master') ||
        lower.contains('knight')) {
      return QuizDifficultyTier.scholarly;
    }
    return QuizDifficultyTier.intermediate;
  }

  static String labelForTier(QuizDifficultyTier tier) {
    switch (tier) {
      case QuizDifficultyTier.gentle:
        return 'Gentle Starter';
      case QuizDifficultyTier.intermediate:
        return 'Intermediate';
      case QuizDifficultyTier.scholarly:
        return 'Scholarly Challenge';
    }
  }

  static double multiplierForTier(QuizDifficultyTier tier) {
    switch (tier) {
      case QuizDifficultyTier.gentle:
        return 1.0;
      case QuizDifficultyTier.intermediate:
        return 1.15;
      case QuizDifficultyTier.scholarly:
        return 1.35;
    }
  }

  /// Prepares a fresh, difficulty-tailored list of questions for any book/level.
  /// Shuffles multiple-choice options and question order on every run so players
  /// cannot memorize option letters (A/B/C/D) on replay.
  static List<QuizQuestion> prepareQuestions({
    required List<QuizQuestion> rawQuestions,
    required String difficultySetting,
    int? seed,
  }) {
    if (rawQuestions.isEmpty) return const [];
    final tier = tierFromSetting(difficultySetting);
    final rng = Random(seed ?? DateTime.now().microsecondsSinceEpoch);

    final adapted = <QuizQuestion>[];
    for (final q in rawQuestions) {
      if ((q.type == QuizType.multipleChoice || q.type == QuizType.roleplay) &&
          q.options.length >= 2) {
        final safeCorrectIdx = q.correctAnswerIndex.clamp(0, q.options.length - 1);
        final correctText = q.options[safeCorrectIdx];

        // Build option list — in Gentle mode, trim 4 options down to 3 clearest choices
        List<String> workingOptions = List<String>.from(q.options);
        if (tier == QuizDifficultyTier.gentle && workingOptions.length > 3) {
          final distractors = <String>[];
          for (int i = 0; i < workingOptions.length; i++) {
            if (i != safeCorrectIdx) distractors.add(workingOptions[i]);
          }
          distractors.shuffle(rng);
          workingOptions = [correctText, ...distractors.take(2)];
        }

        // Shuffle options so the correct answer is never stuck in the same position
        workingOptions.shuffle(rng);
        final newCorrectIdx = workingOptions.indexOf(correctText);

        // Adapt hint & prompt framing to difficulty
        String? adaptedHint = q.contextHint;
        if (tier == QuizDifficultyTier.gentle && (adaptedHint == null || adaptedHint.trim().isEmpty)) {
          adaptedHint = 'Read carefully — look for the detail that directly matches the chapter’s main event.';
        } else if (tier == QuizDifficultyTier.scholarly) {
          // Scholarly Challenge: no automatic hint handout
          adaptedHint = q.contextHint;
        }

        adapted.add(
          QuizQuestion(
            id: q.id,
            prompt: q.prompt,
            options: workingOptions,
            correctAnswerIndex: newCorrectIdx >= 0 ? newCorrectIdx : 0,
            explanation: q.explanation,
            type: q.type,
            clozeSentence: q.clozeSentence,
            targetWord: q.targetWord,
            wordBank: q.wordBank,
            orderedTokens: q.orderedTokens,
            matchingPairs: q.matchingPairs,
            characterSpeaker: q.characterSpeaker,
            contextHint: adaptedHint,
          ),
        );
      } else {
        // Shuffle word banks on Cloze / Reorder so players cannot memorize chip order
        List<String>? shuffledBank = q.wordBank != null ? (List<String>.from(q.wordBank!)..shuffle(rng)) : null;
        adapted.add(
          QuizQuestion(
            id: q.id,
            prompt: q.prompt,
            options: q.options,
            correctAnswerIndex: q.correctAnswerIndex,
            explanation: q.explanation,
            type: q.type,
            clozeSentence: q.clozeSentence,
            targetWord: q.targetWord,
            wordBank: shuffledBank,
            orderedTokens: q.orderedTokens,
            matchingPairs: q.matchingPairs,
            characterSpeaker: q.characterSpeaker,
            contextHint: q.contextHint,
          ),
        );
      }
    }

    // Shuffle question order when there are 3+ questions (keeps sequence fresh on retry)
    if (adapted.length >= 3) {
      adapted.shuffle(rng);
    }

    return adapted;
  }

  /// Calculates tiered chest rarity (Common / Rare / Legendary), Gems,
  /// Leaderboard XP, and bonus hearts based on accuracy + difficulty.
  static QuizRewardOutcome calculateRewards({
    required int correctCount,
    required int totalCount,
    required int baseGems,
    required String difficultySetting,
  }) {
    final safeTotal = totalCount <= 0 ? 1 : totalCount;
    final accuracy = (correctCount / safeTotal).clamp(0.0, 1.0);
    final tier = tierFromSetting(difficultySetting);
    final mult = multiplierForTier(tier);
    final label = labelForTier(tier);

    if (correctCount >= safeTotal) {
      // 100% Flawless -> LEGENDARY CHEST
      return QuizRewardOutcome(
        chestRarity: ChestRarity.legendary,
        gemsEarned: ((baseGems + 35) * mult).round(),
        leaderboardXpEarned: (60 * mult).round(),
        bonusHearts: 2,
        difficultyMultiplier: mult,
        difficultyLabel: label,
      );
    } else if (accuracy >= 0.70) {
      // Few mistakes (70% - 99%) -> RARE CHEST
      return QuizRewardOutcome(
        chestRarity: ChestRarity.rare,
        gemsEarned: ((baseGems * 0.8 + 15) * mult).round(),
        leaderboardXpEarned: (40 * mult).round(),
        bonusHearts: 1,
        difficultyMultiplier: mult,
        difficultyLabel: label,
      );
    } else {
      // Several mistakes (<70%) -> COMMON CHEST
      return QuizRewardOutcome(
        chestRarity: ChestRarity.common,
        gemsEarned: ((baseGems * 0.45 + 5) * mult).round(),
        leaderboardXpEarned: (20 * mult).round(),
        bonusHearts: 0,
        difficultyMultiplier: mult,
        difficultyLabel: label,
      );
    }
  }
}
