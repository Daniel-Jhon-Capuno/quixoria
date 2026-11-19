import 'dart:math';

/// Weekly league built on local data.
///
/// Until online accounts exist, the reader competes against a roster of
/// clearly-labelled classic literary characters whose weekly pace is
/// generated deterministically from the week and tier. Nothing here pretends
/// to be another real person.
class LeagueTier {
  static const List<String> names = [
    'Squire',
    'Page',
    'Knight',
    'Baron',
    'Count',
    'Duke',
    'Grandee',
  ];

  static String nameOf(int tier) => names[tier.clamp(0, names.length - 1)];
  static int get maxTier => names.length - 1;
}

class LeagueEntrant {
  final String id;
  final String name;
  final String origin; // e.g. "Don Quixote"
  final int xp;
  final bool isUser;

  const LeagueEntrant({
    required this.id,
    required this.name,
    required this.origin,
    required this.xp,
    this.isUser = false,
  });
}

class LeagueRoster {
  /// Group size including the reader.
  static const int groupSize = 10;
  static const int promoteCount = 3;
  static const int demoteCount = 3;

  static const List<List<String>> _characters = [
    ['Sancho Panza', 'Don Quixote'],
    ['Dulcinea del Toboso', 'Don Quixote'],
    ['Rocinante', 'Don Quixote'],
    ['Sanson Carrasco', 'Don Quixote'],
    ['Teresa Panza', 'Don Quixote'],
    ['Mary Lennox', 'The Secret Garden'],
    ['Dickon Sowerby', 'The Secret Garden'],
    ['Colin Craven', 'The Secret Garden'],
    ['Martha Sowerby', 'The Secret Garden'],
    ['Mole', 'The Wind in the Willows'],
    ['Ratty', 'The Wind in the Willows'],
    ['Mr. Toad', 'The Wind in the Willows'],
    ['Badger', 'The Wind in the Willows'],
    ['Alice', 'Alice in Wonderland'],
    ['The Cheshire Cat', 'Alice in Wonderland'],
    ['The Mad Hatter', 'Alice in Wonderland'],
    ['The Time Traveller', 'The Time Machine'],
    ['Weena', 'The Time Machine'],
  ];

  /// Monday 00:00 of the week containing [t].
  static DateTime weekStartOf(DateTime t) {
    final d = DateTime(t.year, t.month, t.day);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  static DateTime weekEndOf(DateTime weekStart) => weekStart.add(const Duration(days: 7));

  /// Rival XP at moment [now] for the week beginning [weekStart].
  /// [weekFraction] of 1.0 gives final weekly totals.
  static List<LeagueEntrant> rivals({
    required DateTime weekStart,
    required int tier,
    required DateTime now,
    double? weekFraction,
  }) {
    final seed = weekStart.year * 1000 + weekStart.month * 40 + weekStart.day + tier * 7919;
    final rng = Random(seed);

    final indices = List<int>.generate(_characters.length, (i) => i)..shuffle(rng);
    final elapsed = weekFraction ??
        (now.difference(weekStart).inMinutes / const Duration(days: 7).inMinutes).clamp(0.0, 1.0);

    // Higher tiers have busier rivals.
    final baseWeekly = 90 + tier * 55;

    return [
      for (int i = 0; i < groupSize - 1; i++)
        () {
          final c = _characters[indices[i]];
          final pace = 0.35 + rng.nextDouble() * 1.4; // 0.35x .. 1.75x
          final weeklyTarget = (baseWeekly * pace).round();
          // Slightly front- or back-loaded weeks for variety.
          final curve = 0.75 + rng.nextDouble() * 0.6;
          final xp = (weeklyTarget * pow(elapsed, curve)).round();
          return LeagueEntrant(id: 'rival_$i', name: c[0], origin: c[1], xp: xp);
        }(),
    ];
  }

  /// Full sorted standings including the reader.
  static List<LeagueEntrant> standings({
    required DateTime weekStart,
    required int tier,
    required int userXp,
    required String userName,
    required DateTime now,
    double? weekFraction,
  }) {
    final list = [
      ...rivals(weekStart: weekStart, tier: tier, now: now, weekFraction: weekFraction),
      LeagueEntrant(id: 'user', name: userName, origin: 'You', xp: userXp, isUser: true),
    ];
    // Ties go to the reader.
    list.sort((a, b) {
      final c = b.xp.compareTo(a.xp);
      if (c != 0) return c;
      if (a.isUser) return -1;
      if (b.isUser) return 1;
      return a.name.compareTo(b.name);
    });
    return list;
  }
}
