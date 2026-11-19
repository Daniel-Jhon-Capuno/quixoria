import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';
import 'supabase_service.dart';

class CommunityComment {
  final String id;
  final String postId;
  final String authorHandle;
  final String authorName;
  final String content;
  final DateTime createdAt;

  const CommunityComment({
    required this.id,
    required this.postId,
    required this.authorHandle,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'post_id': postId,
        'author_handle': authorHandle,
        'author_name': authorName,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };

  factory CommunityComment.fromJson(Map<String, dynamic> json) => CommunityComment(
        id: (json['id'] ?? '').toString(),
        postId: (json['post_id'] ?? '').toString(),
        authorHandle: (json['author_handle'] ?? '').toString(),
        authorName: (json['author_name'] ?? 'Scholar').toString(),
        content: (json['content'] ?? '').toString(),
        createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
      );
}

class CommunityPost {
  final String id;
  final String authorHandle;
  final String authorName;
  final String authorTitle;
  final String content;
  final String? bookTag;
  final DateTime createdAt;
  final List<CommunityComment> comments;
  final Map<String, Set<String>> reactionsByEmoji; // emoji -> set of userHandles
  final String authorAvatarIconId;
  final String authorFrameId;
  final String authorBannerId;
  final int authorStreak;
  final int authorXp;
  final int authorAchievements;
  final int authorBooks;

  const CommunityPost({
    required this.id,
    required this.authorHandle,
    required this.authorName,
    required this.authorTitle,
    required this.content,
    this.bookTag,
    required this.createdAt,
    this.comments = const [],
    this.reactionsByEmoji = const {},
    this.authorAvatarIconId = 'don_quixote',
    this.authorFrameId = 'frame_parchment',
    this.authorBannerId = 'banner_classic',
    this.authorStreak = 1,
    this.authorXp = 0,
    this.authorAchievements = 0,
    this.authorBooks = 0,
  });

  int reactionCount(String emoji) => reactionsByEmoji[emoji]?.length ?? 0;

  bool hasReacted(String emoji, String userHandle) =>
      reactionsByEmoji[emoji]?.contains(userHandle.toLowerCase()) ?? false;

  Map<String, dynamic> toJson() => {
        'id': id,
        'author_handle': authorHandle,
        'author_name': authorName,
        'author_title': authorTitle,
        'content': content,
        'book_tag': bookTag,
        'created_at': createdAt.toIso8601String(),
        'comments': comments.map((c) => c.toJson()).toList(),
        'reactions': reactionsByEmoji.map((k, v) => MapEntry(k, v.toList())),
        'author_avatar_icon_id': authorAvatarIconId,
        'author_frame_id': authorFrameId,
        'author_banner_id': authorBannerId,
        'author_streak': authorStreak,
        'author_xp': authorXp,
        'author_achievements': authorAchievements,
        'author_books': authorBooks,
      };

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final rawComments = (json['comments'] as List?) ?? const [];
    final rawReactions = (json['reactions'] as Map?) ?? const {};
    final parsedReactions = <String, Set<String>>{};
    rawReactions.forEach((k, v) {
      if (v is List) {
        parsedReactions[k.toString()] = v.map((e) => e.toString().toLowerCase()).toSet();
      }
    });
    return CommunityPost(
      id: (json['id'] ?? '').toString(),
      authorHandle: (json['author_handle'] ?? '').toString().toLowerCase(),
      authorName: (json['author_name'] ?? 'Scholar').toString(),
      authorTitle: (json['author_title'] ?? 'Scholar').toString(),
      content: (json['content'] ?? '').toString(),
      bookTag: json['book_tag']?.toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
      comments: rawComments
          .whereType<Map>()
          .map((m) => CommunityComment.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      reactionsByEmoji: parsedReactions,
      authorAvatarIconId: (json['author_avatar_icon_id'] ?? 'don_quixote').toString(),
      authorFrameId: (json['author_frame_id'] ?? 'frame_parchment').toString(),
      authorBannerId: (json['author_banner_id'] ?? 'banner_classic').toString(),
      authorStreak: (json['author_streak'] as num?)?.toInt() ?? 1,
      authorXp: (json['author_xp'] as num?)?.toInt() ?? 0,
      authorAchievements: (json['author_achievements'] as num?)?.toInt() ?? 0,
      authorBooks: (json['author_books'] as num?)?.toInt() ?? 0,
    );
  }

