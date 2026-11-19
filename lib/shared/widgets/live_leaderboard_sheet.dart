import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/state/app_state.dart';
import '../../models/cosmetic_item.dart';
import 'framed_mascot_avatar.dart';
import 'profile_trophy_shelf.dart';

/// Live Global Leaderboard modal powered by Supabase (`public.leaderboard_entries`).
/// Works seamlessly for BOTH Email and No-Email Username accounts.
class LiveLeaderboardSheet extends StatefulWidget {
  const LiveLeaderboardSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LiveLeaderboardSheet(),
    );
  }

  @override
  State<LiveLeaderboardSheet> createState() => _LiveLeaderboardSheetState();
}

class _LiveLeaderboardSheetState extends State<LiveLeaderboardSheet> {
  String _sortBy = 'weekly_xp';
  bool _isLoading = true;
  List<Map<String, dynamic>> _entries = const [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final state = context.read<AppState>();
    // Opening the Leaderboard clears the unread leaderboard badge immediately
    state.markLeaderboardSeen();
    final myKey = AuthService.instance.accountKey.trim().toLowerCase();

    // Push current user's freshest stats before fetching global standings
    if (state.isOnline && myKey.isNotEmpty) {
      await SupabaseService.instance.syncLeaderboardEntry(
        accountKey: myKey,
        profile: state.profile,
      );
    }

    final rows = state.isOnline
        ? await SupabaseService.instance.fetchGlobalLeaderboard(sortBy: _sortBy)
        : <Map<String, dynamic>>[];

    // Ensure the current user is always visible even offline or before other players join
    final list = List<Map<String, dynamic>>.from(rows);
    final hasMe = myKey.isNotEmpty &&
        list.any((r) => (r['account_key']?.toString().toLowerCase() ?? '') == myKey);
    if (!hasMe) {
      list.add({
        'account_key': myKey.isEmpty ? 'local_you' : myKey,
        'display_name': state.profile.name,
        'scholar_title': state.profile.readerRank,
        'frame_id': state.profile.equippedFrameId,
        'weekly_xp': state.profile.weeklyXp,
        'streak_days': state.profile.streakDays,
        'books_completed': state.profile.booksCompleted,
        'levels_completed': state.profile.levelsCompleted,
      });
    }

    // Sort locally as well in case we appended the local user row
    list.sort((a, b) {
      final av = (a[_sortBy] as num?)?.toInt() ?? 0;
      final bv = (b[_sortBy] as num?)?.toInt() ?? 0;
      return bv.compareTo(av);
    });

    // Detect rank-up & Top 1% / #1 Champion milestone
    final matchKey = myKey.isEmpty ? 'local_you' : myKey;
    final myIndex = list.indexWhere(
      (r) => (r['account_key']?.toString().toLowerCase() ?? '') == matchKey,
    );
    if (myIndex >= 0) {
      state.processLeaderboardStanding(
        rank: myIndex + 1,
        totalEntrants: list.length,
        openedSheet: true,
      );
    }

    if (!mounted) return;
    setState(() {
      _entries = list;
      _isLoading = false;
    });
  }

  String _metricText(Map<String, dynamic> row) {
    if (_sortBy == 'streak_days') {
      final s = (row['streak_days'] as num?)?.toInt() ?? 1;
      return '$s day${s == 1 ? '' : 's'}';
    }
    if (_sortBy == 'books_completed') {
      final b = (row['books_completed'] as num?)?.toInt() ?? 0;
      return '$b book${b == 1 ? '' : 's'}';
    }
    final xp = (row['weekly_xp'] as num?)?.toInt() ?? 0;
    return '$xp XP';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    final myKey = AuthService.instance.accountKey.trim().toLowerCase();

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.55,
      maxChildSize: 0.94,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 14, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.antiqueGold.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: AppColors.antiqueGold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Global Leaderboard',
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            state.isOnline
                                ? 'Real-time Quixoria Scholar Standings'
                                : 'Offline preview • Reconnect to sync live ranks',
                            style: AppTypography.bodySmall.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh Standings',
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: _isLoading ? null : _loadLeaderboard,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Sort Filter Pills
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Row(
                  children: [
                    _buildSortChip('Weekly XP', 'weekly_xp', Icons.bolt_rounded, theme),
                    const SizedBox(width: 8),
                    _buildSortChip('Streak', 'streak_days', Icons.local_fire_department_rounded, theme),
                    const SizedBox(width: 8),
                    _buildSortChip('Books', 'books_completed', Icons.menu_book_rounded, theme),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final row = _entries[index];
                          final rank = index + 1;
                          final key = row['account_key']?.toString().toLowerCase() ?? '';
                          final isMe = key == myKey || key == 'local_you';
                          final name = row['display_name']?.toString() ?? 'Scholar';
                          final title = row['scholar_title']?.toString() ?? 'Knight Errant of Letters';
                          final frameId = row['frame_id']?.toString() ?? 'frame_classic';
                          final frame = CosmeticCatalog.frameById(frameId);

                          Color rankColor;
                          if (rank == 1) {
                            rankColor = const Color(0xFFD4A338);
                          } else if (rank == 2) {
                            rankColor = const Color(0xFF95A5A6);
                          } else if (rank == 3) {
                            rankColor = const Color(0xFFCD7F32);
                          } else {
                            rankColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () {
                                  PublicPlayerCardSheet.show(
                                    context,
                                    displayName: name,
                                    targetHandle: key,
                                    scholarTitle: title,
                                    frameId: frameId,
                                    rank: rank,
                                    weeklyXp: (row['weekly_xp'] as num?)?.toInt() ?? 0,
                                    streakDays: (row['streak_days'] as num?)?.toInt() ?? 1,
                                    booksCompleted: (row['books_completed'] as num?)?.toInt() ?? 0,
                                    levelsCompleted: (row['levels_completed'] as num?)?.toInt() ?? 0,
                                    isMe: isMe,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? AppColors.antiqueGold.withValues(alpha: 0.14)
                                        : (theme.cardTheme.color ?? theme.colorScheme.surface),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isMe
                                          ? AppColors.antiqueGold
                                          : (rank <= 3
                                              ? rankColor.withValues(alpha: 0.5)
                                              : theme.dividerColor.withValues(alpha: 0.5)),
                                      width: isMe ? 1.8 : 1.1,
                                    ),
                                  ),
                                  child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: rank <= 3
                                      ? Icon(Icons.emoji_events_rounded, color: rankColor, size: 22)
                                      : Text(
                                          '#$rank',
                                          textAlign: TextAlign.center,
                                          style: AppTypography.labelMedium.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: rankColor,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 8),
                                FramedMascotAvatar(
                                  frame: frame,
                                  size: 42,
                                  monogram: name,
                                  showMascot: false,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.titleSmall.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: theme.colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          if (isMe) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: AppColors.antiqueGold,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'YOU',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodySmall.copyWith(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _metricText(row),
                                    style: AppTypography.labelSmall.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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

  Widget _buildSortChip(String label, String key, IconData icon, ThemeData theme) {
    final selected = _sortBy == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_sortBy != key) {
            setState(() => _sortBy = key);
            _loadLeaderboard();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
