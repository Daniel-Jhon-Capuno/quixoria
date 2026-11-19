import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';
import '../../models/app_theme_preset.dart';
import '../../models/quest_level.dart';
import '../../models/quiz_question.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/reward_celebration.dart';
import '../../shared/widgets/streak_celebration_dialog.dart';
import '../../shared/widgets/guide_dialog.dart';
import '../../shared/widgets/quixote_avatar.dart';
import '../../shared/widgets/quixote_mascot.dart';

class QuizScreen extends StatefulWidget {
  final String literatureId;
  final QuestLevel level;
  final List<QuizQuestion> questions;

  const QuizScreen({
    super.key,
    required this.literatureId,
    required this.level,
    required this.questions,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _hasAnswered = false;
  int _correctCount = 0;
  int _streakInQuiz = 0;
  final List<bool> _questionResults = [];
  bool _isQuizCompleted = false;
  bool _hasOpenedTreasureChest = false;

  // Cloze State
  String? _placedClozeWord;
  List<String> _availableWordBank = [];

  // Reorder State
  List<String> _assembledTokens = [];
  List<String> _availableTokenBank = [];

  // Matching Pairs State
  String? _selectedLeftTerm;
  Map<String, String> _matchedPairs = {};
  List<String> _leftItems = [];
  List<String> _rightItems = [];

  // Hints
  bool _showHint = false;

  late AnimationController _feedbackAnimController;
  late AnimationController _shakeAnimController;
  late AnimationController _celebrateBounceController;

  @override
  void initState() {
    super.initState();
    _feedbackAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _shakeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _celebrateBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _initQuestionState();
  }

  void _initQuestionState() {
    _selectedOptionIndex = null;
    _placedClozeWord = null;
    _assembledTokens = [];
    _selectedLeftTerm = null;
    _matchedPairs = {};

    final diff = context.read<AppState>().profile.difficulty.toLowerCase();
    final isGentle = diff.contains('gentle') || diff.contains('page');
    _showHint = isGentle && currentQuestion.contextHint != null;

    if (currentQuestion.type == QuizType.cloze) {
      _availableWordBank = List.from(currentQuestion.wordBank ?? []);
    } else if (currentQuestion.type == QuizType.reorder) {
      _availableTokenBank = List.from(currentQuestion.wordBank ?? currentQuestion.orderedTokens ?? []);
    } else if (currentQuestion.type == QuizType.matching && currentQuestion.matchingPairs != null) {
      _leftItems = currentQuestion.matchingPairs!.keys.toList();
      _rightItems = currentQuestion.matchingPairs!.values.toList()..shuffle(Random(currentQuestion.id.hashCode));
    }
  }

  @override
  void dispose() {
    _feedbackAnimController.dispose();
    _shakeAnimController.dispose();
    _celebrateBounceController.dispose();
    super.dispose();
  }

  QuizQuestion get currentQuestion {
    if (widget.questions.isEmpty) {
      return const QuizQuestion(
        id: 'fallback',
        prompt: 'No questions available.',
        options: ['Continue'],
        correctAnswerIndex: 0,
        explanation: 'Default.',
      );
    }
    return widget.questions[_currentIndex];
  }

  bool _canSubmit() {
    if (_hasAnswered) return false;
    switch (currentQuestion.type) {
      case QuizType.multipleChoice:
      case QuizType.roleplay:
        return _selectedOptionIndex != null;
      case QuizType.cloze:
        return _placedClozeWord != null;
      case QuizType.reorder:
        return _assembledTokens.isNotEmpty;
      case QuizType.matching:
        final totalPairs = currentQuestion.matchingPairs?.length ?? 0;
        return totalPairs > 0 && _matchedPairs.length == totalPairs;
    }
  }

  bool _isCurrentQuestionCorrect() {
    switch (currentQuestion.type) {
      case QuizType.multipleChoice:
      case QuizType.roleplay:
        return _selectedOptionIndex == currentQuestion.correctAnswerIndex;
      case QuizType.cloze:
        final expected = currentQuestion.targetWord?.trim().toLowerCase();
        final actual = _placedClozeWord?.trim().toLowerCase();
        return expected != null && expected == actual;
      case QuizType.reorder:
        final expected = (currentQuestion.orderedTokens ?? []).map((t) => t.trim().toLowerCase()).toList();
        final actual = _assembledTokens.map((t) => t.trim().toLowerCase()).toList();
        if (expected.length != actual.length) return false;
        for (int i = 0; i < expected.length; i++) {
          if (expected[i] != actual[i]) return false;
        }
        return true;
      case QuizType.matching:
        final total = currentQuestion.matchingPairs?.length ?? 0;
        return total > 0 && _matchedPairs.length == total;
    }
  }

  void _submitAnswer() {
    if (!_canSubmit() || _hasAnswered) return;

    final state = context.read<AppState>();
    final isCorrect = _isCurrentQuestionCorrect();
    _questionResults.add(isCorrect);
    if (isCorrect) {
      _correctCount++;
      _streakInQuiz++;
      final totalConsecutive = state.recordCorrectAnswer();
      SoundService.instance.play(Sfx.correct);
      _feedbackAnimController.forward(from: 0.0);
      _celebrateBounceController.forward(from: 0.0);
      HapticService.instance.medium();

      // Milestone streak on exact 10, 20, 30...
      if (totalConsecutive > 0 && totalConsecutive % 10 == 0) {
        SoundService.instance.play(Sfx.streak);
        HapticService.instance.celebration();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.antiqueGold,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Row(
              children: [
                const Icon(Icons.whatshot_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'CHIVALRIC FEAT! $totalConsecutive QUESTIONS CORRECT IN A ROW!',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      _streakInQuiz = 0;
      state.resetConsecutiveCorrectAnswers();
      SoundService.instance.play(Sfx.wrong);
      _shakeAnimController.forward(from: 0.0);
      _feedbackAnimController.forward(from: 0.0);
      _celebrateBounceController.forward(from: 0.0);
      HapticService.instance.error();

      // If this question tests a vocabulary term (contains single-quoted word),
      // schedule it immediately in the user's SRS Word Bank.
      final match = RegExp(r"'([A-Za-z\-]+)'").firstMatch(currentQuestion.prompt);
      if (match != null) {
        final word = match.group(1)!;
        final correctDef = currentQuestion.options.isNotEmpty && currentQuestion.correctAnswerIndex < currentQuestion.options.length
            ? currentQuestion.options[currentQuestion.correctAnswerIndex].toString()
            : (currentQuestion.targetWord ?? currentQuestion.explanation);
        state.addOrUpdateVocabCard(
          word: word,
          definition: correctDef,
          example: currentQuestion.explanation,
          literatureId: widget.literatureId,
          literatureTitle: state.activeLiterature.title,
          markMissed: true,
        );
      }
    }

    setState(() {
      _hasAnswered = true;
    });
  }

  void _nextQuestion() {
    if (_currentIndex + 1 < widget.questions.length) {
      _feedbackAnimController.reset();
      _shakeAnimController.reset();
      _celebrateBounceController.reset();
      setState(() {
        _currentIndex++;
        _hasAnswered = false;
        _initQuestionState();
      });
    } else {
      // Quiz Complete
      _finalizeQuiz();
    }
  }

  void _finalizeQuiz() {
    final state = context.read<AppState>();
    final isPerfect = _correctCount == widget.questions.length;

    // Apply level completion and rewards
    state.completeQuestLevel(
      literatureId: widget.literatureId,
      levelId: widget.level.id,
      isPerfectScore: isPerfect,
    );

    setState(() {
      _isQuizCompleted = true;
    });
  }

  void _confirmExitQuiz(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    GuideDialog.show(
      context: context,
      title: 'Abandon Thy Quest?',
      message:
          'Dost thou truly wish to depart? Thy quiz answers will not be saved, and valuable gems, XP, and literary glory await thy victorious finish!\n\n(Thy spent energy heart shall be faithfully restored to thee.)',
      primaryButtonText: 'Keep Fighting',
      secondaryButtonText: 'Abandon Quiz',
      mood: QuixoteMood.caution,
      onPrimaryPressed: () {
        // GuideDialog already dismissed itself. Keep user on the quiz screen.
      },
      onSecondaryPressed: () {
        // Restore spent energy heart if non-practice so user loses nothing
        if (widget.level.type != LevelType.practice && !state.profile.isPremium) {
          state.restoreEnergy(widget.level.energyCost);
        }
        // Exit Quiz screen cleanly back to the Quest Map
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isQuizCompleted) {
      return _buildResultsScreen();
    }

    final progress = (_currentIndex + 1) / widget.questions.length;
    final isPractice = widget.level.type == LevelType.practice;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmExitQuiz(context);
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: theme.colorScheme.primary),
            onPressed: () => _confirmExitQuiz(context),
          ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.level.typeLabel,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontSize: 15,
              ),
            ),
            Text(
              widget.level.literacyPurpose,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 9.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              isPractice ? AppColors.practiceBlue : AppColors.antiqueGold,
            ),
            minHeight: 6,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Safe Practice Banner
            if (isPractice)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.practiceBlue.withValues(alpha: 0.14),
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: AppColors.practiceBlue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Safe Practice Arena: Incorrect answers consume zero energy hearts!',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? Colors.lightBlue.shade100 : theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.08, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: SingleChildScrollView(
                  key: ValueKey<int>(_currentIndex),
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Counter & Streak Combo Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'QUESTION ${_currentIndex + 1} OF ${widget.questions.length}',
                            style: AppTypography.labelSmall.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          if (_streakInQuiz >= 2)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.streakOrange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.streakOrange.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_fire_department_rounded, size: 14, color: AppColors.streakOrange),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$_streakInQuiz in a row',
                                    style: const TextStyle(
                                      color: AppColors.streakOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Question Type Badge & Difficulty Hint Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getQuestionTypeIcon(currentQuestion.type), size: 13, color: theme.colorScheme.primary),
                                const SizedBox(width: 5),
                                Text(
                                  _getQuestionTypeLabel(currentQuestion.type).toUpperCase(),
                                  style: AppTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.6,
                                    fontSize: 10,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (currentQuestion.contextHint != null)
                            InkWell(
                              onTap: () {
                                HapticService.instance.light();
                                setState(() {
                                  _showHint = !_showHint;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.antiqueGold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.antiqueGold, width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.lightbulb_rounded, size: 13, color: AppColors.antiqueGold),
                                    const SizedBox(width: 4),
                                    Text(
                                      _showHint ? 'Hide Hint' : 'Hint',
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.antiqueGold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Hint Card
                      if (_showHint && currentQuestion.contextHint != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.antiqueGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.antiqueGold.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.menu_book_rounded, size: 16, color: AppColors.antiqueGold),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  currentQuestion.contextHint!,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Companion / In-Character Roleplay Card
                      if (currentQuestion.type == QuizType.roleplay)
                        _buildRoleplayHeader(theme, isDark)
                      else
                        _buildCompanionCard(theme),

                      // Question Prompt
                      Text(
                        currentQuestion.prompt,
                        style: AppTypography.titleLarge.copyWith(
                          fontSize: 20,
                          color: theme.colorScheme.onSurface,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Interactive Exercises based on QuizType
                      if (currentQuestion.type == QuizType.cloze)
                        _buildClozeInteractiveView(theme, isDark)
                      else if (currentQuestion.type == QuizType.reorder)
                        _buildReorderInteractiveView(theme, isDark)
                      else if (currentQuestion.type == QuizType.matching)
                        _buildMatchingInteractiveView(theme, isDark)
                      else
                        for (int i = 0; i < currentQuestion.options.length; i++)
                          _buildOptionTile(
                            index: i,
                            optionText: currentQuestion.options[i],
                            theme: theme,
                            isDark: isDark,
                          ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Feedback Sheet / Action Button
            _buildBottomActionArea(theme, isDark),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildOptionTile({
    required int index,
    required dynamic optionText,
    required ThemeData theme,
    required bool isDark,
  }) {
    final isSelected = _selectedOptionIndex == index;
    final isCorrect = index == currentQuestion.correctAnswerIndex;
    final state = context.read<AppState>();

    final preset = state.activeThemePreset;
    final isSnowy = preset.interfaceStyle == ThemeInterfaceStyle.snowy;
    final isPink = preset.id == 'theme_cute_meadow';
    final isMedieval = preset.interfaceStyle == ThemeInterfaceStyle.medieval;
    final isPlague = preset.interfaceStyle == ThemeInterfaceStyle.plague;
    final isCozy = preset.interfaceStyle == ThemeInterfaceStyle.cozy;

    // Strict theme-family success color (Ice = Frost cyan, Pink = Rose magenta, Medieval = Crimson/Gold)
    final themeSuccessColor = isSnowy
        ? const Color(0xFF00A8CC)
        : (isPink
            ? const Color(0xFFE91E63)
            : (isMedieval
                ? const Color(0xFFD4A338)
                : (isPlague
                    ? const Color(0xFFC77DFF)
                    : (isCozy
                        ? const Color(0xFFE28442)
                        : AppColors.successGreen))));

    // Strict theme-family error color
    final themeErrorColor = isPink
        ? const Color(0xFF88102C)
        : (isSnowy
            ? const Color(0xFF0D2538)
            : AppColors.energyRed);

    Color tileBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    Color borderColor = theme.dividerColor.withValues(alpha: 0.45);
    Color textColor = theme.colorScheme.onSurface;

    if (_hasAnswered) {
      if (isCorrect) {
        tileBg = themeSuccessColor.withValues(alpha: isDark ? 0.24 : 0.14);
        borderColor = themeSuccessColor;
        textColor = isDark ? themeSuccessColor : theme.colorScheme.primary;
      } else if (isSelected && !isCorrect) {
        tileBg = themeErrorColor.withValues(alpha: isDark ? 0.24 : 0.14);
        borderColor = themeErrorColor;
        textColor = isDark ? const Color(0xFFFEB2B2) : themeErrorColor;
      }
    } else if (isSelected) {
      tileBg = theme.colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.15);
      borderColor = theme.colorScheme.primary;
      textColor = isDark ? theme.colorScheme.primary : theme.colorScheme.primary;
    }

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isSelected ? 2.2 : 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Index Letter Badge (A, B, C, D)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.parchmentWarm),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                String.fromCharCode(65 + index),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Option Text
          Expanded(
            child: Text(
              optionText.toString(),
              style: AppTypography.bodyMedium.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),

          if (_hasAnswered && isCorrect)
            Icon(Icons.check_circle_rounded, color: themeSuccessColor, size: 24)
          else if (_hasAnswered && isSelected && !isCorrect)
            Icon(Icons.cancel_rounded, color: themeErrorColor, size: 24),
        ],
      ),
    );

    // Duolingo Shake Animation on Wrong Answer
    if (_hasAnswered && isSelected && !isCorrect) {
      content = AnimatedBuilder(
        animation: _shakeAnimController,
        builder: (context, child) {
          final val = _shakeAnimController.value;
          final wobble = sin(val * pi * 4) * (1.0 - val) * 9.0;
          return Transform.translate(
            offset: Offset(wobble, 0),
            child: child,
          );
        },
        child: content,
      );
    } else if (_hasAnswered && isCorrect) {
      // Duolingo Pop Cheer Animation on Correct Answer
      content = AnimatedBuilder(
        animation: _celebrateBounceController,
        builder: (context, child) {
          final val = _celebrateBounceController.value;
          final scale = 1.0 + (sin(val * pi) * 0.03);
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: content,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _hasAnswered
            ? null
            : () {
                HapticService.instance.selection();
                SoundService.instance.play(Sfx.tap);
                setState(() {
                  _selectedOptionIndex = index;
                });
              },
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );
  }

  Widget _buildCompanionCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.antiqueGold.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          const QuixoteMascot(
            expression: QuixoteExpression.thinking,
            size: 54,
            showSpeechBubble: false,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Don Quixote ponders with thee:',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.antiqueGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '“Consult thy memory of the chapters, noble reader.”',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleplayHeader(ThemeData theme, bool isDark) {
    final speaker = currentQuestion.characterSpeaker ?? 'Don Quixote';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262016) : const Color(0xFFFFF9ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.antiqueGold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.antiqueGold.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Parchment Portrait Medallion
          _buildCharacterPortrait(speaker, isDark),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.antiqueGold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'IN-CHARACTER DILEMMA',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDark ? AppColors.antiqueGold : const Color(0xFF8B6508),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$speaker presents a dilemma:',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '“How dost thou respond in accordance with chivalric wisdom and literary authenticity?”',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterPortrait(String speaker, bool isDark) {
    final lower = speaker.toLowerCase();
    if (lower.contains('quixote') || lower.contains('sancho')) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.antiqueGold.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.antiqueGold, width: 2),
        ),
        child: const ClipOval(
          child: QuixoteMascot(
            expression: QuixoteExpression.encouraging,
            size: 46,
            showSpeechBubble: false,
          ),
        ),
      );
    }

    // Bespoke antique cameo character medallion
    IconData icon = Icons.record_voice_over_rounded;
    Color bg = const Color(0xFF3E2723);
    String initials = 'CH';

    if (lower.contains('holmes') || lower.contains('watson')) {
      icon = Icons.search_rounded;
      bg = const Color(0xFF1A237E);
      initials = 'SH';
    } else if (lower.contains('mary') || lower.contains('garden')) {
      icon = Icons.local_florist_rounded;
      bg = const Color(0xFF2E7D32);
      initials = 'ML';
    } else if (lower.contains('frank') || lower.contains('creature')) {
      icon = Icons.science_rounded;
      bg = const Color(0xFF004D40);
      initials = 'VF';
    } else if (lower.contains('elizabeth') || lower.contains('darcy') || lower.contains('bennet')) {
      icon = Icons.auto_stories_rounded;
      bg = const Color(0xFF880E4F);
      initials = 'EB';
    } else if (lower.contains('fogg') || lower.contains('passepartout')) {
      icon = Icons.schedule_rounded;
      bg = const Color(0xFFB71C1C);
      initials = 'PF';
    } else if (lower.contains('time traveller')) {
      icon = Icons.hourglass_bottom_rounded;
      bg = const Color(0xFF4A148C);
      initials = 'TT';
    } else if (lower.contains('alice') || lower.contains('cat') || lower.contains('hatter')) {
      icon = Icons.auto_awesome_rounded;
      bg = const Color(0xFF6A1B9A);
      initials = 'AC';
    } else if (lower.contains('dantès') || lower.contains('dantes') || lower.contains('faria')) {
      icon = Icons.castle_rounded;
      bg = const Color(0xFF263238);
      initials = 'ED';
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.antiqueGold, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 22),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.antiqueGold,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClozeInteractiveView(ThemeData theme, bool isDark) {
    final sentence = currentQuestion.clozeSentence ?? 'Truth ________ acknowledged.';
    final parts = sentence.split('________');
    final before = parts.isNotEmpty ? parts[0] : '';
    final after = parts.length > 1 ? parts[1] : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.antiqueGold.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 8,
            children: [
              if (before.isNotEmpty)
                Text(
                  before,
                  style: AppTypography.titleMedium.copyWith(fontSize: 16.5, height: 1.4),
                ),
              // Interactive Blank Slot
              InkWell(
                onTap: _hasAnswered || _placedClozeWord == null
                    ? null
                    : () {
                        HapticService.instance.light();
                        SoundService.instance.play(Sfx.tap);
                        setState(() {
                          _availableWordBank.add(_placedClozeWord!);
                          _placedClozeWord = null;
                        });
                      },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  constraints: const BoxConstraints(minWidth: 85, minHeight: 36),
                  decoration: BoxDecoration(
                    color: _placedClozeWord != null
                        ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.28 : 0.16)
                        : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _placedClozeWord != null ? theme.colorScheme.primary : AppColors.antiqueGold,
                      width: _placedClozeWord != null ? 2 : 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _placedClozeWord ?? 'tap word below',
                      style: TextStyle(
                        color: _placedClozeWord != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              if (after.isNotEmpty)
                Text(
                  after,
                  style: AppTypography.titleMedium.copyWith(fontSize: 16.5, height: 1.4),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Word Bank (Tap to place into blank):',
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (int i = 0; i < _availableWordBank.length; i++)
              _buildWordBankChip(
                word: _availableWordBank[i],
                theme: theme,
                isDark: isDark,
                onTap: () {
                  if (_hasAnswered) return;
                  HapticService.instance.selection();
                  SoundService.instance.play(Sfx.tap);
                  setState(() {
                    if (_placedClozeWord != null) {
                      _availableWordBank.add(_placedClozeWord!);
                    }
                    _placedClozeWord = _availableWordBank[i];
                    _availableWordBank.removeAt(i);
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildReorderInteractiveView(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 110),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.antiqueGold.withValues(alpha: 0.5), width: 1.5),
          ),
          child: _assembledTokens.isEmpty
              ? Center(
                  child: Text(
                    'Tap passage fragments from below in sequence to assemble',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      fontStyle: FontStyle.italic,
                      fontSize: 13.5,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0; i < _assembledTokens.length; i++)
                      _buildWordBankChip(
                        word: _assembledTokens[i],
                        theme: theme,
                        isDark: isDark,
                        isPlaced: true,
                        onTap: () {
                          if (_hasAnswered) return;
                          HapticService.instance.light();
                          SoundService.instance.play(Sfx.tap);
                          setState(() {
                            final w = _assembledTokens.removeAt(i);
                            _availableTokenBank.add(w);
                          });
                        },
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 24),
        Text(
          'Passage Fragments (Tap in order):',
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (int i = 0; i < _availableTokenBank.length; i++)
              _buildWordBankChip(
                word: _availableTokenBank[i],
                theme: theme,
                isDark: isDark,
                onTap: () {
                  if (_hasAnswered) return;
                  HapticService.instance.selection();
                  SoundService.instance.play(Sfx.tap);
                  setState(() {
                    final w = _availableTokenBank.removeAt(i);
                    _assembledTokens.add(w);
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMatchingInteractiveView(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.touch_app_rounded, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tap a term on the left, then tap its matching definition on the right.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (final item in _leftItems)
                    _buildMatchingTile(
                      text: item,
                      isLeft: true,
                      theme: theme,
                      isDark: isDark,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  for (final item in _rightItems)
                    _buildMatchingTile(
                      text: item,
                      isLeft: false,
                      theme: theme,
                      isDark: isDark,
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMatchingTile({
    required String text,
    required bool isLeft,
    required ThemeData theme,
    required bool isDark,
  }) {
    final isMatched = isLeft ? _matchedPairs.containsKey(text) : _matchedPairs.containsValue(text);
    final isSelected = isLeft && _selectedLeftTerm == text;

    Color bg = isDark ? const Color(0xFF222222) : Colors.white;
    Color border = theme.dividerColor.withValues(alpha: 0.5);
    Color textColor = theme.colorScheme.onSurface;

    if (isMatched) {
      bg = theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.14);
      border = theme.colorScheme.primary;
      textColor = theme.colorScheme.primary;
    } else if (isSelected) {
      bg = AppColors.antiqueGold.withValues(alpha: isDark ? 0.3 : 0.2);
      border = AppColors.antiqueGold;
      textColor = AppColors.antiqueGold;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: isMatched || _hasAnswered
            ? null
            : () {
                HapticService.instance.selection();
                SoundService.instance.play(Sfx.tap);
                setState(() {
                  if (isLeft) {
                    _selectedLeftTerm = text;
                  } else {
                    if (_selectedLeftTerm != null) {
                      final expected = currentQuestion.matchingPairs?[_selectedLeftTerm];
                      if (expected == text) {
                        _matchedPairs[_selectedLeftTerm!] = text;
                        _selectedLeftTerm = null;
                        SoundService.instance.play(Sfx.correct);
                        HapticService.instance.medium();

                        if (_matchedPairs.length == (currentQuestion.matchingPairs?.length ?? 0)) {
                          _submitAnswer();
                        }
                      } else {
                        SoundService.instance.play(Sfx.wrong);
                        _shakeAnimController.forward(from: 0.0);
                        HapticService.instance.error();
                        _selectedLeftTerm = null;
                      }
                    }
                  }
                });
              },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: isSelected || isMatched ? 2 : 1),
          ),
          child: Row(
            children: [
              if (isMatched) ...[
                Icon(Icons.check_circle_rounded, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  text,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: isMatched || isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12.5,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordBankChip({
    required String word,
    required ThemeData theme,
    required bool isDark,
    bool isPlaced = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isPlaced
              ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.28 : 0.15)
              : (isDark ? const Color(0xFF242424) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPlaced ? theme.colorScheme.primary : theme.dividerColor.withValues(alpha: 0.6),
            width: isPlaced ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          word,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isPlaced ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  IconData _getQuestionTypeIcon(QuizType type) {
    switch (type) {
      case QuizType.cloze:
        return Icons.edit_note_rounded;
      case QuizType.reorder:
        return Icons.sort_by_alpha_rounded;
      case QuizType.matching:
        return Icons.swap_horiz_rounded;
      case QuizType.roleplay:
        return Icons.theater_comedy_rounded;
      case QuizType.multipleChoice:
        return Icons.check_circle_outline_rounded;
    }
  }

  String _getQuestionTypeLabel(QuizType type) {
    switch (type) {
      case QuizType.cloze:
        return 'Fill in the Blank';
      case QuizType.reorder:
        return 'Reconstruct Passage';
      case QuizType.matching:
        return 'Literary Matching';
      case QuizType.roleplay:
        return 'Roleplay Dilemma';
      case QuizType.multipleChoice:
        return 'Comprehension';
    }
  }

  String _getCorrectAnswerDisplay() {
    return _getReviewCorrectAnswer(currentQuestion);
  }

  String _getReviewCorrectAnswer(QuizQuestion q) {
    switch (q.type) {
      case QuizType.cloze:
        return q.targetWord ?? 'Target term';
      case QuizType.reorder:
        return (q.orderedTokens ?? []).join(' ');
      case QuizType.matching:
        return (q.matchingPairs ?? {}).entries.map((e) => '${e.key} → ${e.value}').join(' • ');
      case QuizType.multipleChoice:
      case QuizType.roleplay:
        if (q.options.isNotEmpty && q.correctAnswerIndex < q.options.length) {
          return q.options[q.correctAnswerIndex];
        }
        return 'Correct option';
    }
  }

  Widget _buildBottomActionArea(ThemeData theme, bool isDark) {
    if (!_hasAnswered) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.35), width: 1),
          ),
        ),
        child: DuoButton(
          text: 'Check Answer',
          onPressed: _canSubmit() ? _submitAnswer : null,
          variant: DuoButtonVariant.primary,
        ),
      );
    }

    final isCorrect = _isCurrentQuestionCorrect();
    final state = context.read<AppState>();
    final preset = state.activeThemePreset;
    final isSnowy = preset.interfaceStyle == ThemeInterfaceStyle.snowy;
    final isPink = preset.id == 'theme_cute_meadow';
    final isMedieval = preset.interfaceStyle == ThemeInterfaceStyle.medieval;
    final isPlague = preset.interfaceStyle == ThemeInterfaceStyle.plague;
    final isCozy = preset.interfaceStyle == ThemeInterfaceStyle.cozy;

    final themeSuccessColor = isSnowy
        ? const Color(0xFF00A8CC)
        : (isPink
            ? const Color(0xFFE91E63)
            : (isMedieval
                ? const Color(0xFFD4A338)
                : (isPlague
                    ? const Color(0xFFC77DFF)
                    : (isCozy
                        ? const Color(0xFFE28442)
                        : AppColors.successGreen))));

    final themeErrorColor = isPink
        ? const Color(0xFF88102C)
        : (isSnowy
            ? const Color(0xFF0D2538)
            : AppColors.energyRed);

    final sheetBg = isDark
        ? (isCorrect
            ? (isSnowy
                ? const Color(0xFF0F2638)
                : (isPink
                    ? const Color(0xFF2E0C18)
                    : (isPlague
                        ? const Color(0xFF1E102D)
                        : (isMedieval
                            ? const Color(0xFF280B10)
                            : (isCozy
                                ? const Color(0xFF2A1408)
                                : const Color(0xFF132E1E))))))
            : (widget.level.type == LevelType.practice
                ? const Color(0xFF152736)
                : (isPink
                    ? const Color(0xFF330C1A)
                    : const Color(0xFF33181B))))
        : (isCorrect
            ? (isSnowy
                ? const Color(0xFFE0F4FB)
                : (isPink
                    ? const Color(0xFFFFE3EC)
                    : (isPlague
                        ? const Color(0xFFF3E5F5)
                        : (isMedieval
                            ? const Color(0xFFFCE8E8)
                            : (isCozy
                                ? const Color(0xFFFDF0E2)
                                : const Color(0xFFD4EDDA))))))
            : (widget.level.type == LevelType.practice
                ? const Color(0xFFE3F2FD)
                : (isPink ? const Color(0xFFFFDDE5) : const Color(0xFFFFD9D9))));

    final fgColor = isDark
        ? (isCorrect
            ? (isSnowy
                ? const Color(0xFF7CE4F8)
                : (isPink
                    ? const Color(0xFFFF85A1)
                    : (isPlague
                        ? const Color(0xFFE1BEE7)
                        : (isMedieval
                            ? const Color(0xFFFFCDD2)
                            : (isCozy
                                ? const Color(0xFFFFCC80)
                                : const Color(0xFF9AE6B4))))))
            : (isPink ? const Color(0xFFFF9EB5) : const Color(0xFFFEB2B2)))
        : (isCorrect
            ? (isSnowy
                ? const Color(0xFF0B4666)
                : (isPink
                    ? const Color(0xFF88102C)
                    : (isPlague
                        ? const Color(0xFF4A148C)
                        : (isMedieval
                            ? const Color(0xFF7F101F)
                            : (isCozy
                                ? const Color(0xFF6B2B0B)
                                : const Color(0xFF155724))))))
            : (isPink ? const Color(0xFF780E26) : const Color(0xFF721C24)));

    final correctAnswerBoxBorder = isPink
        ? const Color(0xFFC24168)
        : (isSnowy
            ? const Color(0xFF00A8CC)
            : (isMedieval
                ? const Color(0xFFD4A338)
                : (isPlague
                    ? const Color(0xFFC77DFF)
                    : (isCozy
                        ? const Color(0xFFE28442)
                        : const Color(0xFFC84B31)))));

    final correctAnswerTextColor = isDark
        ? (isPink
            ? const Color(0xFFFF85A1)
            : (isSnowy
                ? const Color(0xFF7CE4F8)
                : (isMedieval
                    ? const Color(0xFFFFCDD2)
                    : (isPlague
                        ? const Color(0xFFE1BEE7)
                        : (isCozy
                            ? const Color(0xFFFFCC80)
                            : const Color(0xFFFEB2B2))))))
        : (isPink
            ? const Color(0xFF88102C)
            : (isSnowy
                ? const Color(0xFF0B4666)
                : (isMedieval
                    ? const Color(0xFF7F101F)
                    : (isPlague
                        ? const Color(0xFF4A148C)
                        : (isCozy
                            ? const Color(0xFF6B2B0B)
                            : const Color(0xFF8B2516))))));

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.4),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _feedbackAnimController,
        curve: Curves.easeOutBack,
      )),
      child: FadeTransition(
        opacity: _feedbackAnimController,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: (isCorrect ? themeSuccessColor : themeErrorColor).withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _feedbackAnimController,
                      curve: Curves.easeOutBack,
                    ),
                    child: QuixoteMascot(
                      expression: isCorrect ? QuixoteExpression.triumphant : QuixoteExpression.sad,
                      size: 58,
                      showSpeechBubble: false,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCorrect ? 'SPLENDID! EXACTLY RIGHT!' : 'VALIANT EFFORT! LANCE MISSED.',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: fgColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCorrect ? '“Thy knightly stroke strikes true!”' : '“Steady thy lance! A warrior learns from every duel.”',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: fgColor.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (!isCorrect) ...[
                Text(
                  'Correct Answer:',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: fgColor,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: correctAnswerBoxBorder.withValues(alpha: 0.7), width: 1.2),
                  ),
                  child: Text(
                    _getCorrectAnswerDisplay(),
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: correctAnswerTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                currentQuestion.explanation,
                style: AppTypography.bodySmall.copyWith(
                  color: fgColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              DuoButton(
                text: _currentIndex + 1 < widget.questions.length ? 'Continue' : 'Finish Quiz',
                onPressed: _nextQuestion,
                variant: DuoButtonVariant.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final total = widget.questions.length;
    final isPerfect = _correctCount == total;
    final isFinalTest = widget.level.type == LevelType.finalTest;
    final percentage = total > 0 ? ((_correctCount / total) * 100).round() : 100;
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String letterGrade;
    if (percentage == 100) {
      letterGrade = 'Grade: A+ (Flawless Scholar)';
    } else if (percentage >= 90) {
      letterGrade = 'Grade: A (Distinguished Knight)';
    } else if (percentage >= 80) {
      letterGrade = 'Grade: B+ (Honor Roll)';
    } else if (percentage >= 70) {
      letterGrade = 'Grade: B (Competent Squire)';
    } else {
      letterGrade = 'Grade: Needs Further Study';
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            children: [
              // Don Quixote Celebrates or Comforts with Animated Expression
              QuixoteMascot(
                expression: isPerfect ? QuixoteExpression.triumphant : QuixoteExpression.encouraging,
                size: 86,
                showSpeechBubble: false,
              ),
              const SizedBox(height: 12),

              // Trophy / Key Celebration
              if (isFinalTest && isPerfect) ...[
                const Icon(Icons.key_rounded, size: 68, color: AppColors.goldenKey),
                const SizedBox(height: 10),
                Text(
                  'GOLDEN KEY CONQUERED!',
                  style: AppTypography.displayMedium.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'With a 100% perfect score on this $total-Question Grand Assessment, thou hast forged a rare Golden Key! Use it in the Bazaar to unlock any epic.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: theme.colorScheme.onSurface),
                ),
              ] else ...[
                Icon(
                  isPerfect ? Icons.military_tech_rounded : Icons.school_rounded,
                  size: 68,
                  color: AppColors.antiqueGold,
                ),
                const SizedBox(height: 14),
                Text(
                  isPerfect ? 'Pristine Scholarship!' : 'Assessment Complete!',
                  style: AppTypography.displayMedium.copyWith(color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPerfect
                        ? theme.colorScheme.primary
                        : (isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.parchmentDark),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    letterGrade,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isPerfect ? AppColors.parchmentCream : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school_rounded, size: 13, color: theme.colorScheme.primary),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Assessed: ${widget.level.literacyPurpose}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Thou hast answered $_correctCount of $total questions correctly ($percentage%).',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: theme.colorScheme.onSurface),
                ),
              ],

              // Milestone Answer Streak Banner (Only at 10, 20, 30... milestones, fully overflow-protected)
              if (appState.consecutiveCorrectAnswers >= 10 && appState.consecutiveCorrectAnswers % 10 == 0) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.streakOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.streakOrange.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: AppColors.streakOrange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'ANSWER STREAK: ${appState.consecutiveCorrectAnswers} CONSECUTIVE IN A ROW!',
                            maxLines: 1,
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.streakOrange,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Royal Treasure Chest of Excellence (Appears on Perfect Sets!)
              if (isPerfect) ...[
                const SizedBox(height: 18),
                _buildTreasureChest(theme, isDark, appState),
              ],

              const SizedBox(height: 24),

              // Score & Loot Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.antiqueGold, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol(
                      label: 'Accuracy',
                      value: '$percentage%',
                      icon: Icons.track_changes_rounded,
                      color: theme.colorScheme.primary,
                      theme: theme,
                    ),
                    _buildStatCol(
                      label: 'Score',
                      value: '$_correctCount / $total',
                      icon: Icons.assignment_turned_in_rounded,
                      color: theme.colorScheme.primary,
                      theme: theme,
                    ),
                    _buildStatCol(
                      label: 'Gems Won',
                      value: '+${widget.level.gemsReward}',
                      icon: Icons.diamond_rounded,
                      color: AppColors.gemCyan,
                      theme: theme,
                    ),
                    if (appState.profile.answerStreak > 0)
                      _buildStatCol(
                        label: 'Answer Streak',
                        value: '${appState.profile.answerStreak}',
                        icon: Icons.local_fire_department_rounded,
                        color: AppColors.streakOrange,
                        theme: theme,
                      ),
                    if (isFinalTest && isPerfect)
                      _buildStatCol(
                        label: 'Golden Key',
                        value: '+1',
                        icon: Icons.key_rounded,
                        color: AppColors.goldenKey,
                        theme: theme,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Comprehensive Exam Review Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Exam Question Review ($total Questions)',
                  style: AppTypography.titleMedium.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              for (int i = 0; i < widget.questions.length; i++) ...[
                _buildReviewItem(
                  index: i,
                  question: widget.questions[i],
                  isCorrect: i < _questionResults.length ? _questionResults[i] : true,
                  theme: theme,
                ),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 24),

              // Return Button with Fluid Navigation
              DuoButton(
                text: 'Return to Quest Map',
                icon: Icons.arrow_back_rounded,
                variant: isPerfect ? DuoButtonVariant.gold : DuoButtonVariant.primary,
                onPressed: () {
                  final state = context.read<AppState>();
                  final currentLiterature = state.catalog.firstWhere(
                    (b) => b.id == widget.literatureId,
                    orElse: () => state.catalog.first,
                  );
                  final isLastLevel = currentLiterature.questLevels.isNotEmpty &&
                      currentLiterature.questLevels.last.id == widget.level.id;
                  final allLevelsCompleted = currentLiterature.questLevels.every((l) => l.isCompleted);
                  final shouldCelebrate = state.isOnline && state.shouldShowDailyStreakCelebration();
                  if (shouldCelebrate) {
                    state.markDailyStreakCelebrated();
                  }

                  Navigator.pop(context);

                  // When finishing a whole book or chapter sequence, congratulate with MasterpieceConqueredDialog!
                  if (isLastLevel || allLevelsCompleted) {
                    MasterpieceConqueredDialog.show(
                      context: context,
                      title: currentLiterature.title,
                      author: currentLiterature.author,
                      bonusGems: 100,
                      onContinue: () {
                        if (shouldCelebrate) {
                          StreakCelebrationDialog.show(
                            context: context,
                            streakDays: state.profile.streakDays,
                            isRekindled: state.profile.streakDays == 1,
                            gemsEarned: widget.level.gemsReward,
                            levelTitle: widget.level.title,
                            onContinue: () {},
                          );
                        }
                      },
                    );
                    return;
                  }

                  // Streak celebration only appears ONCE per day on the first completed activity,
                  // and waits until the 12:00 AM reset before appearing again!
                  if (shouldCelebrate) {
                    StreakCelebrationDialog.show(
                      context: context,
                      streakDays: state.profile.streakDays,
                      isRekindled: state.profile.streakDays == 1,
                      gemsEarned: widget.level.gemsReward,
                      levelTitle: widget.level.title,
                      onContinue: () {},
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTreasureChest(ThemeData theme, bool isDark, AppState appState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF282218), const Color(0xFF1A1814)]
              : [const Color(0xFFFFF8E7), const Color(0xFFFBF0D3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.antiqueGold, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.antiqueGold.withValues(alpha: isDark ? 0.35 : 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.antiqueGold.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.antiqueGold, width: 1.5),
                ),
                child: Icon(
                  _hasOpenedTreasureChest ? Icons.lock_open_rounded : Icons.inventory_2_rounded,
                  color: AppColors.antiqueGold,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hasOpenedTreasureChest
                          ? 'ROYAL CHEST UNLOCKED!'
                          : 'PERFECT FEAT TREASURE CHEST',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.antiqueGold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _hasOpenedTreasureChest
                          ? '+50 Radiant Gems • +2 Energy Hearts Claimed!'
                          : '100% flawless score! Tap to claim royal bounty.',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!_hasOpenedTreasureChest)
            Builder(
              builder: (btnCtx) => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.key_rounded, size: 18, color: Color(0xFF121212)),
                  label: const Text(
                    'OPEN TREASURE CHEST',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.antiqueGold,
                    foregroundColor: const Color(0xFF121212),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    final renderBox = btnCtx.findRenderObject() as RenderBox?;
                    final origin = renderBox != null && renderBox.hasSize
                        ? renderBox.localToGlobal(renderBox.size.center(Offset.zero))
                        : null;

                    HapticService.instance.celebration();

                    // Dispense +50 Gems & +2 Energy Hearts
                    appState.addGems(50);
                    appState.restoreEnergy(2);

                    final hasGoldenKey = widget.level.type == LevelType.finalTest && _correctCount == widget.questions.length;

                    // Pop up gems, hearts, and golden keys and gracefully fly them to their top counters
                    RewardCelebrationOverlay.openChest(
                      context,
                      origin: origin,
                      gems: 50,
                      hearts: 2,
                      keys: hasGoldenKey ? 1 : 0,
                    );

                    setState(() {
                      _hasOpenedTreasureChest = true;
                    });
                  },
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.antiqueGold.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.antiqueGold.withValues(alpha: 0.5)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: AppColors.antiqueGold),
                  SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Bounty Claimed: +50 Gems • +2 Hearts',
                        maxLines: 1,
                        style: TextStyle(color: AppColors.antiqueGold, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewItem({
    required int index,
    required QuizQuestion question,
    required bool isCorrect,
    required ThemeData theme,
  }) {
    final state = context.read<AppState>();
    final preset = state.activeThemePreset;
    final isSnowy = preset.interfaceStyle == ThemeInterfaceStyle.snowy;
    final isPink = preset.id == 'theme_cute_meadow';
    final successColor = isSnowy ? const Color(0xFF00A8CC) : (isPink ? const Color(0xFFE91E63) : theme.colorScheme.primary);
    final errorColor = isPink ? const Color(0xFF88102C) : (isSnowy ? const Color(0xFF0D2538) : AppColors.energyRed);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCorrect ? successColor.withValues(alpha: 0.5) : errorColor.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isCorrect ? successColor : errorColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Q${index + 1}: ${question.prompt}',
                  style: AppTypography.titleSmall.copyWith(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Correct Answer: ${_getReviewCorrectAnswer(question)}',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  question.explanation,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
