class UserProfile {
  String name;
  String email;
  String readerRank;
  int streakDays;
  int answerStreak; // Consecutive 100% flawless quizzes/quests cleared
  DateTime? lastActiveDay;
  DateTime? lastStreakCelebratedDay;
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

  UserProfile({
    this.name = 'Alonso Quijano',
    this.email = 'alonso.quijano@la-mancha.literary',
    this.readerRank = 'Knight Errant of Letters',
    this.streakDays = 1,
    this.answerStreak = 0,
    this.lastActiveDay,
    this.lastStreakCelebratedDay,
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
  }) : readingOffsets = readingOffsets ?? <String, double>{};

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'readerRank': readerRank,
        'streakDays': streakDays,
        'answerStreak': answerStreak,
        'lastActiveDay': lastActiveDay?.toIso8601String(),
        'lastStreakCelebratedDay': lastStreakCelebratedDay?.toIso8601String(),
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
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: (j['name'] as String?) ?? 'Alonso Quijano',
        email: (j['email'] as String?) ?? 'alonso.quijano@la-mancha.literary',
        readerRank: (j['readerRank'] as String?) ?? 'Knight Errant of Letters',
        streakDays: (j['streakDays'] as num?)?.toInt() ?? 1,
        answerStreak: (j['answerStreak'] as num?)?.toInt() ?? 0,
        lastActiveDay: DateTime.tryParse((j['lastActiveDay'] as String?) ?? ''),
        lastStreakCelebratedDay: DateTime.tryParse((j['lastStreakCelebratedDay'] as String?) ?? ''),
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
      );
}
