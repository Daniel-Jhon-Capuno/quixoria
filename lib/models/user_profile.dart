class UserProfile {
  String name;
  String email;
  String readerRank;
  int streakDays;
  int longestStreak;
  int totalDaysRead;
  int answerStreak; // Consecutive 100% flawless quizzes/quests cleared
  DateTime? lastActiveDay;
  DateTime? lastStreakCelebratedDay;
  int? lastActivityUtcMs; // Anti-clock-rollback monotonic timestamp
  String? lastCompletedLocalDayKey; // 'YYYY-MM-DD' in user's local calendar
  String? dailyProgressDayKey; // 'YYYY-MM-DD' for dailyMinutesReadToday rollover
  Map<String, String> streakHistory; // 'YYYY-MM-DD' -> 'completed' | 'frozen'
  List<int> claimedStreakMilestones; // e.g. [3, 7, 14, 30, 100]
  int? repairableStreakDays;
  int? repairWindowExpiresUtcMs;
  int gems;
  int energy;
  int maxEnergy;
  int goldenKeys;
  int streakFreezes;
  int weeklyXp;
  int leagueTier;
  DateTime? leagueWeekStart;
  int booksCompleted;
  int levelsCompleted;
  int notesSaved;
  int dailyGoalMinutes;
  int dailyMinutesReadToday;
  List<String> preferredGenres;
  String ageRange;
  String difficulty;
  String language;
  String readingHabit;
  bool isPremium;
  Map<String, double> readingOffsets;

  // Cosmetics, Achievements & Activity Analytics
  String equippedFrameId;
  String equippedTitleId;
  String equippedBannerId;
  String equippedAvatarIconId;
  List<String> ownedFrameIds;
  List<String> ownedTitleIds;
  List<String> ownedBannerIds;
  List<String> ownedAvatarIconIds;
  List<String> claimedAchievementIds;
  int darkModeChaptersRead;
  int totalQuizzesTaken;
  int totalQuizzesCorrect;
  Map<String, int> activityByDay; // 'YYYY-MM-DD' -> activity weight
  Map<String, String> paragraphHighlights; // 'litId|levelId|pIdx' -> 'gold'|'rose'|'sage'|'sky'
  List<String> bookmarkedPassages; // 'litId|levelId|pIdx'
  int? lastLeaderboardRank;
  bool hasUnreadLeaderboardUpdate;
  bool hasEarnedTop1Percent;
  bool hasClaimedTop1Chest;
  String? lastDailyChestDayKey;
  int dailyChestStreak;
  List<Map<String, dynamic>> friendStreaksJson;
  List<String> defeatedBossBooks;
  List<String> pinnedTrophyIds;
  String? lastSeenAppVersion;

  UserProfile({
    this.name = 'Alonso Quijano',
    this.email = 'alonso.quijano@la-mancha.literary',
    this.readerRank = 'Knight Errant of Letters',
    this.streakDays = 1,
    int? longestStreak,
    int? totalDaysRead,
    this.answerStreak = 0,
    this.lastActiveDay,
    this.lastStreakCelebratedDay,
    this.lastActivityUtcMs,
    this.lastCompletedLocalDayKey,
    this.dailyProgressDayKey,
    Map<String, String>? streakHistory,
    List<int>? claimedStreakMilestones,
    this.repairableStreakDays,
    this.repairWindowExpiresUtcMs,
    this.gems = 650,
    this.energy = 5,
    this.maxEnergy = 5,
    this.goldenKeys = 0,
    this.streakFreezes = 0,
    this.weeklyXp = 0,
    this.leagueTier = 2, // Knight
    this.leagueWeekStart,
    this.booksCompleted = 0,
    this.levelsCompleted = 0,
    this.notesSaved = 0,
    this.dailyGoalMinutes = 15,
    this.dailyMinutesReadToday = 0,
    this.preferredGenres = const ['Adventure', 'Classics', 'Poetry'],
    this.ageRange = 'Young Adult (16-24)',
    this.difficulty = 'Intermediate Explorer',
    this.language = 'English',
    this.readingHabit = 'Regular Reader',
    this.isPremium = false,
    Map<String, double>? readingOffsets,
    this.equippedFrameId = 'frame_classic',
    this.equippedTitleId = 'title_knight_errant',
    this.equippedBannerId = 'banner_classic',
    this.equippedAvatarIconId = 'avatar_quixote',
    List<String>? ownedFrameIds,
    List<String>? ownedTitleIds,
    List<String>? ownedBannerIds,
    List<String>? ownedAvatarIconIds,
    List<String>? claimedAchievementIds,
    this.darkModeChaptersRead = 0,
    this.totalQuizzesTaken = 0,
    this.totalQuizzesCorrect = 0,
    Map<String, int>? activityByDay,
    Map<String, String>? paragraphHighlights,
    List<String>? bookmarkedPassages,
    this.lastLeaderboardRank,
    this.hasUnreadLeaderboardUpdate = false,
    this.hasEarnedTop1Percent = false,
    this.hasClaimedTop1Chest = false,
    this.lastDailyChestDayKey,
    this.dailyChestStreak = 0,
    List<Map<String, dynamic>>? friendStreaksJson,
    List<String>? defeatedBossBooks,
    List<String>? pinnedTrophyIds,
    this.lastSeenAppVersion,
  })  : longestStreak = longestStreak ?? streakDays,
        friendStreaksJson = friendStreaksJson ?? <Map<String, dynamic>>[],
        defeatedBossBooks = defeatedBossBooks ?? <String>[],
        pinnedTrophyIds = pinnedTrophyIds ?? <String>[],
        totalDaysRead = totalDaysRead ?? (streakDays > 0 ? streakDays : 0),
        streakHistory = streakHistory ?? <String, String>{},
        claimedStreakMilestones = claimedStreakMilestones ?? <int>[],
        readingOffsets = readingOffsets ?? <String, double>{},
        paragraphHighlights = paragraphHighlights ?? <String, String>{},
        bookmarkedPassages = bookmarkedPassages ?? <String>[],
        ownedFrameIds = ownedFrameIds ?? <String>['frame_classic'],
        ownedTitleIds = ownedTitleIds ?? <String>['title_knight_errant'],
        ownedBannerIds = ownedBannerIds ?? <String>['banner_classic'],
        ownedAvatarIconIds = ownedAvatarIconIds ??
            <String>[
              'avatar_quixote',
              'avatar_butterfly',
              'avatar_leaf',
              'avatar_fish',
              'avatar_owl',
              'avatar_cat',
            ],
        claimedAchievementIds = claimedAchievementIds ?? <String>[],
        activityByDay = activityByDay ?? <String, int>{};

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'readerRank': readerRank,
        'streakDays': streakDays,
        'longestStreak': longestStreak,
        'totalDaysRead': totalDaysRead,
        'answerStreak': answerStreak,
        'lastActiveDay': lastActiveDay?.toIso8601String(),
        'lastStreakCelebratedDay': lastStreakCelebratedDay?.toIso8601String(),
        'lastActivityUtcMs': lastActivityUtcMs,
        'lastCompletedLocalDayKey': lastCompletedLocalDayKey,
        'dailyProgressDayKey': dailyProgressDayKey,
        'streakHistory': streakHistory,
        'claimedStreakMilestones': claimedStreakMilestones,
        'repairableStreakDays': repairableStreakDays,
        'repairWindowExpiresUtcMs': repairWindowExpiresUtcMs,
        'gems': gems,
        'energy': energy,
        'maxEnergy': maxEnergy,
        'goldenKeys': goldenKeys,
        'streakFreezes': streakFreezes,
        'weeklyXp': weeklyXp,
        'leagueTier': leagueTier,
        'leagueWeekStart': leagueWeekStart?.toIso8601String(),
        'booksCompleted': booksCompleted,
        'levelsCompleted': levelsCompleted,
        'notesSaved': notesSaved,
        'dailyGoalMinutes': dailyGoalMinutes,
        'dailyMinutesReadToday': dailyMinutesReadToday,
        'preferredGenres': preferredGenres,
        'ageRange': ageRange,
        'difficulty': difficulty,
        'language': language,
        'readingHabit': readingHabit,
        'isPremium': isPremium,
        'readingOffsets': readingOffsets,
        'equippedFrameId': equippedFrameId,
        'equippedTitleId': equippedTitleId,
        'equippedBannerId': equippedBannerId,
        'equippedAvatarIconId': equippedAvatarIconId,
        'ownedFrameIds': ownedFrameIds,
        'ownedTitleIds': ownedTitleIds,
        'ownedBannerIds': ownedBannerIds,
        'ownedAvatarIconIds': ownedAvatarIconIds,
        'claimedAchievementIds': claimedAchievementIds,
        'darkModeChaptersRead': darkModeChaptersRead,
        'totalQuizzesTaken': totalQuizzesTaken,
        'totalQuizzesCorrect': totalQuizzesCorrect,
        'activityByDay': activityByDay,
        'paragraphHighlights': paragraphHighlights,
        'bookmarkedPassages': bookmarkedPassages,
        'lastLeaderboardRank': lastLeaderboardRank,
        'hasUnreadLeaderboardUpdate': hasUnreadLeaderboardUpdate,
        'hasEarnedTop1Percent': hasEarnedTop1Percent,
        'hasClaimedTop1Chest': hasClaimedTop1Chest,
        'lastDailyChestDayKey': lastDailyChestDayKey,
        'dailyChestStreak': dailyChestStreak,
        'friendStreaksJson': friendStreaksJson,
        'defeatedBossBooks': defeatedBossBooks,
        'pinnedTrophyIds': pinnedTrophyIds,
        'lastSeenAppVersion': lastSeenAppVersion,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: (j['name'] as String?) ?? 'Alonso Quijano',
        email: (j['email'] as String?) ?? 'alonso.quijano@la-mancha.literary',
        readerRank: (j['readerRank'] as String?) ?? 'Knight Errant of Letters',
        streakDays: (j['streakDays'] as num?)?.toInt() ?? 1,
        longestStreak: (j['longestStreak'] as num?)?.toInt(),
        totalDaysRead: (j['totalDaysRead'] as num?)?.toInt(),
        answerStreak: (j['answerStreak'] as num?)?.toInt() ?? 0,
        lastActiveDay: DateTime.tryParse((j['lastActiveDay'] as String?) ?? ''),
        lastStreakCelebratedDay: DateTime.tryParse((j['lastStreakCelebratedDay'] as String?) ?? ''),
        lastActivityUtcMs: (j['lastActivityUtcMs'] as num?)?.toInt(),
        lastCompletedLocalDayKey: j['lastCompletedLocalDayKey'] as String?,
        dailyProgressDayKey: j['dailyProgressDayKey'] as String?,
        streakHistory: (j['streakHistory'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, v.toString()),
            ) ??
            <String, String>{},
        claimedStreakMilestones: (j['claimedStreakMilestones'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            <int>[],
        repairableStreakDays: (j['repairableStreakDays'] as num?)?.toInt(),
        repairWindowExpiresUtcMs: (j['repairWindowExpiresUtcMs'] as num?)?.toInt(),
        gems: (j['gems'] as num?)?.toInt() ?? 650,
        energy: (j['energy'] as num?)?.toInt() ?? 5,
        maxEnergy: (j['maxEnergy'] as num?)?.toInt() ?? 5,
        goldenKeys: (j['goldenKeys'] as num?)?.toInt() ?? 0,
        streakFreezes: (j['streakFreezes'] as num?)?.toInt() ?? 0,
        weeklyXp: (j['weeklyXp'] as num?)?.toInt() ?? 0,
        leagueTier: (j['leagueTier'] as num?)?.toInt() ?? 2,
        leagueWeekStart: DateTime.tryParse((j['leagueWeekStart'] as String?) ?? ''),
        booksCompleted: (j['booksCompleted'] as num?)?.toInt() ?? 0,
        levelsCompleted: (j['levelsCompleted'] as num?)?.toInt() ?? 0,
        notesSaved: (j['notesSaved'] as num?)?.toInt() ?? 0,
        dailyGoalMinutes: (j['dailyGoalMinutes'] as num?)?.toInt() ?? 15,
        dailyMinutesReadToday: (j['dailyMinutesReadToday'] as num?)?.toInt() ?? 0,
        preferredGenres: (j['preferredGenres'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const ['Adventure', 'Classics', 'Poetry'],
        ageRange: (j['ageRange'] as String?) ?? 'Young Adult (16-24)',
        difficulty: (j['difficulty'] as String?) ?? 'Intermediate Explorer',
        language: (j['language'] as String?) ?? 'English',
        readingHabit: (j['readingHabit'] as String?) ?? 'Regular Reader',
        isPremium: (j['isPremium'] as bool?) ?? false,
        readingOffsets: (j['readingOffsets'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            <String, double>{},
        equippedFrameId: (j['equippedFrameId'] as String?) ?? 'frame_classic',
        equippedTitleId: (j['equippedTitleId'] as String?) ?? 'title_knight_errant',
        equippedBannerId: (j['equippedBannerId'] as String?) ?? 'banner_classic',
        equippedAvatarIconId: (j['equippedAvatarIconId'] as String?) ?? 'avatar_quixote',
        ownedFrameIds: (j['ownedFrameIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>['frame_classic'],
        ownedTitleIds: (j['ownedTitleIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>['title_knight_errant'],
        ownedBannerIds: (j['ownedBannerIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>['banner_classic'],
        ownedAvatarIconIds: (j['ownedAvatarIconIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[
              'avatar_quixote',
              'avatar_butterfly',
              'avatar_leaf',
              'avatar_fish',
              'avatar_owl',
              'avatar_cat',
            ],
        claimedAchievementIds: (j['claimedAchievementIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[],
        darkModeChaptersRead: (j['darkModeChaptersRead'] as num?)?.toInt() ?? 0,
        totalQuizzesTaken: (j['totalQuizzesTaken'] as num?)?.toInt() ?? 0,
        totalQuizzesCorrect: (j['totalQuizzesCorrect'] as num?)?.toInt() ?? 0,
        activityByDay: (j['activityByDay'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toInt()),
            ) ??
            <String, int>{},
        paragraphHighlights: (j['paragraphHighlights'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, v.toString()),
            ) ??
            <String, String>{},
        bookmarkedPassages: (j['bookmarkedPassages'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[],
        lastLeaderboardRank: (j['lastLeaderboardRank'] as num?)?.toInt(),
        hasUnreadLeaderboardUpdate: (j['hasUnreadLeaderboardUpdate'] as bool?) ?? false,
        hasEarnedTop1Percent: (j['hasEarnedTop1Percent'] as bool?) ?? false,
        hasClaimedTop1Chest: (j['hasClaimedTop1Chest'] as bool?) ?? false,
        lastDailyChestDayKey: j['lastDailyChestDayKey'] as String?,
        dailyChestStreak: (j['dailyChestStreak'] as num?)?.toInt() ?? 0,
        friendStreaksJson: (j['friendStreaksJson'] as List<dynamic>?)
                ?.whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m))
                .toList() ??
            <Map<String, dynamic>>[],
        defeatedBossBooks: (j['defeatedBossBooks'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[],
        pinnedTrophyIds: (j['pinnedTrophyIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[],
        lastSeenAppVersion: j['lastSeenAppVersion'] as String?,
      );
}
