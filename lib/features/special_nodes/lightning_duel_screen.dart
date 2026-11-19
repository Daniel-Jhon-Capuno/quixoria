import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';
import '../../data/special_nodes_data.dart';
import '../../models/literature.dart';
import '../../models/quest_level.dart';

/// 45-second timed rapid-fire True / False sprint on the Quest Map.
/// Features a live countdown bar, combo multiplier, instant quick-fact
/// feedback, and Leaderboard XP + Gem rewards scaled by accuracy & combo.
class LightningDuelScreen extends StatefulWidget {
  final Literature literature;
  final QuestLevel level;

  const LightningDuelScreen({
    super.key,
    required this.literature,
    required this.level,
  });

  @override
  State<LightningDuelScreen> createState() => _LightningDuelScreenState();
}

class _LightningDuelScreenState extends State<LightningDuelScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalSeconds = 45;

  late final List<LightningPrompt> _prompts;
  late final AnimationController _pulseController;
  Timer? _timer;

  int _secondsLeft = _totalSeconds;
  int _index = 0;
  int _correctCount = 0;
  int _combo = 0;
  int _maxCombo = 0;
  bool? _lastAnswerCorrect;
  String? _lastQuickFact;
  bool _finished = false;
  bool _rewardsAwarded = false;

  @override
  void initState() {
    super.initState();
    _prompts = SpecialNodesData.lightningPromptsForBook(widget.literature);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        _finishDuel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _submitAnswer(bool answer) {
    if (_finished || _index >= _prompts.length) return;
    final prompt = _prompts[_index];
    final isCorrect = prompt.isTrue == answer;
    final state = context.read<AppState>();

    if (isCorrect) {
      SoundService.instance.play(Sfx.correct);
      state.triggerHaptic();
      _correctCount++;
      _combo++;
      if (_combo > _maxCombo) _maxCombo = _combo;
    } else {
      SoundService.instance.play(Sfx.wrong);
      state.triggerHaptic();
      _combo = 0;
    }

    setState(() {
      _lastAnswerCorrect = isCorrect;
      _lastQuickFact = prompt.quickFact;
    });

    if (_index + 1 >= _prompts.length) {
      _timer?.cancel();
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted) _finishDuel();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 520), () {
        if (!mounted || _finished) return;
        setState(() {
          _index++;
          _lastAnswerCorrect = null;
        });
      });
    }
  }

  int get _gemsEarned => 18 + (_correctCount * 6) + (_maxCombo * 3);
  int get _xpEarned => 20 + (_correctCount * 10) + (_maxCombo * 5);

  void _finishDuel() {
    if (_finished) return;
    _timer?.cancel();
    setState(() => _finished = true);

    if (!_rewardsAwarded) {
      _rewardsAwarded = true;
      final state = context.read<AppState>();
      SoundService.instance.play(Sfx.reward);
      state.addGems(_gemsEarned);
      state.addLeaderboardXp(_xpEarned);
      state.completeQuestLevel(
        literatureId: widget.literature.id,
        levelId: widget.level.id,
        isPerfectScore: _correctCount == _prompts.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _secondsLeft / _totalSeconds;
    final isUrgent = _secondsLeft <= 10;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1324),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1020),
              Color(0xFF162040),
              Color(0xFF1F1638),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            child: _finished ? _buildSummary() : _buildDuelBody(progress, isUrgent),
          ),
        ),
      ),
    );
  }

  Widget _buildDuelBody(double progress, bool isUrgent) {
    final prompt = _prompts[_index];
    final accent = isUrgent ? const Color(0xFFFF5252) : const Color(0xFF38BDF8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top HUD
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
                      const Icon(Icons.bolt_rounded, color: Color(0xFFFACC15), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'LIGHTNING DUEL',
                        style: AppTypography.labelSmall.copyWith(
                          color: const Color(0xFFFACC15),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    widget.literature.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            // Combo badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _combo >= 2
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _combo >= 2
                      ? const Color(0xFFFACC15)
                      : Colors.white.withValues(alpha: 0.16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 16,
                    color: _combo >= 2 ? const Color(0xFFFACC15) : Colors.white54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_combo}x',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Live countdown bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, child) => Transform.scale(
                scale: isUrgent ? 1.0 + (_pulseController.value * 0.1) : 1.0,
                child: child,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withValues(alpha: 0.6)),
                ),
                child: Text(
                  '${_secondsLeft}s',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Step pills
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_prompts.length, (i) {
            final active = i == _index;
            final past = i < _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 24 : 10,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFFACC15)
                    : past
                        ? const Color(0xFF38BDF8)
                        : Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        ),

        const Spacer(),

        // Statement card
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: Container(
            key: ValueKey(_index),
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: _lastAnswerCorrect == null
                    ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
                    : (_lastAnswerCorrect!
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444)),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ROUND ${_index + 1} OF ${_prompts.length}',
                    style: AppTypography.labelSmall.copyWith(
                      color: const Color(0xFF7DD3FC),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  prompt.statement,
                  textAlign: TextAlign.center,
                  style: AppTypography.displaySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.38,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Instant quick-fact banner
        SizedBox(
          height: 54,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _lastQuickFact != null ? 1.0 : 0.0,
            child: _lastQuickFact == null
                ? const SizedBox.shrink()
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: (_lastAnswerCorrect == true
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444))
                          .withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (_lastAnswerCorrect == true
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFEF4444))
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _lastAnswerCorrect == true
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: _lastAnswerCorrect == true
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFFF87171),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _lastQuickFact!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),

        const Spacer(),

        // True / False buttons
        Row(
          children: [
            Expanded(
              child: _DuelActionButton(
                label: 'FALSE',
                icon: Icons.close_rounded,
                color: const Color(0xFFEF4444),
                onTap: _lastAnswerCorrect == null ? () => _submitAnswer(false) : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _DuelActionButton(
                label: 'TRUE',
                icon: Icons.check_rounded,
                color: const Color(0xFF22C55E),
                onTap: _lastAnswerCorrect == null ? () => _submitAnswer(true) : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final perfect = _correctCount == _prompts.length;
    return Center(
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFFACC15).withValues(alpha: 0.5),
            width: 1.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFACC15), Color(0xFFF59E0B)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFACC15).withValues(alpha: 0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.bolt_rounded, color: Color(0xFF1F1600), size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              perfect ? 'LIGHTNING MASTER!' : 'DUEL COMPLETE!',
              style: AppTypography.displaySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You struck $_correctCount/${_prompts.length} correct with a ${_maxCombo}x max combo.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RewardChip(
                  icon: Icons.diamond_rounded,
                  label: '+$_gemsEarned Gems',
                  color: const Color(0xFF38BDF8),
                ),
                const SizedBox(width: 12),
                _RewardChip(
                  icon: Icons.leaderboard_rounded,
                  label: '+$_xpEarned XP',
                  color: const Color(0xFFFACC15),
                ),
              ],
            ),
            const SizedBox(height: 22),
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
                    letterSpacing: 0.8,
                  ),
                ),
                child: const Text('CLAIM & RETURN TO MAP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DuelActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _DuelActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: onTap == null ? 0.35 : 0.92),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.4,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RewardChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
