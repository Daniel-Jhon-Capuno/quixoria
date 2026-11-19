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
import '../../models/quote_card.dart';
import '../../shared/widgets/aesthetic_quote_card.dart';

/// Famous Quote Shrine on the Quest Map.
/// Players restore an iconic literary quote from scrambled phrase chips;
/// completing the shrine automatically mints an Aesthetic Quote Card
/// into their Reading Notebook and awards Gems + Leaderboard XP.
class QuoteShrineScreen extends StatefulWidget {
  final Literature literature;
  final QuestLevel level;

  const QuoteShrineScreen({
    super.key,
    required this.literature,
    required this.level,
  });

  @override
  State<QuoteShrineScreen> createState() => _QuoteShrineScreenState();
}

class _QuoteShrineScreenState extends State<QuoteShrineScreen> {
  late final String _fullQuote;
  late final List<String> _targetChunks;
  late final List<int> _bankIndices;
  final List<int> _placedIndices = [];

  bool _solved = false;
  bool _wrongFlash = false;
  int _mistakes = 0;
  final String _selectedStyle = 'parchment';

  @override
  void initState() {
    super.initState();
    _fullQuote = SpecialNodesData.iconicQuoteForBook(widget.literature);
    _targetChunks = _splitIntoPhraseChunks(_fullQuote);
    _bankIndices = List.generate(_targetChunks.length, (i) => i);
    final rng = Random(widget.literature.id.hashCode ^ 0x5A17);
    _bankIndices.shuffle(rng);
    // Guarantee it's not already in exact sorted order
    if (_bankIndices.length > 1 &&
        List.generate(_bankIndices.length, (i) => i)
            .every((i) => _bankIndices[i] == i)) {
      final first = _bankIndices.removeAt(0);
      _bankIndices.add(first);
    }
  }

