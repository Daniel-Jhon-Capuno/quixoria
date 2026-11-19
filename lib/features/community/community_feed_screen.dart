import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/community_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';
import '../../models/cosmetic_item.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/follow_action_helper.dart';
import '../../shared/widgets/framed_mascot_avatar.dart';
import '../../shared/widgets/profile_banner_painter.dart';
import '../../shared/widgets/quixoria_dialog.dart';
import '../../shared/widgets/scholar_hierarchy_card.dart';

/// Live Community Feed & Wide-User Chat Tab:
/// - 2 switchable feeds: "All Users" and "Following"
/// - Follow / unfollow any user by username or email
/// - Relative timestamps beside author names + 1-hour / day separator headers
/// - `@mention` autocomplete (shows 3 followed users on `@`, filters all on typing)
/// - Highlighted `@mentions` in posts & comments + live mention notifications
/// - Theme-correlated tint & "You" badge for your own posts
/// - Author's equipped profile icon & frame + tap to open Duolingo-style Flex Profile Sheet
class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  static const List<String> _reactionEmojis = ['❤️', '🔥', '👏', '📚'];

  final TextEditingController _composerController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  int _selectedFeedTab = 0; // 0 = All Users, 1 = Following
  bool _attachActiveBook = false;
  bool _showSearchBar = false;
  String _searchQuery = '';
  String? _activeMentionQuery; // Non-null when typing @... in composer

  String _myHandle(AppState state) {
    final auth = AuthService.instance;
    if (auth.usernameHandle.trim().isNotEmpty) {
      return CommunityService.normalizeHandle(auth.usernameHandle);
    }
    if (state.profile.email.trim().isNotEmpty) {
      return CommunityService.normalizeHandle(state.profile.email);
    }
    return CommunityService.normalizeHandle(state.profile.name);
  }

  @override
  void initState() {
    super.initState();
    _composerController.addListener(_onComposerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AppState>();
      CommunityService.instance.onMentionReceived = (senderName, excerpt) {
        NotificationService().showMentionAlert(
          senderName: senderName,
          messageExcerpt: excerpt,
        );
        if (!mounted) return;
        HapticService.instance.medium();
        SoundService.instance.play(Sfx.tap);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
            content: Row(
              children: [
                const Icon(Icons.alternate_email_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$senderName mentioned you: "$excerpt"',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      };
      CommunityService.instance.init(_myHandle(state));
    });
  }

  @override
  void dispose() {
    CommunityService.instance.onMentionReceived = null;
    CommunityService.instance.unsubscribeRealtime();
    _composerController.removeListener(_onComposerChanged);
    _composerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onComposerChanged() {
    final text = _composerController.text;
    final sel = _composerController.selection;
    final cursor = sel.isValid && sel.baseOffset >= 0 ? sel.baseOffset : text.length;
    final beforeCursor = text.substring(0, cursor.clamp(0, text.length));
    final match = RegExp(r'(?:^|\s)@([A-Za-z0-9._-]*)$').firstMatch(beforeCursor);
    final nextQuery = match?.group(1)?.toLowerCase();
    if (nextQuery != _activeMentionQuery) {
      setState(() => _activeMentionQuery = nextQuery);
    }
  }

  void _insertMention(String handle) {
    final text = _composerController.text;
    final sel = _composerController.selection;
    final cursor = sel.isValid && sel.baseOffset >= 0 ? sel.baseOffset : text.length;
    final before = text.substring(0, cursor.clamp(0, text.length));
    final after = text.substring(cursor.clamp(0, text.length));
    final replaced = before.replaceFirst(RegExp(r'@([A-Za-z0-9._-]*)$'), '@$handle ');
    _composerController.value = TextEditingValue(
      text: '$replaced$after',
      selection: TextSelection.collapsed(offset: replaced.length),
    );
    HapticService.instance.light();
    setState(() => _activeMentionQuery = null);
  }

  List<String> _filteredMentionCandidates(CommunityService community) {
    if (_activeMentionQuery == null) return const [];
    final q = _activeMentionQuery!;
    final followed = community.following.toList()..sort();
    if (q.isEmpty) {
      return followed.take(3).toList();
    }
    return followed.where((h) => h.toLowerCase().contains(q)).take(6).toList();
  }

  Future<void> _sendPost(AppState state) async {
    final community = CommunityService.instance;
    final rawText = _composerController.text;
    final mentions = CommunityService.extractMentions(rawText);
    final unlockedAch = state.achievements.where((a) => a.isUnlocked).length;

    final err = await community.sendPost(
      authorHandle: _myHandle(state),
      authorName: state.profile.name,
      authorTitle: state.equippedTitle.title,
      content: rawText,
      bookTag: _attachActiveBook ? state.activeLiterature.title : null,
      authorAvatarIconId: state.profile.equippedAvatarIconId,
      authorFrameId: state.profile.equippedFrameId,
      authorBannerId: state.profile.equippedBannerId,
      authorStreak: state.profile.streakDays,
      authorXp: ScholarHierarchy.computeScholarXp(state),
      authorAchievements: unlockedAch,
      authorBooks: state.profile.booksCompleted,
    );
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.streakOrange),
      );
    } else {
      SoundService.instance.play(Sfx.tap);
      HapticService.instance.light();
      _composerController.clear();
      setState(() => _activeMentionQuery = null);
      if (mentions.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
            content: Text(
              'Notified ${mentions.map((m) => '@$m').join(', ')} live!',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        );
      }
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 45) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  String _formatTimeSeparator(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final postDay = DateTime(dt.year, dt.month, dt.day);
    final dayDiff = today.difference(postDay).inDays;

    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour12:$minute $amPm';

    if (dayDiff == 0) return 'Today • $timeStr';
    if (dayDiff == 1) return 'Yesterday • $timeStr';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day} • $timeStr';
  }

  bool _needsTimeSeparator(List<CommunityPost> posts, int index) {
    if (index == 0) return true;
    final curr = posts[index].createdAt;
    final prev = posts[index - 1].createdAt;
    final diffMinutes = prev.difference(curr).inMinutes.abs();
    final differentDay = curr.year != prev.year || curr.month != prev.month || curr.day != prev.day;
    return differentDay || diffMinutes >= 60;
  }

  Future<void> _openFollowByHandleDialog(AppState state) async {
    final myHandle = _myHandle(state);
    final result = await showQuixoriaDialog<({String input, String? err})>(
      context: context,
      builder: (_) => _FollowScholarDialog(myHandle: myHandle),
    );
    if (!mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.err ??
              (CommunityService.instance.isFollowing(result.input)
                  ? 'Now following ${result.input}!'
                  : 'Unfollowed ${result.input}.'),
        ),
        backgroundColor: result.err != null ? AppColors.streakOrange : AppColors.successGreen,
      ),
    );
  }

  void _openCommentsSheet(AppState state, CommunityPost post) {
    final myHandle = _myHandle(state);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommunityCommentsSheet(
        post: post,
        myHandle: myHandle,
        myName: state.profile.name,
        timeAgoFormatter: _timeAgo,
      ),
    );
  }

  void _openScholarFlexSheet(AppState state, CommunityPost post, String myHandle) {
    HapticService.instance.light();
    final isMine = post.authorHandle == myHandle;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScholarProfileFlexSheet(
        post: post,
        myHandle: myHandle,
        isMine: isMine,
        liveState: isMine ? state : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final border = theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.45);
    final textPrimary = isDark ? const Color(0xFFFDFBF7) : const Color(0xFF1A1C19);
    final textMuted = isDark ? const Color(0xFFC5CEC8) : const Color(0xFF5A625C);
    final myHandle = _myHandle(state);

    return AnimatedBuilder(
      animation: CommunityService.instance,
      builder: (context, _) {
        final community = CommunityService.instance;
        final cooldown = community.cooldownRemaining;
        final mentionCandidates = _filteredMentionCandidates(community);

        final basePosts = _selectedFeedTab == 0
            ? community.posts
            : community.posts
                .where(
                  (p) =>
                      p.authorHandle == myHandle ||
                      community.isFollowing(p.authorHandle),
                )
                .toList();

        final q = _searchQuery.trim().toLowerCase();
        final visiblePosts = q.isEmpty
            ? basePosts
            : basePosts.where((p) {
                final cleanQ = q.startsWith('@') || q.startsWith('#') ? q.substring(1) : q;
                return p.content.toLowerCase().contains(cleanQ) ||
                    p.authorName.toLowerCase().contains(cleanQ) ||
                    p.authorHandle.toLowerCase().contains(cleanQ) ||
                    (p.bookTag?.toLowerCase().contains(cleanQ) ?? false);
              }).toList();

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'Community',
              style: AppTypography.displaySmall.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            actions: [
              IconButton(
                key: const Key('community_search_toggle'),
                tooltip: 'Search posts, @user, or #book',
                icon: Icon(
                  _showSearchBar ? Icons.search_off_rounded : Icons.search_rounded,
                  color: primary,
                ),
                onPressed: () {
                  HapticService.instance.light();
                  setState(() {
                    _showSearchBar = !_showSearchBar;
                    if (!_showSearchBar) {
                      _searchController.clear();
                      _searchQuery = '';
                    }
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ElevatedButton.icon(
                  key: const Key('community_follow_button'),
                  onPressed: () => _openFollowByHandleDialog(state),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                  label: const Text('Follow'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: isDark ? const Color(0xFF141414) : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Smart Search Bar (filter by keyword, @user, or #book)
                if (_showSearchBar)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                    child: TextField(
                      key: const Key('community_search_input'),
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search posts, @user, or #book…',
                        prefixIcon: Icon(Icons.search_rounded, size: 19, color: primary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),

                // 2 Switchable Tabs: All Users vs Following
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: border, width: 2.0),
                    ),
                    child: Row(
                      children: [
                        _feedTabButton(
                          label: 'All Users',
                          index: 0,
                          primary: primary,
                          textMuted: textMuted,
                          isDark: isDark,
                        ),
                        _feedTabButton(
                          label: 'Following (${community.following.length})',
                          index: 1,
                          primary: primary,
                          textMuted: textMuted,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),

                // Live Feed List with 1-Hour / Day Time Separators
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => community.refreshFromCloud(myHandle),
                    child: visiblePosts.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(32),
                            children: [
                              const SizedBox(height: 40),
                              Icon(
                                _selectedFeedTab == 0
                                    ? Icons.forum_rounded
                                    : Icons.group_add_rounded,
                                size: 54,
                                color: primary.withValues(alpha: 0.7),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _selectedFeedTab == 0
                                    ? 'Be the first to post!'
                                    : 'No posts from followed scholars yet',
                                textAlign: TextAlign.center,
                                style: AppTypography.titleMedium.copyWith(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _selectedFeedTab == 0
                                    ? 'Share a quote or mention a friend with @ below.'
                                    : 'Tap Follow above to add scholars by username or email.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall.copyWith(color: textMuted),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: visiblePosts.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (_, idx) {
                              final post = visiblePosts[idx];
                              final showSep = _needsTimeSeparator(visiblePosts, idx);
                              final card = _buildPostCard(
                                post: post,
                                state: state,
                                myHandle: myHandle,
                                cardBg: cardBg,
                                border: border,
                                primary: primary,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                                isDark: isDark,
                              );
                              if (!showSep) return card;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: idx == 0 ? 2 : 6, bottom: 10),
                                    child: Row(
                                      children: [
                                        Expanded(child: Divider(color: border.withValues(alpha: 0.65))),
                                        Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 10),
                                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: cardBg,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: border.withValues(alpha: 0.7)),
                                          ),
                                          child: Text(
                                            _formatTimeSeparator(post.createdAt),
                                            style: AppTypography.labelSmall.copyWith(
                                              color: textMuted,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 10.5,
                                            ),
                                          ),
                                        ),
                                        Expanded(child: Divider(color: border.withValues(alpha: 0.65))),
                                      ],
                                    ),
                                  ),
                                  card,
                                ],
                              );
                            },
                          ),
                  ),
                ),

                // @Mention Autocomplete Strip (shows 3 followed users on @, filters more as you type)
                if (_activeMentionQuery != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E222B) : const Color(0xFFF3EFE6),
                      border: Border(top: BorderSide(color: primary.withValues(alpha: 0.45), width: 1.5)),
                    ),
                    child: mentionCandidates.isEmpty
                        ? Text(
                            community.following.isEmpty
                                ? 'Follow scholars first to @mention them!'
                                : 'No followed scholar matches "@$_activeMentionQuery"',
                            style: AppTypography.labelSmall.copyWith(color: textMuted),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _activeMentionQuery!.isEmpty
                                    ? 'Mention a followed scholar (type to filter more):'
                                    : 'Matching followed scholars:',
                                style: AppTypography.labelSmall.copyWith(
                                  color: primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: mentionCandidates.map((handle) {
                                  return GestureDetector(
                                    onTap: () => _insertMention(handle),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: primary.withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: primary.withValues(alpha: 0.55)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.alternate_email_rounded, size: 13, color: primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            handle,
                                            style: AppTypography.labelSmall.copyWith(
                                              color: textPrimary,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                  ),

                // Bottom Live Message Composer with 5-Second Anti-Spam Cooldown
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border(top: BorderSide(color: border, width: 1.8)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onTap: () => setState(() => _attachActiveBook = !_attachActiveBook),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _attachActiveBook
                                      ? primary.withValues(alpha: 0.16)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _attachActiveBook ? primary : border,
                                    width: 1.4,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.menu_book_rounded,
                                      size: 13,
                                      color: _attachActiveBook ? primary : textMuted,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        _attachActiveBook
                                            ? state.activeLiterature.title
                                            : 'Tag current book',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.labelSmall.copyWith(
                                          color: _attachActiveBook ? primary : textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (cooldown > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Anti-spam: ${cooldown}s',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.streakOrange,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('community_post_input'),
                              controller: _composerController,
                              maxLines: 2,
                              minLines: 1,
                              decoration: const InputDecoration(
                                hintText: 'Post live or type @ to mention…',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            key: const Key('community_send_button'),
                            onPressed: cooldown > 0 ? null : () => _sendPost(state),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: isDark ? const Color(0xFF141414) : Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              cooldown > 0 ? '${cooldown}s' : 'Post',
                              style: AppTypography.labelLarge.copyWith(
                                color: isDark ? const Color(0xFF141414) : Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _feedTabButton({
    required String label,
    required int index,
    required Color primary,
    required Color textMuted,
    required bool isDark,
  }) {
    final active = _selectedFeedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.instance.light();
          setState(() => _selectedFeedTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: active
                  ? (isDark ? const Color(0xFF141414) : Colors.white)
                  : textMuted,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard({
    required CommunityPost post,
    required AppState state,
    required String myHandle,
    required Color cardBg,
    required Color border,
    required Color primary,
    required Color textPrimary,
    required Color textMuted,
    required bool isDark,
  }) {
    final community = CommunityService.instance;
    final isMine = post.authorHandle == myHandle;
    final isDeleted = post.authorTitle == 'deleted';
    final followingAuthor = community.isFollowing(post.authorHandle);

    if (isDeleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: cardBg.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.delete_outline_rounded, size: 17, color: textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                post.content,
                style: AppTypography.bodySmall.copyWith(
                  color: textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            Text(
              _timeAgo(post.createdAt),
              style: AppTypography.labelSmall.copyWith(color: textMuted),
            ),
          ],
        ),
      );
    }

    // Resolve author's equipped frame & profile icon (use live state for your own posts!)
    final AvatarFrame authorFrame = isMine
        ? state.equippedFrame
        : CosmeticCatalog.frameById(post.authorFrameId);
    final String authorIconId = isMine
        ? state.profile.equippedAvatarIconId
        : post.authorAvatarIconId;

    // Theme-correlated visual tint for your own posts vs neutral for other users
    final Color effectiveBg = isMine
        ? Color.alphaBlend(primary.withValues(alpha: isDark ? 0.16 : 0.09), cardBg)
        : cardBg;
    final Color effectiveBorder = isMine ? primary.withValues(alpha: 0.68) : border;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: effectiveBorder, width: isMine ? 2.2 : 2.0),
        boxShadow: [
          BoxShadow(
            color: (isMine ? primary : border).withValues(alpha: isMine ? 0.28 : 0.45),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Tappable Author Avatar showing their equipped Profile Icon & Frame
              GestureDetector(
                onTap: () => _openScholarFlexSheet(state, post, myHandle),
                child: FramedMascotAvatar(
                  frame: authorFrame,
                  size: 42,
                  showMascot: true,
                  avatarIconId: authorIconId,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openScholarFlexSheet(state, post, myHandle),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleSmall.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (isMine) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'You',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF141414) : Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                          Text(
                            '• ${_timeAgo(post.createdAt)}',
                            style: AppTypography.labelSmall.copyWith(
                              color: isMine ? primary : textMuted,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '@${post.authorHandle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(color: textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              if (isMine)
                IconButton(
                  tooltip: 'Delete post',
                  icon: Icon(Icons.delete_outline_rounded, size: 18, color: textMuted),
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    HapticService.instance.light();
                    final confirmed = await showQuixoriaDialog<bool>(
                      context: context,
                      builder: (dlgCtx) {
                        final dlgTheme = Theme.of(dlgCtx);
                        final dlgDark = dlgTheme.brightness == Brightness.dark;
                        return AlertDialog(
                          backgroundColor: dlgDark ? const Color(0xFF1E2128) : const Color(0xFFFAF8F4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(color: AppColors.energyRed.withValues(alpha: 0.45), width: 2.0),
                          ),
                          title: Text(
                            'Delete Message?',
                            style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900),
                          ),
                          content: Text(
                            'Are you sure you want to delete this message from the feed?',
                            style: AppTypography.bodySmall,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dlgCtx).pop(false),
                              child: const Text('Back'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.energyRed,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.of(dlgCtx).pop(true),
                              child: const Text('Confirm'),
                            ),
                          ],
                        );
                      },
                    );
                    if (confirmed == true) {
                      await community.deletePost(postId: post.id, authorHandle: myHandle);
                    }
                  },
                )
              else
                TextButton(
                  onPressed: () {
                    FollowActionHelper.toggleFollowWithConfirm(
                      context,
                      myHandle: myHandle,
                      targetHandle: post.authorHandle,
                      displayName: post.authorName,
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: followingAuthor
                        ? border.withValues(alpha: 0.25)
                        : primary.withValues(alpha: 0.16),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    followingAuthor ? 'Following' : 'Follow',
                    style: AppTypography.labelSmall.copyWith(
                      color: followingAuthor ? textMuted : primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Rich Post Text with Highlighted @Mentions
          _MentionRichText(
            text: post.content,
            myHandle: myHandle,
            baseStyle: AppTypography.bodyMedium.copyWith(color: textPrimary),
            accentColor: primary,
          ),
          if (post.bookTag != null && post.bookTag!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.antiqueGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '📖 ${post.bookTag}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.antiqueGold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Reactions + Comments Row
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final emoji in _reactionEmojis)
                GestureDetector(
                  onTap: () {
                    HapticService.instance.light();
                    community.toggleReaction(
                      postId: post.id,
                      userHandle: myHandle,
                      emoji: emoji,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: post.hasReacted(emoji, myHandle)
                          ? primary.withValues(alpha: 0.18)
                          : border.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: post.hasReacted(emoji, myHandle)
                            ? primary
                            : Colors.transparent,
                        width: 1.4,
                      ),
                    ),
                    child: Text(
                      '$emoji ${post.reactionCount(emoji) > 0 ? post.reactionCount(emoji) : ''}'.trim(),
                      style: AppTypography.labelSmall.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _openCommentsSheet(state, post),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: border.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 14, color: textMuted),
                      const SizedBox(width: 5),
                      Text(
                        '${post.comments.length}',
                        style: AppTypography.labelSmall.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Renders text with `@mentions` highlighted cleanly; mentions of the current
/// user get a warm gold highlight pill so they pop right off the feed.
class _MentionRichText extends StatelessWidget {
  final String text;
  final String myHandle;
  final TextStyle baseStyle;
  final Color accentColor;

  const _MentionRichText({
    required this.text,
    required this.myHandle,
    required this.baseStyle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final regex = RegExp(r'@[A-Za-z0-9._-]+');
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      final rawMention = match.group(0)!;
      final isMe = CommunityService.normalizeHandle(rawMention) == myHandle;
      final badgeColor = isMe ? AppColors.antiqueGold : accentColor;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: isMe ? 0.24 : 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: badgeColor.withValues(alpha: 0.55),
                width: 1.1,
              ),
            ),
            child: Text(
              rawMention,
              style: baseStyle.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w900,
                fontSize: (baseStyle.fontSize ?? 14) - 0.5,
              ),
            ),
          ),
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return Text.rich(TextSpan(style: baseStyle, children: spans));
  }
}

/// Duolingo-style Scholar Flex Profile Sheet opened when tapping any user's
/// avatar or name in the Community Feed. Showcases their banner, framed icon,
/// scholar tier, Follow/Following toggle, streak, XP, achievements & badges!
class _ScholarProfileFlexSheet extends StatelessWidget {
  final CommunityPost post;
  final String myHandle;
  final bool isMine;
  final AppState? liveState;

  const _ScholarProfileFlexSheet({
    required this.post,
    required this.myHandle,
    required this.isMine,
    this.liveState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF17191E) : const Color(0xFFFAF8F4);
    final cardBg = isDark ? const Color(0xFF21242B) : Colors.white;
    final border = theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.45);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1C19);
    final textMuted = isDark ? Colors.white70 : const Color(0xFF5A625C);
    final primary = theme.colorScheme.primary;

    final String bannerId = liveState?.profile.equippedBannerId ?? post.authorBannerId;
    final AvatarFrame frame = liveState != null
        ? liveState!.equippedFrame
        : CosmeticCatalog.frameById(post.authorFrameId);
    final String iconId = liveState?.profile.equippedAvatarIconId ?? post.authorAvatarIconId;
    final int streak = liveState?.profile.streakDays ?? post.authorStreak;
    final int xp = liveState != null ? ScholarHierarchy.computeScholarXp(liveState!) : post.authorXp;
    final int achievements = liveState != null
        ? liveState!.achievements.where((a) => a.isUnlocked).length
        : post.authorAchievements;
    final int books = liveState?.profile.booksCompleted ?? post.authorBooks;
    final tier = ScholarHierarchy.currentTierForXp(xp);

    return AnimatedBuilder(
      animation: CommunityService.instance,
      builder: (ctx, _) {
        final isFollowing = CommunityService.instance.isFollowing(post.authorHandle);
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.84,
          ),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: tier.color.withValues(alpha: 0.55), width: 2.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Scenic Banner + Avatar Header
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      ProfileBannerBackground(bannerId: bannerId, height: 118),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(alpha: 0.4),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 64),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: sheetBg,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: tier.color.withValues(alpha: 0.42),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: FramedMascotAvatar(
                            frame: frame,
                            size: 86,
                            showMascot: true,
                            avatarIconId: iconId,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    child: Column(
                      children: [
                        Text(
                          post.authorName,
                          textAlign: TextAlign.center,
                          style: AppTypography.displaySmall.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${post.authorHandle}',
                          style: AppTypography.bodySmall.copyWith(color: textMuted),
                        ),
                        const SizedBox(height: 10),
                        // Title + Tier Rank Flex Badges
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                              decoration: BoxDecoration(
                                color: tier.color.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: tier.color, width: 1.4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(tier.icon, size: 14, color: tier.color),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Tier ${tier.roman} • ${tier.title}',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: tier.color,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                post.authorTitle,
                                style: AppTypography.labelSmall.copyWith(
                                  color: primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!isMine) ...[
                          const SizedBox(height: 16),
                          DuoButton(
                            text: isFollowing ? 'Following' : 'Follow Scholar',
                            icon: isFollowing
                                ? Icons.check_circle_rounded
                                : Icons.person_add_alt_1_rounded,
                            variant: isFollowing
                                ? DuoButtonVariant.outline
                                : DuoButtonVariant.primary,
                            height: 46,
                            onPressed: () {
                              FollowActionHelper.toggleFollowWithConfirm(
                                context,
                                myHandle: myHandle,
                                targetHandle: post.authorHandle,
                                displayName: post.authorName,
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 18),
                        // Flex Stats Grid (Streak, XP, Achievements, Books)
                        Row(
                          children: [
                            Expanded(
                              child: _flexStatTile(
                                icon: Icons.local_fire_department_rounded,
                                color: AppColors.streakOrange,
                                value: '$streak',
                                label: 'Day Streak',
                                cardBg: cardBg,
                                border: border,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _flexStatTile(
                                icon: Icons.bolt_rounded,
                                color: AppColors.antiqueGold,
                                value: '$xp',
                                label: 'Scholar XP',
                                cardBg: cardBg,
                                border: border,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _flexStatTile(
                                icon: Icons.emoji_events_rounded,
                                color: const Color(0xFF9B59B6),
                                value: '$achievements',
                                label: 'Achievements',
                                cardBg: cardBg,
                                border: border,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _flexStatTile(
                                icon: Icons.auto_stories_rounded,
                                color: AppColors.gemCyan,
                                value: '$books',
                                label: 'Books Read',
                                cardBg: cardBg,
                                border: border,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        // Showcase Badges Strip
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'HONOR BADGES',
                            style: AppTypography.labelSmall.copyWith(
                              color: textMuted,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _badgeChip(
                              icon: tier.icon,
                              label: tier.title,
                              color: tier.color,
                            ),
                            if (streak >= 3)
                              _badgeChip(
                                icon: Icons.local_fire_department_rounded,
                                label: '${streak}d Flame Keeper',
                                color: AppColors.streakOrange,
                              ),
                            if (achievements > 0)
                              _badgeChip(
                                icon: Icons.military_tech_rounded,
                                label: '$achievements Medals',
                                color: AppColors.antiqueGold,
                              ),
                            if (books > 0)
                              _badgeChip(
                                icon: Icons.menu_book_rounded,
                                label: '$books Classics',
                                color: AppColors.successGreen,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _flexStatTile({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    required Color cardBg,
    required Color border,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.42), width: 1.6),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(color: textMuted, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Owns and safely disposes its own TextEditingController inside State.dispose()
/// so closing the Follow dialog never triggers a disposed-controller exception.
class _FollowScholarDialog extends StatefulWidget {
  final String myHandle;

  const _FollowScholarDialog({required this.myHandle});

  @override
  State<_FollowScholarDialog> createState() => _FollowScholarDialogState();
}

class _FollowScholarDialogState extends State<_FollowScholarDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final suggestedHandles = CommunityService.instance.posts
        .map((p) => (handle: p.authorHandle, name: p.authorName))
        .where((e) => e.handle != widget.myHandle && e.handle.isNotEmpty)
        .fold<Map<String, String>>({}, (acc, e) {
          acc.putIfAbsent(e.handle, () => e.name);
          return acc;
        })
        .entries
        .take(4)
        .toList();

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E2128) : const Color(0xFFFAF8F4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Follow Scholar',
        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter a username or email:',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '@username or email@domain.com',
              prefixIcon: Icon(Icons.person_add_alt_1_rounded),
            ),
          ),
          if (suggestedHandles.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Suggested Scholars',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final s in suggestedHandles)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${s.value} (@${s.key})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await FollowActionHelper.toggleFollowWithConfirm(
                          context,
                          myHandle: widget.myHandle,
                          targetHandle: s.key,
                          displayName: s.value,
                        );
                        if (mounted) setState(() {});
                      },
                      child: Text(
                        CommunityService.instance.isFollowing(s.key)
                            ? 'Following'
                            : 'Follow',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () async {
            final input = _controller.text.trim();
            final err = await CommunityService.instance.toggleFollow(
              myHandle: widget.myHandle,
              targetInput: input,
            );
            if (!context.mounted) return;
            Navigator.of(context).pop((input: input, err: err));
          },
          child: const Text('Follow'),
        ),
      ],
    );
  }
}

/// Dedicated StatefulWidget for the Comments Bottom Sheet so its
/// TextEditingController is disposed only when the widget is unmounted
/// (after the modal exit animation finishes), preventing any crash or overflow.
class _CommunityCommentsSheet extends StatefulWidget {
  final CommunityPost post;
  final String myHandle;
  final String myName;
  final String Function(DateTime) timeAgoFormatter;

  const _CommunityCommentsSheet({
    required this.post,
    required this.myHandle,
    required this.myName,
    required this.timeAgoFormatter,
  });

  @override
  State<_CommunityCommentsSheet> createState() => _CommunityCommentsSheetState();
}

class _CommunityCommentsSheetState extends State<_CommunityCommentsSheet> {
  final TextEditingController _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CommunityService.instance,
      builder: (ctx, _) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        final community = CommunityService.instance;
        final latestPost = community.posts.firstWhere(
          (p) => p.id == widget.post.id,
          orElse: () => widget.post,
        );
        final cooldown = community.cooldownRemaining;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.72,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF171A20) : const Color(0xFFFAF8F4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.4),
                width: 2.0,
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Comments (${latestPost.comments.length})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.35)),
                  Expanded(
                    child: latestPost.comments.isEmpty
                        ? Center(
                            child: Text(
                              'No comments yet. Start the conversation!',
                              style: AppTypography.bodySmall,
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: latestPost.comments.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final c = latestPost.comments[i];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.dividerColor.withValues(alpha: 0.35),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            c.authorName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.labelLarge.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            '@${c.authorHandle} • ${widget.timeAgoFormatter(c.createdAt)}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.labelSmall.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    _MentionRichText(
                                      text: c.content,
                                      myHandle: widget.myHandle,
                                      baseStyle: AppTypography.bodySmall,
                                      accentColor: theme.colorScheme.primary,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  // Comment input with 5s anti-spam cooldown
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('community_comment_input'),
                            controller: _commentCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Write a comment…',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          key: const Key('community_comment_reply_btn'),
                          onPressed: cooldown > 0
                              ? null
                              : () async {
                                  final err = await community.addComment(
                                    postId: latestPost.id,
                                    authorHandle: widget.myHandle,
                                    authorName: widget.myName,
                                    content: _commentCtrl.text,
                                  );
                                  if (mounted && err == null) {
                                    _commentCtrl.clear();
                                    HapticService.instance.light();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          child: Text(cooldown > 0 ? '${cooldown}s' : 'Reply'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
