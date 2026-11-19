/// Represents a shared Duolingo-style Friend Streak ("Reading Buddy")
/// between the user and a friend they follow.
class FriendStreak {
  final String id;
  final String name;
  final String handle;
  int streakDays;
  bool youReadToday;
  bool friendReadToday;
  String? lastNudgedDayKey;
  final String avatarIconId;

  FriendStreak({
    required this.id,
    required this.name,
    required this.handle,
    this.streakDays = 1,
    this.youReadToday = false,
    this.friendReadToday = false,
    this.lastNudgedDayKey,
    this.avatarIconId = 'avatar_owl',
  });

  bool get isBothCompleteToday => youReadToday && friendReadToday;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'handle': handle,
        'streakDays': streakDays,
        'youReadToday': youReadToday,
        'friendReadToday': friendReadToday,
        'lastNudgedDayKey': lastNudgedDayKey,
        'avatarIconId': avatarIconId,
      };

  factory FriendStreak.fromJson(Map<String, dynamic> j) => FriendStreak(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? 'Reading Buddy').toString(),
        handle: (j['handle'] ?? '@buddy').toString(),
        streakDays: (j['streakDays'] as num?)?.toInt() ?? 1,
        youReadToday: (j['youReadToday'] as bool?) ?? false,
        friendReadToday: (j['friendReadToday'] as bool?) ?? false,
        lastNudgedDayKey: j['lastNudgedDayKey'] as String?,
        avatarIconId: (j['avatarIconId'] ?? 'avatar_owl').toString(),
      );
}
