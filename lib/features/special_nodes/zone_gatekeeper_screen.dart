import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/difficulty_quiz_engine.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';
import '../../models/literature.dart';
import '../../models/quest_level.dart';
import '../../models/quiz_question.dart';
import '../../shared/widgets/animated_reward_chest.dart';

/// Dramatic 3-Round Zone Gatekeeper Mini-Boss guarding zone transitions.
/// Pulls 3 fresh multiple-choice questions from the book via DifficultyQuizEngine,
/// tracks 3 Boss Shields, and awards a guaranteed Rare or Legendary AnimatedRewardChest!
class ZoneGatekeeperScreen extends StatefulWidget {
  final Literature literature;
  final QuestLevel level;

  const ZoneGatekeeperScreen({
    super.key,
    required this.literature,
    required this.level,
  });

  @override
  State<ZoneGatekeeperScreen> createState() => _ZoneGatekeeperScreenState();
}

class _ZoneGatekeeperScreenState extends State<ZoneGatekeeperScreen> {
  late final List<QuizQuestion> _questions;
  int _round = 0;
  int _correct = 0;
  int _shields = 3;
  int? _pickedOption;
  bool _battleOver = false;
  bool _chestOpened = false;

  @override
  void initState() {
    super.initState();
    _questions = _buildGatekeeperQuestions();
  }

  List<QuizQuestion> _buildGatekeeperQuestions() {
    final state = context.read<AppState>();
    final pool = <QuizQuestion>[];
    for (final list in widget.literature.recallQuizzes.values) {
      for (final q in list) {
        if ((q.type == QuizType.multipleChoice || q.type == QuizType.roleplay) &&
            q.options.length >= 2) {
          pool.add(q);
        }
      }
    }
    for (final list in widget.literature.practiceQuizzes.values) {
      for (final q in list) {
        if ((q.type == QuizType.multipleChoice || q.type == QuizType.roleplay) &&
            q.options.length >= 2) {
          pool.add(q);
        }
      }
    }
    for (final q in widget.literature.finalExam) {
      if ((q.type == QuizType.multipleChoice || q.type == QuizType.roleplay) &&
          q.options.length >= 2) {
        pool.add(q);
      }
    }

    if (pool.isNotEmpty) {
      final prepared = DifficultyQuizEngine.prepareQuestions(
        rawQuestions: pool,
        difficultySetting: state.profile.difficulty,
        seed: widget.literature.id.hashCode ^ DateTime.now().minute,
      );
      return prepared.take(3).toList();
    }

    // Fallback tailored questions if a custom book has no MCQs yet
    return [
      QuizQuestion(
        id: 'gk_1',
        prompt: 'Who authored "${widget.literature.title}"?',
        options: {
          widget.literature.author,
          'Miguel de Cervantes',
          'Mary Shelley',
          'Jane Austen',
        }.toList(),
        correctAnswerIndex: 0,
        explanation: '${widget.literature.author} is the celebrated author of ${widget.literature.title}.',
      ),
      QuizQuestion(
        id: 'gk_2',
        prompt: 'What is the primary goal of a careful scholar crossing a new Zone Gate?',
        options: const [
          'Connecting themes, character motives, and key moments',
          'Skipping every chapter without reading',
          'Ignoring unfamiliar vocabulary',
          'Guessing blindly without reflection',
        ],
        correctAnswerIndex: 0,
        explanation: 'Connecting character motives and themes unlocks deeper literary mastery.',
      ),
      QuizQuestion(
        id: 'gk_3',
        prompt: 'Which habit best strengthens long-term retention of "${widget.literature.title}"?',
        options: const [
          'Recalling plot turning points and saving key quotes',
          'Never revisiting new words',
          'Reading without pausing to reflect',
          'Ignoring the historical setting',
        ],
        correctAnswerIndex: 0,
        explanation: 'Active recall and collecting memorable quotes cement lasting understanding.',
      ),
    ];
  }

