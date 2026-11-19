import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';
import '../../models/literature.dart';
import '../../shared/widgets/literature_cover.dart';
import '../../shared/widgets/themed_card.dart';

class LibraryScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const LibraryScreen({super.key, this.onNavigateTab});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _searchQuery = '';
  String _selectedGenre = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _genres = const [
    'All',
    'Novel',
    'Poem & Sonnet',
    'Adventure',
    'Mystery',
    'Gothic',
    'Philosophy',
    'Classics',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Strictly display only books owned by the user
    final ownedList = state.ownedLiterature;

    // Filter owned books based on search query and genre
    final filteredList = ownedList.where((book) {
      final matchesSearch = _searchQuery.isEmpty ||
          book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.author.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.genres.any((g) => g.toLowerCase().contains(_searchQuery.toLowerCase()));

      if (!matchesSearch) return false;

      if (_selectedGenre == 'All') return true;
      if (_selectedGenre == 'Novel') return book.type == LiteratureType.novel;
      if (_selectedGenre == 'Poem & Sonnet') {
        return book.type == LiteratureType.poem || book.type == LiteratureType.sonnet;
      }
      return book.genres.any((g) => g.toLowerCase().contains(_selectedGenre.toLowerCase()));
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Personal Library',
          style: AppTypography.displaySmall.copyWith(
            color: theme.colorScheme.primary,
            fontSize: 24,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.antiqueGold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.antiqueGold.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${ownedList.length} ${ownedList.length == 1 ? 'Book' : 'Books'} Owned',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.antiqueGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
          children: [
            _buildLibraryHeaderBanner(context, ownedList.length),
            const SizedBox(height: 14),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search your owned books...',
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search_rounded, size: 20, color: AppColors.antiqueGold),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim());
                },
              ),
            ),
            const SizedBox(height: 10),

            // Genre Horizontal Filter Chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _genres.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final genre = _genres[i];
                  final isSelected = _selectedGenre == genre;
                  return ChoiceChip(
                    label: Text(
                      genre,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary,
                    backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedGenre = genre);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Book Cards List
            if (filteredList.isEmpty)
              _buildEmptyState(context, isDark)
            else ...[
              for (final work in filteredList) ...[
                _buildOwnedBookCard(
                  context,
                  state,
                  work,
                  work.id == state.activeLiteratureId,
                ),
                const SizedBox(height: 14),
              ],
              if (widget.onNavigateTab != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.storefront_rounded, size: 18, color: AppColors.antiqueGold),
                    label: const Text(
                      'Unlock More Books in the Royal Bazaar',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.antiqueGold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.antiqueGold.withValues(alpha: 0.6)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      SoundService.instance.play(Sfx.tap);
                      HapticFeedback.lightImpact();
                      widget.onNavigateTab?.call(3);
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryHeaderBanner(BuildContext context, int ownedCount) {
    return ThemedCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 130,
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
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.82),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MY PERSONAL COLLECTION',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.antiqueGold,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your Owned Classical Masterworks & Active Reading Quests',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOwnedBookCard(
    BuildContext context,
    AppState state,
    Literature work,
    bool isActive,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalCount = work.questLevels.length;
    final completedCount = work.questLevels.where((l) => l.isCompleted).length;
    final pct = totalCount > 0 ? ((completedCount / totalCount) * 100).toInt() : 0;

    return ThemedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover
              LiteratureCover(
                literature: work,
                width: 85,
                height: 125,
              ),
              const SizedBox(width: 14),

              // Metadata & Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isActive)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.antiqueGold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ACTIVE QUEST',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: isDark ? const Color(0xFF121212) : Colors.white,
                          ),
                        ),
                      ),
                    Text(
                      work.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      work.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Genre Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: work.genres.take(2).map((g) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            g,
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),

                    // Level Count & Progress
                    Text(
                      '$completedCount of $totalCount Levels ($pct%)',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Work Description
          Text(
            work.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(height: 1.35),
          ),

          const SizedBox(height: 12),

          // Progress Bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.antiqueGold),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$pct% Done',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.antiqueGold : theme.colorScheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(isActive ? Icons.play_arrow_rounded : Icons.explore_outlined, size: 18),
              label: Text(
                isActive
                    ? 'Continue Quest'
                    : (work.isOwned ? 'Switch to this Quest' : 'Embark on Expedition'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? theme.colorScheme.primary : theme.colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                SoundService.instance.play(Sfx.tap);
                HapticFeedback.lightImpact();
                state.setActiveLiterature(work.id);
                // Switch back to Quest tab (Tab index 0)
                widget.onNavigateTab?.call(0);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_rounded, size: 54, color: AppColors.antiqueGold),
            const SizedBox(height: 14),
            Text(
              'No Masterworks Found',
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.antiqueGold : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try adjusting thy search query or genre filter to uncover more classical texts.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
