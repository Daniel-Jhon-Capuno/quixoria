import 'package:flutter/material.dart';
import '../services/ambience_service.dart';
import '../services/auth_service.dart';
import '../services/crash_reporter.dart';
import '../services/haptic_service.dart';
import '../services/notification_service.dart';
import '../services/persistence_service.dart';
import '../services/sound_service.dart';
import '../services/supabase_service.dart';
import '../../app/theme/app_theme.dart';
import '../../models/app_notification.dart';
import '../../models/app_theme_preset.dart';
import '../../models/daily_quest.dart';
import '../../models/league.dart';
import '../../models/literature.dart';
import '../../models/quest_level.dart';
import '../../models/reading_note.dart';
import '../../models/user_profile.dart';
import '../../models/vocab_card.dart';
import '../../data/mock_literature_data.dart';
import '../../data/mock_theme_presets.dart';

class AppState extends ChangeNotifier {
  final PersistenceService? _persistence;

  late UserProfile _profile;
  late List<Literature> _catalog;
  late String _activeLiteratureId;
  late List<ReadingNote> _notes;
  late List<VocabCard> _vocabDeck;
  late List<DailyQuest> _dailyQuests;
  DateTime? _dailyQuestsDate;
  bool _hasCompletedOnboarding = false;
  bool _hasSeenGuidedTour = false;

  // Online / Offline & Connectivity
  bool _isOnline = true;
  late List<AppNotification> _notifications;
  int _previousStreak = 1;
  bool _hasLostStreakPending = false;

  // Settings: Accessibility
  bool _isDarkMode = false;
  bool _isReaderMode = false;
  bool _isDyslexicFont = false;

  // Settings: Audio & Haptics
  bool _soundEffectsEnabled = true;
  bool _musicEnabled = true;
  bool _hapticsEnabled = true;

  // Theme Presets (Medieval, Black Plague, Cozy Hearth, Snowy, etc.)
  late List<AppThemePreset> _themePresets;
  String _activeThemePresetId = 'theme_classic';

  // Gemini Socratic AI Tutor API Key
  String _geminiApiKey = '';
  String get geminiApiKey => _geminiApiKey;
  bool get hasGeminiApiKey => _geminiApiKey.trim().isNotEmpty;

  void setGeminiApiKey(String key) {
    _geminiApiKey = key.trim();
    _save();
    notifyListeners();
  }

  // Neural Voice Narrator Settings (Google Cloud Studio TTS & ElevenLabs)
  String _ttsApiKey = '';
  String _ttsProvider = 'google'; // 'google' | 'elevenlabs'

  String get ttsApiKey => _ttsApiKey;
  String get ttsProvider => _ttsProvider;
  String get effectiveTtsKey => _ttsApiKey.trim().isNotEmpty ? _ttsApiKey.trim() : _geminiApiKey.trim();
  bool get hasTtsKey => effectiveTtsKey.isNotEmpty;

  void setTtsSettings({String? key, String? provider}) {
    if (key != null) _ttsApiKey = key.trim();
    if (provider != null) _ttsProvider = provider.trim();
    _save();
    notifyListeners();
  }

  // Active guide prompt state
  String? _guideMessage;
  String? _guideTitle;
  bool _hasDismissedGuideCard = false;

  // Streak & Milestone Logic
  DateTime? _lastDailyStreakCelebrationDate;
  int _consecutiveCorrectAnswers = 0;

  AppState([this._persistence]) {
    _initDefaults();
    _loadFromPersistence();
    _ensureDailyQuestsCurrent();
    _ensureLeagueWeekCurrent();
    SoundService.instance.enabled = _soundEffectsEnabled;
  }

  void _initDefaults() {
    _profile = UserProfile(
      leagueWeekStart: LeagueRoster.weekStartOf(DateTime.now()),
    );
    _catalog = MockLiteratureData.getInitialCatalog();
    _themePresets = MockThemePresets.getPresets();
    _activeLiteratureId = 'lit_secret_garden';
    _notes = _getInitialNotes();
    _vocabDeck = _getInitialVocabDeck();
    final today = _startOfDay(DateTime.now());
    _dailyQuestsDate = today;
    _dailyQuests = DailyQuest.generateFor(today);
    _notifications = _getInitialNotifications();
    _hasCompletedOnboarding = false;
    _hasSeenGuidedTour = false;
    _isOnline = true;
    _previousStreak = 1;
    _hasLostStreakPending = false;
    _isDarkMode = false;
    _isReaderMode = false;
    _isDyslexicFont = false;
    _soundEffectsEnabled = true;
    _musicEnabled = true;
    _hapticsEnabled = true;
    _activeThemePresetId = 'theme_classic';
    _hasDismissedGuideCard = false;
  }

  static DateTime _startOfDay(DateTime t) => DateTime(t.year, t.month, t.day);

  String? get _activeAccountKey {
    final key = AuthService.instance.accountKey;
    return key.isNotEmpty ? key : null;
  }

  Future<void>? _pendingCloudSync;

  void _loadFromPersistence({String? accountKey}) {
    final saved = _persistence?.loadState(accountKey: accountKey ?? _activeAccountKey);
    if (saved == null) return;
    _applySavedMap(saved);
  }

