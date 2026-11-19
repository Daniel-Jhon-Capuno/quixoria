import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/state/app_state.dart';
import '../../models/app_theme_preset.dart';
import '../../models/daily_quest.dart';
import '../../models/literature.dart';
import '../../models/quest_level.dart';
import '../../shared/widgets/currency_bar.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/live_leaderboard_sheet.dart';
import '../../shared/widgets/duo_level_preview_sheet.dart';
import '../../shared/widgets/guide_dialog.dart';
import '../../shared/widgets/loading_dialog.dart';
import '../../shared/widgets/literature_cover.dart';
import '../../shared/widgets/offline_warning_dialog.dart';
import '../../shared/widgets/quixote_avatar.dart';
import '../../shared/widgets/streak_lost_dialog.dart';
import '../../shared/widgets/themed_card.dart';
import '../../shared/widgets/winding_path_canvas.dart';
import '../../shared/routes/quixoria_page_route.dart';
import '../../shared/widgets/reward_celebration.dart';
import '../../core/services/learning_session_engine.dart';
import '../quiz/quiz_screen.dart';
import '../reader/reader_screen.dart';
import '../special_nodes/campfire_parley_screen.dart';
import '../special_nodes/lightning_duel_screen.dart';
import '../special_nodes/milestone_chest_dialog.dart';
import '../special_nodes/quote_shrine_screen.dart';
import '../special_nodes/word_match_blitz_screen.dart';
import '../special_nodes/zone_gatekeeper_screen.dart';

class QuestScreen extends StatelessWidget {
  final VoidCallback? onSwitchToShop;
  final VoidCallback? onGemsTap;

