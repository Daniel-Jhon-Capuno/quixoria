import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/difficulty_quiz_engine.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';
import '../../models/quiz_question.dart';

/// Duolingo-style Quick Review & Mistake Dojo:
/// Zero-energy 5-question rapid mastery sprint pulling questions from your
/// owned books to sharpen weak spots and award Gems, XP, and +1 Energy Heart!
class MistakeDojoScreen extends StatefulWidget {
  const MistakeDojoScreen({super.key});

  @override
  State<MistakeDojoScreen> createState() => _MistakeDojoScreenState();
}

class _MistakeDojoScreenState extends State<MistakeDojoScreen> {
  late final List<QuizQuestion> _questions;
  int _index = 0;
  int _correct = 0;
  int? _picked;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _questions = _buildReviewPool();
  }

  List<QuizQuestion> _buildReviewPool() {
    final state = context.read<AppState>();
    final pool = <QuizQuestion>[];
    final owned = state.catalog.where((b) => b.isOwned).toList();
    final sourceBooks = owned.isNotEmpty ? owned : [state.activeLiterature];

    for (final book in sourceBooks) {
      for (final list in book.recallQuizzes.values) {
        for (final q in list) {
          if ((q.type == QuizType.multipleChoice || q.type == QuizType.roleplay) &&
              q.options.length >= 2) {
            pool.add(q);
          }
        }
      }
      for (final list in book.practiceQuizzes.values) {
        for (final q in list) {
          if ((q.type == QuizType.multipleChoice || q.type == QuizType.roleplay) &&
              q.options.length >= 2) {
            pool.add(q);
          }
        }
      }
    }

    if (pool.isNotEmpty) {
      final prepared = DifficultyQuizEngine.prepareQuestions(
        rawQuestions: pool,
        difficultySetting: state.profile.difficulty,
        seed: DateTime.now().millisecondsSinceEpoch,
      );
      return prepared.take(5).toList();
    }

    return const [
      QuizQuestion(
        id: 'dojo_fallback_1',
        prompt: 'Which habit best strengthens recall after reading a chapter?',
        options: [
          'Reviewing key turning points and vocabulary',
          'Closing the book immediately without reflection',
          'Skipping unfamiliar words',
          'Never revisiting previous chapters',
        ],
        correctAnswerIndex: 0,
        explanation: 'Active recall cements story details and vocabulary into long-term memory.',
      ),
    ];
  }

  void _pick(int idx) {
    if (_picked != null || _done) return;
    final q = _questions[_index];
    final right = idx == q.correctAnswerIndex;
    if (right) {
      _correct++;
      SoundService.instance.play(Sfx.correct);
    } else {
      SoundService.instance.play(Sfx.wrong);
    }
    HapticService.instance.light();
    setState(() => _picked = idx);

    Future.delayed(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      if (_index + 1 >= _questions.length) {
        final state = context.read<AppState>();
        final gems = 15 + (_correct * 5);
        final xp = 20 + (_correct * 6);
        state.addGems(gems);
        state.addLeaderboardXp(xp);
        if (_correct >= (_questions.length / 2).ceil()) {
          state.restoreEnergy(1);
        }
        SoundService.instance.play(Sfx.reward);
        setState(() => _done = true);
      } else {
        setState(() {
          _index++;
          _picked = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final border = theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.45);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1C19);
    final textMuted = isDark ? Colors.white70 : const Color(0xFF5A625C);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Mistake Dojo',
          style: AppTypography.titleLarge.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
          child: _done
              ? _buildSummary(primary, cardBg, border, textPrimary, textMuted)
              : _buildQuestion(primary, cardBg, border, textPrimary, textMuted),
        ),
      ),
    );
  }

  Widget _buildQuestion(
    Color primary,
    Color cardBg,
    Color border,
    Color textPrimary,
    Color textMuted,
  ) {
    final q = _questions[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_index + 1) / _questions.length,
                  minHeight: 10,
                  backgroundColor: border.withValues(alpha: 0.35),
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${_index + 1}/${_questions.length}',
              style: AppTypography.labelMedium.copyWith(color: textMuted),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border, width: 2.0),
          ),
          child: Text(
            q.prompt,
            style: AppTypography.titleLarge.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: q.options.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, idx) {
              final isRight = idx == q.correctAnswerIndex;
              final isSelected = _picked == idx;
              Color tileBorder = border;
              Color tileBg = cardBg;
              if (_picked != null) {
                if (isRight) {
                  tileBorder = AppColors.successGreen;
                  tileBg = AppColors.successGreen.withValues(alpha: 0.14);
                } else if (isSelected) {
                  tileBorder = AppColors.energyRed;
                  tileBg = AppColors.energyRed.withValues(alpha: 0.14);
                }
              }

              return InkWell(
                onTap: _picked == null ? () => _pick(idx) : null,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(
                    color: tileBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: tileBorder, width: 2.0),
                  ),
                  child: Text(
                    q.options[idx],
                    style: AppTypography.bodyMedium.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
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

  Widget _buildSummary(
    Color primary,
    Color cardBg,
    Color border,
    Color textPrimary,
    Color textMuted,
  ) {
    final gems = 15 + (_correct * 5);
    final xp = 20 + (_correct * 6);
    final earnedHeart = _correct >= (_questions.length / 2).ceil();

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.antiqueGold, width: 2.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fitness_center_rounded, color: AppColors.antiqueGold, size: 52),
            const SizedBox(height: 12),
            Text(
              'Dojo Complete!',
              style: AppTypography.displaySmall.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$_correct / ${_questions.length} mastered',
              style: AppTypography.titleMedium.copyWith(color: textMuted),
            ),
            const SizedBox(height: 14),
            Text(
              '+$gems Gems • +$xp XP${earnedHeart ? ' • +1 ❤️' : ''}',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.antiqueGold,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
