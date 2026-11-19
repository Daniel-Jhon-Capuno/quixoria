import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';
import '../../models/reading_note.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/quixote_avatar.dart';

/// Socratic reading companion sheet powered by Google Gemini (gemini-3.8-flash)
/// and studio neural voice narration.
class SocraticCounselSheet extends StatefulWidget {
  final String passage;
  final String bookTitle;
  final String chapterTitle;
  final String literatureId;

  const SocraticCounselSheet({
    super.key,
    required this.passage,
    required this.bookTitle,
    required this.chapterTitle,
    required this.literatureId,
  });

  static Future<void> show(
    BuildContext context, {
    required String passage,
    required String bookTitle,
    required String chapterTitle,
    required String literatureId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SocraticCounselSheet(
        passage: passage,
        bookTitle: bookTitle,
        chapterTitle: chapterTitle,
        literatureId: literatureId,
      ),
    );
  }

  @override
  State<SocraticCounselSheet> createState() => _SocraticCounselSheetState();
}

class _SocraticCounselSheetState extends State<SocraticCounselSheet> {
  final TextEditingController _queryController = TextEditingController();
  bool _isLoading = false;
  GeminiCounselResult? _counsel;
  QuixoteMood _mood = QuixoteMood.inquiring;
  bool _savedToNotes = false;
  String? _selectedQuery = 'What does this mean?';
  String? _activeQuestion;
  int _requestId = 0;
  ScrollController? _activeScrollController;

  final List<({String label, String query})> _quickPrompts = const [
    (label: '💡 What does this mean?', query: 'What does this mean?'),
    (label: '🔍 Explain tricky words', query: 'Explain tricky words'),
    (label: '⚔️ What would Don Quixote do?', query: 'What would Don Quixote do?'),
    (label: '📖 Tell me what happens next!', query: 'Tell me what happens next'),
  ];