  /// Groups words into 5–7 satisfying phrase chips so the puzzle is fun and readable.
  List<String> _splitIntoPhraseChunks(String quote) {
    final words = quote.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length <= 6) return words;
    final chunkSize = (words.length / 6).ceil().clamp(2, 4);
    final chunks = <String>[];
    for (int i = 0; i < words.length; i += chunkSize) {
      final end = (i + chunkSize).clamp(0, words.length);
      chunks.add(words.sublist(i, end).join(' '));
    }
    return chunks;
  }

  void _pickFromBank(int chunkIdx) {
    if (_solved) return;
    final state = context.read<AppState>();
    state.triggerHaptic();
    setState(() {
      _wrongFlash = false;
      _bankIndices.remove(chunkIdx);
      _placedIndices.add(chunkIdx);
    });
  }

  void _removeFromPlaced(int chunkIdx) {
    if (_solved) return;
    setState(() {
      _wrongFlash = false;
      _placedIndices.remove(chunkIdx);
      _bankIndices.add(chunkIdx);
    });
  }

  void _checkQuote() {
    if (_placedIndices.length != _targetChunks.length) return;
    final assembled = _placedIndices.map((i) => _targetChunks[i]).join(' ');
    final expected = _targetChunks.join(' ');
    final state = context.read<AppState>();

    if (assembled == expected) {
      SoundService.instance.play(Sfx.reward);
      state.triggerHaptic();
      final gems = _mistakes == 0 ? 40 : 25;
      final xp = _mistakes == 0 ? 45 : 30;
      state.addQuoteCard(
        quoteText: _fullQuote,
        literatureId: widget.literature.id,
        literatureTitle: widget.literature.title,
        author: widget.literature.author,
        chapterTitle: widget.level.title,
        styleKey: _selectedStyle,
      );
      state.addGems(gems);
      state.addLeaderboardXp(xp);
      state.completeQuestLevel(
        literatureId: widget.literature.id,
        levelId: widget.level.id,
        isPerfectScore: _mistakes == 0,
      );
      setState(() => _solved = true);
    } else {
      SoundService.instance.play(Sfx.wrong);
      state.triggerHaptic();
      setState(() {
        _mistakes++;
        _wrongFlash = true;
      });
    }
  }

  void _resetTiles() {
    setState(() {
      _wrongFlash = false;
      _bankIndices.addAll(_placedIndices);
      _placedIndices.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgTop = isDark ? const Color(0xFF171324) : const Color(0xFFFAF8F4);
    final bgBot = isDark ? const Color(0xFF231B36) : const Color(0xFFF0E9DD);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E1B24);
    final textMuted = isDark ? Colors.white70 : const Color(0xFF5D576B);
    final shrineAccent = isDark ? const Color(0xFFD8A4FF) : const Color(0xFF7C3AED);

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
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
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
                              Icon(Icons.format_quote_rounded, size: 16, color: shrineAccent),
                              const SizedBox(width: 4),
                              Text(
                                'FAMOUS QUOTE SHRINE',
                                style: AppTypography.labelSmall.copyWith(
                                  color: shrineAccent,
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
                    if (!_solved && _placedIndices.isNotEmpty)
                      TextButton.icon(
                        onPressed: _resetTiles,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Clear'),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                Expanded(
                  child: SingleChildScrollView(
                    child: _solved
                        ? _buildSolvedView(shrineAccent, textPrimary, textMuted)
                        : _buildPuzzleView(isDark, shrineAccent, textPrimary, textMuted),
                  ),
                ),

                const SizedBox(height: 12),

                if (_solved)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text('KEEP QUOTE CARD & RETURN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.antiqueGold,
                      foregroundColor: const Color(0xFF1F1600),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _placedIndices.length == _targetChunks.length
                        ? _checkQuote
                        : null,
                    icon: const Icon(Icons.verified_rounded, size: 18),
                    label: const Text('INSCRIBE ON SHRINE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: shrineAccent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: shrineAccent.withValues(alpha: 0.25),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPuzzleView(
    bool isDark,
    Color shrineAccent,
    Color textPrimary,
    Color textMuted,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Restore the Sacred Quote',
          style: AppTypography.displaySmall.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap the engraved phrases in order to unlock an Aesthetic Quote Card for your Notebook.',
          style: AppTypography.bodySmall.copyWith(color: textMuted),
        ),
        const SizedBox(height: 18),

        // Inscription tablet
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          constraints: const BoxConstraints(minHeight: 148),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _wrongFlash
                  ? const Color(0xFFEF4444)
                  : shrineAccent.withValues(alpha: 0.4),
              width: 1.8,
            ),
          ),
          child: _placedIndices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_stories_rounded,
                        color: shrineAccent.withValues(alpha: 0.5),
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap phrase tiles below to assemble the quote…',
                        style: AppTypography.bodySmall.copyWith(color: textMuted),
                      ),
                    ],
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: _placedIndices.map((idx) {
                    return ActionChip(
                      label: Text(
                        _targetChunks[idx],
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      backgroundColor: shrineAccent,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      onPressed: () => _removeFromPlaced(idx),
                    );
                  }).toList(),
                ),
        ),

        if (_wrongFlash) ...[
          const SizedBox(height: 10),
          Text(
            'Not quite the exact cadence — tap any placed phrase to reorder it!',
            style: AppTypography.bodySmall.copyWith(
              color: const Color(0xFFEF4444),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],

        const SizedBox(height: 22),

        Text(
          'PHRASE BANK',
          style: AppTypography.labelSmall.copyWith(
            color: textMuted,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _bankIndices.map((idx) {
            return ActionChip(
              label: Text(
                _targetChunks[idx],
                style: AppTypography.bodyMedium.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white,
              side: BorderSide(
                color: shrineAccent.withValues(alpha: 0.32),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onPressed: () => _pickFromBank(idx),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSolvedView(
    Color shrineAccent,
    Color textPrimary,
    Color textMuted,
  ) {
    final previewCard = QuoteCard(
      id: 'preview',
      quoteText: _fullQuote,
      literatureId: widget.literature.id,
      literatureTitle: widget.literature.title,
      author: widget.literature.author,
      chapterTitle: widget.level.title,
      styleKey: _selectedStyle,
      createdAt: DateTime.now(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF22C55E).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF22C55E)),
                const SizedBox(width: 6),
                Text(
                  'SAVED TO READING NOTEBOOK!',
                  style: AppTypography.labelSmall.copyWith(
                    color: const Color(0xFF22C55E),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        AestheticQuoteCard(
          card: previewCard,
          showActions: false,
        ),
        const SizedBox(height: 10),
        Text(
          'Rewards earned: +${_mistakes == 0 ? 40 : 25} Gems • +${_mistakes == 0 ? 45 : 30} Leaderboard XP',
          textAlign: TextAlign.center,
          style: AppTypography.labelMedium.copyWith(
            color: shrineAccent,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
