import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/state/app_state.dart';
import '../../models/app_theme_preset.dart';
import '../../models/literature.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/guide_dialog.dart';
import '../../shared/widgets/loading_dialog.dart';
import '../../shared/widgets/literature_cover.dart';
import '../../shared/widgets/quixote_avatar.dart';
import '../../shared/widgets/reward_celebration.dart';

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
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
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
                Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Theme Packs', maxLines: 1, softWrap: false))),
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

                // 3. Gems & Caballero Pass
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
          height: 250,
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

  Widget _buildClusterCard(BuildContext context, AppState state, Literature lit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => _showPurchaseSheet(context, state, lit),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.borderLight,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: LiteratureCover(
                literature: lit,
                width: 100,
                height: 135,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lit.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : AppColors.inkDark,
              ),
            ),
            const Spacer(),
            if (lit.isOwned)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : AppColors.parchmentDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'OWNED',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark ? AppColors.antiqueGold : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.diamond_rounded, size: 14, color: AppColors.gemCyan),
                  const SizedBox(width: 4),
                  Text(
                    '${lit.gemCost}',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.gemCyan,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogItemRow(BuildContext context, AppState state, Literature lit) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF2C2C2C) : AppColors.parchmentWarm,
                foregroundColor: isDark ? AppColors.antiqueGold : primary,
                elevation: 0,
              ),
              onPressed: () {
                state.setActiveLiterature(lit.id);
                widget.onNavigateTab?.call(0);
              },
              child: const Text('Read'),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.antiqueGold : primary,
                foregroundColor: isDark ? const Color(0xFF121212) : Colors.white,
              ),
              onPressed: () => _showPurchaseSheet(context, state, lit),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.diamond_rounded, size: 14, color: isDark ? const Color(0xFF121212) : AppColors.parchmentCream),
                  const SizedBox(width: 4),
                  Text('${lit.gemCost}'),
                ],
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

              // Unlock with Gems button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.lock_open_rounded),
                  label: Text('Unlock for ${lit.gemCost} Gems'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAffordGems ? primary : AppColors.parchmentDark,
                    foregroundColor: canAffordGems ? AppColors.parchmentCream : AppColors.inkLight,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: canAffordGems
                      ? () {
                          GuideDialog.show(
                            context: context,
                            title: 'Confirm Purchase',
                            message:
                                'Wilt thou spend 💎 ${lit.gemCost} gems to unlock "${lit.title}" for thy library?',
                            primaryButtonText: 'Confirm & Unlock',
                            secondaryButtonText: 'Keep My Gems',
                            mood: QuixoteMood.inquiring,
                            onPrimaryPressed: () {
                              state.purchaseLiteratureWithGems(lit.id);
                              Navigator.pop(ctx);
                              GuideDialog.show(
                                context: context,
                                title: 'Masterwork Acquired!',
                                message:
                                    'Thy library expands! "${lit.title}" hath been secured. May its pages enlighten thy valiant quest.',
                                primaryButtonText: 'Start Reading',
                                onPrimaryPressed: () {
                                  state.setActiveLiterature(lit.id);
                                  widget.onNavigateTab?.call(0);
                                },
                                mood: QuixoteMood.triumphant,
                              );
                            },
                          );
                        }
                      : null,
                ),
              ),

              // Unlock with Golden Key button (if available)
              if (hasGoldenKey) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.key_rounded, color: isDark ? const Color(0xFF121212) : primary),
                    label: Text(
                      'Bypass Gem Cost: Unlock with 1 Golden Key',
                      style: TextStyle(color: isDark ? const Color(0xFF121212) : primary, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.antiqueGold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      GuideDialog.show(
                        context: context,
                        title: 'Use Golden Key?',
                        message:
                            'Wilt thou use 1 Golden Key 🗝️ to unlock "${lit.title}" without spending gems?',
                        primaryButtonText: 'Unlock Masterwork',
                        secondaryButtonText: 'Keep My Key',
                        mood: QuixoteMood.inquiring,
                        onPrimaryPressed: () {
                          state.unlockLiteratureWithGoldenKey(lit.id);
                          Navigator.pop(ctx);
                          GuideDialog.show(
                            context: context,
                            title: 'Golden Key Unleashed!',
                            message:
                                'By virtue of thy pristine scholarship, the legendary seal is broken! "${lit.title}" is now thine!',
                            primaryButtonText: 'Enter the Quest',
                            onPrimaryPressed: () {
                              state.setActiveLiterature(lit.id);
                              widget.onNavigateTab?.call(0);
                            },
                            mood: QuixoteMood.triumphant,
                          );
                        },
                      );
                    },
                  ),
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

          // Presets list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: presets.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final preset = presets[index];
              final isActive = preset.id == state.activeThemePresetId;
              final canAfford = state.profile.gems >= preset.gemPrice;

              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? AppColors.antiqueGold
                        : (isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.borderLight),
                    width: isActive ? 2.0 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            GuideDialog.show(
                              context: context,
                              title: 'Acquire Grimoire Preset?',
                              message: 'Wilt thou spend 💎 ${preset.gemPrice} gems to unlock and download "${preset.name}"?',
                              primaryButtonText: 'Confirm & Unlock',
                              secondaryButtonText: 'Keep My Gems',
                              mood: QuixoteMood.inquiring,
                              onPrimaryPressed: () async {
                                final success = state.buyThemePreset(preset.id);
                                if (success) {
                                  RewardCelebrationOverlay.showCelebration(
                                    context,
                                    celebrationType: CelebrationType.gems,
                                  );
                                  // Auto trigger in-app download with loading dialog
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
                                        content: Text('Unlocked and downloaded ${preset.name}! Ready to equip.'),
                                        backgroundColor: preset.primary,
                                      ),
                                    );
                                  }
                                }
                              },
                            );
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: freezes >= 3
                        ? theme.dividerColor
                        : (canBuyFreeze ? freezeAccent : theme.dividerColor),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: canBuyFreeze
                      ? () {
                          final ok = state.buyStreakFreeze();
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Streak Freeze equipped! (${state.profile.streakFreezes}/3 held)'),
                              ),
                            );
                          }
                        }
                      : null,
                  child: Text(
                    freezes >= 3 ? 'Full (3/3)' : '100 Gems',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.antiqueGold),
                            foregroundColor: AppColors.antiqueGold,
                          ),
                          onPressed: () => _openSimulatedCheckout(
                            context: context,
                            state: state,
                            itemName: 'Caballero Pass (Monthly)',
                            priceTag: '\$4.99 / month',
                            onCompleted: () => state.activatePremiumSubscription('Monthly'),
                          ),
                          child: const Text('\$4.99 / mo'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.antiqueGold,
                            foregroundColor: isDark ? const Color(0xFF121212) : theme.colorScheme.primary,
                          ),
                          onPressed: () => _openSimulatedCheckout(
                            context: context,
                            state: state,
                            itemName: 'Caballero Pass (Yearly Best Value)',
                            priceTag: '\$39.99 / year',
                            onCompleted: () => state.activatePremiumSubscription('Yearly'),
                          ),
                          child: const Text('Yearly \$39.99'),
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
    final primary = theme.colorScheme.primary;

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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.antiqueGold : primary,
              foregroundColor: isDark ? const Color(0xFF121212) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              _openSimulatedCheckout(
                context: context,
                state: state,
                itemName: title,
                priceTag: price,
                onCompleted: () => state.addGems(amount),
              );
            },
            child: Text(price),
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

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Confirm & Complete Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onCompleted();
                    GuideDialog.show(
                      context: context,
                      title: 'Order Complete!',
                      message:
                          'Thy transaction for "$itemName" hath been recorded in thy chivalric ledger. Long live the reader!',
                      primaryButtonText: 'Return to Bazaar',
                      onPrimaryPressed: () {},
                      mood: QuixoteMood.triumphant,
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
}
