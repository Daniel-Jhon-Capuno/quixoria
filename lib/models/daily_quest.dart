import 'dart:math';
import 'package:flutter/material.dart';

/// What a daily quest measures.
enum QuestMetric {
  levelsCompleted,
  gemsEarned,
  perfectQuizzes,
  wordsReviewed,
  correctAnswers,
  chaptersRead,
}

class DailyQuest {
  final String id;
  final QuestMetric metric;
  final int target;
  final int rewardGems;
  int progress;
  bool claimed;

  DailyQuest({
    required this.id,
    required this.metric,
    required this.target,
    required this.rewardGems,
    this.progress = 0,
    this.claimed = false,
  });

  bool get isComplete => progress >= target;
  bool get canClaim => isComplete && !claimed;
  double get fraction => (progress / target).clamp(0.0, 1.0);

  String get title {
    switch (metric) {
      case QuestMetric.levelsCompleted:
        return target == 1 ? 'Complete 1 level' : 'Complete $target levels';
      case QuestMetric.gemsEarned:
        return 'Earn $target gems';
      case QuestMetric.perfectQuizzes:
        return target == 1 ? 'Ace a quiz with no mistakes' : 'Ace $target quizzes with no mistakes';
      case QuestMetric.wordsReviewed:
        return 'Review $target words in your Word Bank';
      case QuestMetric.correctAnswers:
        return 'Answer $target questions correctly';
      case QuestMetric.chaptersRead:
        return target == 1 ? 'Read 1 chapter' : 'Read $target chapters';
    }
  }

  IconData get icon {
    switch (metric) {
      case QuestMetric.levelsCompleted:
        return Icons.flag_rounded;
      case QuestMetric.gemsEarned:
        return Icons.diamond_rounded;
      case QuestMetric.perfectQuizzes:
        return Icons.military_tech_rounded;
      case QuestMetric.wordsReviewed:
        return Icons.style_rounded;
      case QuestMetric.correctAnswers:
        return Icons.check_circle_rounded;
      case QuestMetric.chaptersRead:
        return Icons.menu_book_rounded;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'metric': metric.name,
        'target': target,
        'rewardGems': rewardGems,
        'progress': progress,
        'claimed': claimed,
      };

  factory DailyQuest.fromJson(Map<String, dynamic> j) => DailyQuest(
        id: j['id'] as String,
        metric: QuestMetric.values.firstWhere(
          (m) => m.name == j['metric'],
          orElse: () => QuestMetric.levelsCompleted,
        ),
        target: (j['target'] as num).toInt(),
        rewardGems: (j['rewardGems'] as num).toInt(),
        progress: (j['progress'] as num?)?.toInt() ?? 0,
        claimed: (j['claimed'] as bool?) ?? false,
      );

  /// Builds today's 3 quests. Deterministic per calendar day so the set never
  /// reshuffles if the app restarts mid-day.
  static List<DailyQuest> generateFor(DateTime day) {
    final seed = day.year * 10000 + day.month * 100 + day.day;
    final rng = Random(seed);

    final pool = <DailyQuest Function(String)>[
      (id) => DailyQuest(id: id, metric: QuestMetric.levelsCompleted, target: 2 + rng.nextInt(2), rewardGems: 20),
      (id) => DailyQuest(id: id, metric: QuestMetric.gemsEarned, target: 50 + rng.nextInt(3) * 25, rewardGems: 15),
      (id) => DailyQuest(id: id, metric: QuestMetric.perfectQuizzes, target: 1, rewardGems: 25),
      (id) => DailyQuest(id: id, metric: QuestMetric.wordsReviewed, target: 5 + rng.nextInt(2) * 5, rewardGems: 15),
      (id) => DailyQuest(id: id, metric: QuestMetric.correctAnswers, target: 8 + rng.nextInt(3) * 4, rewardGems: 20),
      (id) => DailyQuest(id: id, metric: QuestMetric.chaptersRead, target: 1, rewardGems: 10),
    ];

    final indices = List<int>.generate(pool.length, (i) => i)..shuffle(rng);
    return [
      for (int i = 0; i < 3; i++) pool[indices[i]]('dq_${seed}_$i'),
    ];
  }
}
