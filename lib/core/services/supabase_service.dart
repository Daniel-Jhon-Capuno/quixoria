import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';
import '../../models/reading_note.dart';
import '../../models/user_profile.dart';
import '../../models/vocab_card.dart';

/// Supabase Cloud Authentication & PostgreSQL Synchronization Service.
///
/// Supports BOTH:
/// 1. Email + Password accounts via Supabase Auth + `public.profiles` (`state_json`)
/// 2. No-Email Username + Password accounts via `public.username_accounts` (salted SHA-256 + `state_json`)
///
/// Both account types sync full progress to Supabase Cloud so deleting and
/// reinstalling the app restores the user's exact progress on re-login.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://eyxaxsmsqfsmegwazrwx.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_n0RG9ZmHsV4WfUuupv6AVg_1RrvGKP7',
  );

  static const String _kSupabaseRefreshToken = 'quixoria_supabase_refresh_token';
  static const String _kActiveUsernameAccount = 'quixoria_active_username_account';

  SupabaseClient? _client;
  String? _activeUsernameAccount;

  /// True when valid Supabase project credentials have been provided.
  bool get isConfigured =>
      supabaseUrl.trim().isNotEmpty &&
      supabaseAnonKey.trim().isNotEmpty &&
      supabaseUrl.startsWith('http');

  String? get activeUsernameAccount => _activeUsernameAccount;

  SupabaseClient _createClient() {
    return SupabaseClient(
      supabaseUrl.trim(),
      supabaseAnonKey.trim(),
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        autoRefreshToken: false,
      ),
    );
  }

  /// Refreshes the JWT access token on-demand if it has expired while the app stayed open.
  Future<void> _ensureFreshSession(SupabaseClient c) async {
    final session = c.auth.currentSession;
    if (session != null && session.isExpired) {
      try {
        final res = await c.auth.refreshSession();
        if (res.session?.refreshToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kSupabaseRefreshToken, res.session!.refreshToken!);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SupabaseService] On-demand token refresh failed: $e');
        }
      }
    }
  }

  SupabaseClient? get client {
    if (_client == null && isConfigured) {
      _client = _createClient();
    }
    return _client;
  }

  User? get currentUser => client?.auth.currentUser;

  bool get hasActiveCloudSession => currentUser != null || (_activeUsernameAccount != null && _activeUsernameAccount!.isNotEmpty);

  /// Initializes the Supabase client and restores any persisted session token or username account.
  Future<void> init() async {
    if (!isConfigured) return;

    try {
      _client ??= _createClient();
      final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString(_kActiveUsernameAccount);
      _activeUsernameAccount = (savedUsername != null && savedUsername.isNotEmpty) ? savedUsername : null;

      final savedRefreshToken = prefs.getString(_kSupabaseRefreshToken);
      if (savedRefreshToken != null && savedRefreshToken.isNotEmpty) {
        final response = await _client!.auth.setSession(savedRefreshToken);
        if (response.session?.refreshToken != null) {
          await prefs.setString(_kSupabaseRefreshToken, response.session!.refreshToken!);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseService] Init / session restore notice: $e');
      }
    }
  }

  Future<void> _persistSession(Session? session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (session?.refreshToken != null) {
        await prefs.setString(_kSupabaseRefreshToken, session!.refreshToken!);
      } else {
        await prefs.remove(_kSupabaseRefreshToken);
      }
    } catch (_) {}
  }

  Future<void> setActiveUsernameAccount(String? username) async {
    final normalized = (username ?? '').trim().toLowerCase();
    _activeUsernameAccount = normalized.isEmpty ? null : normalized;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_activeUsernameAccount != null) {
        await prefs.setString(_kActiveUsernameAccount, _activeUsernameAccount!);
      } else {
        await prefs.remove(_kActiveUsernameAccount);
      }
    } catch (_) {}
  }

  /// Registers a new email user in Supabase Auth.
  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final c = client;
    if (!isConfigured || c == null) return null;
    await setActiveUsernameAccount(null);
    final res = await c.auth.signUp(
      email: email.trim(),
      password: password.trim(),
      data: {'full_name': fullName.trim()},
    );
    if (res.session != null) {
      await _persistSession(res.session);
    }
    return res;
  }

  /// Resends the signup verification OTP code via Supabase Auth.
  Future<void> resendSignupOtp(String email) async {
    final c = client;
    if (!isConfigured || c == null) return;
    await c.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
    );
  }

  /// Verifies the email OTP code (6–8 digits) sent by Supabase Auth.
  Future<AuthResponse?> verifySignupOtp({
    required String email,
    required String code,
  }) async {
    final c = client;
    if (!isConfigured || c == null) return null;
    await setActiveUsernameAccount(null);
    final res = await c.auth.verifyOTP(
      type: OtpType.signup,
      email: email.trim(),
      token: code.trim(),
    );
    if (res.session != null) {
      await _persistSession(res.session);
    }
    return res;
  }

  /// Signs in an existing email user with email and password via Supabase Auth.
  Future<AuthResponse?> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final c = client;
    if (!isConfigured || c == null) return null;
    await setActiveUsernameAccount(null);
    final res = await c.auth.signInWithPassword(
      email: email.trim(),
      password: password.trim(),
    );
    if (res.session != null) {
      await _persistSession(res.session);
    }
    return res;
  }

  /// Sends a password reset email via Supabase Auth.
  Future<void> sendPasswordResetEmail(String email) async {
    final c = client;
    if (!isConfigured || c == null) return;
    await c.auth.resetPasswordForEmail(email.trim());
  }

  /// Signs out from Supabase Auth and clears persisted refresh tokens / username session.
  Future<void> signOut() async {
    try {
      await _client?.auth.signOut();
    } catch (_) {}
    await _persistSession(null);
    await setActiveUsernameAccount(null);
  }

  // ===========================================================================
  // NO-EMAIL USERNAME + PASSWORD CLOUD ACCOUNTS (`public.username_accounts`)
  // ===========================================================================

  /// Fetches a username account record from Supabase (`public.username_accounts`).
  /// Throws on network/table error so callers can distinguish "not found" vs "offline".
  Future<Map<String, dynamic>?> fetchUsernameAccount(String username) async {
    final c = client;
    if (!isConfigured || c == null) return null;
    final clean = username.trim().toLowerCase();
    if (clean.isEmpty) return null;

    final row = await c
        .from('username_accounts')
        .select()
        .eq('username', clean)
        .maybeSingle();
    return row;
  }

  /// Creates a new no-email username account in `public.username_accounts`.
  /// Returns `'ok'`, `'taken'`, or throws on network/server error.
  Future<String> registerUsernameAccount({
    required String username,
    required String displayName,
    required String passwordSalt,
    required String passwordHash,
  }) async {
    final c = client;
    if (!isConfigured || c == null) return 'unconfigured';
    final clean = username.trim().toLowerCase();

    final existing = await c
        .from('username_accounts')
        .select('username')
        .eq('username', clean)
        .maybeSingle();
    if (existing != null) {
      return 'taken';
    }

    await c.from('username_accounts').insert({
      'username': clean,
      'display_name': displayName.trim().isEmpty ? clean : displayName.trim(),
      'password_salt': passwordSalt,
      'password_hash': passwordHash,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    await setActiveUsernameAccount(clean);
    return 'ok';
  }

  /// Updates the password hash for a no-email username account in Supabase.
  Future<bool> updateUsernameAccountPassword({
    required String username,
    required String passwordSalt,
    required String passwordHash,
  }) async {
    final c = client;
    if (!isConfigured || c == null) return false;
    final clean = username.trim().toLowerCase();
    try {
      await c.from('username_accounts').update({
        'password_salt': passwordSalt,
        'password_hash': passwordHash,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('username', clean);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseService] Username password update notice: $e');
      }
      return false;
    }
  }

  /// Compacts `catalogProgress` to only owned or progressed books so cloud snapshots stay lean.
  Map<String, dynamic> _compactStateSnapshot(Map<String, dynamic> fullStateJson) {
    final compact = Map<String, dynamic>.from(fullStateJson);
    if (compact['catalogProgress'] is Map) {
      final rawCat = compact['catalogProgress'] as Map;
      final compactCat = <String, dynamic>{};
      for (final entry in rawCat.entries) {
        if (entry.value is Map) {
          final m = entry.value as Map;
          final isOwned = m['isOwned'] == true;
          final completed = (m['completedLevelIds'] is List) ? (m['completedLevelIds'] as List) : const [];
          final levelIdx = (m['currentLevelIndex'] as num?)?.toInt() ?? 0;
          if (isOwned || completed.isNotEmpty || levelIdx > 0) {
            compactCat[entry.key.toString()] = m;
          }
        }
      }
      compact['catalogProgress'] = compactCat;
    }
    return compact;
  }

  /// Builds a compact purchases & streak backup safe for Supabase Auth JWT `userMetadata`
  /// (never exceeds JWT size limits while preserving Caballero Pass, Gems, Cosmetics,
  /// Streak, Owned Books, and Owned Themes).
  Map<String, dynamic> _buildLeanMetadataBackup(
    UserProfile profile,
    List<String> ownedBookIds,
    Map<String, dynamic>? compactState,
  ) {
    final ownedThemeIds = <String>[];
    if (compactState != null && compactState['themePresets'] is Map) {
      final tm = compactState['themePresets'] as Map;
      tm.forEach((k, v) {
        if (v is Map && v['isOwned'] == true) {
          ownedThemeIds.add(k.toString());
        }
      });
    }
    return {
      'profile': profile.toJson(),
      'ownedBookIds': ownedBookIds,
      'ownedThemeIds': ownedThemeIds,
      'activeThemePresetId': compactState?['activeThemePresetId'],
      'activeLiteratureId': compactState?['activeLiteratureId'],
      'savedAtUtcMs': DateTime.now().toUtc().millisecondsSinceEpoch,
    };
  }

  /// Upserts the user's profile, Caballero Pass, gems, streak, cosmetics, owned books,
  /// owned themes, and full progress snapshot to Supabase Cloud.
  /// Persists across ALL account types (Email Auth, Username accounts, and email-keyed
  /// universal cloud backup) so deleting & reinstalling the app ALWAYS restores everything.
  Future<bool> syncProfile({
    required UserProfile profile,
    required List<String> ownedBookIds,
    Map<String, dynamic>? fullStateJson,
    String? accountKey,
  }) async {
    final c = client;
    if (!isConfigured || c == null) return false;

    final compact = fullStateJson != null ? _compactStateSnapshot(fullStateJson) : null;
    final normalizedKey = (accountKey ?? _activeUsernameAccount ?? profile.email)
        .trim()
        .toLowerCase();
    bool syncedAnywhere = false;

    // 1. Universal Cloud Snapshot Mirror (`public.username_accounts` keyed by username OR email)
    // Ensures purchases, Caballero Pass, Gems, Cosmetics, and Streak survive app deletion
    // even if Supabase Auth JWT expires or `profiles.state_json` wasn't migrated yet!
    if (normalizedKey.isNotEmpty &&
        !normalizedKey.contains('guest.scholar') &&
        compact != null) {
      try {
        final existing = await c
            .from('username_accounts')
            .select('username')
            .eq('username', normalizedKey)
            .maybeSingle();
        if (existing != null) {
          await c.from('username_accounts').update({
            'display_name': profile.name,
            'state_json': compact,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }).eq('username', normalizedKey);
          syncedAnywhere = true;
        } else {
          // Create a cloud backup row keyed by accountKey (safe sentinel hash for email mirror)
          await c.from('username_accounts').upsert({
            'username': normalizedKey,
            'display_name': profile.name.trim().isEmpty ? normalizedKey : profile.name.trim(),
            'password_salt': 'cloud_backup_mirror',
            'password_hash': 'cloud_backup_mirror',
            'state_json': compact,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });
          syncedAnywhere = true;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SupabaseService] Universal cloud mirror sync notice: $e');
        }
      }
    }

    // 2. Supabase Auth Email Account (`public.profiles` + lean `userMetadata` backup)
    await _ensureFreshSession(c);
    final uid = currentUser?.id;
    if (uid == null) return syncedAnywhere;

    final profilePayload = <String, dynamic>{
      'id': uid,
      'full_name': profile.name,
      'email': profile.email,
      'streak_days': profile.streakDays,
      'gems': profile.gems,
      'golden_keys': profile.goldenKeys,
      'owned_books': ownedBookIds,
      if (compact != null) 'state_json': compact,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      await c.from('profiles').upsert(profilePayload);
      syncedAnywhere = true;
    } catch (e) {
      try {
        profilePayload.remove('state_json');
        await c.from('profiles').upsert(profilePayload);
        syncedAnywhere = true;
      } catch (inner) {
        if (kDebugMode) {
          debugPrint('[SupabaseService] Profile table sync notice: $inner');
        }
      }
    }

    // Lean JWT userMetadata backup (always fits under JWT size limit!)
    try {
      final leanBackup = _buildLeanMetadataBackup(profile, ownedBookIds, compact);
      await c.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': profile.name,
            'quixoria_state': leanBackup,
          },
        ),
      );
      syncedAnywhere = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseService] Lean metadata sync notice: $e');
      }
    }

    return syncedAnywhere;
  }

  /// Deep-merges two profile JSON maps without losing Caballero Pass, cosmetics,
  /// streak history, or owned items when combining table columns with full snapshots.
  Map<String, dynamic> _mergeProfileMaps(
    Map<String, dynamic> base,
    Map<String, dynamic> overlay,
  ) {
    final merged = Map<String, dynamic>.from(base);
    overlay.forEach((k, v) {
      if (v != null) {
        merged[k] = v;
      }
    });
    // Never lose Caballero Pass (`isPremium == true`) during merge
    if (base['isPremium'] == true || overlay['isPremium'] == true) {
      merged['isPremium'] = true;
    }
    return merged;
  }

  /// Fetches the user's saved cloud progress from Supabase upon reinstalling or logging in on a new device.
  /// Works for Email accounts, Username accounts, AND email-keyed universal cloud backups.
  Future<Map<String, dynamic>?> fetchCloudState({String? accountKey}) async {
    final c = client;
    if (!isConfigured || c == null) return null;

    final normalizedKey = (accountKey ?? _activeUsernameAccount ?? currentUser?.email ?? '')
        .trim()
        .toLowerCase();

    Map<String, dynamic>? restoredState;

    // 1. Check Universal Cloud Mirror (`public.username_accounts` by username OR email)
    if (normalizedKey.isNotEmpty && !normalizedKey.contains('guest.scholar')) {
      try {
        final row = await c
            .from('username_accounts')
            .select()
            .eq('username', normalizedKey)
            .maybeSingle();
        if (row != null && row['state_json'] is Map) {
          final restored = Map<String, dynamic>.from(row['state_json'] as Map);
          final existingProfile = (restored['profile'] is Map)
              ? Map<String, dynamic>.from(restored['profile'] as Map)
              : <String, dynamic>{};
          if ((row['display_name']?.toString() ?? '').isNotEmpty &&
              (existingProfile['name']?.toString() ?? '').isEmpty) {
            existingProfile['name'] = row['display_name'];
          }
          restored['profile'] = existingProfile;
          restoredState = restored;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SupabaseService] Universal cloud mirror fetch notice: $e');
        }
      }
    }

    // 2. Check Supabase Auth Email Account (`public.profiles` + `userMetadata`)
    await _ensureFreshSession(c);
    User? user = currentUser;
    if (user == null) return restoredState;

    try {
      final refreshed = await c.auth.getUser();
      if (refreshed.user != null) {
        user = refreshed.user;
      }
    } catch (_) {}

    if (user == null) return restoredState;

    // 2a. Fetch from public.profiles (`state_json` + columns)
    try {
      final profileRow = await c
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileRow != null) {
        if (profileRow['state_json'] is Map) {
          final rowState = Map<String, dynamic>.from(profileRow['state_json'] as Map);
          // Prefer whichever snapshot has richer profile data (or merge)
          if (restoredState == null) {
            restoredState = rowState;
          } else {
            final p1 = (restoredState['profile'] is Map)
                ? Map<String, dynamic>.from(restoredState['profile'] as Map)
                : <String, dynamic>{};
            final p2 = (rowState['profile'] is Map)
                ? Map<String, dynamic>.from(rowState['profile'] as Map)
                : <String, dynamic>{};
            rowState['profile'] = _mergeProfileMaps(p1, p2);
            restoredState = rowState;
          }
        }
        restoredState ??= <String, dynamic>{};
        final existingProfile = (restoredState['profile'] is Map)
            ? Map<String, dynamic>.from(restoredState['profile'] as Map)
            : <String, dynamic>{};
        // Only overlay non-null column values WITHOUT wiping cosmetics or isPremium!
        final columnOverlay = <String, dynamic>{
          if (profileRow['full_name'] != null) 'name': profileRow['full_name'],
          if (profileRow['email'] != null) 'email': profileRow['email'],
          if (profileRow['streak_days'] != null) 'streakDays': profileRow['streak_days'],
          if (profileRow['gems'] != null) 'gems': profileRow['gems'],
          if (profileRow['golden_keys'] != null) 'goldenKeys': profileRow['golden_keys'],
        };
        restoredState['profile'] = _mergeProfileMaps(existingProfile, columnOverlay);

        if (profileRow['owned_books'] is List) {
          final ownedIds = (profileRow['owned_books'] as List).map((e) => e.toString()).toSet();
          final catProgress = (restoredState['catalogProgress'] is Map)
              ? Map<String, dynamic>.from(restoredState['catalogProgress'] as Map)
              : <String, dynamic>{};
          for (final bookId in ownedIds) {
            final bookEntry = (catProgress[bookId] is Map)
                ? Map<String, dynamic>.from(catProgress[bookId] as Map)
                : <String, dynamic>{};
            bookEntry['isOwned'] = true;
            catProgress[bookId] = bookEntry;
          }
          restoredState['catalogProgress'] = catProgress;
        }
      }
    } catch (_) {}

    // 2b. Deep-merge lean backup from Supabase Auth `userMetadata` (NEVER overwrite profile!)
    final rawSnapshot = user.userMetadata?['quixoria_state'];
    if (rawSnapshot is Map) {
      final metaMap = Map<String, dynamic>.from(rawSnapshot);
      restoredState ??= <String, dynamic>{};
      if (metaMap['profile'] is Map) {
        final metaProfile = Map<String, dynamic>.from(metaMap['profile'] as Map);
        final currentProfile = (restoredState['profile'] is Map)
            ? Map<String, dynamic>.from(restoredState['profile'] as Map)
            : <String, dynamic>{};
        // Merge metaProfile as base so isPremium, ownedFrameIds, ownedBannerIds,
        // ownedAvatarIconIds, ownedTitleIds, streakFreezes, streakHistory are NEVER lost!
        restoredState['profile'] = _mergeProfileMaps(metaProfile, currentProfile);
      }
      if (metaMap['ownedBookIds'] is List) {
        final catProgress = (restoredState['catalogProgress'] is Map)
            ? Map<String, dynamic>.from(restoredState['catalogProgress'] as Map)
            : <String, dynamic>{};
        for (final id in (metaMap['ownedBookIds'] as List)) {
          final bookId = id.toString();
          final bookEntry = (catProgress[bookId] is Map)
              ? Map<String, dynamic>.from(catProgress[bookId] as Map)
              : <String, dynamic>{};
          bookEntry['isOwned'] = true;
          catProgress[bookId] = bookEntry;
        }
        restoredState['catalogProgress'] = catProgress;
      }
      if (metaMap['ownedThemeIds'] is List) {
        final themePresets = (restoredState['themePresets'] is Map)
            ? Map<String, dynamic>.from(restoredState['themePresets'] as Map)
            : <String, dynamic>{};
        for (final id in (metaMap['ownedThemeIds'] as List)) {
          final tid = id.toString();
          themePresets[tid] = {'isOwned': true, 'isDownloaded': true};
        }
        restoredState['themePresets'] = themePresets;
      }
      if (restoredState['catalogProgress'] == null && metaMap['catalogProgress'] is Map) {
        restoredState['catalogProgress'] = metaMap['catalogProgress'];
      }
    }

    // 3. Fallback restore vocab_cards from table if missing in snapshot
    try {
      if (restoredState == null || restoredState['vocabDeck'] == null || (restoredState['vocabDeck'] as List).isEmpty) {
        final vocabRows = await c.from('vocab_cards').select().eq('user_id', user.id);
        if (vocabRows.isNotEmpty) {
          restoredState ??= <String, dynamic>{};
          restoredState['vocabDeck'] = vocabRows.map((r) => {
            'word': r['word'] ?? '',
            'definition': r['definition'] ?? '',
            'example': r['example'] ?? '',
            'literatureId': r['literature_id'] ?? 'lit_secret_garden',
            'literatureTitle': r['literature_title'] ?? 'The Secret Garden',
            'box': r['box'] ?? 0,
            'dueAt': r['due_at'] ?? DateTime.now().toIso8601String(),
          }).toList();
        }
      }
    } catch (_) {}

    // 4. Fallback restore reading_notes from table if missing in snapshot
    try {
      if (restoredState == null || restoredState['notes'] == null || (restoredState['notes'] as List).isEmpty) {
        final noteRows = await c.from('reading_notes').select().eq('user_id', user.id);
        if (noteRows.isNotEmpty) {
          restoredState ??= <String, dynamic>{};
          restoredState['notes'] = noteRows.map((r) => {
            'id': r['client_note_id']?.toString() ?? r['id']?.toString() ?? 'note_${DateTime.now().millisecondsSinceEpoch}',
            'literatureId': r['literature_id'] ?? 'lit_secret_garden',
            'literatureTitle': r['literature_title'] ?? 'The Secret Garden',
            'chapterTitle': r['chapter_title'] ?? 'Chapter 1',
            'type': r['note_type'] ?? 'reflection',
            'title': r['title'] ?? '',
            'content': r['content'] ?? '',
            'createdAt': r['created_at'] ?? DateTime.now().toIso8601String(),
          }).toList();
        }
      }
    } catch (_) {}

    return restoredState;
  }

  /// Inserts or updates a vocabulary flashcard in `public.vocab_cards`.
  Future<void> syncVocabCard(VocabCard card) async {
    final c = client;
    final uid = currentUser?.id;
    if (!isConfigured || c == null || uid == null) return;

    try {
      await c.from('vocab_cards').upsert(
        {
          'user_id': uid,
          'word': card.word,
          'definition': card.definition,
          'example': card.example,
          'literature_id': card.literatureId,
          'literature_title': card.literatureTitle,
          'box': card.box,
          'due_at': card.dueAt.toUtc().toIso8601String(),
        },
        onConflict: 'user_id,word',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseService] VocabCard sync notice: $e');
      }
    }
  }

  /// Inserts or updates a reading note in `public.reading_notes`.
  Future<void> syncReadingNote(ReadingNote note) async {
    final c = client;
    final uid = currentUser?.id;
    if (!isConfigured || c == null || uid == null) return;

    try {
      await c.from('reading_notes').upsert(
        {
          'user_id': uid,
          'client_note_id': note.id,
          'literature_id': note.literatureId,
          'literature_title': note.literatureTitle,
          'chapter_title': note.chapterTitle,
          'note_type': note.type.name,
          'title': note.title,
          'content': note.content,
          'created_at': note.createdAt.toUtc().toIso8601String(),
        },
        onConflict: 'user_id,client_note_id',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseService] ReadingNote sync notice: $e');
      }
    }
  }

  // ===========================================================================
  // LIVE GLOBAL LEADERBOARD (`public.leaderboard_entries`)
  // ===========================================================================

  /// Upserts the active user's live standings into `public.leaderboard_entries`.
  /// Works for BOTH Email and No-Email Username accounts!
  Future<void> syncLeaderboardEntry({
    required String accountKey,
    required UserProfile profile,
  }) async {
    final c = client;
    final cleanKey = accountKey.trim().toLowerCase();
    if (!isConfigured || c == null || cleanKey.isEmpty || cleanKey == 'guest.scholar@quixoria.realm') {
      return;
    }

    try {
      await c.from('leaderboard_entries').upsert(
        {
          'account_key': cleanKey,
          'display_name': profile.name.trim().isEmpty ? 'Scholar' : profile.name.trim(),
          'scholar_title': profile.readerRank,
          'frame_id': profile.equippedFrameId,
          'weekly_xp': profile.weeklyXp,
          'streak_days': profile.streakDays,
          'books_completed': profile.booksCompleted,
          'levels_completed': profile.levelsCompleted,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'account_key',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseService] Leaderboard sync notice: $e');
      }
    }
  }

  /// Fetches live global rankings from `public.leaderboard_entries`.
  /// `sortBy`: `'weekly_xp'`, `'streak_days'`, or `'books_completed'`.
  Future<List<Map<String, dynamic>>> fetchGlobalLeaderboard({
    String sortBy = 'weekly_xp',
    int limit = 50,
  }) async {
    final c = client;
    if (!isConfigured || c == null) return const [];

    final validSort = (sortBy == 'streak_days' || sortBy == 'books_completed')
        ? sortBy
        : 'weekly_xp';

    try {
      final rows = await c
          .from('leaderboard_entries')
          .select()
          .order(validSort, ascending: false)
          .order('levels_completed', ascending: false)
          .limit(limit);
      return rows.map((r) => Map<String, dynamic>.from(r)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseService] Leaderboard fetch notice: $e');
      }
      return const [];
    }
  }

  /// Deep-link redirect URI registered in AndroidManifest.xml for Google OAuth.
  static const String oauthRedirectUrl = 'com.example.quixoria://login-callback';

  /// Checks whether the Google OAuth provider is currently enabled in Supabase Auth settings.
  Future<bool> isGoogleOAuthEnabled() async {
    if (!isConfigured) return false;
    try {
      final res = await http
          .get(
            Uri.parse('${supabaseUrl.trim()}/auth/v1/settings'),
            headers: {'apikey': supabaseAnonKey.trim()},
          )
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['external'] is Map) {
          return decoded['external']['google'] == true;
        }
      }
    } catch (_) {}
    return false;
  }

  /// Checks if a username is already registered in `public.username_accounts`.
  Future<bool> isUsernameTaken(String username) async {
    final c = client;
    final clean = username.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
    if (!isConfigured || c == null || clean.isEmpty) return false;
    try {
      final row = await c
          .from('username_accounts')
          .select('username')
          .eq('username', clean)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));
      return row != null;
    } catch (_) {
      return false;
    }
  }

  /// Checks whether this email already has a saved Quixoria cloud account.
  Future<bool> hasExistingCloudAccount(String email) async {
    final c = client;
    final clean = email.trim().toLowerCase();
    if (!isConfigured || c == null || clean.isEmpty) return false;
    try {
      final mirrorRow = await c
          .from('username_accounts')
          .select('username')
          .eq('username', clean)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));
      if (mirrorRow != null) return true;
    } catch (_) {}
    try {
      final profileRow = await c
          .from('profiles')
          .select('id')
          .eq('email', clean)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));
      if (profileRow != null) return true;
    } catch (_) {}
    return false;
  }

  /// Builds the Supabase Google OAuth authorization URL with the app's deep-link callback.
  /// Includes `prompt=select_account` so Google ALWAYS lets the user choose which Gmail to use.
  Uri buildGoogleOAuthUri() {
    final redirect = Uri.encodeComponent(oauthRedirectUrl);
    return Uri.parse(
      '${supabaseUrl.trim()}/auth/v1/authorize?provider=google&redirect_to=$redirect&prompt=select_account',
    );
  }

  /// Completes a Supabase OAuth deep-link callback and persists the returned session.
  /// Handles both SDK `getSessionFromUrl` and direct fragment `access_token` / `refresh_token` parsing.
  Future<User?> completeOAuthCallback(Uri callbackUri) async {
    final c = client;
    if (!isConfigured || c == null) return null;

    // 1. Primary path: Supabase SDK getSessionFromUrl
    try {
      final res = await c.auth.getSessionFromUrl(callbackUri);
      await _persistSession(res.session);
      await setActiveUsernameAccount(null);
      if ((res.session.user.email ?? '').trim().isNotEmpty) {
        return res.session.user;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseService] getSessionFromUrl fallback: $e');
      }
    }

    // 2. Reliable fallback: parse implicit fragment (#access_token=...&refresh_token=...)
    try {
      final params = <String, String>{
        ...callbackUri.queryParameters,
        if (callbackUri.fragment.isNotEmpty)
          ...Uri.splitQueryString(callbackUri.fragment),
      };
      final refreshToken = params['refresh_token'];
      final accessToken = params['access_token'];

      if (refreshToken != null && refreshToken.isNotEmpty) {
        final sessionRes = await c.auth.setSession(refreshToken);
        await _persistSession(sessionRes.session);
        await setActiveUsernameAccount(null);
        if (sessionRes.user != null) return sessionRes.user;
      }
      if (accessToken != null && accessToken.isNotEmpty) {
        final userRes = await c.auth.getUser(accessToken);
        await setActiveUsernameAccount(null);
        if (userRes.user != null) return userRes.user;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseService] OAuth fragment parse notice: $e');
      }
    }
    return c.auth.currentUser;
  }
}
