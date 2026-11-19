import 'dart:math' as math;
import '../../models/user_profile.dart';

/// Current visual & behavioral state of a user's reading streak.
enum StreakStatus {
  /// User already completed today's daily goal.
  activeToday,

  /// Streak is alive (> 0) from yesterday/freeze, but today's goal is not yet done.
  atRiskToday,

  /// Streak was broken after missing day(s) without enough freezes.
  broken,

  /// Brand-new scholar who hasn't completed their first day yet.
  fresh,
}

/// Visual status of an individual calendar day in the Weekly Streak Calendar.
enum WeeklyDayState {
  completed,
  frozen,
  missed,
  todayPending,
  future,
}

class WeeklyStreakDay {
  final DateTime date;
  final String dayKey;
  final String shortLabel; // Mon, Tue, ...
  final WeeklyDayState state;
  final bool isToday;

  const WeeklyStreakDay({
    required this.date,
    required this.dayKey,
    required this.shortLabel,
    required this.state,
    required this.isToday,
  });
}

class StreakMilestone {
  final int days;
  final String title;
  final int gemReward;
  final int bonusFreezes;

  const StreakMilestone({
    required this.days,
    required this.title,
    required this.gemReward,
    this.bonusFreezes = 0,
  });
}

class StreakEvaluationResult {
  final bool changed;
  final int freezesConsumed;
  final bool streakBroken;
  final int previousStreakBeforeBreak;
  final bool clockTampered;
  final bool dailyMinutesReset;

  const StreakEvaluationResult({
    this.changed = false,
    this.freezesConsumed = 0,
    this.streakBroken = false,
    this.previousStreakBeforeBreak = 0,
    this.clockTampered = false,
    this.dailyMinutesReset = false,
  });
}

class StreakActivityResult {
  final bool streakExtended;
  final bool dailyGoalJustReached;
  final bool clockTampered;
  final int newStreakDays;
  final int freezesConsumed;
  final List<StreakMilestone> newlyReachedMilestones;

  const StreakActivityResult({
    this.streakExtended = false,
    this.dailyGoalJustReached = false,
    this.clockTampered = false,
    required this.newStreakDays,
    this.freezesConsumed = 0,
    this.newlyReachedMilestones = const [],
  });
}

/// Pure, UI-independent automatic Streak Engine.
///
/// Design guarantees:
/// - **100% Automatic**: Never requires tapping/claiming; extends automatically
///   once per local calendar day when the user completes a real activity
///   (level/quiz completion or hitting their daily reading minutes goal).
/// - **Local Calendar Day + Travel/Timezone Safe**: Uses local `'YYYY-MM-DD'`
///   keys and enforces monotonic UTC timestamps to prevent clock-rollback cheating.
/// - **Multi-Freeze Protection**: Automatically consumes 1 freeze per missed day
///   when enough freezes are available and records `'frozen'` days in history.
/// - **Fair 48-Hour Streak Repair**: If a streak breaks, offers a 48h repair
///   window (costing [repairGemCost] gems) to restore the broken streak.
/// - **Offline-First & Supabase-Mergeable**: Cleanly merges local and cloud
///   day histories without losing or double-counting days.
class StreakService {
  static const int maxFreezes = 3;
  static const int repairGemCost = 150;
  static const Duration repairWindowDuration = Duration(hours: 48);

  /// Tolerance for minor NTP / automatic network clock adjustments.
  static const Duration clockRollbackTolerance = Duration(minutes: 10);

  static const List<StreakMilestone> milestones = [
    StreakMilestone(days: 3, title: 'Kindled Spark', gemReward: 75),
    StreakMilestone(days: 7, title: 'Weekly Flame', gemReward: 150, bonusFreezes: 1),
    StreakMilestone(days: 14, title: 'Fortnight Scholar', gemReward: 300),
    StreakMilestone(days: 30, title: 'Moonlight Archivist', gemReward: 600, bonusFreezes: 1),
    StreakMilestone(days: 100, title: 'Immortal Flame', gemReward: 2000, bonusFreezes: 1),
  ];

