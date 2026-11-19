import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/state/app_state.dart';
import '../../models/literature.dart';
import '../../models/reading_note.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/guide_dialog.dart';
import '../../shared/widgets/quixote_3d_character.dart';
import '../../shared/widgets/quixote_avatar.dart';
import '../../shared/widgets/reward_celebration.dart';
import '../../shared/widgets/streak_celebration_dialog.dart';
import '../../core/services/ambience_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import 'ambience_soundscape_sheet.dart';
import 'socratic_counsel_sheet.dart';

class ReaderScreen extends StatefulWidget {
  final Literature literature;
  final int chapterIndex;
  final String levelId;

  const ReaderScreen({
    super.key,
    required this.literature,
    required this.chapterIndex,
    required this.levelId,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  double _fontSize = 19.0;
  final ScrollController _scrollController = ScrollController();
  double _readProgress = 0.0;
  bool _showMarginalia = false;

  // Notable vocabulary dictionary for tap-to-define
  static const Map<String, Map<String, String>> _vocabularyGlossary = {
    'ayah': {
      'word': 'Ayah',
      'phonetic': '/ˈɑː.jə/',
      'definition': 'A native Indian nursemaid or maidservant employed to care for children in Anglo-Indian households.',
      'type': 'Noun (Historical Colonial)',
    },
    'tyrannical': {
      'word': 'Tyrannical',
      'phonetic': '/tɪˈræn.ɪ.kəl/',
      'definition': 'Exercising power in a cruel, arbitrary, or domineering manner; imperious and overbearing.',
      'type': 'Adjective',
    },
    'cholera': {
      'word': 'Cholera',
      'phonetic': '/ˈkɒl.ər.ə/',
      'definition': 'An acute, often fatal bacterial disease of the small intestine, common in tropical epidemics.',
      'type': 'Noun (Pathology)',
    },
    'compound': {
      'word': 'Compound',
      'phonetic': '/ˈkɒm.paʊnd/',
      'definition': 'An enclosed residential ground or cluster of buildings and bungalows surrounded by a wall.',
      'type': 'Noun (Architecture)',
    },
    'hidalgo': {
      'word': 'Hidalgo',
      'phonetic': '/ɪˈdæl.ɡoʊ/',
      'definition': 'A member of the Spanish lower nobility or country gentleman of ancient, honorable lineage.',
      'type': 'Noun (Spanish Chivalry)',
    },
    'buckler': {
      'word': 'Buckler',
      'phonetic': '/ˈbʌk.lər/',
      'definition': 'A small, round shield held by a center handle or strapped to the arm for parrying in hand-to-hand combat.',
      'type': 'Noun (Medieval Armament)',
    },
    'hack': {
      'word': 'Hack',
      'phonetic': '/hæk/',
      'definition': 'An ordinary, worn-out road horse kept for routine riding or hire, contrasting with a knightly warhorse.',
      'type': 'Noun (Equine)',
    },
    'pasteboard': {
      'word': 'Pasteboard',
      'phonetic': '/ˈpeɪst.bɔːrd/',
      'definition': 'Stiff, firm cardboard created by pasting multiple layers of paper together.',
      'type': 'Noun (Material)',
    },
    'vigil': {
      'word': 'Vigil',
      'phonetic': '/ˈvɪdʒ.ɪl/',
      'definition': 'A solemn, sleepless period of prayerful watchfulness kept before a sacred ceremony or knighthood.',
      'type': 'Noun (Chivalric Custom)',
    },
    'deduction': {
      'word': 'Deduction',
      'phonetic': '/dɪˈdʌk.ʃən/',
      'definition': 'The inference of particular facts by applying logical principles to observed physical evidence.',
      'type': 'Noun (Forensic Logic)',
    },
    'ineffable': {
      'word': 'Ineffable',
      'phonetic': '/ɪnˈef.ə.bəl/',
      'definition': 'Too immense, wondrous, or sacred to be expressed in ordinary human words.',
      'type': 'Adjective',
    },
    'circumnavigate': {
      'word': 'Circumnavigate',
      'phonetic': '/ˌsɜː.kəmˈnæv.ɪ.ɡeɪt/',
      'definition': 'To sail or travel entirely around an island, continent, or the globe.',
      'type': 'Verb (Navigation)',
    },
    'fastidious': {
      'word': 'Fastidious',
      'phonetic': '/fæsˈtɪd.i.əs/',
      'definition': 'Very attentive to accuracy, precision, and propriety; difficult to please.',
      'type': 'Adjective',
    },
    'circumspection': {
      'word': 'Circumspection',
      'phonetic': '/ˌsɜː.kəmˈspek.ʃən/',
      'definition': 'Prudent care, discretion, and careful observation of circumstances before acting.',
      'type': 'Noun',
    },
  };

  @override
  void initState() {
    super.initState();
    SoundService.instance.play(Sfx.pageTurn);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = Provider.of<AppState>(context, listen: false);
      if (state.musicEnabled) {
        AmbienceService.instance.resume();
      }
      final offset = state.getReadingOffset(widget.literature.id, widget.chapterIndex);
      if (offset > 60 && _scrollController.hasClients) {
        final target = offset.clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.jumpTo(target);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.bookmark_added_rounded, color: AppColors.antiqueGold, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Resumed from thy previous reading mark.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final max = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
      setState(() {
        _readProgress = max > 0 ? (current / max).clamp(0.0, 1.0) : 1.0;
      });
      if (current > 60 && mounted) {
        Provider.of<AppState>(context, listen: false)
            .saveReadingOffset(widget.literature.id, widget.chapterIndex, current);
      }
    }
  }

  void _saveReadingOffset() {
    if (!mounted || !_scrollController.hasClients) return;
    final current = _scrollController.offset;
    Provider.of<AppState>(context, listen: false)
        .saveReadingOffset(widget.literature.id, widget.chapterIndex, current);
  }

  @override
  void dispose() {
    AmbienceService.instance.pause();
    _saveReadingOffset();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Chapter get chapter {
    if (widget.chapterIndex < widget.literature.chapters.length) {
      return widget.literature.chapters[widget.chapterIndex];
    }
    return widget.literature.chapters.first;
  }

  String get _donQuixoteMarginalia {
    switch (widget.literature.id) {
      case 'lit_don_quixote':
        return '“Hearken, friend! When I chose Rocinante and Dulcinea, many called it madness. But to dare to dream of honor when the world settles for mediocrity—that is the highest chivalry!”';
      case 'lit_study_in_scarlet':
        return '“Observe this Mr. Holmes! His lance is his magnifying lens, and his armor is pure deductive science! A true knight of the intellect!”';
      case 'lit_around_the_world_80_days':
        return '“Eighty days across steamships and locomotives! Phileas Fogg rides with the unyielding purpose of a knight-errant upon the world’s map!”';
      case 'lit_pride_and_prejudice':
        return '“Hasty judgments wound more deeply than a steel blade. Elizabeth and Darcy teach us that true nobility requires humility of heart.”';
      default:
        return '“Linger upon these passages, noble reader. Every classic masterwork holds a secret mirror to human virtue.”';
    }
  }

  void _showWordDefinition(String key) {
    HapticFeedback.lightImpact();
    final wordData = _vocabularyGlossary[key.toLowerCase()];
    if (wordData == null) return;

    final state = context.read<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    wordData['word']!,
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.antiqueGold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    wordData['phonetic']!,
                    style: AppTypography.bodySmall.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.antiqueGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  wordData['type']!,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.antiqueGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                wordData['definition']!,
                style: AppTypography.bodyMedium.copyWith(
                  height: 1.45,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.antiqueGold,
                    foregroundColor: isDark ? const Color(0xFF121212) : Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.bookmark_add_rounded, size: 20),
                  label: const Text(
                    'Add to Word Bank (+10 XP)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    final pCol = Theme.of(context).colorScheme.primary;
                    state.addOrUpdateVocabCard(
                      word: wordData['word']!,
                      definition: wordData['definition']!,
                      example: 'Found in ${widget.literature.title}, Chapter ${chapter.chapterNumber}',
                      literatureId: widget.literature.id,
                      literatureTitle: widget.literature.title,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added "${wordData['word']}" to thy Spaced Repetition Word Bank!'),
                        backgroundColor: pCol,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;
    final isDyslexic = state.isDyslexicFont;
    final isReaderMode = state.isReaderMode;
    final bgColor = isDark
        ? AppColors.darkBackground
        : (isReaderMode ? const Color(0xFFF7F2E7) : AppColors.parchmentCream);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        _saveReadingOffset();
      },
      child: Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.darkAccentGold : Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.literature.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              chapter.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(fontSize: 11),
            ),
          ],
        ),
        actions: [
          // Reading Ambience & Music toggle
          IconButton(
            tooltip: 'Reading Ambience & Music',
            icon: const Icon(
              Icons.spatial_audio_rounded,
              color: AppColors.antiqueGold,
            ),
            onPressed: () {
              HapticService.instance.light();
              SoundService.instance.play(Sfx.tap);
              AmbienceSoundscapeSheet.show(context);
            },
          ),
          // Ask Don Quixote dialogue
          IconButton(
            tooltip: 'Ask Don Quixote',
            icon: const Icon(
              Icons.forum_rounded,
              color: AppColors.antiqueGold,
            ),
            onPressed: () {
              HapticService.instance.medium();
              SoundService.instance.play(Sfx.tap);
              final clean = chapter.content.replaceAll('\r\n', '\n');
              final paragraphs = clean
                  .split(RegExp(r'\n\s*\n'))
                  .map((p) => p.trim())
                  .where((p) => p.isNotEmpty)
                  .toList();
              final passage = chapter.quoteHighlight ?? (paragraphs.isNotEmpty ? paragraphs.first : chapter.title);
              SocraticCounselSheet.show(
                context,
                passage: passage,
                bookTitle: widget.literature.title,
                chapterTitle: chapter.title,
                literatureId: widget.literature.id,
              );
            },
          ),
          // Reader Display & Commentary Settings Menu
          PopupMenuButton<String>(
            tooltip: 'Reader Display & Options',
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark ? AppColors.darkAccentGold : Theme.of(context).colorScheme.primary,
            ),
            onSelected: (action) {
              if (action == 'increase_font') {
                if (_fontSize < 28) setState(() => _fontSize += 2);
              } else if (action == 'decrease_font') {
                if (_fontSize > 15) setState(() => _fontSize -= 2);
              } else if (action == 'toggle_marginalia') {
                setState(() => _showMarginalia = !_showMarginalia);

              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'decrease_font',
                child: Row(
                  children: [
                    const Icon(Icons.text_decrease_rounded, size: 18),
                    const SizedBox(width: 10),
                    Text('Smaller Font (${_fontSize.toInt()}pt)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'increase_font',
                child: Row(
                  children: [
                    const Icon(Icons.text_increase_rounded, size: 18),
                    const SizedBox(width: 10),
                    Text('Larger Font (${_fontSize.toInt()}pt)'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'toggle_marginalia',
                child: Row(
                  children: [
                    Icon(
                      _showMarginalia ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: AppColors.antiqueGold,
                    ),
                    const SizedBox(width: 10),
                    Text(_showMarginalia ? 'Hide Counsel Notes' : 'Show Counsel Notes'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _readProgress,
            backgroundColor: AppColors.parchmentDark,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.antiqueGold),
            minHeight: 4,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Offline Banner Alert
              if (!state.isOnline) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD35400).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD35400)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: Color(0xFFD35400), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Offline Reading: You may read freely and take notes, but gem rewards and daily streaks require an online connection.',
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFFD35400),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Don Quixote Marginalia Speech Banner (if toggled)
              if (_showMarginalia) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.antiqueGold, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.antiqueGold.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DonQuixote3DCharacter(
                        size: 54,
                        pose: CharacterPose.reading,
                        emotion: CharacterEmotion.happy,
                        idleValue: 0.4,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'QUIXOTE’S MARGINALIA',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.antiqueGold,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    fontSize: 10.5,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _showMarginalia = false),
                                  child: const Icon(Icons.close_rounded, size: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _donQuixoteMarginalia,
                              style: AppTypography.bodySmall.copyWith(
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Metadata bar: Estimated reading time & chapter badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'CHAPTER ${chapter.chapterNumber}',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark ? AppColors.darkAccentGold : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 15, color: AppColors.inkLight),
                      const SizedBox(width: 4),
                      Text(
                        '~${chapter.estimatedMinutes} min read',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Chapter Title
              Text(
                chapter.title,
                style: AppTypography.displayMedium.copyWith(
                  color: isDark ? AppColors.darkAccentGold : Theme.of(context).colorScheme.primary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'By ${widget.literature.author}',
                style: AppTypography.bodySmall.copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.antiqueGold, thickness: 1.5),
              const SizedBox(height: 20),

              // Highlighted Quotation Callout (if available)
              if (chapter.quoteHighlight != null) ...[
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: const Border(
                      left: BorderSide(color: AppColors.antiqueGold, width: 4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.format_quote_rounded, color: AppColors.antiqueGold, size: 28),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: isDark ? AppColors.darkAccentGold : Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                            label: const Text('Save to Notes', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              final pColor = Theme.of(context).colorScheme.primary;
                              state.addNote(
                                literatureId: widget.literature.id,
                                literatureTitle: widget.literature.title,
                                chapterTitle: chapter.title,
                                type: NoteType.quote,
                                title: 'Quotation from Chapter ${chapter.chapterNumber}',
                                content: chapter.quoteHighlight!,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Saved to your Notes notebook.'),
                                  backgroundColor: pColor,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Text(
                        chapter.quoteHighlight!,
                        style: AppTypography.quote.copyWith(fontSize: 16),
                      ),
                      if (chapter.quoteContext != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '— ${chapter.quoteContext!}',
                          style: AppTypography.bodySmall.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.inkLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Interactive Literary Body Text with Drop Cap & Tap-to-Define Words
              _buildInteractiveBodyText(chapter.content, _fontSize, isDyslexic, isDark),

              const SizedBox(height: 36),
              const Divider(color: AppColors.borderLight),
              const SizedBox(height: 24),

              // Chapter Completion & Next Activity Transition
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.antiqueGold, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.inkDark.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (!state.isOnline) ...[
                      const Icon(
                        Icons.cloud_off_rounded,
                        color: Color(0xFFD35400),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Chapter Read (Offline)',
                        style: AppTypography.titleLarge.copyWith(color: isDark ? AppColors.darkAccentGold : Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You completed this passage offline. Progress is stored locally for reading, but no gems or streak flames were recorded.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      DuoButton(
                        text: 'Finish Offline Reading',
                        icon: Icons.check_circle_outline_rounded,
                        variant: DuoButtonVariant.outline,
                        onPressed: () {
                          state.clearReadingOffset(widget.literature.id, widget.chapterIndex);
                          state.clearReadingOffset(widget.literature.id, widget.chapterIndex);
                          state.completeQuestLevel(
                            literatureId: widget.literature.id,
                            levelId: widget.levelId,
                            isPerfectScore: false,
                          );
                          Navigator.pop(context);
                          GuideDialog.show(
                            context: context,
                            title: 'Reading by Candlelight',
                            message:
                                'Thou hast finished Chapter ${chapter.chapterNumber} in offline peace! Connect to the realm later to record gems and ignite streak flames.',
                            primaryButtonText: 'Understood, Sir Knight',
                            onPrimaryPressed: () {},
                            mood: QuixoteMood.inquiring,
                          );
                        },
                      ),
                    ] else ...[
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Chapter Complete!',
                        style: AppTypography.titleLarge.copyWith(color: isDark ? AppColors.darkAccentGold : Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.shouldShowDailyStreakCelebration()
                            ? 'You have absorbed the knowledge of this passage and earned 25 Gems + kept your reading campfire blazing!'
                            : 'You have absorbed the knowledge of this passage and earned 25 Gems!',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      DuoButton(
                        text: state.shouldShowDailyStreakCelebration()
                            ? 'Claim Reward & Ignite Flame'
                            : 'Claim Reward & Complete Chapter',
                        icon: state.shouldShowDailyStreakCelebration()
                            ? Icons.local_fire_department_rounded
                            : Icons.check_circle_rounded,
                        variant: DuoButtonVariant.gold,
                        onPressed: () {
                          final shouldCelebrate = state.isOnline && state.shouldShowDailyStreakCelebration();
                          if (shouldCelebrate) {
                            state.markDailyStreakCelebrated();
                          }

                          state.clearReadingOffset(widget.literature.id, widget.chapterIndex);
                          state.completeQuestLevel(
                            literatureId: widget.literature.id,
                            levelId: widget.levelId,
                            isPerfectScore: false,
                          );

                          final currentLvl = widget.literature.questLevels.firstWhere(
                            (l) => l.id == widget.levelId,
                            orElse: () => widget.literature.questLevels.first,
                          );

                          // Daily streak celebration appears only ONCE per day on the first completed activity
                          if (shouldCelebrate) {
                            StreakCelebrationDialog.show(
                              context: context,
                              streakDays: state.profile.streakDays,
                              isRekindled: state.profile.streakDays == 1,
                              gemsEarned: currentLvl.gemsReward,
                              levelTitle: currentLvl.title,
                              onContinue: () {
                                Navigator.pop(context);
                                RewardCelebrationOverlay.instance?.launchFlight(
                                  gems: currentLvl.gemsReward,
                                );
                              },
                            );
                          } else {
                            Navigator.pop(context);
                            // Satisfying rewarding animation with flying gems to top counter
                            RewardCelebrationOverlay.instance?.launchFlight(
                              gems: currentLvl.gemsReward,
                            );
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildInteractiveBodyText(String text, double fontSize, bool isDyslexic, bool isDark) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    // Sanitize typographical spacing: normalize linebreaks, single spaces,
    // and ensure punctuation has trailing space so words never stick together.
    var clean = text.replaceAll('\r\n', '\n');
    clean = clean.replaceAll(RegExp(r'[ \t]+'), ' ');
    clean = clean.replaceAllMapped(RegExp(r'([a-z\.\,\?\!\;])([A-Z])'), (m) => '${m[1]} ${m[2]}');
    final trimmed = clean.trim();

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final readingStyle = AppTypography.getReadingBodyStyle(
      isDyslexic: isDyslexic,
      fontSize: fontSize,
      color: isDark ? const Color(0xFFF0F0F0) : AppColors.inkDark,
    );

    // Split text into distinct paragraphs
    final paragraphs = trimmed.split(RegExp(r'\n\s*\n'));
    final paragraphWidgets = <Widget>[];

    for (int pIdx = 0; pIdx < paragraphs.length; pIdx++) {
      final pText = paragraphs[pIdx].trim();
      if (pText.isEmpty) continue;

      final spans = <InlineSpan>[];

      if (pIdx == 0 && pText.isNotEmpty) {
        // Drop Cap on the first paragraph
        final firstChar = pText[0];
        final remaining = pText.length > 1 ? pText.substring(1).trimLeft() : '';

        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: Container(
              margin: const EdgeInsets.only(right: 10, top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                firstChar,
                style: (isDyslexic ? GoogleFonts.lexend : GoogleFonts.lora)(
                  fontSize: fontSize * 2.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
          ),
        );

        _appendSpansForParagraph(remaining, spans, readingStyle, primary);
      } else {
        _appendSpansForParagraph(pText, spans, readingStyle, primary);
      }

      paragraphWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onLongPress: () {
                HapticFeedback.mediumImpact();
                SocraticCounselSheet.show(
                  context,
                  passage: pText,
                  bookTitle: widget.literature.title,
                  chapterTitle: chapter.title,
                  literatureId: widget.literature.id,
                );
              },
              child: RichText(
                textAlign: TextAlign.start,
                text: TextSpan(
                  style: readingStyle,
                  children: spans,
                ),
              ),
            ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: paragraphWidgets,
    );
  }

  void _appendSpansForParagraph(
    String pText,
    List<InlineSpan> spans,
    TextStyle readingStyle,
    Color primary,
  ) {
    if (pText.isEmpty) return;

    // Tokenize by word-runs and trailing whitespace to guarantee spacing is never dropped
    final tokenRegex = RegExp(r'(\S+)(\s*)');
    final matches = tokenRegex.allMatches(pText).toList();

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final token = match.group(1)!;
      final whitespace = match.group(2) ?? '';

      // Strip punctuation to check glossary
      final cleanWord = token.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
      final isVocab = _vocabularyGlossary.containsKey(cleanWord);

      if (isVocab) {
        spans.add(
          TextSpan(
            text: token,
            style: readingStyle.copyWith(
              color: primary,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dashed,
              decorationColor: primary,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _showWordDefinition(cleanWord),
          ),
        );
      } else {
        spans.add(TextSpan(text: token, style: readingStyle));
      }

      // Preserve spaces or add a separating space between words
      if (whitespace.isNotEmpty) {
        spans.add(TextSpan(text: whitespace, style: readingStyle));
      } else if (i < matches.length - 1) {
        spans.add(TextSpan(text: ' ', style: readingStyle));
      }
    }
  }
}
