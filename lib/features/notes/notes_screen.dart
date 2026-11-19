import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';
import '../../models/literature.dart';
import '../../models/reading_note.dart';
import '../../models/vocab_card.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/hinge_swing_dialog.dart';
import '../../shared/widgets/literature_cover.dart';
import '../../shared/routes/quixoria_page_route.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  NoteType? _selectedFilterType;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedVocabIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final dueCount = state.dueVocabCards.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Reading Notebook',
          style: AppTypography.displaySmall.copyWith(
            color: theme.colorScheme.primary,
            fontSize: 24,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
            ),
            child: TabBar(
              controller: _tabController,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              labelColor: theme.colorScheme.onPrimary,
              unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              labelStyle: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, fontSize: 12.0),
              tabs: [
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Word Bank'),
                        if (dueCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.antiqueGold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$dueCount',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.inkDark,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('By Book'),
                  ),
                ),
                const Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('All Notes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Add Note'),
        onPressed: () => _showNoteComposer(context, state),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Spaced-Repetition Word Bank
          _buildWordBankView(context, state, theme),

          // 2. My Literature Notebooks View
          _buildMyLiteratureView(context, state, theme),

          // 3. All Notes Search & Filter View
          _buildAllNotesView(context, state),
        ],
      ),
    );
  }

  // --- WORD BANK (SPACED REPETITION) TAB ---
  Widget _buildWordBankView(BuildContext context, AppState state, ThemeData theme) {
    final deck = state.vocabDeck;
    final dueCards = state.dueVocabCards;
    final masteredCount = deck.where((c) => c.isMastered).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        // Spaced-Repetition Summary Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.antiqueGold.withValues(alpha: 0.65), width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.antiqueGold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.style_rounded, color: AppColors.antiqueGold, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spaced-Repetition Lexicon',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dueCards.isEmpty
                              ? 'All words reviewed for today! Practice anytime to reinforce.'
                              : '${dueCards.length} literary ${dueCards.length == 1 ? 'word is' : 'words are'} due for review today (+5 gems each).',
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildLexiconMiniStat(theme, 'Total Words', '${deck.length}', Icons.menu_book_rounded),
                  const SizedBox(width: 10),
                  _buildLexiconMiniStat(theme, 'Due Today', '${dueCards.length}', Icons.schedule_rounded),
                  const SizedBox(width: 10),
                  _buildLexiconMiniStat(theme, 'Mastered', '$masteredCount', Icons.workspace_premium_rounded),
                ],
              ),
              const SizedBox(height: 14),
              DuoButton(
                text: dueCards.isNotEmpty
                    ? 'Practice ${dueCards.length} Due Words'
                    : 'Practice All Words (${deck.length})',
                icon: Icons.bolt_rounded,
                variant: dueCards.isNotEmpty ? DuoButtonVariant.gold : DuoButtonVariant.primary,
                onPressed: deck.isEmpty
                    ? null
                    : () => _openFlashcardReviewSheet(
                          context,
                          dueCards.isNotEmpty ? dueCards : deck,
                        ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Vocabulary Cards (${deck.length})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Word'),
              onPressed: () => _showAddVocabDialog(context, state, theme),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (deck.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45)),
            ),
            child: Column(
              children: [
                const Icon(Icons.menu_book_rounded, size: 44, color: AppColors.antiqueGold),
                const SizedBox(height: 12),
                Text(
                  'Your Word Bank is Empty',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap any highlighted vocabulary word while reading a chapter or tap "Add Word" above to save words to your personal lexicon.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        else
          for (final card in deck) ...[
            _buildVocabCardTile(context, card, theme),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _buildLexiconMiniStat(ThemeData theme, String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.antiqueGold),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVocabCardTile(BuildContext context, VocabCard card, ThemeData theme) {
    final isDue = card.isDue();
    final isExpanded = _expandedVocabIds.contains(card.key);
    final state = context.read<AppState>();
    final isDark = theme.brightness == Brightness.dark;
    final Color strengthColor = card.box >= 4
        ? state.activeThemePreset.successColor
        : (card.box >= 2 ? AppColors.antiqueGold : AppColors.streakOrange);

    return InkWell(
      onTap: () {
        HapticService.instance.selection();
        SoundService.instance.play(Sfx.tap);
        setState(() {
          if (isExpanded) {
            _expandedVocabIds.remove(card.key);
          } else {
            _expandedVocabIds.add(card.key);
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded
                ? AppColors.antiqueGold
                : (isDue
                    ? AppColors.antiqueGold.withValues(alpha: 0.65)
                    : theme.dividerColor.withValues(alpha: 0.35)),
            width: isExpanded ? 1.5 : 1.1,
          ),
          boxShadow: isExpanded
              ? [
                  BoxShadow(
                    color: AppColors.antiqueGold.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Primary Header: Word + Book Context + Due Badges + Chevron
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.word,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isExpanded ? AppColors.antiqueGold : theme.colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 13,
                            color: isDark ? AppColors.antiqueGold : const Color(0xFF8D6E63),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              card.literatureTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? AppColors.antiqueGold.withValues(alpha: 0.85)
                                    : const Color(0xFF6D4C41),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Due Status Pill
                if (isDue)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.antiqueGold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'DUE NOW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.antiqueGold,
                      ),
                    ),
                  ),

                // Box Strength Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: strengthColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Box ${card.box}/${VocabCard.masteredBox} • ${card.strengthLabel}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: strengthColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Animated Chevron
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),

            // If Minimized: Show subtle single-line preview
            if (!isExpanded) ...[
              const SizedBox(height: 8),
              Text(
                card.definition,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
            ],

            // If Expanded: Full Rich Hierarchy & Story Context
            if (isExpanded) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // 1. Definition Section
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, size: 14, color: AppColors.antiqueGold),
                  const SizedBox(width: 6),
                  Text(
                    'MEANING & DEFINITION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.antiqueGold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                card.definition,
                style: AppTypography.bodyMedium.copyWith(
                  height: 1.45,
                  fontSize: 13,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // 2. Story Context Quote Box
              if (card.example.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161620) : AppColors.parchmentCream,
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: const BorderSide(color: AppColors.antiqueGold, width: 3.5),
                      top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                      right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                      bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.format_quote_rounded, size: 14, color: AppColors.antiqueGold),
                          const SizedBox(width: 4),
                          Text(
                            'ORIGINAL BOOK PASSAGE:',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.antiqueGold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '“${card.example}”',
                        style: AppTypography.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '— ${card.literatureTitle}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 3. Spaced-Repetition Mastery Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Memory Retention: ${(card.mastery * 100).toInt()}%',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: strengthColor),
                  ),
                  Text(
                    'Recalled: ${card.timesCorrect} • Missed: ${card.timesWrong}',
                    style: TextStyle(fontSize: 10.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: card.mastery,
                  minHeight: 5,
                  backgroundColor: theme.dividerColor.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Quick Practice Actions
              Row(
                children: [
                  // Practice single word
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      side: BorderSide(color: AppColors.antiqueGold.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.flash_on_rounded, size: 15, color: AppColors.antiqueGold),
                    label: const Text('Review Flashcard', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      _openFlashcardReviewSheet(context, [card]);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openFlashcardReviewSheet(BuildContext context, List<VocabCard> cardsToReview) {
    final sessionCards = List<VocabCard>.from(cardsToReview);
    int currentIdx = 0;
    bool isRevealed = false;
    int sessionCorrect = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final theme = Theme.of(modalCtx);
            final state = modalCtx.read<AppState>();
            final done = currentIdx >= sessionCards.length;

            if (done) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 34),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.workspace_premium_rounded, size: 64, color: AppColors.antiqueGold),
                    const SizedBox(height: 12),
                    Text(
                      'Lexicon Session Complete!',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You recalled $sessionCorrect of ${sessionCards.length} words and earned +${sessionCorrect * 5} gems.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 22),
                    DuoButton(
                      text: 'Done',
                      variant: DuoButtonVariant.gold,
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
              );
            }

            final card = sessionCards[currentIdx];

            return Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CARD ${currentIdx + 1} OF ${sessionCards.length}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.antiqueGold,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      SoundService.instance.play(Sfx.tap);
                      setModalState(() => isRevealed = !isRevealed);
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 220),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color ?? theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.antiqueGold, width: 1.6),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            card.literatureTitle.toUpperCase(),
                            style: AppTypography.labelSmall.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                              letterSpacing: 0.9,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            card.word,
                            textAlign: TextAlign.center,
                            style: AppTypography.displaySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (!isRevealed)
                            Text(
                              'Tap card to reveal definition & context',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.antiqueGold,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else ...[
                            const Divider(),
                            const SizedBox(height: 10),
                            Text(
                              card.definition,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyLarge.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (card.example.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                '“${card.example}”',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (!isRevealed)
                    DuoButton(
                      text: 'Reveal Definition',
                      variant: DuoButtonVariant.primary,
                      onPressed: () {
                        SoundService.instance.play(Sfx.tap);
                        setModalState(() => isRevealed = true);
                      },
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: DuoButton(
                            text: 'Missed It',
                            variant: DuoButtonVariant.vermillion,
                            onPressed: () {
                              state.reviewVocabCard(card.key, false, literatureId: card.literatureId);
                              setModalState(() {
                                currentIdx++;
                                isRevealed = false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DuoButton(
                            text: card.isDue(DateTime.now()) ? 'Knew It (+5 Gems)' : 'Knew It (Practice)',
                            variant: DuoButtonVariant.primary,
                            onPressed: () {
                              sessionCorrect++;
                              state.reviewVocabCard(card.key, true, literatureId: card.literatureId);
                              setModalState(() {
                                currentIdx++;
                                isRevealed = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddVocabDialog(BuildContext context, AppState state, ThemeData theme) {
    final wordCtrl = TextEditingController();
    final defCtrl = TextEditingController();
    final exCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        title: Text('Add Word to Lexicon', style: AppTypography.titleLarge.copyWith(color: theme.colorScheme.primary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: wordCtrl,
                decoration: const InputDecoration(labelText: 'Word', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: defCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Definition', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: exCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Example sentence (optional)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (wordCtrl.text.trim().isEmpty || defCtrl.text.trim().isEmpty) return;
              state.addOrUpdateVocabCard(
                word: wordCtrl.text.trim(),
                definition: defCtrl.text.trim(),
                example: exCtrl.text.trim(),
                literatureId: state.activeLiterature.id,
                literatureTitle: state.activeLiterature.title,
              );
              Navigator.pop(ctx);
            },
            child: const Text('Add Word'),
          ),
        ],
      ),
    );
  }

  // --- MY LITERATURE TAB ---
  Widget _buildMyLiteratureView(BuildContext context, AppState state, ThemeData theme) {
    final ownedList = state.ownedLiterature;

    if (ownedList.isEmpty) {
      return const Center(child: Text('No owned literature in thy library yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: ownedList.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 14),
      itemBuilder: (ctx, index) {
        final work = ownedList[index];
        final workNotes = state.getNotesForLiterature(work.id);
        final latestNote = workNotes.isNotEmpty ? workNotes.first : null;

        return Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45), width: 1.2),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LiteratureCover(
                literature: work,
                width: 70,
                height: 100,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      work.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      work.author,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.notes_rounded, size: 14, color: AppColors.antiqueGold),
                        const SizedBox(width: 4),
                        Text(
                          '${workNotes.length} notes recorded',
                          style: AppTypography.labelSmall.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (latestNote != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Recent: "${latestNote.title}"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        icon: const Icon(Icons.auto_stories_outlined, size: 16),
                        label: const Text('Open Notebook', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => _openDedicatedNotebook(context, state, work),
                      ),
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

  // --- DEDICATED NOTEBOOK FOR A WORK ---
  void _openDedicatedNotebook(BuildContext context, AppState state, Literature work) {
    Navigator.push(
      context,
      QuixoriaPageRoute(
        builder: (ctx) => _DedicatedNotebookScreen(work: work),
      ),
    );
  }

  // --- ALL NOTES TAB ---
  Widget _buildAllNotesView(BuildContext context, AppState state) {
    final theme = Theme.of(context);
    List<ReadingNote> filtered = state.notes;

    if (_selectedFilterType != null) {
      filtered = filtered.where((n) => n.type == _selectedFilterType).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((n) {
        return n.title.toLowerCase().contains(q) ||
            n.content.toLowerCase().contains(q) ||
            n.literatureTitle.toLowerCase().contains(q);
      }).toList();
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search reflections, quotes, vocabulary...',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.cardTheme.color ?? theme.colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.45)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.45)),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
        ),

        // Filter chips: Reflection, Quote, Question, Vocabulary
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedFilterType == null,
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: _selectedFilterType == null ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                  fontSize: 12,
                ),
                onSelected: (sel) => setState(() => _selectedFilterType = null),
              ),
              const SizedBox(width: 8),
              for (final type in NoteType.values) ...[
                FilterChip(
                  label: Text(type.label),
                  selected: _selectedFilterType == type,
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: _selectedFilterType == type ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                    fontSize: 12,
                  ),
                  onSelected: (sel) => setState(() {
                    _selectedFilterType = sel ? type : null;
                  }),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),

        // List of notes
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_rounded, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
                      const SizedBox(height: 12),
                      Text('No matching notes found', style: AppTypography.titleMedium.copyWith(color: theme.colorScheme.onSurface)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemBuilder: (ctx, index) {
                    final note = filtered[index];
                    return _buildNoteCard(context, state, note);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(BuildContext context, AppState state, ReadingNote note) {
    final theme = Theme.of(context);
    Color badgeColor;
    switch (note.type) {
      case NoteType.reflection:
        badgeColor = theme.colorScheme.primary;
        break;
      case NoteType.quote:
        badgeColor = AppColors.antiqueGold;
        break;
      case NoteType.question:
        badgeColor = AppColors.vermillion;
        break;
      case NoteType.vocabulary:
        badgeColor = theme.colorScheme.primary;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45), width: 1.2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  note.type.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    onPressed: () => _showEditNoteModal(context, state, note),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.energyRed),
                    onPressed: () {
                      HingeSwingDeleteDialog.show(
                        context: context,
                        noteTitle: note.title,
                        onConfirm: () {
                          final deletedNote = note;
                          state.deleteNote(deletedNote.id);
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Note "${deletedNote.title}" removed.'),
                              action: SnackBarAction(
                                label: 'UNDO',
                                textColor: AppColors.antiqueGold,
                                onPressed: () => state.restoreNote(deletedNote),
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        },
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note.title,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            note.content,
            style: AppTypography.bodyMedium.copyWith(
              height: 1.45,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${note.literatureTitle} • ${note.chapterTitle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ),
              Text(
                '${note.createdAt.month}/${note.createdAt.day}',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNoteComposer(BuildContext context, AppState state, [String? preselectedLitId]) {
    final theme = Theme.of(context);
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    NoteType selectedType = NoteType.reflection;
    String selectedLitId = preselectedLitId ?? state.ownedLiterature.first.id;
    String chapterContext = 'Chapter 1: Reading Context';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final owned = state.ownedLiterature;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Record a Literary Note',
                      style: AppTypography.titleLarge.copyWith(color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 16),

                    // Literature Selector Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedLitId,
                      decoration: InputDecoration(
                        labelText: 'Source Work',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      items: owned.map((lit) {
                        return DropdownMenuItem(
                          value: lit.id,
                          child: Text(lit.title, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedLitId = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Note Type Chips
                    Text('Note Classification', style: AppTypography.labelSmall),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: NoteType.values.map((t) {
                        final isSel = selectedType == t;
                        return ChoiceChip(
                          label: Text(t.label),
                          selected: isSel,
                          selectedColor: theme.colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSel ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => selectedType = t);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: selectedType == NoteType.vocabulary ? 'Vocabulary Word' : 'Note Title / Headline',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Content
                    TextField(
                      controller: contentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: selectedType == NoteType.vocabulary ? 'Definition & Context' : 'Thoughts, Quotes, or Insights',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          if (titleController.text.trim().isEmpty ||
                              contentController.text.trim().isEmpty) {
                            return;
                          }
                          final lit = owned.firstWhere((l) => l.id == selectedLitId);
                          state.addNote(
                            literatureId: lit.id,
                            literatureTitle: lit.title,
                            chapterTitle: chapterContext,
                            type: selectedType,
                            title: titleController.text.trim(),
                            content: contentController.text.trim(),
                          );
                          Navigator.pop(modalCtx);
                        },
                        child: const Text('Save Note to Grimoire'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditNoteModal(BuildContext context, AppState state, ReadingNote note) {
    final theme = Theme.of(context);
    final titleController = TextEditingController(text: note.title);
    final contentController = TextEditingController(text: note.content);
    NoteType selectedType = note.type;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit Note', style: AppTypography.titleLarge.copyWith(color: theme.colorScheme.primary)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          state.updateNote(
                            note.id,
                            titleController.text.trim(),
                            contentController.text.trim(),
                            selectedType,
                          );
                          Navigator.pop(modalCtx);
                        },
                        child: const Text('Update Note'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Dedicated notebook viewer for a specific literature item
class _DedicatedNotebookScreen extends StatelessWidget {
  final Literature work;

  const _DedicatedNotebookScreen({required this.work});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final notes = state.getNotesForLiterature(work.id);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${work.title} Notebook',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notebook Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45), width: 1.2),
                ),
                child: Row(
                  children: [
                    LiteratureCover(literature: work, width: 75, height: 110),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            work.title,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'By ${work.author}',
                            style: AppTypography.bodySmall.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${notes.length} total entries saved',
                            style: AppTypography.labelSmall.copyWith(color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text('Saved Notes & Passages', style: AppTypography.titleLarge.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(height: 12),

              if (notes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.menu_book_outlined, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
                      const SizedBox(height: 12),
                      Text('No notes for this work yet.', style: AppTypography.bodyMedium.copyWith(color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 8),
                      Text(
                        'Highlight quotes while reading or tap "Add Note" below to capture reflections!',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                )
              else
                for (final n in notes) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              n.type.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              n.chapterTitle,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(n.title, style: AppTypography.titleSmall.copyWith(color: theme.colorScheme.onSurface)),
                        const SizedBox(height: 4),
                        Text(n.content, style: AppTypography.bodyMedium.copyWith(color: theme.colorScheme.onSurface)),
                      ],
                    ),
                  ),
                ],

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Note to this Notebook'),
                  onPressed: () {
                    state.addNote(
                      literatureId: work.id,
                      literatureTitle: work.title,
                      chapterTitle: 'General Reflection',
                      type: NoteType.reflection,
                      title: 'Reflection on ${work.title}',
                      content: 'A poignant and adventurous literary exploration.',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Note added!')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