  @override
  void initState() {
    super.initState();
    _queryController.text = 'What does this mean?';
    _fetchCounsel('What does this mean?');
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _scrollToAnswer(ScrollController? scrollController) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = scrollController ?? _activeScrollController;
      if (ctrl != null && ctrl.hasClients) {
        ctrl.animateTo(
          ctrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _fetchCounsel([String? customQuery, ScrollController? scrollController]) async {
    final state = Provider.of<AppState>(context, listen: false);
    final thisRequestId = ++_requestId;

    final query = customQuery ?? _queryController.text.trim();

    setState(() {
      _isLoading = true;
      _savedToNotes = false;
      _mood = QuixoteMood.inquiring;
      if (customQuery != null) {
        _selectedQuery = customQuery;
      }
    });

    final result = await GeminiService.instance.consultDonQuixote(
      passage: widget.passage,
      bookTitle: widget.bookTitle,
      userQuestion: query.isNotEmpty ? query : null,
      apiKey: state.geminiApiKey,
      isOnline: state.isOnline,
    );

    if (mounted && thisRequestId == _requestId) {
      setState(() {
        _isLoading = false;
        _counsel = result;
        _activeQuestion = query.isNotEmpty ? query : 'What does this mean?';
        _mood = result.isAiPowered ? QuixoteMood.triumphant : QuixoteMood.proud;
      });
      SoundService.instance.play(Sfx.guide);
      _scrollToAnswer(scrollController);
    }
  }

  void _saveCounselToNotes() {
    if (_counsel == null || _savedToNotes) return;
    final state = Provider.of<AppState>(context, listen: false);

    state.addNote(
      literatureId: widget.literatureId,
      literatureTitle: widget.bookTitle,
      chapterTitle: widget.chapterTitle,
      type: NoteType.reflection,
      title: 'Don Quixote’s Advice',
      content: '“${widget.passage}”\n\nDon Quixote: ${_counsel!.text}',
    );

    setState(() => _savedToNotes = true);
    SoundService.instance.play(Sfx.reward);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.bookmark_added_rounded, color: AppColors.antiqueGold, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Don Quixote’s advice saved to thy Notes!',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1E26) : AppColors.parchmentWarm;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        _activeScrollController = scrollController;
        return Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
            border: Border.all(
              color: AppColors.antiqueGold.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              // Top drag notch
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    QuixoteAvatar(size: 38, mood: _mood),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ask Don Quixote',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Thy Knightly Reading Friend • ${widget.bookTitle}',
                            style: AppTypography.bodySmall.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Excerpt Container
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF16161D) : AppColors.parchmentCream,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.format_quote_rounded,
                                size: 16,
                                color: AppColors.antiqueGold,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Story Passage',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.antiqueGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '“${widget.passage}”',
                            style: AppTypography.bodySmall.copyWith(
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick prompt chips
                    Text(
                      'Ask Sir Quixote:',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickPrompts.map((item) {
                        final isSelected = _selectedQuery == item.query;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticService.instance.light();
                              SoundService.instance.play(Sfx.tap);
                              setState(() {
                                _selectedQuery = item.query;
                                _queryController.text = item.query;
                              });
                              _fetchCounsel(item.query, scrollController);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.antiqueGold.withValues(alpha: isDark ? 0.22 : 0.16)
                                    : (isDark ? const Color(0xFF262633) : AppColors.parchmentDark.withValues(alpha: 0.35)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.antiqueGold
                                      : (isDark ? Colors.white24 : AppColors.antiqueGold.withValues(alpha: 0.28)),
                                  width: isSelected ? 1.8 : 1.1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.antiqueGold.withValues(alpha: 0.35),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.antiqueGold
                                          : theme.colorScheme.onSurface.withValues(alpha: 0.9),
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.antiqueGold),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Quixote Response Card (Placed directly under chips for immediate visibility!)
                    if (_isLoading) ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF171720) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.antiqueGold.withValues(alpha: 0.3),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(color: AppColors.antiqueGold),
                            const SizedBox(height: 12),
                            Text(
                              'Don Quixote is pondering thy question...',
                              style: AppTypography.bodySmall.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else if (_counsel != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF171720) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.antiqueGold.withValues(alpha: 0.4),
                            width: 1.3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.antiqueGold.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.antiqueGold.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.shield_rounded,
                                        size: 14,
                                        color: AppColors.antiqueGold,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        "Sir Quixote's Advice",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.antiqueGold : const Color(0xFF7A5400),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _counsel!.isAiPowered ? '✨ Gemini Socratic' : 'Knightly Wisdom',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10.5,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                            if (_activeQuestion != null && _activeQuestion!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: theme.dividerColor.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.antiqueGold.withValues(alpha: 0.25), width: 1.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.help_outline_rounded, size: 13, color: AppColors.antiqueGold),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Question: "$_activeQuestion"',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Text(
                              _counsel!.text,
                              style: AppTypography.bodyMedium.copyWith(
                                height: 1.55,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DuoButton(
                              text: _savedToNotes ? 'Inscribed in Thy Notes ✓' : 'Save Advice to Notes',
                              icon: _savedToNotes ? Icons.check_circle_rounded : Icons.bookmark_add_rounded,
                              variant: _savedToNotes ? DuoButtonVariant.outline : DuoButtonVariant.gold,
                              height: 42,
                              onPressed: _savedToNotes ? null : _saveCounselToNotes,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Custom Question Input (Follow-up input below the card)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _queryController,
                            style: AppTypography.bodySmall,
                            decoration: InputDecoration(
                              hintText: 'Ask Don Quixote any question about this part...',
                              hintStyle: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF16161D) : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.antiqueGold, width: 1.5),
                              ),
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                HapticService.instance.light();
                                SoundService.instance.play(Sfx.tap);
                                setState(() => _selectedQuery = null);
                                _fetchCounsel(val.trim(), scrollController);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.antiqueGold,
                            foregroundColor: isDark ? const Color(0xFF121212) : Colors.white,
                          ),
                          onPressed: () {
                            final text = _queryController.text.trim();
                            if (text.isNotEmpty) {
                              HapticService.instance.light();
                              SoundService.instance.play(Sfx.tap);
                              setState(() => _selectedQuery = null);
                              _fetchCounsel(text, scrollController);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