  const QuestScreen({
    super.key,
    this.onSwitchToShop,
    this.onGemsTap,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final activeWork = state.activeLiterature;
    final theme = Theme.of(context);

    // Check if player lost their streak (e.g. 12:00 AM midnight passed)
    if (state.hasLostStreakPending) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (state.hasLostStreakPending && context.mounted) {
          state.clearLostStreakPending();
          StreakLostDialog.show(
            context: context,
            previousStreak: state.previousStreak,
            onRekindle: () => state.rekindleStreak(),
            onRestore: () => state.restoreStreakWithGems(),
            onDismiss: () {},
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Currency Top Bar
            CurrencyBar(
              onGemsTap: onGemsTap ?? onSwitchToShop,
              onKeysTap: onSwitchToShop,
            ),

            // Scrollable Quest Path & Header
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // 1-Tap Continue Reading Hero Shortcut
                    _buildContinueReadingHero(context, activeWork, state),

                    // Duolingo-style Sticky Section & Progress Indicator
                    _buildDuolingoSectionHeader(context, activeWork, state),

                    // Daily Quests & Weekly League Quick Strip
                    _buildQuestsAndLeagueStrip(context, state),

                    // Active Literary Header Card (Minimalist summary with tap for details)
                    _buildActiveBookCard(context, activeWork, state),

                    const SizedBox(height: 12),

                    // Winding Path Canvas (With Don Quixote standing at the Active Mission Node!)
                    WindingPathView(
                      levels: activeWork.questLevels,
                      onLevelTap: (level) => _handleLevelTap(context, state, activeWork, level),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueReadingHero(BuildContext context, Literature work, AppState state) {
    if (work.questLevels.isEmpty) return const SizedBox.shrink();
    final activeLevel = work.questLevels.firstWhere(
      (l) => !l.isCompleted && !l.isLocked,
      orElse: () => work.questLevels.last,
    );
    final chapterIdx = activeLevel.chapterIndex.clamp(
      0,
      work.chapters.isNotEmpty ? work.chapters.length - 1 : 0,
    );
    final chapterTitle = work.chapters.isNotEmpty
        ? work.chapters[chapterIdx].title
        : activeLevel.title;
    final completedCount = work.questLevels.where((l) => l.isCompleted).length;
    final totalCount = work.questLevels.length;
    final pct = totalCount > 0 ? ((completedCount / totalCount) * 100).round() : 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF232833), const Color(0xFF171A22)]
              : [Colors.white, const Color(0xFFF6F1E6)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            offset: const Offset(0, 3.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONTINUE READING • $pct%',
                  style: AppTypography.labelSmall.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  chapterTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  work.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 108,
            child: DuoButton(
              key: const Key('quest_continue_reading_btn'),
              text: 'Read Now',
              variant: DuoButtonVariant.gold,
              height: 40,
              onPressed: () {
                HapticService.instance.light();
                SoundService.instance.play(Sfx.tap);
                Navigator.of(context).push(
                  QuixoriaPageRoute(
                    builder: (_) => ReaderScreen(
                      literature: work,
                      chapterIndex: chapterIdx,
                      levelId: activeLevel.id,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuolingoSectionHeader(BuildContext context, Literature work, AppState state) {
    final theme = Theme.of(context);
    final activeLevelIndex = work.questLevels.indexWhere((l) => !l.isCompleted && !l.isLocked);
    final activeLevel = activeLevelIndex != -1
        ? work.questLevels[activeLevelIndex]
        : (work.questLevels.isNotEmpty ? work.questLevels.last : null);
    final completedCount = work.questLevels.where((l) => l.isCompleted).length;
    final totalCount = work.questLevels.length;
    final progress = totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;
    final currentUnit = (activeLevel?.chapterIndex ?? 0) + 1;

    final isMedieval = state.activeThemePreset.interfaceStyle == ThemeInterfaceStyle.medieval;

    return ThemedCard(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      showBattlementHeader: isMedieval,
      battlementTitle: 'Citadel Quest • Unit $currentUnit',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Section Badge + Guidebook Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.antiqueGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map_rounded, size: 14, color: AppColors.antiqueGold),
                    const SizedBox(width: 5),
                    Text(
                      'SECTION 1 • UNIT $currentUnit',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.antiqueGold,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        fontSize: 10,
                      ),
                    ),
                    if (activeLevel != null && !activeLevel.isCompleted) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.vermillion,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '1 NEW',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              InkWell(
                onTap: () => _showGuidebookSheet(context, work, activeLevel),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_rounded, size: 13, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Guidebook',
                        style: AppTypography.labelSmall.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Current Objective Title
          Text(
            activeLevel != null ? activeLevel.title : 'All Chapter Milestones Achieved',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            activeLevel != null
                ? '${activeLevel.typeLabel} • ${activeLevel.description}'
                : 'Every node in this masterwork has been conquered.',
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),

          // Progress Bar with Percentage and Quick Resume Action
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: theme.dividerColor.withValues(alpha: 0.25),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.antiqueGold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedCount of $totalCount Steps Conquered (${(progress * 100).toInt()}%)',
                      style: AppTypography.labelSmall.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (activeLevel != null) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Resume'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.antiqueGold,
                    foregroundColor: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF121212)
                        : Theme.of(context).colorScheme.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                  onPressed: () => _handleLevelTap(context, state, work, activeLevel),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showGuidebookSheet(BuildContext context, Literature work, QuestLevel? activeLevel) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (sheetCtx, scrollCtrl) {
            return SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.antiqueGold.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: AppColors.antiqueGold, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unit Guidebook',
                              style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${work.title} • Study Notes & Vocabulary',
                              style: AppTypography.bodySmall.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Chivalric Lore Frontispiece Artwork
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      height: 130,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.antiqueGold.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/quixote_sancho_classic.jpg',
                            fit: BoxFit.cover,
                            alignment: const Alignment(0, -0.3),
                            errorBuilder: (ctx, err, stack) => Container(
                              color: const Color(0xFF2C1E14),
                              child: const Center(
                                child: Icon(Icons.auto_stories_rounded, color: AppColors.antiqueGold, size: 36),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.75),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            left: 14,
                            right: 14,
                            child: Text(
                              'The Expedition of La Mancha • Unit Lore & Lexicon',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 1: Overview
                  Text(
                    'Chapter Overview & Historical Setting',
                    style: AppTypography.titleSmall.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    work.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurface,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Section 2: Key Vocabulary Glossary
                  Text(
                    'Unit Key Vocabulary & Archaic Terms',
                    style: AppTypography.titleSmall.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._buildBookGlossaryTiles(work, theme),
                  const SizedBox(height: 18),

                  // Section 3: Literary Theme
                  Text(
                    'Key Literary Theme',
                    style: AppTypography.titleSmall.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.antiqueGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.antiqueGold.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '"Where you tend a rose, my lad, a thistle cannot grow."\n\nNature and literature act as catalysts for spiritual renewal, transforming isolation into purpose and love.',
                      style: AppTypography.bodySmall.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildBookGlossaryTiles(Literature work, ThemeData theme) {
    final title = work.title.toLowerCase();
    final Map<String, String> glossary;
    if (title.contains('prophet') || title.contains('gibran')) {
      glossary = {
        'Almustafa': 'The chosen prophet who waited twelve years in Orphalese.',
        'Orphalese': 'The coastal city where the prophet shared poetic wisdom.',
        'Almitra': 'The seeress who first questions Almustafa on love and life.',
        'Pilgrim': 'A seeker of spiritual truth and inner illumination.',
      };
    } else if (title.contains('quixote')) {
      glossary = {
        'Hidalgo': 'A Spanish nobleman or gentleman of honorable lineage.',
        'Rocinante': 'Don Quixote’s faithful, weary steed of adventure.',
        'Chivalry': 'The medieval code of knightly honor, valor, and courtly devotion.',
        'Buckler': 'A small, round shield used in chivalric jousting and duels.',
      };
    } else if (title.contains('secret garden')) {
      glossary = {
        'Ayah': 'A native Indian nursemaid or governess in colonial households.',
        'Yorkshire Moor': 'Vast, wild upland landscape overgrown with heather and gorse.',
        'Tyrannical': 'Ruling harshly with imperious demands for absolute obedience.',
        'Misselthwaite': 'The historic, hundred-room gothic manor of mysteries.',
      };
    } else if (title.contains('scarlet') || title.contains('holmes')) {
      glossary = {
        'Deduction': 'The disciplined science of drawing conclusions from subtle clues.',
        '221B Baker St': 'Famous London consulting quarters of Sherlock Holmes.',
        'Trichinopoly': 'A variety of cheroot cigar identified forensically.',
        'Forensics': 'Scientific observation applied to solving complex mysteries.',
      };
    } else if (title.contains('frankenstein')) {
      glossary = {
        'Galvanism': 'Electricity produced chemically, once thought to impart life.',
        'Ingolstadt': 'The Bavarian university town of Victor’s feverish experiments.',
        'Promethean': 'Daringly creative or defiant, challenging divine boundaries.',
        'Catastrophe': 'A sudden, disastrous culmination of unchecked hubris.',
      };
    } else {
      glossary = {
        work.author: 'Master creator and author of this classical narrative.',
        work.genres.isNotEmpty ? work.genres.first : 'Classic': 'Primary literary classification and style of this work.',
        'Subtext': 'The implicit philosophical meaning beneath the literal narrative.',
        'Cadence': 'The rhythmic, elevated flow of language and prose.',
      };
    }

    return glossary.entries
        .map((e) => _buildVocabTile(e.key, e.value, theme))
        .toList();
  }

  Widget _buildVocabTile(String word, String definition, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              word,
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              definition,
              style: AppTypography.bodySmall.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestsAndLeagueStrip(BuildContext context, AppState state) {
    final theme = Theme.of(context);
    final quests = state.dailyQuests;
    final claimableQuests = quests.where((q) => q.canClaim).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: Row(
        children: [
          // Daily Quests Minimal Pill
          Expanded(
            child: InkWell(
              onTap: () => _showDailyQuestsSheet(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: claimableQuests > 0
                        ? AppColors.antiqueGold
                        : theme.dividerColor.withValues(alpha: 0.45),
                    width: claimableQuests > 0 ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.antiqueGold.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.task_alt_rounded, size: 16, color: AppColors.antiqueGold),
                        ),
                        if (claimableQuests > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.vermillion,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Center(
                                child: Text(
                                  '$claimableQuests',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Quests',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.antiqueGold),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Weekly League Card with Red Live Badge Dot (no cramped LIVE pill)
          Expanded(
            child: InkWell(
              onTap: () => _showLeagueStandingsSheet(context),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.45),
                    width: 1.8,
                  ),
                ),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(Icons.emoji_events_rounded, size: 17, color: theme.colorScheme.primary),
                        ),
                        // Red badge dot ONLY shown when there is an unread leaderboard update
                        if (state.hasUnreadLeaderboardUpdate)
                          Positioned(
                            top: -3,
                            right: -3,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.vermillion,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.cardTheme.color ?? theme.colorScheme.surface,
                                  width: 1.6,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Leaderboard',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 18, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDailyQuestsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Consumer<AppState>(
              builder: (sheetCtx, state, _) {
                final theme = Theme.of(sheetCtx);
                final quests = state.dailyQuests;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.task_alt_rounded, color: AppColors.antiqueGold, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Chivalric Quests',
                              style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Refreshes every midnight (12:00 AM). Claim gems for each goal fulfilled.',
                              style: AppTypography.bodySmall.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final q in quests) ...[
                    _buildDailyQuestCard(sheetCtx, state, q, theme),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  },
);
}

  Widget _buildDailyQuestCard(BuildContext context, AppState state, DailyQuest q, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: q.canClaim ? AppColors.antiqueGold : theme.dividerColor.withValues(alpha: 0.45),
          width: q.canClaim ? 1.5 : 1.1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.antiqueGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(q.icon, color: AppColors.antiqueGold, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: q.fraction,
                    minHeight: 7,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.25),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      q.isComplete
                          ? (state.activeThemePreset.interfaceStyle == ThemeInterfaceStyle.snowy
                              ? const Color(0xFF00A8CC)
                              : (state.activeThemePreset.id == 'theme_cute_meadow'
                                  ? const Color(0xFFE91E63)
                                  : theme.colorScheme.primary))
                          : AppColors.antiqueGold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${q.progress} / ${q.target} • Reward: +${q.rewardGems} gems',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (q.claimed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (state.activeThemePreset.interfaceStyle == ThemeInterfaceStyle.snowy
                        ? const Color(0xFF00A8CC)
                        : (state.activeThemePreset.id == 'theme_cute_meadow'
                            ? const Color(0xFFE91E63)
                            : theme.colorScheme.primary))
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Claimed',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: (state.activeThemePreset.interfaceStyle == ThemeInterfaceStyle.snowy
                      ? const Color(0xFF00A8CC)
                      : (state.activeThemePreset.id == 'theme_cute_meadow'
                          ? const Color(0xFFE91E63)
                          : theme.colorScheme.primary)),
                ),
              ),
            )
          else if (q.canClaim)
            Builder(
              builder: (btnCtx) => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.antiqueGold,
                  foregroundColor: AppColors.inkDark,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final renderBox = btnCtx.findRenderObject() as RenderBox?;
                  final origin = renderBox != null && renderBox.hasSize
                      ? renderBox.localToGlobal(renderBox.size.center(Offset.zero))
                      : null;
                  state.claimDailyQuest(q.id);
                  RewardCelebrationOverlay.claimDailyQuest(
                    context,
                    origin: origin,
                    gems: q.rewardGems,
                  );
                },
                child: Text(
                  'Claim +${q.rewardGems}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showLeagueStandingsSheet(BuildContext context) {
    HapticService.instance.light();
    SoundService.instance.play(Sfx.tap);
    LiveLeaderboardSheet.show(context);
  }


  Widget _buildActiveBookCard(BuildContext context, Literature work, AppState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalCount = work.questLevels.length;
    final completedCount = work.questLevels.where((l) => l.isCompleted).length;
    final pct = totalCount > 0 ? ((completedCount / totalCount) * 100).toInt() : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: InkWell(
        onTap: () => _showExpeditionDetailsSheet(context, work, state),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.45),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              // Clean Classical Book Icon Badge (Zero font clipping)
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.antiqueGold.withValues(alpha: isDark ? 0.22 : 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.antiqueGold.withValues(alpha: 0.55),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 18,
                  color: AppColors.antiqueGold,
                ),
              ),
              const SizedBox(width: 10),

              // Title only
              Expanded(
                child: Text(
                  work.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Clean progress percentage label (no redundant pill box)
              Text(
                '$pct%',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.antiqueGold : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExpeditionDetailsSheet(BuildContext context, Literature work, AppState state) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'CURRENT EXPEDITION',
                              style: AppTypography.labelSmall.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            work.title,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            work.author,
                            style: AppTypography.bodySmall.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Level ${(work.currentLevelIndex + 1).clamp(1, work.questLevels.length)} of ${work.questLevels.length} Conquered',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: work.progressPercentage,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.antiqueGold),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  work.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: DuoButton(
                        text: 'Switch Book',
                        variant: DuoButtonVariant.outline,
                        height: 46,
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showBookSwitchSheet(context, state);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DuoButton(
                        text: 'Continue',
                        variant: DuoButtonVariant.primary,
                        height: 46,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBookSwitchSheet(BuildContext context, AppState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.82,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (_, scrollCtrl) {
                return ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, color: AppColors.antiqueGold, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'Switch Literary Expedition',
                          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose which classic masterpiece to explore along the chivalric quest map.',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final lit in state.literatureList) ...[
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          SoundService.instance.play(Sfx.tap);
                          state.setActiveLiterature(lit.id);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: lit.id == state.activeLiteratureId
                                ? AppColors.antiqueGold.withValues(alpha: isDark ? 0.18 : 0.12)
                                : theme.cardTheme.color ?? theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: lit.id == state.activeLiteratureId
                                  ? AppColors.antiqueGold
                                  : theme.dividerColor.withValues(alpha: 0.35),
                              width: lit.id == state.activeLiteratureId ? 1.8 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.antiqueGold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.antiqueGold.withValues(alpha: 0.4)),
                                ),
                                child: const Icon(Icons.auto_stories_rounded, size: 20, color: AppColors.antiqueGold),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lit.title,
                                      style: AppTypography.titleSmall.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: lit.id == state.activeLiteratureId
                                            ? AppColors.antiqueGold
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      lit.author,
                                      style: AppTypography.bodySmall.copyWith(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (lit.id == state.activeLiteratureId)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.antiqueGold,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.black : Colors.white,
                                    ),
                                  ),
                                )
                              else
                                const Icon(Icons.chevron_right_rounded, color: AppColors.antiqueGold, size: 22),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _handleLevelTap(
    BuildContext context,
    AppState state,
    Literature work,
    QuestLevel level,
  ) {
    DuoLevelPreviewSheet.show(
      context,
      literature: work,
      level: level,
      onStart: () => _launchLevel(context, state, work, level),
    );
  }

  void _launchLevel(
    BuildContext context,
    AppState state,
    Literature work,
    QuestLevel level,
  ) {
    if (level.isLocked) return;

    if (level.type == LevelType.read) {
      // Direct opening to reader (available online and offline!)
      Navigator.push(
        context,
        QuixoriaPageRoute(
          builder: (ctx) => ReaderScreen(
            literature: work,
            chapterIndex: level.chapterIndex,
            levelId: level.id,
          ),
        ),
      );
      return;
    }

    // Special interactive Quest Map encounters
    switch (level.type) {
      case LevelType.treasureChest:
        MilestoneChestDialog.show(context, literature: work, level: level);
        return;
      case LevelType.lightningDuel:
        Navigator.push(
          context,
          QuixoriaPageRoute(
            builder: (ctx) => LightningDuelScreen(literature: work, level: level),
          ),
        );
        return;
      case LevelType.campfireParley:
        Navigator.push(
          context,
          QuixoriaPageRoute(
            builder: (ctx) => CampfireParleyScreen(literature: work, level: level),
          ),
        );
        return;
      case LevelType.quoteShrine:
        Navigator.push(
          context,
          QuixoriaPageRoute(
            builder: (ctx) => QuoteShrineScreen(literature: work, level: level),
          ),
        );
        return;
      case LevelType.wordMatchBlitz:
        Navigator.push(
          context,
          QuixoriaPageRoute(
            builder: (ctx) => WordMatchBlitzScreen(literature: work, level: level),
          ),
        );
        return;
      case LevelType.zoneGatekeeper:
        Navigator.push(
          context,
          QuixoriaPageRoute(
            builder: (ctx) => ZoneGatekeeperScreen(literature: work, level: level),
          ),
        );
        return;
      default:
        break;
    }

    {
      // If offline, quizzes cannot be started - present full bulleted warning:
      if (!state.isOnline) {
        OfflineWarningDialog.show(context);
        return;
      }

      // For Quiz levels (Recall, Practice, Final):
      // The guide character dialog asks whether the user wants to Start Quiz or Reread Chapter!
      final isPractice = level.type == LevelType.practice;

      GuideDialog.show(
        context: context,
        title: isPractice ? 'Enter Safe Practice?' : 'Dost Thou Dare the Quiz?',
        message: isPractice
            ? 'In this practice grove, no energy hearts shall be lost from mistakes. Test thy knowledge freely!'
            : 'A sharp mind conquers all quests! Ensure thou hast absorbed the passage before facing the examination.',
        primaryButtonText: "I'm Ready for the Quiz",
        secondaryButtonText: 'Reread the Chapter',
        mood: isPractice ? QuixoteMood.inquiring : QuixoteMood.caution,
        onPrimaryPressed: () {
          // Check energy for non-practice quizzes (Caballero pass members have infinite energy!)
          if (!isPractice && !state.profile.isPremium && state.profile.energy < level.energyCost) {
            final canAfford = state.profile.gems >= 50;
            GuideDialog.show(
              context: context,
              title: 'A Weary Knight!',
              message:
                  'Thou hast no energy hearts remaining (${state.profile.energy}/${state.profile.maxEnergy})! Even Rocinante rests.\n\n${canAfford ? "Replenish thy vigor now for 50 gems, or enter Practice mode (0 energy)." : "Thou needest 50 gems to replenish thy vigor, or enter Practice mode (0 energy) to continue thy studies without hearts."}',
              primaryButtonText: canAfford ? 'Refill (50 💎)' : 'Practice Mode',
              secondaryButtonText: 'Dismiss',
              mood: QuixoteMood.caution,
              onPrimaryPressed: () {
                if (canAfford) {
                  state.refillEnergyWithGems(50);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vigor restored! All energy hearts are replenished.'),
                      backgroundColor: AppColors.antiqueGold,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter any Practice level on the map to study with zero energy cost!'),
                      backgroundColor: AppColors.practiceBlue,
                    ),
                  );
                }
              },
            );
            return;
          }

          // Deduct energy if applicable (not deducted for premium members)
          if (!isPractice && !state.profile.isPremium) {
            state.spendEnergy(level.energyCost);
          }

          // Intelligent Duolingo-style session engine (difficulty-tailored, book-specific, zero paid APIs)
          final questions = LearningSessionEngine.instance.assembleSession(
            work: work,
            level: level,
            difficulty: state.profile.difficulty,
            // Spaced repetition is scoped to THIS book only: words missed in other
            // books never appear here, since they don't share the same context.
            missedWords: state.vocabDeck
                .where((c) => c.literatureId == work.id && c.box < 2)
                .map((c) => c.word)
                .toList(),
          );

          // Tactile loading transition: Don Quixote prepares the trial
          QuixoriaLoadingDialog.show(
            context,
            title: 'Summoning the Trial...',
            message: 'Don Quixote gathers questions from "${work.title}"...',
            minDisplayTime: const Duration(milliseconds: 650),
            task: Future.delayed(const Duration(milliseconds: 650)),
          ).then((_) {
            if (context.mounted) {
              Navigator.push(
                context,
                QuixoriaPageRoute(
                  builder: (ctx) => QuizScreen(
                    literatureId: work.id,
                    level: level,
                    questions: questions,
                  ),
                ),
              );
            }
          });
        },
        onSecondaryPressed: () {
          // Open Reader to review
          Navigator.push(
            context,
            QuixoriaPageRoute(
              builder: (ctx) => ReaderScreen(
                literature: work,
                chapterIndex: level.chapterIndex,
                levelId: level.id,
              ),
            ),
          );
        },
      );
    }
  }
}
