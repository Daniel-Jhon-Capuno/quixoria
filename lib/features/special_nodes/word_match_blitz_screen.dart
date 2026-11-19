import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';
import '../../data/special_nodes_data.dart';
import '../../models/literature.dart';
import '../../models/quest_level.dart';

/// Tactile 5-pair Word Match Blitz on the Quest Map.
/// Tap a literary term on the left and its matching meaning on the right;
/// all mastered pairs are added straight into the user's Word Bank!
class WordMatchBlitzScreen extends StatefulWidget {
  final Literature literature;
  final QuestLevel level;

  const WordMatchBlitzScreen({
    super.key,
    required this.literature,
    required this.level,
  });

  @override
  State<WordMatchBlitzScreen> createState() => _WordMatchBlitzScreenState();
}

class _WordMatchBlitzScreenState extends State<WordMatchBlitzScreen> {
  late final List<MapEntry<String, String>> _pairs;
  late final List<int> _rightOrder;

  int? _selectedLeft;
  int? _selectedRight;
  int? _wrongLeft;
  int? _wrongRight;
  final Set<int> _matchedIds = {};
  int _mistakes = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _pairs = SpecialNodesData.wordPairsForBook(widget.literature).entries.toList();
    _rightOrder = List.generate(_pairs.length, (i) => i);
    _rightOrder.shuffle(Random(widget.literature.id.hashCode ^ 0x33C));
  }

  void _tapLeft(int pairIndex) {
    if (_completed || _matchedIds.contains(pairIndex)) return;
    context.read<AppState>().triggerHaptic();
    setState(() {
      _wrongLeft = null;
      _wrongRight = null;
      _selectedLeft = pairIndex;
    });
    _evaluatePair();
  }

  void _tapRight(int pairIndex) {
    if (_completed || _matchedIds.contains(pairIndex)) return;
    context.read<AppState>().triggerHaptic();
    setState(() {
      _wrongLeft = null;
      _wrongRight = null;
      _selectedRight = pairIndex;
    });
    _evaluatePair();
  }

  void _evaluatePair() {
    if (_selectedLeft == null || _selectedRight == null) return;
    final left = _selectedLeft!;
    final right = _selectedRight!;
    final state = context.read<AppState>();

    if (left == right) {
      SoundService.instance.play(Sfx.correct);
      state.triggerHaptic();
      setState(() {
        _matchedIds.add(left);
        _selectedLeft = null;
        _selectedRight = null;
      });
      if (_matchedIds.length == _pairs.length) {
        _finishBlitz();
      }
    } else {
      SoundService.instance.play(Sfx.wrong);
      state.triggerHaptic();
      setState(() {
        _mistakes++;
        _wrongLeft = left;
        _wrongRight = right;
        _selectedLeft = null;
        _selectedRight = null;
      });
      Future.delayed(const Duration(milliseconds: 520), () {
        if (!mounted) return;
        setState(() {
          _wrongLeft = null;
          _wrongRight = null;
        });
      });
    }
  }

  int get _gemsEarned => _mistakes == 0 ? 40 : (_mistakes <= 2 ? 30 : 20);
  int get _xpEarned => _mistakes == 0 ? 45 : 30;

  void _finishBlitz() {
    if (_completed) return;
    final state = context.read<AppState>();
    SoundService.instance.play(Sfx.reward);

    for (final p in _pairs) {
      state.addOrUpdateVocabCard(
        word: p.key,
        definition: p.value,
        example: 'Mastered in ${widget.literature.title} Word Match Blitz.',
        literatureId: widget.literature.id,
        literatureTitle: widget.literature.title,
      );
    }

    state.addGems(_gemsEarned);
    state.addLeaderboardXp(_xpEarned);
    state.completeQuestLevel(
      literatureId: widget.literature.id,
      levelId: widget.level.id,
      isPerfectScore: _mistakes == 0,
    );

    setState(() => _completed = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgTop = isDark ? const Color(0xFF0E1D1B) : const Color(0xFFF6FBF9);
    final bgBot = isDark ? const Color(0xFF142826) : const Color(0xFFE7F4EF);
    final textPrimary = isDark ? Colors.white : const Color(0xFF132A24);
    final textMuted = isDark ? Colors.white70 : const Color(0xFF4B6B62);
    final accent = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBot],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: textMuted),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.extension_rounded, size: 16, color: accent),
                              const SizedBox(width: 5),
                              Text(
                                'WORD MATCH BLITZ',
                                style: AppTypography.labelSmall.copyWith(
                                  color: accent,
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
                            style: AppTypography.bodySmall.copyWith(color: textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: accent.withValues(alpha: 0.45)),
                      ),
                      child: Text(
                        '${_matchedIds.length}/${_pairs.length}',
                        style: AppTypography.labelMedium.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (_completed)
                  Expanded(child: _buildVictoryCard(accent, textPrimary, textMuted))
                else ...[
                  Text(
                    'Pair each literary word with its meaning',
                    style: AppTypography.titleMedium.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Every matched pair is saved to your Lexicon Word Bank.',
                    style: AppTypography.bodySmall.copyWith(color: textMuted),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _pairs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, row) {
                        final leftIdx = row;
                        final rightIdx = _rightOrder[row];
                        return Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: _MatchTile(
                                text: _pairs[leftIdx].key,
                                isBold: true,
                                isDark: isDark,
                                accent: accent,
                                isMatched: _matchedIds.contains(leftIdx),
                                isSelected: _selectedLeft == leftIdx,
                                isWrong: _wrongLeft == leftIdx,
                                onTap: () => _tapLeft(leftIdx),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 6,
                              child: _MatchTile(
                                text: _pairs[rightIdx].value,
                                isBold: false,
                                isDark: isDark,
                                accent: accent,
                                isMatched: _matchedIds.contains(rightIdx),
                                isSelected: _selectedRight == rightIdx,
                                isWrong: _wrongRight == rightIdx,
                                onTap: () => _tapRight(rightIdx),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVictoryCard(Color accent, Color textPrimary, Color textMuted) {
    return Center(
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.2),
              ),
              child: Icon(Icons.menu_book_rounded, size: 36, color: accent),
            ),
            const SizedBox(height: 14),
            Text(
              _mistakes == 0 ? 'FLAWLESS LEXICON!' : 'WORDS MASTERED!',
              style: AppTypography.displaySmall.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'All ${_pairs.length} words have been added to your Word Bank.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              '+$_gemsEarned Gems  •  +$_xpEarned Leaderboard XP',
              style: AppTypography.labelLarge.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
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
                  ),
                ),
                child: const Text('RETURN TO MAP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final String text;
  final bool isBold;
  final bool isDark;
  final Color accent;
  final bool isMatched;
  final bool isSelected;
  final bool isWrong;
  final VoidCallback onTap;

  const _MatchTile({
    required this.text,
    required this.isBold,
    required this.isDark,
    required this.accent,
    required this.isMatched,
    required this.isSelected,
    required this.isWrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMatched
        ? const Color(0xFF22C55E).withValues(alpha: 0.16)
        : isWrong
            ? const Color(0xFFEF4444).withValues(alpha: 0.2)
            : isSelected
                ? accent.withValues(alpha: 0.24)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white);

    final border = isMatched
        ? const Color(0xFF22C55E)
        : isWrong
            ? const Color(0xFFEF4444)
            : isSelected
                ? accent
                : accent.withValues(alpha: 0.25);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: const BoxConstraints(minHeight: 74),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: isSelected || isWrong ? 2.0 : 1.3),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isMatched ? null : onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: (isBold ? AppTypography.titleSmall : AppTypography.bodySmall)
                    .copyWith(
                  color: isMatched
                      ? const Color(0xFF22C55E)
                      : (isDark ? Colors.white : const Color(0xFF132A24)),
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                  decoration: isMatched ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