  /// Formats a local [DateTime] into `'YYYY-MM-DD'`.
  static String localDayKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Parses `'YYYY-MM-DD'` back to a local midnight [DateTime], or null.
  static DateTime? parseDayKey(String? key) {
    if (key == null || key.length != 10) return null;
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// Computes integer calendar-day difference (`to - from`) using UTC noon
  /// so Daylight Saving Time (23h / 25h) days never cause off-by-one bugs!
  static int calendarDaysBetween(DateTime fromLocal, DateTime toLocal) {
    final a = DateTime.utc(fromLocal.year, fromLocal.month, fromLocal.day, 12);
    final b = DateTime.utc(toLocal.year, toLocal.month, toLocal.day, 12);
    return b.difference(a).inDays;
  }

  /// Resolves the last completed local calendar day from [profile] (with
  /// backward-compatible migration from legacy [UserProfile.lastActiveDay]).
  static DateTime? _resolveLastCompletedDay(UserProfile profile) {
    final parsed = parseDayKey(profile.lastCompletedLocalDayKey);
    if (parsed != null) return parsed;
    if (profile.lastActiveDay != null) {
      return DateTime(
        profile.lastActiveDay!.year,
        profile.lastActiveDay!.month,
        profile.lastActiveDay!.day,
      );
    }
    return null;
  }

  /// Checks whether the device clock appears to have been rolled backward
  /// significantly compared to the last recorded UTC activity timestamp.
  static bool isClockRolledBack(UserProfile profile, DateTime now) {
    final lastUtc = profile.lastActivityUtcMs;
    if (lastUtc == null) return false;
    final nowUtc = now.toUtc().millisecondsSinceEpoch;
    return nowUtc < (lastUtc - clockRollbackTolerance.inMilliseconds);
  }

  /// Returns whether a broken streak can currently be repaired.
  static bool canRepairStreak(UserProfile profile, {DateTime? now}) {
    final t = now ?? DateTime.now();
    final repairDays = profile.repairableStreakDays ?? 0;
    final expiresMs = profile.repairWindowExpiresUtcMs ?? 0;
    if (repairDays <= 0 || profile.streakDays > 0) return false;
    return t.toUtc().millisecondsSinceEpoch <= expiresMs;
  }

  /// Computes the current [StreakStatus] for UI badges and flame icons.
  static StreakStatus computeStatus(UserProfile profile, {DateTime? now}) {
    final t = now ?? DateTime.now();
    final todayKey = localDayKey(t);
    final lastDay = _resolveLastCompletedDay(profile);

    if (profile.lastCompletedLocalDayKey == todayKey ||
        profile.streakHistory[todayKey] == 'completed') {
      return StreakStatus.activeToday;
    }

    if (profile.streakDays <= 0) {
      return (profile.totalDaysRead > 0 || (profile.repairableStreakDays ?? 0) > 0)
          ? StreakStatus.broken
          : StreakStatus.fresh;
    }

    if (lastDay == null) {
      return StreakStatus.atRiskToday;
    }

    final gap = calendarDaysBetween(lastDay, DateTime(t.year, t.month, t.day));
    if (gap == 0) return StreakStatus.activeToday;
    if (gap == 1) return StreakStatus.atRiskToday;
    // If gap >= 2 and freezes cover all missed days, still atRiskToday until evaluated
    final missed = gap - 1;
    if (missed > 0 && profile.streakFreezes >= missed) {
      return StreakStatus.atRiskToday;
    }
    return StreakStatus.broken;
  }

  /// Evaluates midnight rollover, freeze consumption, and broken-streak
  /// detection whenever the app opens, resumes, or before recording activity.
  static StreakEvaluationResult evaluateOnAppOpenOrResume(
    UserProfile profile, {
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final todayKey = localDayKey(today);

    // 1. Anti-clock-tampering check: never allow rolling the clock back to fake days
    if (isClockRolledBack(profile, t)) {
      return const StreakEvaluationResult(clockTampered: true);
    }

    bool changed = false;
    bool dailyMinutesReset = false;

    // 2. Midnight rollover for daily reading minutes counter
    if (profile.dailyProgressDayKey != todayKey) {
      if (profile.dailyMinutesReadToday != 0) {
        profile.dailyMinutesReadToday = 0;
        dailyMinutesReset = true;
      }
      profile.dailyProgressDayKey = todayKey;
      changed = true;
    }

    // 3. Expire stale repair window
    if (profile.repairWindowExpiresUtcMs != null &&
        t.toUtc().millisecondsSinceEpoch > profile.repairWindowExpiresUtcMs!) {
      profile.repairableStreakDays = null;
      profile.repairWindowExpiresUtcMs = null;
      changed = true;
    }

    final lastDay = _resolveLastCompletedDay(profile);
    if (lastDay == null || profile.streakDays <= 0) {
      return StreakEvaluationResult(
        changed: changed,
        dailyMinutesReset: dailyMinutesReset,
      );
    }

    final gap = calendarDaysBetween(lastDay, today);
    if (gap <= 1) {
      // Same day (0) or consecutive day (1 — still alive, at risk until midnight)
      return StreakEvaluationResult(
        changed: changed,
        dailyMinutesReset: dailyMinutesReset,
      );
    }

    // gap >= 2 -> User missed (gap - 1) full calendar day(s)
    final missedDays = gap - 1;
    // Count only missed days not already marked frozen in history
    final unfrozenMissedDates = <DateTime>[];
    for (int offset = 1; offset <= missedDays; offset++) {
      final d = DateTime(lastDay.year, lastDay.month, lastDay.day + offset);
      final k = localDayKey(d);
      if (profile.streakHistory[k] != 'frozen' &&
          profile.streakHistory[k] != 'completed') {
        unfrozenMissedDates.add(d);
      }
    }

    if (unfrozenMissedDates.isEmpty) {
      return StreakEvaluationResult(
        changed: changed,
        dailyMinutesReset: dailyMinutesReset,
      );
    }

    if (profile.streakFreezes >= unfrozenMissedDates.length) {
      // Automatically shield every missed day with Streak Freezes!
      final consumed = unfrozenMissedDates.length;
      profile.streakFreezes -= consumed;
      for (final d in unfrozenMissedDates) {
        profile.streakHistory[localDayKey(d)] = 'frozen';
      }
      // Advance lastCompletedLocalDayKey to yesterday so gap is now 1 (atRiskToday)
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      profile.lastCompletedLocalDayKey = localDayKey(yesterday);
      profile.lastActiveDay = yesterday;
      profile.lastActivityUtcMs = math.max(
        profile.lastActivityUtcMs ?? 0,
        t.toUtc().millisecondsSinceEpoch,
      );
      return StreakEvaluationResult(
        changed: true,
        freezesConsumed: consumed,
        dailyMinutesReset: dailyMinutesReset,
      );
    } else {
      // Not enough freezes -> streak breaks! Offer 48-hour fair repair window.
      final previous = profile.streakDays;
      profile.repairableStreakDays = previous;
      profile.repairWindowExpiresUtcMs =
          t.toUtc().add(repairWindowDuration).millisecondsSinceEpoch;
      profile.streakDays = 0;
      return StreakEvaluationResult(
        changed: true,
        streakBroken: true,
        previousStreakBeforeBreak: previous,
        dailyMinutesReset: dailyMinutesReset,
      );
    }
  }

  /// Automatically records real reading/quiz activity and extends the streak
  /// **at most once per local calendar day** when the daily goal is met.
  static StreakActivityResult recordQualifiedActivity(
    UserProfile profile, {
    int minutesAdded = 0,
    bool completedLevelOrQuiz = false,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final todayKey = localDayKey(today);

    // 1. Evaluate rollover, freezes, and clock integrity first
    final eval = evaluateOnAppOpenOrResume(profile, now: t);
    if (eval.clockTampered) {
      return StreakActivityResult(
        clockTampered: true,
        newStreakDays: profile.streakDays,
      );
    }

    final wasGoalMetBefore =
        profile.dailyMinutesReadToday >= profile.dailyGoalMinutes;
    if (minutesAdded > 0) {
      profile.dailyMinutesReadToday += minutesAdded;
    }
    final isGoalMetNow =
        completedLevelOrQuiz ||
        profile.dailyMinutesReadToday >= profile.dailyGoalMinutes;
    final dailyGoalJustReached = !wasGoalMetBefore &&
        profile.dailyMinutesReadToday >= profile.dailyGoalMinutes;

    // Update monotonic UTC timestamp
    profile.lastActivityUtcMs = math.max(
      profile.lastActivityUtcMs ?? 0,
      t.toUtc().millisecondsSinceEpoch,
    );

    if (!isGoalMetNow) {
      return StreakActivityResult(
        newStreakDays: profile.streakDays,
        freezesConsumed: eval.freezesConsumed,
      );
    }

    // 2. Enforce strictly ONE streak increment per local calendar day
    if (profile.lastCompletedLocalDayKey == todayKey ||
        profile.streakHistory[todayKey] == 'completed') {
      return StreakActivityResult(
        streakExtended: false,
        dailyGoalJustReached: dailyGoalJustReached,
        newStreakDays: profile.streakDays,
        freezesConsumed: eval.freezesConsumed,
      );
    }

    // 3. Extend (or start/rekindle) the streak automatically!
    final lastDay = _resolveLastCompletedDay(profile);
    if (profile.streakDays <= 0 || lastDay == null) {
      profile.streakDays = 1;
    } else {
      final gap = calendarDaysBetween(lastDay, today);
      if (gap == 1) {
        profile.streakDays += 1;
      } else if (gap == 0) {
        // Already today (legacy migration guard)
        if (profile.streakDays == 0) profile.streakDays = 1;
      } else {
        profile.streakDays = 1;
      }
    }

    profile.lastCompletedLocalDayKey = todayKey;
    profile.lastActiveDay = today;
    profile.streakHistory[todayKey] = 'completed';
    profile.totalDaysRead += 1;
    if (profile.streakDays > profile.longestStreak) {
      profile.longestStreak = profile.streakDays;
    }

    // Clear any old repair offer once a fresh streak day is earned
    profile.repairableStreakDays = null;
    profile.repairWindowExpiresUtcMs = null;

    // 4. Automatically award any newly reached milestones (3, 7, 14, 30, 100 days)
    final newlyReached = <StreakMilestone>[];
    for (final m in milestones) {
      if (profile.streakDays >= m.days &&
          !profile.claimedStreakMilestones.contains(m.days)) {
        profile.claimedStreakMilestones.add(m.days);
        profile.gems += m.gemReward;
        if (m.bonusFreezes > 0) {
          profile.streakFreezes =
              (profile.streakFreezes + m.bonusFreezes).clamp(0, maxFreezes);
        }
        newlyReached.add(m);
      }
    }

    return StreakActivityResult(
      streakExtended: true,
      dailyGoalJustReached: dailyGoalJustReached || completedLevelOrQuiz,
      newStreakDays: profile.streakDays,
      freezesConsumed: eval.freezesConsumed,
      newlyReachedMilestones: newlyReached,
    );
  }

  /// Repairs a recently broken streak within the 48-hour window for [gemCost] gems.
  static bool repairBrokenStreak(
    UserProfile profile, {
    int gemCost = repairGemCost,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    if (!canRepairStreak(profile, now: t)) return false;
    if (profile.gems < gemCost) return false;

    final restored = profile.repairableStreakDays!;
    profile.gems -= gemCost;
    profile.streakDays = restored;
    if (profile.streakDays > profile.longestStreak) {
      profile.longestStreak = profile.streakDays;
    }
    final yesterday = DateTime(t.year, t.month, t.day - 1);
    final yesterdayKey = localDayKey(yesterday);
    profile.streakHistory[yesterdayKey] = 'frozen';
    profile.lastCompletedLocalDayKey = yesterdayKey;
    profile.lastActiveDay = yesterday;
    profile.repairableStreakDays = null;
    profile.repairWindowExpiresUtcMs = null;
    profile.lastActivityUtcMs = math.max(
      profile.lastActivityUtcMs ?? 0,
      t.toUtc().millisecondsSinceEpoch,
    );
    return true;
  }

  /// Merges offline local streak progress with cloud Supabase profile data
  /// without losing days or double-counting milestones.
  static void mergeOfflineWithCloud(UserProfile local, UserProfile cloud) {
    // Union of day history ('completed' takes priority over 'frozen')
    cloud.streakHistory.forEach((dayKey, status) {
      final existing = local.streakHistory[dayKey];
      if (existing == null || (existing == 'frozen' && status == 'completed')) {
        local.streakHistory[dayKey] = status;
      }
    });

    // Union of claimed milestones
    for (final m in cloud.claimedStreakMilestones) {
      if (!local.claimedStreakMilestones.contains(m)) {
        local.claimedStreakMilestones.add(m);
      }
    }

    local.longestStreak = math.max(local.longestStreak, cloud.longestStreak);
    local.totalDaysRead = math.max(
      math.max(local.totalDaysRead, cloud.totalDaysRead),
      local.streakHistory.values.where((v) => v == 'completed').length,
    );

    if ((cloud.lastActivityUtcMs ?? 0) > (local.lastActivityUtcMs ?? 0)) {
      local.lastActivityUtcMs = cloud.lastActivityUtcMs;
      if (cloud.streakDays > local.streakDays) {
        local.streakDays = cloud.streakDays;
      }
      if (cloud.lastCompletedLocalDayKey != null) {
        local.lastCompletedLocalDayKey = cloud.lastCompletedLocalDayKey;
      }
    }
  }

  /// Builds the 7-day Monday–Sunday Weekly Calendar for the current local week.
  static List<WeeklyStreakDay> getWeeklyCalendar(
    UserProfile profile, {
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final todayKey = localDayKey(today);
    // Monday = 1 .. Sunday = 7
    final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return List.generate(7, (i) {
      final date = DateTime(monday.year, monday.month, monday.day + i);
      final key = localDayKey(date);
      final hist = profile.streakHistory[key];
      final isToday = key == todayKey;

      WeeklyDayState state;
      if (hist == 'completed' || profile.lastCompletedLocalDayKey == key) {
        state = WeeklyDayState.completed;
      } else if (hist == 'frozen') {
        state = WeeklyDayState.frozen;
      } else if (isToday) {
        state = WeeklyDayState.todayPending;
      } else if (date.isAfter(today)) {
        state = WeeklyDayState.future;
      } else {
        state = WeeklyDayState.missed;
      }

      return WeeklyStreakDay(
        date: date,
        dayKey: key,
        shortLabel: labels[i],
        state: state,
        isToday: isToday,
      );
    });
  }

  /// Returns the next upcoming [StreakMilestone], or null if 100+ days reached.
  static StreakMilestone? nextMilestone(int currentStreakDays) {
    for (final m in milestones) {
      if (currentStreakDays < m.days) return m;
    }
    return null;
  }
}