  void _applySavedMap(Map<String, dynamic> saved) {
    try {
      if (saved['profile'] is Map<String, dynamic>) {
        _profile = UserProfile.fromJson(saved['profile'] as Map<String, dynamic>);
      }
      if (AuthService.instance.isAuthenticated) {
        if (AuthService.instance.userName.isNotEmpty) {
          _profile.name = AuthService.instance.userName;
        }
        if (AuthService.instance.userEmail.isNotEmpty) {
          _profile.email = AuthService.instance.userEmail;
        }
      }
      _activeLiteratureId = (saved['activeLiteratureId'] as String?) ?? _activeLiteratureId;
      _hasCompletedOnboarding = (saved['hasCompletedOnboarding'] as bool?) ?? _hasCompletedOnboarding;
      _hasSeenGuidedTour = (saved['hasSeenGuidedTour'] as bool?) ?? _hasSeenGuidedTour;
      _previousStreak = (saved['previousStreak'] as num?)?.toInt() ?? _previousStreak;
      _hasLostStreakPending = (saved['hasLostStreakPending'] as bool?) ?? _hasLostStreakPending;
      _isDarkMode = (saved['isDarkMode'] as bool?) ?? _isDarkMode;
      _isReaderMode = (saved['isReaderMode'] as bool?) ?? _isReaderMode;
      _isDyslexicFont = (saved['isDyslexicFont'] as bool?) ?? _isDyslexicFont;
      _soundEffectsEnabled = (saved['soundEffectsEnabled'] as bool?) ?? _soundEffectsEnabled;
      _musicEnabled = (saved['musicEnabled'] as bool?) ?? _musicEnabled;
      _hapticsEnabled = (saved['hapticsEnabled'] as bool?) ?? _hapticsEnabled;
      HapticService.instance.enabled = _hapticsEnabled;
      AmbienceService.instance.syncWithSettings(musicEnabled: _musicEnabled);
      _activeThemePresetId = (saved['activeThemePresetId'] as String?) ?? _activeThemePresetId;
      _hasDismissedGuideCard = (saved['hasDismissedGuideCard'] as bool?) ?? _hasDismissedGuideCard;

      // Restore owned/downloaded theme presets
      if (saved['themePresets'] is Map<String, dynamic>) {
        final presetMap = saved['themePresets'] as Map<String, dynamic>;
        for (final preset in _themePresets) {
          final pData = presetMap[preset.id];
          if (pData is Map<String, dynamic>) {
            preset.isOwned = (pData['isOwned'] as bool?) ?? preset.isOwned;
            preset.isDownloaded = (pData['isDownloaded'] as bool?) ?? preset.isDownloaded;
            if (preset.isDownloaded) preset.downloadProgress = 1.0;
          }
        }
      }

      // Restore catalog progress (owned books, completed/unlocked levels, currentLevelIndex, gemsEarned)
      if (saved['catalogProgress'] is Map<String, dynamic>) {
        final catMap = saved['catalogProgress'] as Map<String, dynamic>;
        for (final lit in _catalog) {
          final lData = catMap[lit.id];
          if (lData is Map<String, dynamic>) {
            lit.isOwned = (lData['isOwned'] as bool?) ?? lit.isOwned;
            lit.currentLevelIndex = (lData['currentLevelIndex'] as num?)?.toInt() ?? lit.currentLevelIndex;
            lit.gemsEarned = (lData['gemsEarned'] as num?)?.toInt() ?? lit.gemsEarned;
            final completedIds = (lData['completedLevelIds'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toSet() ??
                <String>{};
            final unlockedIds = (lData['unlockedLevelIds'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toSet() ??
                <String>{};
            for (final lvl in lit.questLevels) {
              if (completedIds.contains(lvl.id)) {
                lvl.isCompleted = true;
                lvl.isLocked = false;
              } else if (unlockedIds.contains(lvl.id)) {
                lvl.isLocked = false;
              }
            }
          }
        }
      }

      // Restore notes
      if (saved['notes'] is List<dynamic>) {
        _notes = (saved['notes'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(ReadingNote.fromJson)
            .toList();
      }

      // Restore vocab deck
      if (saved['vocabDeck'] is List<dynamic>) {
        _vocabDeck = (saved['vocabDeck'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(VocabCard.fromJson)
            .toList();
      }

      // Restore daily quests
      if (saved['dailyQuestsDate'] is String && saved['dailyQuests'] is List<dynamic>) {
        _dailyQuestsDate = DateTime.tryParse(saved['dailyQuestsDate'] as String);
        final loadedQuests = (saved['dailyQuests'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(DailyQuest.fromJson)
            .toList();
        if (loadedQuests.isNotEmpty) {
          _dailyQuests = loadedQuests;
        }
      }

      // Restore last streak celebrated day
      if (saved['lastStreakCelebratedDay'] is String) {
        _profile.lastStreakCelebratedDay = DateTime.tryParse(saved['lastStreakCelebratedDay'] as String);
        _lastDailyStreakCelebrationDate = _profile.lastStreakCelebratedDay;
      }

      // Restore Gemini API Key
      if (saved['geminiApiKey'] is String) {
        _geminiApiKey = saved['geminiApiKey'] as String;
      }

      // Restore TTS Settings
      if (saved['ttsApiKey'] is String) {
        _ttsApiKey = saved['ttsApiKey'] as String;
      }
      if (saved['ttsProvider'] is String) {
        _ttsProvider = saved['ttsProvider'] as String;
      }
    } catch (_) {
      // Fall back to defaults if JSON schema mismatches
    }
  }

  Map<String, dynamic> toPersistableJson() {
    final presetMap = <String, dynamic>{};
    for (final p in _themePresets) {
      presetMap[p.id] = {
        'isOwned': p.isOwned,
        'isDownloaded': p.isDownloaded,
      };
    }

    final catMap = <String, dynamic>{};
    for (final lit in _catalog) {
      catMap[lit.id] = {
        'isOwned': lit.isOwned,
        'currentLevelIndex': lit.currentLevelIndex,
        'gemsEarned': lit.gemsEarned,
        'completedLevelIds': lit.questLevels.where((l) => l.isCompleted).map((l) => l.id).toList(),
        'unlockedLevelIds': lit.questLevels.where((l) => !l.isLocked).map((l) => l.id).toList(),
      };
    }

    return {
      'profile': _profile.toJson(),
      'activeLiteratureId': _activeLiteratureId,
      'hasCompletedOnboarding': _hasCompletedOnboarding,
      'hasSeenGuidedTour': _hasSeenGuidedTour,
      'previousStreak': _previousStreak,
      'hasLostStreakPending': _hasLostStreakPending,
      'isDarkMode': _isDarkMode,
      'isReaderMode': _isReaderMode,
      'isDyslexicFont': _isDyslexicFont,
      'soundEffectsEnabled': _soundEffectsEnabled,
      'musicEnabled': _musicEnabled,
      'hapticsEnabled': _hapticsEnabled,
      'activeThemePresetId': _activeThemePresetId,
      'hasDismissedGuideCard': _hasDismissedGuideCard,
      'themePresets': presetMap,
      'catalogProgress': catMap,
      'notes': _notes.map((n) => n.toJson()).toList(),
      'vocabDeck': _vocabDeck.map((v) => v.toJson()).toList(),
      'dailyQuestsDate': _dailyQuestsDate?.toIso8601String(),
      'dailyQuests': _dailyQuests.map((q) => q.toJson()).toList(),
      'lastStreakCelebratedDay': _profile.lastStreakCelebratedDay?.toIso8601String(),
      'geminiApiKey': _geminiApiKey,
      'ttsApiKey': _ttsApiKey,
      'ttsProvider': _ttsProvider,
    };
  }

  void _save() {
    final payload = toPersistableJson();
    final key = _activeAccountKey;
    _persistence?.saveState(payload, accountKey: key).catchError((e, stack) {
      CrashReporter.instance.recordError(
        e,
        stack is StackTrace ? stack : null,
        source: 'app_state_save',
      );
      return false;
    });
    if (_isOnline &&
        SupabaseService.instance.isConfigured &&
        SupabaseService.instance.hasActiveCloudSession) {
      _enqueueCloudSync(payload);
    }
  }

  void _enqueueCloudSync(Map<String, dynamic> payload) {
    final owned = ownedLiterature.map((b) => b.id).toList();
    final profileSnapshot = _profile;
    final previous = _pendingCloudSync ?? Future<void>.value();
    _pendingCloudSync = previous.then((_) async {
      await SupabaseService.instance.syncProfile(
        profile: profileSnapshot,
        ownedBookIds: owned,
        fullStateJson: payload,
      );
    }).catchError((_) {});
  }

  /// Explicitly flushes local & cloud progress (called on logout, app background, and Wi-Fi reconnect).
  Future<void> flushCloudSync() async {
    final payload = toPersistableJson();
    final key = _activeAccountKey;
    try {
      await _persistence?.saveState(payload, accountKey: key);
    } catch (_) {}

    if (_isOnline &&
        SupabaseService.instance.isConfigured &&
        SupabaseService.instance.hasActiveCloudSession) {
      _enqueueCloudSync(payload);
      try {
        await _pendingCloudSync;
      } catch (_) {}
    }
  }

  /// Initializes or restores the exact account state after Sign Up or Log In,
  /// preventing any cross-account data leakage on shared devices.
  Future<bool> loadAccountOnLogin({
    required String name,
    required String email,
    bool isNewAccount = false,
  }) async {
    final key = _activeAccountKey;
    _initDefaults();

    if (!isNewAccount) {
      // 1. Load this account's local save (if present on this device)
      _loadFromPersistence(accountKey: key);

      // 2. Pull latest cloud progress from Supabase (survives delete & reinstall)
      final restoredFromCloud = await pullCloudProgress();
      if (restoredFromCloud) {
        if (_profile.name.trim().isNotEmpty) {
          await AuthService.instance.updateDisplayName(_profile.name);
        }
        return true;
      }

      // 3. If local save existed for this account, keep it; otherwise apply login name/email
      if (_profile.email.trim().isEmpty || _profile.email == 'alonso@la-mancha.realm') {
        _profile.name = name.trim().isNotEmpty ? name.trim() : _profile.name;
        _profile.email = email.trim().isNotEmpty ? email.trim() : _profile.email;
      }
      _ensureDailyQuestsCurrent();
      _ensureLeagueWeekCurrent();
      await flushCloudSync();
      notifyListeners();
      return false;
    } else {
      // Fresh Sign-Up: start cleanly with the new user's name & email and persist immediately
      if (name.trim().isNotEmpty) _profile.name = name.trim();
      if (email.trim().isNotEmpty) _profile.email = email.trim();
      _ensureDailyQuestsCurrent();
      _ensureLeagueWeekCurrent();
      await flushCloudSync();
      notifyListeners();
      return false;
    }
  }

  /// Synchronizes the profile with an auto-saved authenticated session upon app re-open.
  void restoreAuthenticatedSession({bool markReadyForMainPage = true}) {
    if (!AuthService.instance.isAuthenticated) return;
    _loadFromPersistence(accountKey: _activeAccountKey);
    if (AuthService.instance.userName.isNotEmpty) {
      _profile.name = AuthService.instance.userName;
    }
    if (AuthService.instance.userEmail.isNotEmpty) {
      _profile.email = AuthService.instance.userEmail;
    }
    if (markReadyForMainPage) {
      _hasCompletedOnboarding = true;
    }
    notifyListeners();
    // Pull cloud progress first so we never overwrite newer cloud data with stale local state
    pullCloudProgress();
  }

  /// Pulls and restores the user's saved cloud progress from Supabase (e.g. after reinstalling the app).
  /// Returns true if cloud progress was found and applied.
  Future<bool> pullCloudProgress() async {
    if (!_isOnline ||
        !SupabaseService.instance.isConfigured ||
        !SupabaseService.instance.hasActiveCloudSession) {
      return false;
    }
    try {
      final cloudState = await SupabaseService.instance.fetchCloudState();
      if (cloudState != null && cloudState.isNotEmpty) {
        _applySavedMap(cloudState);
        _hasCompletedOnboarding = true;
        final payload = toPersistableJson();
        await _persistence?.saveState(payload, accountKey: _activeAccountKey);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Resets all local device data back to factory defaults.
  Future<void> resetAllData() async {
    await _persistence?.clearAll();
    _initDefaults();
    SoundService.instance.enabled = _soundEffectsEnabled;
    notifyListeners();
  }

  // Getters
  UserProfile get profile => _profile;
  List<Literature> get catalog => _catalog;
  List<Literature> get literatureList => _catalog;
  String get activeLiteratureId => _activeLiteratureId;
  List<ReadingNote> get notes => _notes;
  List<VocabCard> get vocabDeck => _vocabDeck;
  List<VocabCard> get dueVocabCards {
    final now = DateTime.now();
    return _vocabDeck.where((c) => c.isDue(now)).toList();
  }

  List<DailyQuest> get dailyQuests {
    _ensureDailyQuestsCurrent();
    return _dailyQuests;
  }

  List<AppThemePreset> get themePresets => _themePresets;
  String get activeThemePresetId => _activeThemePresetId;

  // Connectivity & Notifications
  bool get isOnline => _isOnline;
  List<AppNotification> get notifications => _notifications;
  int get previousStreak => _previousStreak;
  bool get hasLostStreakPending => _hasLostStreakPending;
  bool get hasDismissedGuideCard => _hasDismissedGuideCard;

  /// Total count of notifications/badges on the Quest Map (unclaimed daily quests + new unconquered level)
  int get questBadgeCount {
    int count = 0;
    count += dailyQuests.where((q) => q.canClaim).length;
    try {
      final active = activeLiterature;
      final hasActive = active.questLevels.any((l) => !l.isCompleted && !l.isLocked);
      if (hasActive) count += 1;
    } catch (_) {}
    return count;
  }

  // League Getters
  String get leagueTierName => LeagueTier.nameOf(_profile.leagueTier);

  List<LeagueEntrant> get currentLeagueStandings {
    _ensureLeagueWeekCurrent();
    final now = DateTime.now();
    final weekStart = _profile.leagueWeekStart ?? LeagueRoster.weekStartOf(now);
    return LeagueRoster.standings(
      weekStart: weekStart,
      tier: _profile.leagueTier,
      userXp: _profile.weeklyXp,
      userName: _profile.name,
      now: now,
    );
  }

  int get currentLeagueRank {
    final standings = currentLeagueStandings;
    final idx = standings.indexWhere((e) => e.isUser);
    return idx == -1 ? standings.length : idx + 1;
  }

  void _ensureDailyQuestsCurrent() {
    final today = _startOfDay(DateTime.now());
    if (_dailyQuestsDate == null || _dailyQuestsDate != today) {
      _dailyQuestsDate = today;
      _dailyQuests = DailyQuest.generateFor(today);
    }
  }

  void _ensureLeagueWeekCurrent() {
    final now = DateTime.now();
    final currentWeekStart = LeagueRoster.weekStartOf(now);
    final savedWeekStart = _profile.leagueWeekStart;
    if (savedWeekStart == null) {
      _profile.leagueWeekStart = currentWeekStart;
      return;
    }
    if (currentWeekStart.isAfter(savedWeekStart)) {
      // Evaluate previous week's final standings
      final finalStandings = LeagueRoster.standings(
        weekStart: savedWeekStart,
        tier: _profile.leagueTier,
        userXp: _profile.weeklyXp,
        userName: _profile.name,
        now: LeagueRoster.weekEndOf(savedWeekStart),
        weekFraction: 1.0,
      );
      final rankIndex = finalStandings.indexWhere((e) => e.isUser);
      if (rankIndex != -1 && rankIndex < LeagueRoster.promoteCount) {
        _profile.leagueTier = (_profile.leagueTier + 1).clamp(0, LeagueTier.maxTier);
      } else if (rankIndex >= LeagueRoster.groupSize - LeagueRoster.demoteCount) {
        _profile.leagueTier = (_profile.leagueTier - 1).clamp(0, LeagueTier.maxTier);
      }
      _profile.weeklyXp = 0;
      _profile.leagueWeekStart = currentWeekStart;
      _save();
    }
  }

  void _advanceQuest(QuestMetric metric, [int amount = 1]) {
    _ensureDailyQuestsCurrent();
    for (final q in _dailyQuests) {
      if (q.metric == metric && !q.claimed) {
        q.progress = (q.progress + amount).clamp(0, q.target);
      }
    }
  }

  bool claimDailyQuest(String questId) {
    _ensureDailyQuestsCurrent();
    final idx = _dailyQuests.indexWhere((q) => q.id == questId);
    if (idx == -1) return false;
    final quest = _dailyQuests[idx];
    if (!quest.canClaim) return false;

    quest.claimed = true;
    _profile.gems += quest.rewardGems;
    activeLiterature.gemsEarned += quest.rewardGems;
    _profile.weeklyXp += 15;
    SoundService.instance.play(Sfx.reward);
    triggerHaptic();
    _save();
    notifyListeners();
    return true;
  }

  int get consecutiveCorrectAnswers => _consecutiveCorrectAnswers;

  int recordCorrectAnswer() {
    _consecutiveCorrectAnswers += 1;
    _advanceQuest(QuestMetric.correctAnswers, 1);
    _save();
    notifyListeners();
    return _consecutiveCorrectAnswers;
  }

  void resetConsecutiveCorrectAnswers() {
    _consecutiveCorrectAnswers = 0;
    _save();
    notifyListeners();
  }

  bool shouldShowDailyStreakCelebration() {
    if (!_isOnline) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check persistent profile date first, fallback to in-memory date
    final celebrated = _profile.lastStreakCelebratedDay ?? _lastDailyStreakCelebrationDate;
    if (celebrated != null) {
      final lastDate = DateTime(celebrated.year, celebrated.month, celebrated.day);
      if (!today.isAfter(lastDate)) {
        // Already celebrated today; strictly wait for 12:00 AM midnight reset!
        return false;
      }
    }
    return true;
  }

  void markDailyStreakCelebrated() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _profile.lastStreakCelebratedDay = today;
    _lastDailyStreakCelebrationDate = today;
    _save();
    notifyListeners();
  }

  // Word Bank (Spaced Repetition)
  void addOrUpdateVocabCard({
    required String word,
    required String definition,
    String example = '',
    required String literatureId,
    required String literatureTitle,
    bool markMissed = false,
  }) {
    final key = word.trim().toLowerCase();
    // Cards are scoped per book: the same word in two books has two different contexts.
    final existingIdx = _vocabDeck.indexWhere((c) => c.key == key && c.literatureId == literatureId);
    if (existingIdx != -1) {
      if (markMissed) {
        _vocabDeck[existingIdx].markWrong();
      }
      if (_isOnline && SupabaseService.instance.isConfigured) {
        SupabaseService.instance.syncVocabCard(_vocabDeck[existingIdx]);
      }
    } else {
      final newCard = VocabCard(
        word: word.trim(),
        definition: definition.trim(),
        example: example.trim(),
        literatureId: literatureId,
        literatureTitle: literatureTitle,
        box: 0,
      );
      _vocabDeck.insert(0, newCard);
      if (_isOnline && SupabaseService.instance.isConfigured) {
        SupabaseService.instance.syncVocabCard(newCard);
      }
    }
    _save();
    notifyListeners();
  }

  /// Reviews a vocabulary flashcard. Returns true if gems (+5) were awarded (only when the card was due).
  /// Words already known/reviewed today can still be practiced, but no longer grant repeat gems.
  bool reviewVocabCard(String wordKey, bool correct, {String? literatureId}) {
    final key = wordKey.trim().toLowerCase();
    final idx = _vocabDeck.indexWhere(
      (c) => c.key == key && (literatureId == null || c.literatureId == literatureId),
    );
    if (idx == -1) return false;

    final card = _vocabDeck[idx];
    final wasDue = card.isDue(DateTime.now());
    bool awardedGems = false;

    if (correct) {
      if (wasDue) {
        card.markCorrect();
        _profile.gems += 5;
        _profile.weeklyXp += 5;
        _advanceQuest(QuestMetric.gemsEarned, 5);
        _advanceQuest(QuestMetric.wordsReviewed, 1);
        awardedGems = true;
      }
      SoundService.instance.play(Sfx.correct);
    } else {
      card.markWrong();
      SoundService.instance.play(Sfx.wrong);
    }

    if (_isOnline && SupabaseService.instance.isConfigured) {
      SupabaseService.instance.syncVocabCard(card);
    }
    triggerHaptic();
    _save();
    notifyListeners();
    return awardedGems;
  }

  void dismissGuideCard() {
    _hasDismissedGuideCard = true;
    _save();
    notifyListeners();
  }

  void toggleOnlineStatus([bool? val]) {
    _isOnline = val ?? !_isOnline;
    SoundService.instance.play(Sfx.toggle);
    triggerHaptic();
    addNotification(
      AppNotification(
        id: 'notif_net_${DateTime.now().millisecondsSinceEpoch}',
        title: _isOnline ? 'Realm Connected (Online)' : 'Offline Reading Mode Active',
        message: _isOnline
            ? 'Thou art connected to the royal ledger. Full rewards, gems, and streak flames are recorded.'
            : 'Thou art in offline mode. Chapters and notes remain open to read, but gems and streaks are paused.',
        timestamp: DateTime.now(),
        type: _isOnline ? NotificationType.expeditionReady : NotificationType.offlineWarning,
      ),
    );
    _save();
    notifyListeners();
  }

  void addNotification(AppNotification notif) {
    _notifications.insert(0, notif);
    SoundService.instance.play(Sfx.notification);
    triggerHaptic();
    notifyListeners();
  }

  void markAllNotificationsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  bool buyStreakFreeze() {
    if (_profile.streakFreezes >= 3) return false;
    if (spendGems(100)) {
      _profile.streakFreezes += 1;
      SoundService.instance.play(Sfx.purchase);
      triggerHaptic();
      _save();
      notifyListeners();
      return true;
    }
    return false;
  }

  void simulateMidnightStreakLoss() {
    if (_profile.streakFreezes > 0 && _profile.streakDays > 0) {
      _profile.streakFreezes -= 1;
      addNotification(
        AppNotification(
          id: 'notif_freeze_used_${DateTime.now().millisecondsSinceEpoch}',
          title: '${_profile.name}, Streak Freeze Activated',
          message: 'Midnight frost descended, but your Streak Freeze shielded your ${_profile.streakDays}-day campfire (${_profile.streakFreezes} freezes left).',
          timestamp: DateTime.now(),
          type: NotificationType.streakRekindled,
          recipientName: _profile.name,
        ),
      );
      triggerHaptic();
      _save();
      notifyListeners();
      return;
    }

    _previousStreak = _profile.streakDays > 0 ? _profile.streakDays : 5;
    _profile.streakDays = 0;
    _hasLostStreakPending = true;
    addNotification(
      AppNotification(
        id: 'notif_streak_lost_${DateTime.now().millisecondsSinceEpoch}',
        title: '${_profile.name}, The Campfire Has Gone Cold',
        message: 'Midnight arrived and your $_previousStreak-day streak was extinguished into cold ash. Tap to rekindle your campfire today.',
        timestamp: DateTime.now(),
        type: NotificationType.streakLost,
        recipientName: _profile.name,
      ),
    );
    NotificationService().showStreakLostAlert(
      userName: _profile.name,
      previousStreak: _previousStreak,
    );
    triggerHaptic();
    _save();
    notifyListeners();
  }

  void simulateMidnightStreakWarning() {
    final workTitle = activeLiterature.title;
    addNotification(
      AppNotification(
        id: 'notif_streak_warn_${DateTime.now().millisecondsSinceEpoch}',
        title: '${_profile.name}, Midnight Hour Approaches (12:00 AM)',
        message: 'Complete today\'s reading in "$workTitle" before midnight to protect your ${_profile.streakDays}-day campfire.',
        timestamp: DateTime.now(),
        type: NotificationType.streakExpiring,
        recipientName: _profile.name,
        relatedWorkTitle: workTitle,
      ),
    );
    NotificationService().showStreakWarning(
      userName: _profile.name,
      streakDays: _profile.streakDays,
      activeBook: workTitle,
    );
    triggerHaptic();
    notifyListeners();
  }

  void clearLostStreakPending() {
    _hasLostStreakPending = false;
    _save();
    notifyListeners();
  }

  void rekindleStreak() {
    _profile.streakDays = 1;
    _hasLostStreakPending = false;
    SoundService.instance.play(Sfx.streakRekindle);
    triggerHaptic();
    addNotification(
      AppNotification(
        id: 'notif_rekindle_${DateTime.now().millisecondsSinceEpoch}',
        title: '${_profile.name}, Campfire Rekindled',
        message: 'The spark caught kindling! Day 1 streak is ignited. Read daily before 12:00 AM midnight to keep it blazing.',
        timestamp: DateTime.now(),
        type: NotificationType.streakRekindled,
        recipientName: _profile.name,
      ),
    );
    _save();
    notifyListeners();
  }

  bool restoreStreakWithGems() {
    if (_profile.isPremium || spendGems(50)) {
      _profile.streakDays = _previousStreak;
      _hasLostStreakPending = false;
      SoundService.instance.play(Sfx.streakRekindle);
      triggerHaptic();
      addNotification(
        AppNotification(
          id: 'notif_restore_${DateTime.now().millisecondsSinceEpoch}',
          title: '${_profile.name}, Streak Restored with Ember Shield',
          message: 'Your $_previousStreak-day streak has been shielded from the midnight frost.',
          timestamp: DateTime.now(),
          type: NotificationType.streakRekindled,
          recipientName: _profile.name,
        ),
      );
      _save();
      notifyListeners();
      return true;
    }
    return false;
  }

  void simulateLowEnergyAlert() {
    _profile.energy = 1;
    addNotification(
      AppNotification(
        id: 'notif_energy_${DateTime.now().millisecondsSinceEpoch}',
        title: '${_profile.name}, Knightly Energy is Weary (1/${_profile.maxEnergy})',
        message: 'Your knightly spirit wanes. Rest to restore hearts or undertake safe Practice levels without penalty.',
        timestamp: DateTime.now(),
        type: NotificationType.lowEnergy,
        recipientName: _profile.name,
      ),
    );
    NotificationService().showLowEnergyAlert(
      userName: _profile.name,
      currentEnergy: 1,
      maxEnergy: _profile.maxEnergy,
    );
    triggerHaptic();
    _save();
    notifyListeners();
  }

  void triggerEnergyRestoredNotification() {
    final bookTitle = activeLiterature.title;
    addNotification(
      AppNotification(
        id: 'notif_energy_full_${DateTime.now().millisecondsSinceEpoch}',
        title: '${_profile.name}, Energy is Fully Restored (${_profile.maxEnergy}/${_profile.maxEnergy})',
        message: 'Your stamina has recovered. All ${_profile.maxEnergy} hearts beat strong for your quest.',
        timestamp: DateTime.now(),
        type: NotificationType.energyRestored,
        recipientName: _profile.name,
        relatedWorkTitle: bookTitle,
      ),
    );
    NotificationService().showEnergyRestoredAlert(
      userName: _profile.name,
      maxEnergy: _profile.maxEnergy,
      activeBook: bookTitle,
    );
    triggerHaptic();
    _save();
    notifyListeners();
  }

  void triggerReadingGoalAchieved() {
    _profile.dailyMinutesReadToday = _profile.dailyGoalMinutes;
    final bookTitle = activeLiterature.title;
    addNotification(
      AppNotification(
        id: 'notif_goal_${DateTime.now().millisecondsSinceEpoch}',
        title: '${_profile.name}, Daily Reading Goal Fulfilled',
        message: 'You completed your ${_profile.dailyGoalMinutes}-minute pledge with "$bookTitle" today. Don Quixote salutes your devotion.',
        timestamp: DateTime.now(),
        type: NotificationType.readingGoalAchieved,
        recipientName: _profile.name,
        relatedWorkTitle: bookTitle,
      ),
    );
    NotificationService().showReadingGoalAchievedAlert(
      userName: _profile.name,
      minutes: _profile.dailyGoalMinutes,
      activeBook: bookTitle,
    );
    triggerHaptic();
    _save();
    notifyListeners();
  }

  void triggerExpeditionReady() {
    addNotification(
      AppNotification(
        id: 'notif_expedition_${DateTime.now().millisecondsSinceEpoch}',
        title: '${_profile.name}, Morning Expeditions Await',
        message: 'The morning herald brings fresh literary quests. Advance your chronicle to earn bonus guild gems.',
        timestamp: DateTime.now(),
        type: NotificationType.expeditionReady,
        recipientName: _profile.name,
      ),
    );
    NotificationService().showExpeditionReadyAlert(
      userName: _profile.name,
    );
    triggerHaptic();
    notifyListeners();
  }

  void triggerGoldenKeyAwarded([String? bookTitle]) {
    final title = bookTitle ?? activeLiterature.title;
    addGoldenKey();
    addNotification(
      AppNotification(
        id: 'notif_golden_key_${DateTime.now().millisecondsSinceEpoch}',
        title: '${_profile.name}, Golden Key of Masterwork Awarded',
        message: 'Your perfect understanding of "$title" has forged a Golden Key. Any volume in the realm may now be unlocked.',
        timestamp: DateTime.now(),
        type: NotificationType.goldenKeyAwarded,
        recipientName: _profile.name,
        relatedWorkTitle: title,
      ),
    );
    NotificationService().showGoldenKeyAlert(
      userName: _profile.name,
      bookTitle: title,
    );
    triggerHaptic();
    _save();
    notifyListeners();
  }

  void triggerMarginaliaReflection() {
    final title = activeLiterature.title;
    addNotification(
      AppNotification(
        id: 'notif_margin_${DateTime.now().millisecondsSinceEpoch}',
        title: '${_profile.name}, Marginalia Awaits Contemplation',
        message: 'Revisit your thoughtful notes and reflections on "$title" to deepen your literary understanding.',
        timestamp: DateTime.now(),
        type: NotificationType.marginaliaReflection,
        recipientName: _profile.name,
        relatedWorkTitle: title,
      ),
    );
    NotificationService().showMarginaliaReminderAlert(
      userName: _profile.name,
      bookTitle: title,
    );
    triggerHaptic();
    notifyListeners();
  }

  Future<void> sendRealPhoneNotificationTest() async {
    final title = '${_profile.name}, Quixoria Royal Dispatch';
    final body = 'Hark, ${_profile.name}! Real system notifications are operational on your device.';
    addNotification(
      AppNotification(
        id: 'notif_test_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: body,
        timestamp: DateTime.now(),
        type: NotificationType.expeditionReady,
        recipientName: _profile.name,
      ),
    );
    await NotificationService().showTestNotification(
      title: title,
      message: body,
    );
    triggerHaptic();
    notifyListeners();
  }

  AppThemePreset get activeThemePreset {
    return _themePresets.firstWhere(
      (p) => p.id == _activeThemePresetId,
      orElse: () => _themePresets.first,
    );
  }

  ThemeData get currentThemeData {
    if (_isDarkMode && _activeThemePresetId == 'theme_classic') {
      return AppTheme.darkTheme;
    }
    return activeThemePreset.toThemeData(isDarkMode: _isDarkMode);
  }

  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get hasSeenGuidedTour => _hasSeenGuidedTour;

  void completeGuidedTour() {
    _hasSeenGuidedTour = true;
    _save();
    notifyListeners();
  }

  void restartGuidedTour() {
    _hasSeenGuidedTour = false;
    notifyListeners();
  }
  String? get guideMessage => _guideMessage;
  String? get guideTitle => _guideTitle;

  // Settings getters
  bool get isDarkMode => _isDarkMode;
  bool get isReaderMode => _isReaderMode;
  bool get isDyslexicFont => _isDyslexicFont;
  bool get soundEffectsEnabled => _soundEffectsEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get hapticsEnabled => _hapticsEnabled;

  void toggleDarkMode([bool? value]) {
    _isDarkMode = value ?? !_isDarkMode;
    SoundService.instance.play(Sfx.toggle);
    triggerHaptic();
    _save();
    notifyListeners();
  }

  void toggleReaderMode([bool? value]) {
    _isReaderMode = value ?? !_isReaderMode;
    SoundService.instance.play(Sfx.toggle);
    triggerHaptic();
    _save();
    notifyListeners();
  }

  void toggleDyslexicFont([bool? value]) {
    _isDyslexicFont = value ?? !_isDyslexicFont;
    SoundService.instance.play(Sfx.toggle);
    triggerHaptic();
    _save();
    notifyListeners();
  }

  void toggleSoundEffects([bool? value]) {
    final nextVal = value ?? !_soundEffectsEnabled;
    if (_soundEffectsEnabled) {
      SoundService.instance.play(Sfx.toggle);
    }
    _soundEffectsEnabled = nextVal;
    SoundService.instance.enabled = _soundEffectsEnabled;
    if (_soundEffectsEnabled) {
      SoundService.instance.play(Sfx.toggle);
    }
    triggerHaptic();
    _save();
    notifyListeners();
  }

  void toggleMusic([bool? value]) {
    _musicEnabled = value ?? !_musicEnabled;
    AmbienceService.instance.syncWithSettings(musicEnabled: _musicEnabled);
    if (_musicEnabled) {
      AmbienceService.instance.resume();
    } else {
      AmbienceService.instance.pause();
    }
    SoundService.instance.play(Sfx.toggle);
    triggerHaptic();
    _save();
    notifyListeners();
  }

  void toggleHaptics([bool? value]) {
    _hapticsEnabled = value ?? !_hapticsEnabled;
    HapticService.instance.enabled = _hapticsEnabled;
    SoundService.instance.play(Sfx.toggle);
    if (_hapticsEnabled) HapticService.instance.medium();
    _save();
    notifyListeners();
  }

  void triggerHaptic() {
    if (_hapticsEnabled) {
      HapticService.instance.light();
    }
  }

  Future<void> logout() async {
    // Flush any pending local & cloud progress BEFORE signing out and clearing the session token
    await flushCloudSync();
    await AuthService.instance.logout();
    // Reset in-memory state cleanly so the next account on this device starts fresh
    _initDefaults();
    notifyListeners();
  }

  Literature get activeLiterature {
    return _catalog.firstWhere(
      (lit) => lit.id == _activeLiteratureId,
      orElse: () => _catalog.first,
    );
  }

  List<Literature> get ownedLiterature {
    return _catalog.where((lit) => lit.isOwned).toList();
  }

  List<Literature> get shopLiterature {
    return _catalog;
  }

  // Set active quest literature
  void setActiveLiterature(String id) {
    if (_activeLiteratureId != id) {
      _activeLiteratureId = id;
      _save();
      notifyListeners();
    }
  }

  void syncWithAuthSession() {
    if (AuthService.instance.isAuthenticated) {
      if (AuthService.instance.userName.isNotEmpty) {
        _profile.name = AuthService.instance.userName;
      }
      if (AuthService.instance.userEmail.isNotEmpty) {
        _profile.email = AuthService.instance.userEmail;
      }
      _save();
      notifyListeners();
    }
  }

  // User Profile Editing
  void updateUserProfile({
    String? name,
    String? email,
    String? readerRank,
    String? ageRange,
    String? difficulty,
    int? dailyGoalMinutes,
  }) {
    if (name != null && name.trim().isNotEmpty) {
      _profile.name = name.trim();
      AuthService.instance.updateDisplayName(_profile.name);
    }
    if (email != null && email.trim().isNotEmpty) _profile.email = email.trim();
    if (readerRank != null) _profile.readerRank = readerRank;
    if (ageRange != null) _profile.ageRange = ageRange;
    if (difficulty != null) _profile.difficulty = difficulty;
    if (dailyGoalMinutes != null) _profile.dailyGoalMinutes = dailyGoalMinutes;
    triggerHaptic();
    _save();
    notifyListeners();
  }

  // Theme Presets Store & Management
  bool buyThemePreset(String presetId) {
    final index = _themePresets.indexWhere((p) => p.id == presetId);
    if (index == -1) return false;

    final preset = _themePresets[index];
    if (preset.isOwned) return true;

    if (spendGems(preset.gemPrice)) {
      preset.isOwned = true;
      SoundService.instance.play(Sfx.purchase);
      triggerHaptic();
      _save();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> downloadThemePreset(String presetId) async {
    final index = _themePresets.indexWhere((p) => p.id == presetId);
    if (index == -1) return;

    final preset = _themePresets[index];
    if (!preset.isOwned) return;

    // Simulate animated in-app asset download
    for (int step = 1; step <= 5; step++) {
      await Future.delayed(const Duration(milliseconds: 150));
      preset.downloadProgress = step / 5.0;
      notifyListeners();
    }

    preset.isDownloaded = true;
    SoundService.instance.play(Sfx.themeDownload);
    triggerHaptic();
    _save();
    notifyListeners();
  }

  void applyThemePreset(String presetId) {
    final index = _themePresets.indexWhere((p) => p.id == presetId);
    if (index == -1) return;

    final preset = _themePresets[index];
    if (preset.isOwned && preset.isDownloaded) {
      _activeThemePresetId = presetId;
      addNotification(
        AppNotification(
          id: 'notif_theme_${DateTime.now().millisecondsSinceEpoch}',
          title: '${_profile.name}, Realm Aesthetic Equipped',
          message: 'You have donned the ${preset.name} visual theme across Quixoria.',
          timestamp: DateTime.now(),
          type: NotificationType.themeEquipped,
          recipientName: _profile.name,
        ),
      );
      SoundService.instance.play(Sfx.tap);
      triggerHaptic();
      _save();
      notifyListeners();
    }
  }

  // Update Onboarding with personalization and starting bounty
  void completeOnboarding({
    required List<String> genres,
    required String ageRange,
    required String difficulty,
    required int dailyGoalMinutes,
    String language = 'English',
    String readingHabit = 'Regular Reader',
    String? startingLiteratureId,
    int bonusGems = 100,
  }) {
    _profile.preferredGenres = genres;
    _profile.ageRange = ageRange;
    _profile.difficulty = difficulty;
    _profile.dailyGoalMinutes = dailyGoalMinutes;
    _profile.language = language;
    _profile.readingHabit = readingHabit;
    _profile.gems += bonusGems;
    _hasCompletedOnboarding = true;
    if (startingLiteratureId != null) {
      final index = _catalog.indexWhere((l) => l.id == startingLiteratureId);
      if (index != -1) {
        _catalog[index].isOwned = true;
        _activeLiteratureId = startingLiteratureId;
      }
    }
    _save();
    notifyListeners();
  }

  // Energy Management
  bool spendEnergy(int cost) {
    if (_profile.energy >= cost) {
      _profile.energy -= cost;
      if (_profile.energy <= 1 && !_profile.isPremium) {
        NotificationService().showLowEnergyAlert(
          userName: _profile.name,
          currentEnergy: _profile.energy,
          maxEnergy: _profile.maxEnergy,
        );
      }
      _save();
      notifyListeners();
      return true;
    }
    return false;
  }

  void refillEnergy() {
    _profile.energy = _profile.maxEnergy;
    triggerEnergyRestoredNotification();
    _save();
    notifyListeners();
  }

  /// Refills all energy hearts using gems (standard cost 50 gems)
  bool refillEnergyWithGems([int gemCost = 50]) {
    if (_profile.energy >= _profile.maxEnergy) return false;
    if (_profile.gems < gemCost) return false;
    _profile.gems -= gemCost;
    _profile.energy = _profile.maxEnergy;
    triggerEnergyRestoredNotification();
    _save();
    notifyListeners();
    return true;
  }

  void restoreEnergy(int amount) {
    final oldEnergy = _profile.energy;
    _profile.energy = (_profile.energy + amount).clamp(0, _profile.maxEnergy);
    if (oldEnergy < _profile.maxEnergy && _profile.energy == _profile.maxEnergy) {
      triggerEnergyRestoredNotification();
    } else {
      _save();
      notifyListeners();
    }
  }

  void recordDailyAppActivity() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_profile.lastActiveDay == null) {
      _profile.lastActiveDay = today;
    } else {
      final lastDate = DateTime(
        _profile.lastActiveDay!.year,
        _profile.lastActiveDay!.month,
        _profile.lastActiveDay!.day,
      );
      final differenceInDays = today.difference(lastDate).inDays;

      if (differenceInDays == 1) {
        // Next consecutive calendar day
        _profile.streakDays += 1;
        _profile.lastActiveDay = today;
        SoundService.instance.play(Sfx.streak);
        addNotification(
          AppNotification(
            id: 'notif_streak_inc_${now.millisecondsSinceEpoch}',
            title: '${_profile.name}, Streak Extended! (${_profile.streakDays} Days)',
            message: 'Thou hast answered the chivalric call another day! Campfire blazing strong.',
            timestamp: now,
            type: NotificationType.streakRekindled,
            recipientName: _profile.name,
          ),
        );
      } else if (differenceInDays == 2 && _profile.streakFreezes > 0) {
        // Missed 1 calendar day, but a Streak Freeze protects the streak!
        _profile.streakFreezes -= 1;
        _profile.streakDays += 1;
        _profile.lastActiveDay = today;
        SoundService.instance.play(Sfx.streak);
        addNotification(
          AppNotification(
            id: 'notif_freeze_saved_${now.millisecondsSinceEpoch}',
            title: '${_profile.name}, Streak Freeze Saved Your Campfire!',
            message: 'You missed yesterday, so 1 Streak Freeze was used to keep your ${_profile.streakDays}-day streak alive (${_profile.streakFreezes} left).',
            timestamp: now,
            type: NotificationType.streakRekindled,
            recipientName: _profile.name,
          ),
        );
      } else if (differenceInDays > 1) {
        // Missed one or more days without a freeze
        _previousStreak = _profile.streakDays;
        _profile.streakDays = 1;
        _profile.lastActiveDay = today;
        _hasLostStreakPending = true;
      } else {
        _profile.lastActiveDay = today;
      }
    }
    _save();
    notifyListeners();
  }

  // Gem Management
  void addGems(int amount) {
    _profile.gems += amount;
    activeLiterature.gemsEarned += amount;
    _advanceQuest(QuestMetric.gemsEarned, amount);
    _save();
    notifyListeners();
  }

  bool spendGems(int amount) {
    if (_profile.gems >= amount) {
      _profile.gems -= amount;
      _save();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Golden Key Management
  void addGoldenKey() {
    _profile.goldenKeys += 1;
    _save();
    notifyListeners();
  }

  bool spendGoldenKey() {
    if (_profile.goldenKeys > 0) {
      _profile.goldenKeys -= 1;
      _save();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Purchase Literature
  bool purchaseLiteratureWithGems(String literatureId) {
    final index = _catalog.indexWhere((l) => l.id == literatureId);
    if (index == -1) return false;

    final item = _catalog[index];
    if (item.isOwned) return true;

    if (spendGems(item.gemCost)) {
      item.isOwned = true;
      _profile.booksCompleted += 0;
      SoundService.instance.play(Sfx.bookAcquired);
      _save();
      notifyListeners();
      return true;
    }
    return false;
  }

  bool unlockLiteratureWithGoldenKey(String literatureId) {
    final index = _catalog.indexWhere((l) => l.id == literatureId);
    if (index == -1) return false;

    final item = _catalog[index];
    if (item.isOwned) return true;

    if (spendGoldenKey()) {
      item.isOwned = true;
      SoundService.instance.play(Sfx.bookAcquired);
      _save();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Simulated Premium Subscription Activation
  void activatePremiumSubscription(String planName) {
    _profile.isPremium = true;
    _profile.energy = _profile.maxEnergy;
    // Bonus welcome gift from Don Quixote
    addGems(500);
    addGoldenKey();
    SoundService.instance.play(Sfx.reward);
    _save();
    notifyListeners();
  }

  // Reading Position Tracking
  double getReadingOffset(String literatureId, int chapterIndex) {
    return _profile.readingOffsets['${literatureId}_$chapterIndex'] ?? 0.0;
  }

  void saveReadingOffset(String literatureId, int chapterIndex, double offset) {
    final key = '${literatureId}_$chapterIndex';
    final prev = _profile.readingOffsets[key] ?? 0.0;
    // Debounce micro-scrolls: only save if change exceeds 20px
    if ((prev - offset).abs() > 20.0) {
      _profile.readingOffsets[key] = offset;
      _save();
    }
  }

  void clearReadingOffset(String literatureId, int chapterIndex) {
    final key = '${literatureId}_$chapterIndex';
    if (_profile.readingOffsets.containsKey(key)) {
      _profile.readingOffsets.remove(key);
      _save();
    }
  }

  // Complete a Level
  bool completeQuestLevel({
    required String literatureId,
    required String levelId,
    required bool isPerfectScore,
  }) {
    final litIndex = _catalog.indexWhere((l) => l.id == literatureId);
    if (litIndex == -1) return false;

    final lit = _catalog[litIndex];
    final levelIndex = lit.questLevels.indexWhere((lvl) => lvl.id == levelId);
    if (levelIndex == -1) return false;

    final level = lit.questLevels[levelIndex];

    if (!_isOnline) {
      // Offline mode: allow level reading completion locally so user can continue reading,
      // but strictly DO NOT award gems, DO NOT increment streak, and DO NOT award golden keys!
      if (!level.isCompleted) {
        level.isCompleted = true;
        if (levelIndex + 1 < lit.questLevels.length) {
          lit.questLevels[levelIndex + 1].isLocked = false;
          lit.currentLevelIndex = levelIndex + 1;
        }
      }
      addNotification(
        AppNotification(
          id: 'notif_offline_${DateTime.now().millisecondsSinceEpoch}',
          title: '${_profile.name}, Offline Reading Recorded',
          message: 'You completed "${level.title}" offline. No gems or streak progression were recorded without an online connection.',
          timestamp: DateTime.now(),
          type: NotificationType.offlineWarning,
          recipientName: _profile.name,
        ),
      );
      _save();
      notifyListeners();
      return false; // indicates offline completion (no rewards)
    }

    _ensureLeagueWeekCurrent();
    _advanceQuest(QuestMetric.levelsCompleted, 1);
    if (level.type == LevelType.read) {
      _advanceQuest(QuestMetric.chaptersRead, 1);
    }
    if (isPerfectScore) {
      _advanceQuest(QuestMetric.perfectQuizzes, 1);
    }

    if (!level.isCompleted) {
      level.isCompleted = true;
      _profile.levelsCompleted += 1;
      _profile.weeklyXp += isPerfectScore ? 35 : 25;
      addGems(level.gemsReward);
      SoundService.instance.play(Sfx.levelComplete);

      // Online: Daily App Streak & Answer Streak
      recordDailyAppActivity();

      // Answer streak tracking (only awarded for 100% flawless quizzes/quests)
      if (isPerfectScore) {
        _profile.answerStreak += 1;
      } else {
        _profile.answerStreak = 0;
      }

      // Track daily reading progress
      _profile.dailyMinutesReadToday += 5;
      if (_profile.dailyMinutesReadToday >= _profile.dailyGoalMinutes) {
        NotificationService().showReadingGoalAchievedAlert(
          userName: _profile.name,
          minutes: _profile.dailyGoalMinutes,
          activeBook: lit.title,
        );
        addNotification(
          AppNotification(
            id: 'notif_goal_${DateTime.now().millisecondsSinceEpoch}',
            title: '${_profile.name}, Daily Reading Goal Fulfilled',
            message: 'You completed your ${_profile.dailyGoalMinutes}-minute pledge with "${lit.title}" today. Don Quixote salutes your devotion.',
            timestamp: DateTime.now(),
            type: NotificationType.readingGoalAchieved,
            recipientName: _profile.name,
            relatedWorkTitle: lit.title,
          ),
        );
      }

      // Final exam evaluation
      if (level.type == LevelType.finalTest) {
        if (isPerfectScore) {
          addGoldenKey();
          NotificationService().showGoldenKeyAlert(
            userName: _profile.name,
            bookTitle: lit.title,
          );
          addNotification(
            AppNotification(
              id: 'notif_golden_key_${DateTime.now().millisecondsSinceEpoch}',
              title: '${_profile.name}, Golden Key of Masterwork Awarded',
              message: 'Your perfect understanding of "${lit.title}" has forged a Golden Key. Any volume in the realm may now be unlocked.',
              timestamp: DateTime.now(),
              type: NotificationType.goldenKeyAwarded,
              recipientName: _profile.name,
              relatedWorkTitle: lit.title,
            ),
          );
        }
        _profile.booksCompleted += 1;
      }

      // Unlock next level in sequence
      if (levelIndex + 1 < lit.questLevels.length) {
        lit.questLevels[levelIndex + 1].isLocked = false;
        lit.currentLevelIndex = levelIndex + 1;
      }
    } else {
      // Retaking level online still sustains daily streak & updates answer streak
      _profile.weeklyXp += isPerfectScore ? 15 : 10;
      SoundService.instance.play(Sfx.levelComplete);
      recordDailyAppActivity();
      if (isPerfectScore) {
        _profile.answerStreak += 1;
      } else {
        _profile.answerStreak = 0;
      }
    }

    _save();
    notifyListeners();
    return true; // online completion with rewards & streak triggered!
  }

  // Notes Management
  void addNote({
    required String literatureId,
    required String literatureTitle,
    required String chapterTitle,
    required NoteType type,
    required String title,
    required String content,
  }) {
    final newNote = ReadingNote(
      id: 'note_${DateTime.now().millisecondsSinceEpoch}',
      literatureId: literatureId,
      literatureTitle: literatureTitle,
      chapterTitle: chapterTitle,
      type: type,
      title: title,
      content: content,
      createdAt: DateTime.now(),
    );
    _notes.insert(0, newNote);
    _profile.notesSaved = _notes.length;
    if (_isOnline && SupabaseService.instance.isConfigured) {
      SupabaseService.instance.syncReadingNote(newNote);
    }

    // Also add vocabulary notes into the SRS Word Bank automatically
    if (type == NoteType.vocabulary && title.trim().isNotEmpty) {
      addOrUpdateVocabCard(
        word: title,
        definition: content,
        literatureId: literatureId,
        literatureTitle: literatureTitle,
      );
    }

    addNotification(
      AppNotification(
        id: 'notif_note_${DateTime.now().millisecondsSinceEpoch}',
        title: '${_profile.name}, Marginalia Inscribed',
        message: 'Your insight on "$literatureTitle" has been preserved in your reading notebook.',
        timestamp: DateTime.now(),
        type: NotificationType.marginaliaReflection,
        recipientName: _profile.name,
        relatedWorkTitle: literatureTitle,
      ),
    );
    _save();
    notifyListeners();
  }

  void updateNote(String id, String newTitle, String newContent, NoteType newType) {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notes[index] = _notes[index].copyWith(
        title: newTitle,
        content: newContent,
        type: newType,
      );
      _save();
      notifyListeners();
    }
  }

  void deleteNote(String id) {
    _notes.removeWhere((n) => n.id == id);
    _profile.notesSaved = _notes.length;
    _save();
    notifyListeners();
  }

  void restoreNote(ReadingNote note) {
    if (!_notes.any((n) => n.id == note.id)) {
      _notes.insert(0, note);
      _profile.notesSaved = _notes.length;
      _save();
      notifyListeners();
    }
  }

  List<ReadingNote> getNotesForLiterature(String literatureId) {
    return _notes.where((n) => n.literatureId == literatureId).toList();
  }

  List<VocabCard> _getInitialVocabDeck() {
    return <VocabCard>[];
  }

  List<ReadingNote> _getInitialNotes() {
    return <ReadingNote>[];
  }

  List<AppNotification> _getInitialNotifications() {
    return <AppNotification>[];
  }
}