  CommunityPost copyWith({
    List<CommunityComment>? comments,
    Map<String, Set<String>>? reactionsByEmoji,
  }) {
    return CommunityPost(
      id: id,
      authorHandle: authorHandle,
      authorName: authorName,
      authorTitle: authorTitle,
      content: content,
      bookTag: bookTag,
      createdAt: createdAt,
      comments: comments ?? this.comments,
      reactionsByEmoji: reactionsByEmoji ?? this.reactionsByEmoji,
      authorAvatarIconId: authorAvatarIconId,
      authorFrameId: authorFrameId,
      authorBannerId: authorBannerId,
      authorStreak: authorStreak,
      authorXp: authorXp,
      authorAchievements: authorAchievements,
      authorBooks: authorBooks,
    );
  }
}

/// Manages Live Community Feed posts, comments, reactions, username/email
/// follows, Supabase Realtime subscriptions, and the 5-second anti-spam cooldown.
class CommunityService extends ChangeNotifier {
  static final CommunityService instance = CommunityService._();
  CommunityService._();

  static const int spamCooldownSeconds = 5;
  static const String _postsCacheKey = 'quixoria_community_posts_v1';
  static const String _followsCacheKey = 'quixoria_community_follows_v1';
  static const String _seenFollowersCacheKey = 'quixoria_seen_followers_v1';

  final List<CommunityPost> _posts = [];
  final Set<String> _following = {};
  final Set<String> _followers = {};
  final Set<String> _seenFollowerHandles = {};

  bool _isLoading = false;
  bool _initialized = false;
  bool enableRealtime = true;
  DateTime? _lastSentAt;
  Timer? _cooldownTimer;
  RealtimeChannel? _channel;
  final Set<String> _seenMentionIds = {};

  /// Optional callback invoked live when a new post or comment mentions the
  /// current user (`@myHandle`).
  void Function(String senderName, String excerpt)? onMentionReceived;

  /// Optional callback invoked when a real user follows the current user.
  void Function(String followerHandle, String followerName)? onNewFollowerReceived;

  /// Optional callback invoked whenever the set of mutual follows changes.
  void Function(Set<String> mutualHandles)? onMutualsChanged;

  /// Extracts all normalized `@handle` mentions from [text].
  static Set<String> extractMentions(String text) {
    final regex = RegExp(r'@([A-Za-z0-9._-]+)');
    return regex
        .allMatches(text)
        .map((m) => normalizeHandle(m.group(1) ?? ''))
        .where((h) => h.isNotEmpty)
        .toSet();
  }

  List<CommunityPost> get posts => List.unmodifiable(_posts);
  Set<String> get following => Set.unmodifiable(_following);
  Set<String> get followers => Set.unmodifiable(_followers);
  Set<String> get mutualHandles => _following.intersection(_followers);
  bool isFollowedBy(String handle) => _followers.contains(normalizeHandle(handle));
  bool isMutual(String handle) => isFollowing(handle) && isFollowedBy(handle);
  bool get isLoading => _isLoading;

  /// Resolves a readable display name for a real Supabase handle from known
  /// community posts, or formats the handle cleanly.
  String displayNameForHandle(String handle) {
    final norm = normalizeHandle(handle);
    for (final p in _posts) {
      if (p.authorHandle == norm && p.authorName.trim().isNotEmpty) {
        return p.authorName.trim();
      }
      for (final c in p.comments) {
        if (normalizeHandle(c.authorHandle) == norm && c.authorName.trim().isNotEmpty) {
          return c.authorName.trim();
        }
      }
    }
    if (norm.contains('@')) {
      final local = norm.split('@').first;
      if (local.isNotEmpty) return local;
    }
    return norm.isEmpty ? 'Scholar' : norm;
  }

  int get cooldownRemaining {
    if (_lastSentAt == null) return 0;
    final elapsed = DateTime.now().difference(_lastSentAt!).inSeconds;
    return (spamCooldownSeconds - elapsed).clamp(0, spamCooldownSeconds);
  }

  bool get isOnCooldown => cooldownRemaining > 0;

  static String normalizeHandle(String raw) {
    final clean = raw.trim().toLowerCase();
    if (clean.startsWith('@')) return clean.substring(1);
    return clean;
  }

  Future<void> init(String myHandle) async {
    final normalizedMe = normalizeHandle(myHandle);
    if (!_initialized) {
      _initialized = true;
      await _loadLocalCache();
    }
    final synced = await refreshFromCloud(normalizedMe);
    if (synced) {
      _subscribeRealtime(normalizedMe);
    }
  }

