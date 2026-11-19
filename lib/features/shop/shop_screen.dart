import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';
import '../../models/app_theme_preset.dart';
import '../../models/literature.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/quixoria_dialog.dart';
import '../../shared/widgets/guide_dialog.dart';
import '../../shared/widgets/loading_dialog.dart';
import '../../shared/widgets/literature_cover.dart';
import '../../shared/widgets/living_biome_painter.dart';
import '../../shared/widgets/quixote_avatar.dart';
import '../../shared/widgets/reward_celebration.dart';
import 'cosmetics_shop_tab.dart';

class ShopScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;
  final int initialTabIndex;

  const ShopScreen({
    super.key,
    this.onNavigateTab,
    this.initialTabIndex = 0,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String? _selectedFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
  }

  @override
  void didUpdateWidget(covariant ShopScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      final target = widget.initialTabIndex.clamp(0, 3);
      if (_tabController.index != target) {
        _tabController.animateTo(target);
      }
    }
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Literary Bazaar',
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
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: const EdgeInsets.symmetric(horizontal: 2),
              indicator: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              labelColor: theme.colorScheme.onPrimary,
              unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Literature', maxLines: 1, softWrap: false))),
                Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Themes', maxLines: 1, softWrap: false))),
                Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Cosmetics', maxLines: 1, softWrap: false))),
                Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Gems & Pass', maxLines: 1, softWrap: false))),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (!state.isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: const Color(0xFFD35400),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bazaar offline view: Reconnect to exchange gems or download grimoires.',
                      style: AppTypography.labelSmall.copyWith(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  InkWell(
                    onTap: () => state.toggleOnlineStatus(true),
                    child: const Text(
                      'Go Online',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Literature Catalog
                _buildLiteratureCatalog(context, state),

                // 2. Thematic Presets & Grimoires
                _buildThemePacks(context, state),

                // 3. Avatar Frames & Scholar Titles Cosmetics Boutique
                const CosmeticsShopTab(),

                // 4. Gems & Caballero Pass
                _buildGemsAndPremium(context, state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- LITERATURE CATALOG ---
  Widget _buildLiteratureCatalog(BuildContext context, AppState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    List<Literature> list = state.shopLiterature;

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((lit) {
        return lit.title.toLowerCase().contains(q) ||
            lit.author.toLowerCase().contains(q) ||
            lit.genres.any((g) => g.toLowerCase().contains(q)) ||
            lit.type.label.toLowerCase().contains(q);
      }).toList();
    }

    if (_selectedFilter != null) {
      list = list.where((lit) {
        return lit.genres.contains(_selectedFilter) ||
            lit.type.label.toLowerCase() == _selectedFilter!.toLowerCase();
      }).toList();
    }

    final preset = state.activeThemePreset;
    final isSnowy = preset.interfaceStyle == ThemeInterfaceStyle.snowy;
    final isPink = preset.id == 'theme_cute_meadow';
    final chipColor = isSnowy
        ? const Color(0xFF00A8CC)
        : (isPink ? const Color(0xFFE91E63) : (isDark ? AppColors.antiqueGold : theme.colorScheme.primary));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Filter controls
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: isDark ? Colors.white : AppColors.inkDark),
              decoration: InputDecoration(
                hintText: 'Search by title, author, genre...',
                hintStyle: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.inkLight),
                prefixIcon: Icon(Icons.search, color: isDark ? AppColors.antiqueGold : theme.colorScheme.primary),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : AppColors.surfaceCard,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.borderLight,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.borderLight,
                  ),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Genre / Type filter pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildFilterChip('All', _selectedFilter == null, () {
                  setState(() => _selectedFilter = null);
                }, chipColor, isDark),
                _buildFilterChip('Adventure', _selectedFilter == 'Adventure', () {
                  setState(() => _selectedFilter = 'Adventure');
                }, chipColor, isDark),
                _buildFilterChip('Mystery', _selectedFilter == 'Mystery', () {
                  setState(() => _selectedFilter = 'Mystery');
                }, chipColor, isDark),
                _buildFilterChip('Fantasy', _selectedFilter == 'Fantasy', () {
                  setState(() => _selectedFilter = 'Fantasy');
                }, chipColor, isDark),
                _buildFilterChip('Classics', _selectedFilter == 'Classics', () {
                  setState(() => _selectedFilter = 'Classics');
                }, chipColor, isDark),
                _buildFilterChip('Poetry', _selectedFilter == 'Poetry', () {
                  setState(() => _selectedFilter = 'Poetry');
                }, chipColor, isDark),
                _buildFilterChip('Novel', _selectedFilter == 'Novel', () {
                  setState(() => _selectedFilter = 'Novel');
                }, chipColor, isDark),
                _buildFilterChip('Sonnet', _selectedFilter == 'Sonnet', () {
                  setState(() => _selectedFilter = 'Sonnet');
                }, chipColor, isDark),
              ],
            ),
          ),

          // Story Clusters & Featured Work
          if (_searchQuery.isEmpty && _selectedFilter == null) ...[
            // Daily Reading Treasure Chest (#9)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: _buildDailyReadingChestCard(context, state),
            ),

            // Featured Collector's Masterwork Spotlight Card
            if (list.isNotEmpty)
              _buildFeaturedBookSpotlight(
                context,
                state,
                list.firstWhere((l) => !l.isOwned, orElse: () => list.first),
              ),

            _buildStoryCluster(
              title: 'Masterwork Quest',
              subtitle: 'Unlockable with Golden Keys or Gems',
              works: list.where((l) => l.gemCost >= 1000).toList(),
              context: context,
              state: state,
            ),
            _buildStoryCluster(
              title: 'Bold Adventures & Mysteries',
              subtitle: 'Thrilling escapades and hidden enigmas',
              works: list.where((l) => l.genres.contains('Adventure') || l.genres.contains('Mystery')).toList(),
              context: context,
              state: state,
            ),
            _buildStoryCluster(
              title: 'Poems and Sonnets',
              subtitle: 'Lyrical reflections to soothe the wandering soul',
              works: list.where((l) => l.type == LiteratureType.poem || l.type == LiteratureType.sonnet).toList(),
              context: context,
              state: state,
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Search Results (${list.length})',
                style: AppTypography.titleMedium.copyWith(
                  color: isDark ? AppColors.antiqueGold : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: list.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) => _buildCatalogItemRow(context, state, list[index]),
            ),
          ],
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onSelected, Color activeColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: activeColor,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : null,
        side: BorderSide(
          color: isSelected
              ? activeColor
              : (isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.borderLight),
        ),
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white.withValues(alpha: 0.85) : AppColors.inkDark),
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (val) => onSelected(),
      ),
    );
  }

  Widget _buildStoryCluster({
    required String title,
    required String subtitle,
    required List<Literature> works,
    required BuildContext context,
    required AppState state,
  }) {
    if (works.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleLarge.copyWith(
                  color: isDark ? AppColors.antiqueGold : theme.colorScheme.primary,
                ),
              ),
              Text(subtitle, style: AppTypography.bodySmall),
            ],
          ),
        ),
        SizedBox(
          height: 306,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            scrollDirection: Axis.horizontal,
            itemCount: works.length,
            separatorBuilder: (ctx, i) => const SizedBox(width: 14),
            itemBuilder: (ctx, index) {
              final lit = works[index];
              return _buildClusterCard(context, state, lit);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedBookSpotlight(BuildContext context, AppState state, Literature lit) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = state.activeThemePreset.effectivePrimary(isDarkMode: isDark);

    return GestureDetector(
      onTap: () => _showPurchaseSheet(context, state, lit),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [theme.colorScheme.surface, accent.withValues(alpha: 0.22)]
                : [theme.colorScheme.surface, accent.withValues(alpha: 0.10)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.24 : 0.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: LiteratureCover(literature: lit, width: 100, height: 142),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.antiqueGold.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: AppColors.antiqueGold.withValues(alpha: 0.6)),
                    ),
                    child: const Text(
                      'FEATURED EDITION',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                        color: AppColors.antiqueGold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lit.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 16.5,
                      height: 1.2,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${lit.author} • ${lit.chapters.length} Chapters',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DuoButton(
                    text: lit.isOwned ? 'Open in Library' : 'Inspect • ${lit.gemCost} Gems',
                    icon: lit.isOwned ? Icons.menu_book_rounded : Icons.diamond_rounded,
                    variant: lit.isOwned ? DuoButtonVariant.primary : DuoButtonVariant.gold,
                    height: 40,
                    onPressed: () => _showPurchaseSheet(context, state, lit),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClusterCard(BuildContext context, AppState state, Literature lit) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = state.activeThemePreset.effectivePrimary(isDarkMode: isDark);

    return InkWell(
      onTap: () => _showPurchaseSheet(context, state, lit),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: lit.isOwned
                ? AppColors.successGreen.withValues(alpha: 0.45)
                : accent.withValues(alpha: isDark ? 0.32 : 0.22),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: LiteratureCover(
                  literature: lit,
                  width: 126,
                  height: 162,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              lit.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              lit.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
            const Spacer(),
            if (lit.isOwned)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.45)),
                ),
                child: Center(
                  child: Text(
                    'OWNED',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.antiqueGold,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Color.alphaBlend(Colors.black.withValues(alpha: 0.28), AppColors.antiqueGold),
                      offset: const Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.diamond_rounded, size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Buy ${lit.gemCost}',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogItemRow(BuildContext context, AppState state, Literature lit) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          LiteratureCover(literature: lit, width: 65, height: 95),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lit.title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.inkDark,
                  ),
                ),
                Text(
                  lit.author,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? const Color(0xFFC5CEC8) : AppColors.inkLight,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: lit.genres.map((g) {
                    return Text(
                      '#$g ',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 10,
                        color: AppColors.antiqueGold,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (lit.isOwned)
            SizedBox(
              width: 88,
              child: DuoButton(
                text: 'Read',
                variant: DuoButtonVariant.primary,
                height: 38,
                onPressed: () {
                  state.setActiveLiterature(lit.id);
                  widget.onNavigateTab?.call(0);
                },
              ),
            )
          else
            SizedBox(
              width: 104,
              child: DuoButton(
                text: '${lit.gemCost} 💎',
                variant: DuoButtonVariant.gold,
                height: 38,
                onPressed: () => _showPurchaseSheet(context, state, lit),
              ),
            ),
        ],
      ),
    );
  }

  // --- PURCHASE BOTTOM SHEET ---
  void _showPurchaseSheet(BuildContext context, AppState state, Literature lit) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    if (lit.isOwned) {
      showModalBottomSheet(
        context: context,
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.parchmentCream,
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline_rounded, color: state.activeThemePreset.successColor, size: 48),
                const SizedBox(height: 12),
                Text('Already in Thy Library', style: AppTypography.titleLarge.copyWith(color: isDark ? Colors.white : AppColors.inkDark)),
                const SizedBox(height: 8),
                Text('Thou already ownest this classic work. Set it as thy active quest now?', style: TextStyle(color: isDark ? const Color(0xFFC5CEC8) : AppColors.inkLight)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.antiqueGold : primary,
                      foregroundColor: isDark ? const Color(0xFF121212) : Colors.white,
                    ),
                    onPressed: () {
                      state.setActiveLiterature(lit.id);
                      Navigator.pop(ctx);
                      widget.onNavigateTab?.call(0);
                    },
                    child: const Text('Embark on this Quest'),
                  ),
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    if (!state.isOnline) {
      GuideDialog.show(
        context: context,
        title: 'Connection Required',
        message:
            'Unlocking literature with gems or Golden Keys requires a connection to the Royal Ledger. Reconnect to complete thy exchange!',
        primaryButtonText: 'Connect Now',
        mood: QuixoteMood.caution,
        onPrimaryPressed: () => state.toggleOnlineStatus(true),
      );
      return;
    }

    final currentGems = state.profile.gems;
    final canAffordGems = currentGems >= lit.gemCost;
    final diff = lit.gemCost - currentGems;
    final hasGoldenKey = state.profile.goldenKeys > 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.parchmentCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LiteratureCover(literature: lit, width: 80, height: 120),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lit.title,
                          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(lit.author, style: AppTypography.bodySmall),
                        const SizedBox(height: 8),
                        Text(
                          lit.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Economy summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Price in Gems:', style: AppTypography.bodyMedium),
                  Row(
                    children: [
                      const Icon(Icons.diamond_rounded, size: 18, color: AppColors.gemCyan),
                      const SizedBox(width: 4),
                      Text(
                        '${lit.gemCost}',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.gemCyan,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Thy Gem Balance:', style: AppTypography.bodyMedium),
                  Text('$currentGems', style: AppTypography.bodyMedium),
                ],
              ),
              const SizedBox(height: 12),

              if (!canAffordGems)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.energyRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.energyRed, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Thou needest $diff more gems! Complete daily expeditions, recall quizzes, or use a Golden Key.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.energyRed),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Unlock with Gems 3D button
              DuoButton(
                text: 'Unlock for ${lit.gemCost} Gems',
                icon: Icons.lock_open_rounded,
                variant: canAffordGems ? DuoButtonVariant.gold : DuoButtonVariant.outline,
                height: 50,
                onPressed: canAffordGems
                    ? () async {
                        final confirmed = await showPurchaseConfirmDialog(
                          context: ctx,
                          itemName: lit.title,
                          priceLabel: '${lit.gemCost} Gems',
                          icon: Icons.menu_book_rounded,
                          description: 'Add "${lit.title}" by ${lit.author} permanently to your library.',
                          accentColor: AppColors.antiqueGold,
                        );
                        if (!confirmed || !ctx.mounted) return;
                        state.purchaseLiteratureWithGems(lit.id);
                        SoundService.instance.play(Sfx.purchase);
                        Navigator.pop(ctx);
                        if (context.mounted) {
                          RewardCelebrationOverlay.showCelebration(
                            context,
                            celebrationType: CelebrationType.gems,
                          );
                          await showPurchaseCelebrationDialog(
                            context: context,
                            title: 'Masterwork Acquired!',
                            subtitle: '"${lit.title}" has been added to your Personal Library. Tap Start Reading anytime!',
                            icon: Icons.auto_stories_rounded,
                            accentColor: AppColors.antiqueGold,
                            buttonText: 'Start Reading',
                          );
                          if (context.mounted) {
                            state.setActiveLiterature(lit.id);
                            widget.onNavigateTab?.call(0);
                          }
                        }
                      }
                    : null,
              ),

              // Unlock with Golden Key 3D button (if available)
              if (hasGoldenKey) ...[
                const SizedBox(height: 10),
                DuoButton(
                  text: 'Unlock with 1 Golden Key',
                  icon: Icons.key_rounded,
                  variant: DuoButtonVariant.primary,
                  height: 48,
                  onPressed: () async {
                    final confirmed = await showPurchaseConfirmDialog(
                      context: ctx,
                      itemName: lit.title,
                      priceLabel: '1 Golden Key',
                      icon: Icons.key_rounded,
                      description: 'Use 1 Golden Key to unlock "${lit.title}" without spending any Gems.',
                      accentColor: AppColors.goldenKey,
                    );
                    if (!confirmed || !ctx.mounted) return;
                    state.unlockLiteratureWithGoldenKey(lit.id);
                    SoundService.instance.play(Sfx.purchase);
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      RewardCelebrationOverlay.showCelebration(
                        context,
                        celebrationType: CelebrationType.gems,
                      );
                      await showPurchaseCelebrationDialog(
                        context: context,
                        title: 'Golden Key Unleashed!',
                        subtitle: 'The legendary seal is broken! "${lit.title}" is now yours to read.',
                        icon: Icons.key_rounded,
                        accentColor: AppColors.goldenKey,
                        buttonText: 'Enter the Quest',
                      );
                      if (context.mounted) {
                        state.setActiveLiterature(lit.id);
                        widget.onNavigateTab?.call(0);
                      }
                    }
                  },
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // --- THEME PACKS & GRIMOIRES TAB ---
  Widget _buildThemePacks(BuildContext context, AppState state) {
    final presets = state.themePresets;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theme Header Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C1E3A), Color(0xFF191322)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF9D65C9), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9D65C9).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD4A5FF), width: 1),
                      ),
                      child: Text(
                        'REALM AESTHETICS & PRESETS',
                        style: AppTypography.labelSmall.copyWith(
                          color: const Color(0xFFF3E8FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.gemCyan),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.diamond_rounded, size: 14, color: AppColors.gemCyan),
                          const SizedBox(width: 4),
                          Text(
                            '${state.profile.gems} Gems',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.gemCyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Historical & Seasonal Grimoires',
                  style: AppTypography.displaySmall.copyWith(
                    color: const Color(0xFFFAF6EE),
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Spend your hard-earned reading gems to unlock full visual presets. Transform typography, surfaces, borders, and buttons across every quest and quiz.',
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFFDCD6CD),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Available Presets (${presets.length})',
            style: AppTypography.titleLarge.copyWith(
              color: isDark ? AppColors.antiqueGold : Theme.of(context).colorScheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Presets list (Living World Biomes featured first!)
          Builder(
            builder: (context) {
              final sortedPresets = [
                ...presets.where((p) => p.isLivingBiome),
                ...presets.where((p) => !p.isLivingBiome),
              ];
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedPresets.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final preset = sortedPresets[index];
                  final isActive = preset.id == state.activeThemePresetId;
                  final canAfford = state.profile.gems >= preset.gemPrice;
                  final liveAccent = preset.effectivePrimary(isDarkMode: isDark);

                  return Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1D21) : AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isActive
                            ? AppColors.antiqueGold
                            : (preset.isLivingBiome
                                ? liveAccent.withValues(alpha: 0.65)
                                : (isDark ? Colors.white.withValues(alpha: 0.14) : AppColors.borderLight)),
                        width: (isActive || preset.isLivingBiome) ? 2.0 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (preset.isLivingBiome ? liveAccent : Colors.black)
                              .withValues(alpha: isDark ? 0.28 : 0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live Animated Biome Diorama Banner for Living World Biomes (4,000 gems)
                        if (preset.isLivingBiome)
                          Stack(
                            children: [
                              LivingBiomePreviewBanner(
                                biomeId: preset.biomeId!,
                                isDark: isDark,
                                height: 174,
                              ),
                              Positioned(
                                top: 10,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFD15C), Color(0xFFD4A338)],
                                    ),
                                    borderRadius: BorderRadius.circular(99),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_awesome_rounded, size: 12, color: Color(0xFF1F1600)),
                                      SizedBox(width: 4),
                                      Text(
                                        'LIVING MAP BIOME',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.6,
                                          color: Color(0xFF1F1600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                right: 12,
                                child: Material(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(99),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(99),
                                    onTap: () => _showLiveMapPreviewModal(context, state, preset),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.map_rounded, size: 13, color: Color(0xFFFFE066)),
                                          SizedBox(width: 5),
                                          Text(
                                            'Preview on Map',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          // Rich Live Mini-UI Showcase Banner for Realm Grimoires
                          _buildThemeMiniUiBanner(context, state, preset, isDark),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (preset.mapFeatures.isNotEmpty) ...[
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: preset.mapFeatures.map((feat) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: liveAccent.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: liveAccent.withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: Text(
                                        feat,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: liveAccent,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                              ],
                    // Top Row: Emoji, Title, Era, and Status Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: preset.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: preset.border, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              preset.icon,
                              size: 26,
                              color: preset.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preset.name,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.inkDark,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2C2C2C) : AppColors.parchmentDark.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  preset.eraTag,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isDark ? const Color(0xFFDCD6CD) : AppColors.inkMedium,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status Badge
                        if (isActive) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: preset.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 13, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'ACTIVE',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (preset.isOwned) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.antiqueGold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.antiqueGold),
                            ),
                            child: Text(
                              'OWNED',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark ? AppColors.antiqueGold : preset.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.gemCyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.gemCyan),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.diamond_rounded, size: 13, color: AppColors.gemCyan),
                                const SizedBox(width: 4),
                                Text(
                                  '${preset.gemPrice}',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isDark ? AppColors.gemCyan : preset.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(
                      preset.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkMedium,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Palette Swatches
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.parchmentWarm.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Palette:',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.inkLight,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildSwatchDot(preset.primary, 'Primary'),
                          const SizedBox(width: 6),
                          _buildSwatchDot(preset.secondary, 'Secondary'),
                          const SizedBox(width: 6),
                          _buildSwatchDot(preset.background, 'Background'),
                          const SizedBox(width: 6),
                          _buildSwatchDot(preset.surface, 'Surface'),
                          const SizedBox(width: 6),
                          _buildSwatchDot(preset.accent, 'Accent'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Action Controls
                    if (isActive) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: preset.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: preset.primary.withOpacity(0.2)),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shield_outlined, size: 16, color: preset.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Currently Active Preset',
                                style: AppTypography.titleSmall.copyWith(
                                  color: preset.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (preset.isOwned && preset.isDownloaded) ...[
                      DuoButton(
                        text: 'Equip ${preset.name}',
                        icon: Icons.palette_rounded,
                        variant: DuoButtonVariant.primary,
                        height: 48,
                        onPressed: () async {
                          await QuixoriaLoadingDialog.show(
                            context,
                            title: 'Manifesting ${preset.name}',
                            message: 'Adapting interface architecture, stonework accents, and literary grimoire...',
                            task: Future.delayed(const Duration(milliseconds: 900), () => state.applyThemePreset(preset.id)),
                          );
                          if (context.mounted) {
                            RewardCelebrationOverlay.showCelebration(
                              context,
                              celebrationType: CelebrationType.gems,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Equipped ${preset.name}! The realm has adapted to this era.'),
                                backgroundColor: preset.primary,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ] else if (preset.isOwned && !preset.isDownloaded) ...[
                      if (preset.downloadProgress > 0 && preset.downloadProgress < 1.0) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Downloading Realm Assets...',
                                  style: AppTypography.labelSmall.copyWith(color: preset.primary),
                                ),
                                Text(
                                  '${(preset.downloadProgress * 100).toInt()}%',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: preset.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: preset.downloadProgress,
                                backgroundColor: AppColors.borderLight,
                                valueColor: AlwaysStoppedAnimation<Color>(preset.primary),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        DuoButton(
                          text: 'Download Theme Pack (Free)',
                          icon: Icons.download_rounded,
                          variant: DuoButtonVariant.gold,
                          height: 48,
                          onPressed: () async {
                            if (!state.isOnline) {
                              GuideDialog.show(
                                context: context,
                                title: 'Online Connection Required',
                                message: 'Downloading realm theme assets requires an active connection. Reconnect to download ${preset.name}!',
                                primaryButtonText: 'Connect Now',
                                mood: QuixoteMood.caution,
                                onPrimaryPressed: () => state.toggleOnlineStatus(true),
                              );
                              return;
                            }
                            await QuixoriaLoadingDialog.show(
                              context,
                              title: 'Downloading ${preset.name}',
                              message: 'Acquiring manuscript typography, historical emblems, and interface styling...',
                              task: state.downloadThemePreset(preset.id),
                              minDisplayTime: const Duration(milliseconds: 1400),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${preset.name} downloaded! Tap Equip to activate.'),
                                  backgroundColor: preset.primary,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ] else ...[
                      // Not owned - purchase
                      if (canAfford) ...[
                        DuoButton(
                          text: 'Unlock for ${preset.gemPrice} Gems',
                          icon: Icons.diamond_rounded,
                          variant: DuoButtonVariant.gold,
                          height: 48,
                          onPressed: () async {
                            if (!state.isOnline) {
                              GuideDialog.show(
                                context: context,
                                title: 'Online Ledger Required',
                                message: 'Unlocking grimoires with gems requires an active connection to the Royal Ledger. Reconnect to unlock ${preset.name}!',
                                primaryButtonText: 'Connect Now',
                                mood: QuixoteMood.caution,
                                onPrimaryPressed: () => state.toggleOnlineStatus(true),
                              );
                              return;
                            }
                            final confirmed = await showPurchaseConfirmDialog(
                              context: context,
                              itemName: '${preset.name} Theme',
                              priceLabel: '${preset.gemPrice} Gems',
                              icon: preset.icon,
                              description: 'Unlock and download "${preset.name}" to transform Quixoria’s palette, borders, and typography.',
                              accentColor: preset.primary,
                            );
                            if (!confirmed || !context.mounted) return;
                            final success = state.buyThemePreset(preset.id);
                            if (success) {
                              SoundService.instance.play(Sfx.purchase);
                              RewardCelebrationOverlay.showCelebration(
                                context,
                                celebrationType: CelebrationType.gems,
                              );
                              await QuixoriaLoadingDialog.show(
                                context,
                                title: 'Downloading ${preset.name}',
                                message: 'Acquiring manuscript typography, historical emblems, and interface styling...',
                                task: state.downloadThemePreset(preset.id),
                                minDisplayTime: const Duration(milliseconds: 1200),
                              );
                              if (context.mounted) {
                                await showPurchaseCelebrationDialog(
                                  context: context,
                                  title: '${preset.name} Unlocked!',
                                  subtitle: 'Your new theme pack is downloaded and ready to equip.',
                                  icon: preset.icon,
                                  accentColor: preset.primary,
                                  buttonText: 'Wonderful!',
                                );
                              }
                            }
                          },
                        ),
                      ] else ...[
                        DuoButton(
                          text: 'Need ${preset.gemPrice - state.profile.gems} More Gems',
                          icon: Icons.lock_outline_rounded,
                          variant: DuoButtonVariant.outline,
                          height: 48,
                          onPressed: null,
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Earn gems by completing reading chapters & recall quizzes!',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              color: AppColors.inkLight,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSwatchDot(Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withOpacity(0.2), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }

  // --- GEMS & PREMIUM TAB ---
  Widget _buildGemsAndPremium(BuildContext context, AppState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final freezes = state.profile.streakFreezes;
    final canBuyFreeze = freezes < 3 && state.profile.gems >= 100;

    final preset = state.activeThemePreset;
    final isPink = preset.id == 'theme_cute_meadow';
    final isSnowy = preset.interfaceStyle == ThemeInterfaceStyle.snowy;
    final isMedieval = preset.interfaceStyle == ThemeInterfaceStyle.medieval;
    final isPlague = preset.interfaceStyle == ThemeInterfaceStyle.plague;
    final isCozy = preset.interfaceStyle == ThemeInterfaceStyle.cozy;

    final freezeAccent = isPink
        ? const Color(0xFFC24168)
        : (isMedieval
            ? const Color(0xFF991B2D)
            : (isPlague
                ? const Color(0xFFC77DFF)
                : (isCozy
                    ? const Color(0xFFE28442)
                    : (isSnowy ? const Color(0xFF00A8CC) : AppColors.practiceBlue))));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily Reading Treasure Chest (#9)
          _buildDailyReadingChestCard(context, state),
          const SizedBox(height: 16),

          // Current Balance Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.antiqueGold, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBalCol('Gems', '${state.profile.gems}', Icons.diamond_rounded, isPink ? const Color(0xFFE91E63) : AppColors.gemCyan),
                _buildBalCol('Energy', '${state.profile.energy}/${state.profile.maxEnergy}', Icons.favorite_rounded, AppColors.energyRed),
                _buildBalCol('Freezes', '$freezes/3', Icons.ac_unit_rounded, freezeAccent),
                _buildBalCol('Golden Keys', '${state.profile.goldenKeys}', Icons.key_rounded, AppColors.goldenKey),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Streak Freeze Power-Up Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: freezeAccent.withValues(alpha: 0.55),
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: freezeAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.ac_unit_rounded,
                    color: freezeAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Streak Freeze ($freezes/3 Equipped)',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Protects your daily reading streak for 1 missed midnight deadline automatically.',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 112,
                  child: DuoButton(
                    text: freezes >= 3 ? 'Full (3/3)' : '100 💎',
                    variant: freezes >= 3
                        ? DuoButtonVariant.outline
                        : (canBuyFreeze ? DuoButtonVariant.gold : DuoButtonVariant.outline),
                    height: 40,
                    onPressed: canBuyFreeze
                        ? () async {
                            final confirmed = await showPurchaseConfirmDialog(
                              context: context,
                              itemName: 'Streak Freeze',
                              priceLabel: '100 Gems',
                              icon: Icons.ac_unit_rounded,
                              description: 'Protects your daily reading streak automatically if you miss a day.',
                              accentColor: freezeAccent,
                            );
                            if (!confirmed || !context.mounted) return;
                            final ok = state.buyStreakFreeze();
                            if (ok && context.mounted) {
                              SoundService.instance.play(Sfx.purchase);
                              RewardCelebrationOverlay.showCelebration(
                                context,
                                celebrationType: CelebrationType.gems,
                              );
                              await showPurchaseCelebrationDialog(
                                context: context,
                                title: 'Streak Freeze Equipped!',
                                subtitle: 'You now hold ${state.profile.streakFreezes}/3 Streak Freezes to guard your flame.',
                                icon: Icons.ac_unit_rounded,
                                accentColor: freezeAccent,
                              );
                            }
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Caballero Pass / Premium Card (Pure neutral dark mode in dark mode; thematic in light mode)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF242424), const Color(0xFF141414)]
                    : [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.85),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.antiqueGold, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.antiqueGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.profile.isPremium ? 'CABALLERO PASS ACTIVE' : 'QUIXOTE GUILD PASS',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark ? const Color(0xFF121212) : theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.stars_rounded, color: AppColors.antiqueGold, size: 28),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  state.profile.isPremium ? 'Thou Art a Full Caballero!' : 'The Caballero Pass',
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.parchmentCream,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  state.profile.isPremium
                      ? 'Thy membership is fully unlocked. Enjoy infinite energy hearts, audio narrations, exclusive antique bindings, and 2x daily quest gems!'
                      : 'Unlock infinite energy hearts, audio narrations, exclusive vintage leather book bindings, and 2x daily quest gems.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.parchmentWarm,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                if (state.profile.isPremium) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check, size: 16, color: AppColors.parchmentCream),
                        const SizedBox(width: 6),
                        Text(
                          'Caballero Pass Active',
                          style: AppTypography.titleSmall.copyWith(color: AppColors.parchmentCream),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: DuoButton(
                          text: '\$4.99 / mo',
                          variant: DuoButtonVariant.outline,
                          height: 46,
                          onPressed: () => _openSimulatedCheckout(
                            context: context,
                            state: state,
                            itemName: 'Caballero Pass (Monthly)',
                            priceTag: '\$4.99 / month',
                            onCompleted: () => state.activatePremiumSubscription('Monthly'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DuoButton(
                          text: 'Yearly \$39.99',
                          icon: Icons.stars_rounded,
                          variant: DuoButtonVariant.gold,
                          height: 46,
                          onPressed: () => _openSimulatedCheckout(
                            context: context,
                            state: state,
                            itemName: 'Caballero Pass (Yearly Best Value)',
                            priceTag: '\$39.99 / year',
                            onCompleted: () => state.activatePremiumSubscription('Yearly'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Instant Activation • Cancel Anytime in Settings',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 10,
                      color: AppColors.parchmentWarm.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Gem Bundles
          Text('Gem Chests', style: AppTypography.titleLarge.copyWith(color: isDark ? AppColors.antiqueGold : theme.colorScheme.primary)),
          const SizedBox(height: 12),

          _buildGemBundleRow(context, state, 'Satchel of 500 Gems', 500, '\$1.99'),
          const SizedBox(height: 10),
          _buildGemBundleRow(context, state, 'Chest of 1,200 Gems', 1200, '\$3.99'),
          const SizedBox(height: 10),
          _buildGemBundleRow(context, state, 'Dragon Hoard of 3,000 Gems', 3000, '\$8.99'),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBalCol(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
      ],
    );
  }

  Widget _buildGemBundleRow(
    BuildContext context,
    AppState state,
    String title,
    int amount,
    String price,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.diamond_rounded, color: AppColors.gemCyan, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall.copyWith(color: isDark ? Colors.white : AppColors.inkDark)),
                Text('+$amount Gems', style: AppTypography.bodySmall.copyWith(color: AppColors.gemCyan, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SizedBox(
            width: 104,
            child: DuoButton(
              text: 'Buy $price',
              variant: DuoButtonVariant.gold,
              height: 40,
              onPressed: () {
                _openSimulatedCheckout(
                  context: context,
                  state: state,
                  itemName: title,
                  priceTag: price,
                  onCompleted: () => state.addGems(amount),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openSimulatedCheckout({
    required BuildContext context,
    required AppState state,
    required String itemName,
    required String priceTag,
    required VoidCallback onCompleted,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.parchmentCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Royal Treasury Checkout',
                    style: AppTypography.titleLarge.copyWith(color: isDark ? AppColors.antiqueGold : primary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.antiqueGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.antiqueGold),
                    ),
                    child: Text(
                      'SECURE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.antiqueGold : primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Item: $itemName',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Price: $priceTag',
                style: AppTypography.bodySmall.copyWith(color: AppColors.inkLight),
              ),
              const SizedBox(height: 16),

              // Royal Treasury Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2C3E50), Color(0xFF1A252F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'QUIXORIA ROYAL TREASURY CARD',
                          style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1),
                        ),
                        Icon(Icons.contactless_rounded, color: Colors.white.withOpacity(0.7), size: 20),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '••••  ••••  ••••  1605',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        letterSpacing: 2.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          state.profile.name.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'EXP 12/29',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Reassurance message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Protected by the Quixoria Royal Treasury. Your benefits activate immediately upon confirmation.',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Confirm 3D Button + Animated Celebration Popup
              DuoButton(
                text: 'Confirm & Complete Order',
                icon: Icons.check_circle_rounded,
                variant: DuoButtonVariant.gold,
                height: 52,
                onPressed: () {
                  Navigator.pop(ctx);
                  onCompleted();
                  SoundService.instance.play(Sfx.purchase);
                  RewardCelebrationOverlay.showCelebration(
                    context,
                    celebrationType: CelebrationType.gems,
                  );
                  final isPass = itemName.toLowerCase().contains('pass');
                  showPurchaseCelebrationDialog(
                    context: context,
                    title: isPass ? 'Guild Pass Activated!' : 'Purchase Complete!',
                    subtitle: '$itemName has been added to your account.',
                    icon: isPass ? Icons.workspace_premium_rounded : Icons.diamond_rounded,
                    accentColor: isPass ? AppColors.antiqueGold : AppColors.gemCyan,
                    buttonText: 'Awesome!',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// #9 Daily Reading Treasure Chest Card (7-day escalating gem rewards + Day 7 Freeze)
  Widget _buildDailyReadingChestCard(BuildContext context, AppState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canClaim = state.canClaimDailyChest;
    final day = state.nextDailyChestDay;
    final gems = state.nextDailyChestGems;
    final hasFreeze = state.nextDailyChestHasFreeze;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: canClaim
              ? (isDark
                  ? [const Color(0xFF2B2314), const Color(0xFF1D170C)]
                  : [const Color(0xFFFFF8E6), const Color(0xFFFFEDC2)])
              : (isDark
                  ? [theme.colorScheme.surface, theme.colorScheme.surface]
                  : [theme.colorScheme.surface, theme.colorScheme.surface]),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: canClaim
              ? const Color(0xFFFFB703)
              : theme.dividerColor.withValues(alpha: 0.45),
          width: canClaim ? 1.8 : 1.2,
        ),
        boxShadow: canClaim
            ? [
                BoxShadow(
                  color: const Color(0xFFFFB703).withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: canClaim
                    ? [const Color(0xFFFFE066), const Color(0xFFFFB703)]
                    : [Colors.grey.shade400, Colors.grey.shade500],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              canClaim ? Icons.card_giftcard_rounded : Icons.check_circle_rounded,
              color: canClaim ? const Color(0xFF1F1600) : Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canClaim
                      ? 'Daily Reading Chest • Day $day/7'
                      : 'Daily Chest Opened ✓',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  canClaim
                      ? (hasFreeze
                          ? 'Jackpot! Open for +$gems Gems + 1 Streak Freeze!'
                          : 'Free daily reward: +$gems Gems toward themes & books!')
                      : 'Come back tomorrow for Day $day (+$gems Gems)!',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (canClaim)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB703),
                foregroundColor: const Color(0xFF1F1600),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                final reward = state.claimDailyReadingChest();
                if (reward == null || !context.mounted) return;
                RewardCelebrationOverlay.showCelebration(
                  context,
                  celebrationType: CelebrationType.gems,
                );
                await showPurchaseCelebrationDialog(
                  context: context,
                  title: 'Day ${reward.day} Chest Opened!',
                  subtitle: reward.gotFreeze
                      ? '+${reward.gems} Gems & +1 Streak Freeze added to your treasury!'
                      : '+${reward.gems} Gems added to your treasury! Keep coming back daily for the Day 7 Jackpot (+1,000 Gems).',
                  icon: Icons.card_giftcard_rounded,
                  accentColor: const Color(0xFFFFB703),
                  buttonText: 'Collect!',
                );
              },
              child: const Text(
                'Open',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
              ),
            ),
        ],
      ),
    );
  }

  /// Rich Live Mini-UI Showcase Banner for standard Realm Themes so they look visual & alive
  Widget _buildThemeMiniUiBanner(
    BuildContext context,
    AppState state,
    AppThemePreset preset,
    bool isDark,
  ) {
    final bg = isDark ? (preset.darkBackground ?? const Color(0xFF14171A)) : preset.background;
    final surf = isDark ? (preset.darkSurface ?? const Color(0xFF1E2228)) : preset.surface;
    final prim = preset.effectivePrimary(isDarkMode: isDark);
    final borderCol = isDark ? (preset.darkBorder ?? prim.withValues(alpha: 0.35)) : preset.border;
    final txtCol = isDark ? const Color(0xFFF5F3F8) : preset.textPrimary;

    return Container(
      height: 112,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: borderCol, width: 1.2)),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              // Mini illustrated preview card showing the real theme surfaces
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: surf,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderCol, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: prim.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: prim.withValues(alpha: 0.5)),
                        ),
                        child: Icon(preset.icon, color: prim, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preset.eraTag.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                                color: prim,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              preset.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: txtCol,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                _miniDot(preset.primary),
                                const SizedBox(width: 5),
                                _miniDot(preset.accent),
                                const SizedBox(width: 5),
                                _miniDot(preset.background),
                                const SizedBox(width: 5),
                                _miniDot(preset.darkBackground ?? const Color(0xFF14171A)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Quick Preview on Map pill
              Material(
                color: prim.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _showLiveMapPreviewModal(context, state, preset),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: prim.withValues(alpha: 0.45)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_rounded, size: 18, color: prim),
                        const SizedBox(height: 3),
                        Text(
                          'Preview',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: prim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniDot(Color c) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.2), width: 1),
      ),
    );
  }

  /// #1 Full-Screen Interactive "Preview on Map" Modal for any Living Biome or Theme
  void _showLiveMapPreviewModal(
    BuildContext context,
    AppState state,
    AppThemePreset preset,
  ) {
    bool previewDark = state.isDarkMode;
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final bg = previewDark
                ? (preset.darkBackground ?? const Color(0xFF121417))
                : preset.background;
            final accent = preset.effectivePrimary(isDarkMode: previewDark);
            final txtCol = previewDark ? Colors.white : preset.textPrimary;
            final canAfford = state.profile.gems >= preset.gemPrice;

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  height: MediaQuery.of(ctx).size.height * 0.78,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: accent, width: 2.0),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Live Animated Biome Scenery at Full Height!
                      if (preset.isLivingBiome)
                        LivingBiomePreviewBanner(
                          biomeId: preset.biomeId!,
                          isDark: previewDark,
                          height: double.infinity,
                        ),

                      // Sample Winding Quest Path Nodes down the center
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _previewNode(Icons.check_rounded, accent, previewDark, completed: true),
                            _previewConnector(accent),
                            _previewNode(Icons.auto_stories_rounded, accent, previewDark, active: true),
                            _previewConnector(accent),
                            _previewNode(Icons.lock_rounded, accent, previewDark),
                          ],
                        ),
                      ),

                      // Top Bar: Title + Day/Night Preview Toggle + Close
                      Positioned(
                        top: 14,
                        left: 14,
                        right: 14,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: (previewDark ? Colors.black : Colors.white).withValues(alpha: 0.78),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: accent.withValues(alpha: 0.5)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'LIVE MAP PREVIEW',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        color: accent,
                                      ),
                                    ),
                                    Text(
                                      preset.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: txtCol,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Day / Night toggle right inside Preview!
                            Material(
                              color: (previewDark ? Colors.black : Colors.white).withValues(alpha: 0.82),
                              shape: const CircleBorder(),
                              child: IconButton(
                                tooltip: previewDark ? 'Preview Light Mode' : 'Preview Dark Mode',
                                icon: Icon(
                                  previewDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                                  color: previewDark ? const Color(0xFFFDE68A) : const Color(0xFFF59E0B),
                                ),
                                onPressed: () => setModalState(() => previewDark = !previewDark),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Material(
                              color: (previewDark ? Colors.black : Colors.white).withValues(alpha: 0.82),
                              shape: const CircleBorder(),
                              child: IconButton(
                                icon: Icon(Icons.close_rounded, color: txtCol),
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom CTA Dock: Equip or Unlock directly from Preview!
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: (previewDark ? const Color(0xFF14171A) : Colors.white)
                                .withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: accent.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (preset.mapFeatures.isNotEmpty) ...[
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  alignment: WrapAlignment.center,
                                  children: preset.mapFeatures
                                      .map(
                                        (f) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: accent.withValues(alpha: 0.14),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            f,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: accent,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: 10),
                              ],
                              DuoButton(
                                text: preset.isOwned
                                    ? (state.activeThemePresetId == preset.id
                                        ? 'Currently Active ✓'
                                        : 'Equip This Theme')
                                    : (canAfford
                                        ? 'Unlock for ${preset.gemPrice} Gems'
                                        : 'Need ${preset.gemPrice - state.profile.gems} More Gems'),
                                icon: preset.isOwned
                                    ? Icons.check_circle_rounded
                                    : (canAfford ? Icons.diamond_rounded : Icons.lock_outline_rounded),
                                variant: preset.isOwned
                                    ? DuoButtonVariant.primary
                                    : (canAfford ? DuoButtonVariant.gold : DuoButtonVariant.outline),
                                height: 46,
                                onPressed: (preset.isOwned && state.activeThemePresetId == preset.id) ||
                                        (!preset.isOwned && !canAfford)
                                    ? null
                                    : () {
                                        if (preset.isOwned) {
                                          state.applyThemePreset(preset.id);
                                          Navigator.of(ctx).pop();
                                        } else {
                                          final ok = state.buyThemePreset(preset.id);
                                          if (ok) {
                                            state.downloadThemePreset(preset.id);
                                            state.applyThemePreset(preset.id);
                                            Navigator.of(ctx).pop();
                                          }
                                        }
                                      },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _previewNode(IconData icon, Color accent, bool isDark, {bool completed = false, bool active = false}) {
    return Container(
      width: active ? 62 : 52,
      height: active ? 62 : 52,
      decoration: BoxDecoration(
        color: active || completed ? accent : (isDark ? const Color(0xFF232830) : Colors.white),
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? const Color(0xFFFFE066) : accent,
          width: active ? 3.5 : 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: active ? 0.55 : 0.25),
            blurRadius: active ? 16 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: active || completed ? Colors.white : accent.withValues(alpha: 0.65),
        size: active ? 28 : 22,
      ),
    );
  }

  Widget _previewConnector(Color accent) {
    return Container(
      width: 4,
      height: 28,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}
