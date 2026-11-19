import 'package:flutter/foundation.dart';
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

  /// Upserts the user's profile, streak, gems, owned books, and full progress snapshot to Supabase.
  /// Works for BOTH Email accounts (`profiles` + `userMetadata`) and Username-only accounts (`username_accounts`).
  Future<void> syncProfile({
    required UserProfile profile,
    required List<String> ownedBookIds,
    Map<String, dynamic>? fullStateJson,
  }) async {
    final c = client;
    if (!isConfigured || c == null) return;

    final compact = fullStateJson != null ? _compactStateSnapshot(fullStateJson) : null;

    // Route 1: No-Email Username Cloud Account
    if (currentUser == null && _activeUsernameAccount != null && _activeUsernameAccount!.isNotEmpty) {
      try {
        await c.from('username_accounts').update({
          'display_name': profile.name,
          if (compact != null) 'state_json': compact,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('username', _activeUsernameAccount!);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SupabaseService] Username account sync notice: $e');
        }
      }
      return;
    }

    // Route 2: Supabase Auth Email Account
    await _ensureFreshSession(c);
    final uid = currentUser?.id;
    if (uid == null) return;

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
    } catch (e) {
      // Fallback if the user hasn't added the `state_json` column to `public.profiles` yet
      try {
        profilePayload.remove('state_json');
        await c.from('profiles').upsert(profilePayload);
      } catch (inner) {
        if (kDebugMode) {
          debugPrint('[SupabaseService] Profile table sync notice: $inner');
        }
      }
    }

    if (compact != null) {
      try {
        await c.auth.updateUser(
          UserAttributes(
            data: {
              'full_name': profile.name,
              'quixoria_state': compact,
            },
          ),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SupabaseService] Cloud state snapshot sync notice: $e');
        }
      }
    }
  }

  /// Fetches the user's saved cloud progress from Supabase upon reinstalling or logging in on a new device.
  /// Works for BOTH Email accounts and Username-only (no email) accounts.
  Future<Map<String, dynamic>?> fetchCloudState() async {
    final c = client;
    if (!isConfigured || c == null) return null;

    // Route 1: No-Email Username Cloud Account
    if (currentUser == null && _activeUsernameAccount != null && _activeUsernameAccount!.isNotEmpty) {
      try {
        final row = await c
            .from('username_accounts')
            .select()
            .eq('username', _activeUsernameAccount!)
            .maybeSingle();
        if (row != null) {
          final rawState = row['state_json'];
          if (rawState is Map) {
            final restored = Map<String, dynamic>.from(rawState);
            final existingProfile = (restored['profile'] is Map)
                ? Map<String, dynamic>.from(restored['profile'] as Map)
                : <String, dynamic>{};
            if ((row['display_name']?.toString() ?? '').isNotEmpty) {
              existingProfile['name'] = row['display_name'];
            }
            restored['profile'] = existingProfile;
            return restored;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SupabaseService] Username account fetch notice: $e');
        }
      }
      return null;
    }

    // Route 2: Supabase Auth Email Account
    await _ensureFreshSession(c);
    User? user = currentUser;
    if (user == null) return null;

    // Refresh user from Supabase Auth server to guarantee freshest userMetadata
    try {
      final refreshed = await c.auth.getUser();
      if (refreshed.user != null) {
        user = refreshed.user;
      }
    } catch (_) {}

    if (user == null) return null;
    Map<String, dynamic>? restoredState;

    // 1. Fetch latest row from public.profiles (prefers full `state_json` column if present)
    try {
      final profileRow = await c
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileRow != null) {
        if (profileRow['state_json'] is Map) {
          restoredState = Map<String, dynamic>.from(profileRow['state_json'] as Map);
        }
        restoredState ??= <String, dynamic>{};
        final existingProfile = (restoredState['profile'] is Map)
            ? Map<String, dynamic>.from(restoredState['profile'] as Map)
            : <String, dynamic>{};
        existingProfile['name'] = profileRow['full_name'] ?? existingProfile['name'];
        existingProfile['email'] = profileRow['email'] ?? existingProfile['email'];
        existingProfile['streakDays'] = profileRow['streak_days'] ?? existingProfile['streakDays'];
        existingProfile['gems'] = profileRow['gems'] ?? existingProfile['gems'];
        existingProfile['goldenKeys'] = profileRow['golden_keys'] ?? existingProfile['goldenKeys'];
        restoredState['profile'] = existingProfile;

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

    // 2. Fallback / merge full state snapshot from Supabase user metadata if `profiles.state_json` wasn't populated
    final rawSnapshot = user.userMetadata?['quixoria_state'];
    if (rawSnapshot is Map) {
      if (restoredState == null || restoredState['catalogProgress'] == null) {
        final metaMap = Map<String, dynamic>.from(rawSnapshot);
        if (restoredState != null && restoredState['profile'] is Map) {
          metaMap['profile'] = restoredState['profile'];
        }
        restoredState = metaMap;
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
}