  Future<void> _loadLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawPosts = prefs.getString(_postsCacheKey);
      if (rawPosts != null && rawPosts.isNotEmpty) {
        final decoded = jsonDecode(rawPosts);
        if (decoded is List) {
          _posts
            ..clear()
            ..addAll(
              decoded
                  .whereType<Map>()
                  .map((m) => CommunityPost.fromJson(Map<String, dynamic>.from(m))),
            );
        }
      }
      final rawFollows = prefs.getStringList(_followsCacheKey);
      if (rawFollows != null) {
        _following
          ..clear()
          ..addAll(rawFollows.map(normalizeHandle));
      }
      final rawSeenFollowers = prefs.getStringList(_seenFollowersCacheKey);
      if (rawSeenFollowers != null) {
        _seenFollowerHandles
          ..clear()
          ..addAll(rawSeenFollowers.map(normalizeHandle));
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _postsCacheKey,
        jsonEncode(_posts.take(60).map((p) => p.toJson()).toList()),
      );
      await prefs.setStringList(_followsCacheKey, _following.toList());
      await prefs.setStringList(_seenFollowersCacheKey, _seenFollowerHandles.toList());
    } catch (_) {}
  }

  Future<bool> refreshFromCloud(String myHandle) async {
    if (!SupabaseService.instance.isConfigured) return false;
    _isLoading = true;
    notifyListeners();
    var succeeded = false;
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return false;
      final postsRows = await client
          .from('community_posts')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      final commentsRows = await client
          .from('community_comments')
          .select()
          .order('created_at', ascending: true)
          .limit(200);
      final reactionsRows = await client.from('community_reactions').select().limit(500);
      final followsRows = await client.from('user_follows').select().limit(500);

      final commentsByPost = <String, List<CommunityComment>>{};
      for (final row in (commentsRows as List)) {
        final c = CommunityComment.fromJson(Map<String, dynamic>.from(row as Map));
        commentsByPost.putIfAbsent(c.postId, () => []).add(c);
      }

      final reactionsByPost = <String, Map<String, Set<String>>>{};
      for (final row in (reactionsRows as List)) {
        final map = Map<String, dynamic>.from(row as Map);
        final pid = (map['post_id'] ?? '').toString();
        final emoji = (map['emoji'] ?? '').toString();
        final user = normalizeHandle((map['user_handle'] ?? '').toString());
        if (pid.isNotEmpty && emoji.isNotEmpty && user.isNotEmpty) {
          reactionsByPost.putIfAbsent(pid, () => {});
          reactionsByPost[pid]!.putIfAbsent(emoji, () => <String>{}).add(user);
        }
      }

      final loadedPosts = <CommunityPost>[];
      for (final row in (postsRows as List)) {
        final base = CommunityPost.fromJson(Map<String, dynamic>.from(row as Map));
        loadedPosts.add(
          base.copyWith(
            comments: commentsByPost[base.id] ?? const [],
            reactionsByEmoji: reactionsByPost[base.id] ?? const {},
          ),
        );
      }

      final normMe = normalizeHandle(myHandle);
      final newFollowing = <String>{};
      final newFollowers = <String>{};
      for (final row in (followsRows as List)) {
        final map = Map<String, dynamic>.from(row as Map);
        final f = normalizeHandle((map['follower_handle'] ?? '').toString());
        final t = normalizeHandle((map['target_handle'] ?? '').toString());
        if (f == normMe && t.isNotEmpty) newFollowing.add(t);
        if (t == normMe && f.isNotEmpty) newFollowers.add(f);
      }

      final previousIds = _posts.map((p) => p.id).toSet();
      final hadInitialPosts = _posts.isNotEmpty;

      _posts
        ..clear()
        ..addAll(loadedPosts);
      _following
        ..clear()
        ..addAll(newFollowing);
      _followers
        ..clear()
        ..addAll(newFollowers);

      // Notify the user when a real scholar follows them (if not yet seen & not yet mutual)
      if (normMe.isNotEmpty) {
        for (final follower in newFollowers) {
          if (follower != normMe && !_seenFollowerHandles.contains(follower)) {
            _seenFollowerHandles.add(follower);
            if (!newFollowing.contains(follower)) {
              onNewFollowerReceived?.call(follower, displayNameForHandle(follower));
            }
          }
        }
      }
      onMutualsChanged?.call(mutualHandles);

      // Trigger live mention notification for newly arrived posts mentioning me
      if (hadInitialPosts && normMe.isNotEmpty && onMentionReceived != null) {
        for (final p in loadedPosts) {
          if (!previousIds.contains(p.id) &&
              p.authorHandle != normMe &&
              !_seenMentionIds.contains(p.id) &&
              extractMentions(p.content).contains(normMe)) {
            _seenMentionIds.add(p.id);
            onMentionReceived?.call(p.authorName, p.content);
          }
        }
      }
      await _saveLocalCache();
      succeeded = true;
    } catch (e) {
      debugPrint('[CommunityService] Cloud refresh fallback: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return succeeded;
  }

  void _subscribeRealtime(String myHandle) {
    if (!enableRealtime || !SupabaseService.instance.isConfigured) return;
    if (_channel != null) return;
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return;
      _channel = client
          .channel('public:quixoria_community_live')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'community_posts',
            callback: (_) => refreshFromCloud(myHandle),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'community_comments',
            callback: (_) => refreshFromCloud(myHandle),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'community_reactions',
            callback: (_) => refreshFromCloud(myHandle),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'user_follows',
            callback: (_) => refreshFromCloud(myHandle),
          )
          .subscribe();
    } catch (e) {
      debugPrint('[CommunityService] Realtime subscribe notice: $e');
    }
  }

  void _startCooldown() {
    _lastSentAt = DateTime.now();
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (cooldownRemaining <= 0) {
        timer.cancel();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  /// Sends a live post to the Community Feed. Returns an error string if blocked
  /// (e.g. empty message or 5-second anti-spam cooldown active), or null on success.
  Future<String?> sendPost({
    required String authorHandle,
    required String authorName,
    required String authorTitle,
    required String content,
    String? bookTag,
    String authorAvatarIconId = 'don_quixote',
    String authorFrameId = 'frame_parchment',
    String authorBannerId = 'banner_classic',
    int authorStreak = 1,
    int authorXp = 0,
    int authorAchievements = 0,
    int authorBooks = 0,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return 'Write something first.';
    if (isOnCooldown) {
      return 'Slow down! Wait ${cooldownRemaining}s before sending again.';
    }

    final post = CommunityPost(
      id: 'post_${DateTime.now().microsecondsSinceEpoch}',
      authorHandle: normalizeHandle(authorHandle),
      authorName: authorName.trim().isEmpty ? 'Scholar' : authorName.trim(),
      authorTitle: authorTitle,
      content: trimmed,
      bookTag: bookTag,
      createdAt: DateTime.now(),
      authorAvatarIconId: authorAvatarIconId,
      authorFrameId: authorFrameId,
      authorBannerId: authorBannerId,
      authorStreak: authorStreak,
      authorXp: authorXp,
      authorAchievements: authorAchievements,
      authorBooks: authorBooks,
    );

    _posts.insert(0, post);
    _startCooldown();
    await _saveLocalCache();

    if (SupabaseService.instance.isConfigured) {
      try {
        final client = SupabaseService.instance.client;
        if (client != null) {
          final basePayload = {
            'id': post.id,
            'author_handle': post.authorHandle,
            'author_name': post.authorName,
            'author_title': post.authorTitle,
            'content': post.content,
            'book_tag': post.bookTag,
            'created_at': post.createdAt.toIso8601String(),
          };
          try {
            await client.from('community_posts').insert({
              ...basePayload,
              'author_avatar_icon_id': post.authorAvatarIconId,
              'author_frame_id': post.authorFrameId,
              'author_banner_id': post.authorBannerId,
              'author_streak': post.authorStreak,
              'author_xp': post.authorXp,
              'author_achievements': post.authorAchievements,
              'author_books': post.authorBooks,
            });
          } catch (_) {
            // Fallback for older DB schema without cosmetic columns
            await client.from('community_posts').insert(basePayload);
          }
        }
      } catch (e) {
        debugPrint('[CommunityService] Cloud post insert notice: $e');
      }
    }
    return null;
  }

  /// Adds a live comment to a post, respecting the 5-second anti-spam cooldown.
  Future<String?> addComment({
    required String postId,
    required String authorHandle,
    required String authorName,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return 'Write a comment first.';
    if (isOnCooldown) {
      return 'Wait ${cooldownRemaining}s before commenting again.';
    }

    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return 'Post not found.';

    final comment = CommunityComment(
      id: 'cmt_${DateTime.now().microsecondsSinceEpoch}',
      postId: postId,
      authorHandle: normalizeHandle(authorHandle),
      authorName: authorName.trim().isEmpty ? 'Scholar' : authorName.trim(),
      content: trimmed,
      createdAt: DateTime.now(),
    );

    final updatedComments = [..._posts[idx].comments, comment];
    _posts[idx] = _posts[idx].copyWith(comments: updatedComments);
    _startCooldown();
    await _saveLocalCache();

    if (SupabaseService.instance.isConfigured) {
      try {
        final client = SupabaseService.instance.client;
        if (client != null) {
          await client.from('community_comments').insert(comment.toJson());
        }
      } catch (e) {
        debugPrint('[CommunityService] Cloud comment notice: $e');
      }
    }
    return null;
  }

  /// Toggles an emoji reaction on a post live.
  Future<void> toggleReaction({
    required String postId,
    required String userHandle,
    required String emoji,
  }) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final normUser = normalizeHandle(userHandle);
    final currentMap = <String, Set<String>>{};
    _posts[idx].reactionsByEmoji.forEach((k, v) => currentMap[k] = Set<String>.from(v));

    final set = currentMap.putIfAbsent(emoji, () => <String>{});
    final removing = set.contains(normUser);
    if (removing) {
      set.remove(normUser);
    } else {
      set.add(normUser);
    }

    _posts[idx] = _posts[idx].copyWith(reactionsByEmoji: currentMap);
    notifyListeners();
    await _saveLocalCache();

    if (SupabaseService.instance.isConfigured) {
      try {
        final client = SupabaseService.instance.client;
        if (client == null) return;
        if (removing) {
          await client
              .from('community_reactions')
              .delete()
              .eq('post_id', postId)
              .eq('user_handle', normUser)
              .eq('emoji', emoji);
        } else {
          await client.from('community_reactions').upsert({
            'post_id': postId,
            'user_handle': normUser,
            'emoji': emoji,
          });
        }
      } catch (e) {
        debugPrint('[CommunityService] Cloud reaction notice: $e');
      }
    }
  }

  bool isFollowing(String handle) => _following.contains(normalizeHandle(handle));

  /// Follows or unfollows a user by username or email.
  Future<String?> toggleFollow({
    required String myHandle,
    required String targetInput,
  }) async {
    final normMe = normalizeHandle(myHandle);
    final normTarget = normalizeHandle(targetInput);
    if (normTarget.isEmpty) return 'Enter a username or email.';
    if (normTarget == normMe) return 'You cannot follow yourself.';

    final alreadyFollowing = _following.contains(normTarget);
    if (alreadyFollowing) {
      _following.remove(normTarget);
    } else {
      _following.add(normTarget);
    }
    onMutualsChanged?.call(mutualHandles);
    notifyListeners();
    await _saveLocalCache();

    if (SupabaseService.instance.isConfigured) {
      try {
        final client = SupabaseService.instance.client;
        if (client == null) return null;
        if (alreadyFollowing) {
          await client
              .from('user_follows')
              .delete()
              .eq('follower_handle', normMe)
              .eq('target_handle', normTarget);
        } else {
          await client.from('user_follows').upsert({
            'follower_handle': normMe,
            'target_handle': normTarget,
          });
        }
      } catch (e) {
        debugPrint('[CommunityService] Cloud follow notice: $e');
      }
    }
    return null;
  }

  /// Soft-deletes a post authored by the current user so the feed shows
  /// "<Name> deleted a message" cleanly (locally & in Supabase).
  Future<void> deletePost({
    required String postId,
    required String authorHandle,
  }) async {
    final normMe = normalizeHandle(authorHandle);
    final idx = _posts.indexWhere((p) => p.id == postId && p.authorHandle == normMe);
    if (idx == -1) return;
    final original = _posts[idx];
    final tombstone = '${original.authorName} deleted a message';
    _posts[idx] = CommunityPost(
      id: original.id,
      authorHandle: original.authorHandle,
      authorName: original.authorName,
      authorTitle: 'deleted',
      content: tombstone,
      bookTag: null,
      createdAt: original.createdAt,
      comments: const [],
      reactionsByEmoji: const {},
    );
    notifyListeners();
    await _saveLocalCache();

    if (SupabaseService.instance.isConfigured) {
      try {
        final client = SupabaseService.instance.client;
        if (client != null) {
          await client
              .from('community_posts')
              .update({
                'content': tombstone,
                'author_title': 'deleted',
                'book_tag': null,
              })
              .eq('id', postId)
              .eq('author_handle', normMe);
        }
      } catch (e) {
        debugPrint('[CommunityService] Cloud delete post notice: $e');
      }
    }
  }

  /// Unsubscribes from the Realtime WebSocket channel cleanly.
  void unsubscribeRealtime() {
    final ch = _channel;
    _channel = null;
    if (ch != null) {
      try {
        SupabaseService.instance.client?.removeChannel(ch);
      } catch (_) {}
    }
  }

  /// Cancels any active cooldown timer & realtime channel cleanly.
  void cancelTimers() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    unsubscribeRealtime();
  }
}