  void _selectOption(int index) {
    if (_pickedOption != null || _battleOver) return;
    final q = _questions[_round];
    final isRight = index == q.correctAnswerIndex;
    final state = context.read<AppState>();

    if (isRight) {
      SoundService.instance.play(Sfx.correct);
      state.triggerHaptic();
      _correct++;
    } else {
      SoundService.instance.play(Sfx.wrong);
      state.triggerHaptic();
      _shields = (_shields - 1).clamp(0, 3);
    }

    setState(() => _pickedOption = index);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_shields <= 0 || _round + 1 >= _questions.length) {
        setState(() => _battleOver = true);
      } else {
        setState(() {
          _round++;
          _pickedOption = null;
        });
      }
    });
  }

  bool get _victory => _shields > 0 && _correct >= (_questions.length / 2).ceil();

  QuizRewardOutcome get _chestOutcome {
    final flawless = _correct == _questions.length;
    return QuizRewardOutcome(
      chestRarity: flawless ? ChestRarity.legendary : ChestRarity.rare,
      gemsEarned: flawless ? 75 : 50,
      leaderboardXpEarned: flawless ? 90 : 55,
      bonusHearts: flawless ? 1 : 0,
      difficultyMultiplier: 1.25,
      difficultyLabel: 'Zone Gatekeeper',
    );
  }

  void _openBossChest(Offset? _) {
    if (_chestOpened) return;
    final state = context.read<AppState>();
    final outcome = _chestOutcome;
    SoundService.instance.play(Sfx.reward);
    state.triggerHaptic();
    state.addGems(outcome.gemsEarned);
    state.addLeaderboardXp(outcome.leaderboardXpEarned);
    if (outcome.bonusHearts > 0) {
      state.restoreEnergy(outcome.bonusHearts);
    }
    state.completeQuestLevel(
      literatureId: widget.literature.id,
      levelId: widget.level.id,
      isPerfectScore: _correct == _questions.length,
    );
    setState(() => _chestOpened = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0D18),
              Color(0xFF2D1224),
              Color(0xFF160B14),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            child: _battleOver ? _buildOutcomeView() : _buildBossBattle(),
          ),
        ),
      ),
    );
  }

  Widget _buildBossBattle() {
    final q = _questions[_round];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Boss HUD
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fort_rounded, color: Color(0xFFF43F5E), size: 16),
                      const SizedBox(width: 5),
                      Text(
                        'ZONE GATEKEEPER',
                        style: AppTypography.labelSmall.copyWith(
                          color: const Color(0xFFFDA4AF),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Trial ${_round + 1} of ${_questions.length}',
                    style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            // Shields
            Row(
              children: List.generate(3, (i) {
                final active = i < _shields;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    active ? Icons.shield_rounded : Icons.shield_outlined,
                    color: active ? const Color(0xFFF43F5E) : Colors.white24,
                    size: 22,
                  ),
                );
              }),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Gatekeeper emblem
        Center(
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFF43F5E), Color(0xFF881337)],
              ),
              border: Border.all(
                color: const Color(0xFFFDE047).withValues(alpha: 0.75),
                width: 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.45),
                  blurRadius: 24,
                ),
              ],
            ),
            child: const Icon(Icons.fort_rounded, color: Colors.white, size: 38),
          ),
        ),

        const SizedBox(height: 18),

        // Question card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFF43F5E).withValues(alpha: 0.45),
              width: 1.6,
            ),
          ),
          child: Text(
            q.prompt,
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: ListView.separated(
            itemCount: q.options.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final isSelected = _pickedOption == idx;
              final isRight = idx == q.correctAnswerIndex;
              Color bg = Colors.white.withValues(alpha: 0.07);
              Color border = Colors.white.withValues(alpha: 0.18);
              if (_pickedOption != null) {
                if (isRight) {
                  bg = const Color(0xFF22C55E).withValues(alpha: 0.24);
                  border = const Color(0xFF22C55E);
                } else if (isSelected) {
                  bg = const Color(0xFFEF4444).withValues(alpha: 0.24);
                  border = const Color(0xFFEF4444);
                }
              }

              return Material(
                color: bg,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: _pickedOption == null ? () => _selectOption(idx) : null,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: border, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            String.fromCharCode(65 + idx),
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            q.options[idx],
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOutcomeView() {
    if (!_victory) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFFF43F5E), size: 54),
              const SizedBox(height: 12),
              Text(
                'THE GATE HOLDS FIRM',
                style: AppTypography.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You cleared $_correct of ${_questions.length} trials. Regroup and challenge the Gatekeeper again!',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('BACK'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _round = 0;
                          _correct = 0;
                          _shields = 3;
                          _pickedOption = null;
                          _battleOver = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF43F5E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('RETRY TRIAL'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFD4A338).withValues(alpha: 0.6),
              width: 1.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GATEKEEPER VANQUISHED!',
                textAlign: TextAlign.center,
                style: AppTypography.displaySmall.copyWith(
                  color: const Color(0xFFFDE047),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cleared $_correct/${_questions.length} trials — the path to the next realm opens!',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 18),
              AnimatedRewardChest(
                outcome: _chestOutcome,
                isOpened: _chestOpened,
                onOpenChest: _openBossChest,
              ),
              const SizedBox(height: 18),
              if (_chestOpened)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.antiqueGold,
                      foregroundColor: const Color(0xFF1F1600),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    child: const Text('ADVANCE ON THE MAP'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
