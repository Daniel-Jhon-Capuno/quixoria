import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int morningReminderId = 2006; // 7:00 AM daily
  static const int middayReminderId = 2013; // 1:00 PM daily
  static const int eveningReminderId = 2022; // 9:30 PM daily

  bool _isInitialized = false;
  bool _tzInitialized = false;

  void _configureLocalTimeZone() {
    if (_tzInitialized) return;
    try {
      tz_data.initializeTimeZones();
      final localOffset = DateTime.now().timeZoneOffset;
      tz.Location? matched;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.currentTimeZone.offset == localOffset) {
          matched ??= loc;
          // Prefer well-known canonical cities when offset matches
          if (loc.name == 'Asia/Manila' ||
              loc.name == 'Asia/Singapore' ||
              loc.name == 'Asia/Tokyo' ||
              loc.name == 'America/New_York' ||
              loc.name == 'America/Los_Angeles' ||
              loc.name == 'Europe/London') {
            matched = loc;
            break;
          }
        }
      }
      tz.setLocalLocation(matched ?? tz.UTC);
      _tzInitialized = true;
      debugPrint('[NotificationService] Local timezone resolved: ${tz.local.name} (offset=$localOffset)');
    } catch (e) {
      debugPrint('Timezone init fallback: $e');
    }
  }

  /// Exposes the resolved local timezone name for diagnostics & testing.
  String get resolvedTimeZoneName {
    _configureLocalTimeZone();
    return tz.local.name;
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> init() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    try {
      _configureLocalTimeZone();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('Notification tapped: ${details.payload}');
        },
      );

      // Request Android 13+ runtime notification permission & exact alarm permission
      await requestPermissions();

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error (safe fallback): $e');
    }
  }

  /// Explicitly requests Android 13+ notification permission and exact alarm
  /// permission. Returns true if notifications are enabled on the device.
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidImpl?.requestNotificationsPermission();
        // Exact alarms permission is optional (we gracefully fall back to inexact)
        try {
          await androidImpl?.requestExactAlarmsPermission();
        } catch (_) {}
        return granted ?? (await areNotificationsEnabled());
      }
      return true;
    } catch (e) {
      debugPrint('Permission request notice: $e');
      return false;
    }
  }

  /// Checks whether the user has granted OS notification permission.
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        return (await androidImpl?.areNotificationsEnabled()) ?? true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns the number of currently queued OS scheduled notifications.
  Future<int> pendingNotificationCount() async {
    if (kIsWeb) return 0;
    try {
      await init();
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      return pending.length;
    } catch (_) {
      return 0;
    }
  }

  /// Builds high-priority heads-up pop-up notification details (with BigText
  /// expansion, vibration, sound, and public lock-screen visibility).
  NotificationDetails _getNotificationDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
    String? bigTitle,
    String? bigBody,
    Importance importance = Importance.max,
    Priority priority = Priority.max,
  }) {
    final style = (bigBody != null && bigBody.isNotEmpty)
        ? BigTextStyleInformation(
            bigBody,
            contentTitle: bigTitle,
            summaryText: 'Quixoria',
          )
        : const DefaultStyleInformation(true, true);

    final androidDetails = AndroidNotificationDetails(
      '${channelId}_v2', // Fresh v2 channel ID ensures Android applies Importance.max heads-up pop-up
      channelName,
      channelDescription: channelDescription,
      importance: importance,
      priority: priority,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
      ticker: bigTitle ?? channelName,
      sound: const RawResourceAndroidNotificationSound('notification'),
      styleInformation: style,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification.wav',
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  /// Sends a live heads-up pop-up notification when someone @mentions you in the Feed.
  Future<void> showMentionAlert({
    required String senderName,
    required String messageExcerpt,
  }) async {
    if (kIsWeb) return;
    try {
      await init();
      final title = '💬 $senderName mentioned you!';
      final details = _getNotificationDetails(
        channelId: 'quixoria_mentions',
        channelName: 'Quixoria Mentions & Replies',
        channelDescription: 'Live alerts when a fellow scholar @mentions you in the Community Feed',
        bigTitle: title,
        bigBody: messageExcerpt,
      );
      await _notificationsPlugin.show(
        id: 1010,
        title: title,
        body: messageExcerpt,
        notificationDetails: details,
        payload: 'community_mention',
      );
    } catch (e) {
      debugPrint('Failed to show mention notification: $e');
    }
  }

  /// Sends a personalized push notification to the phone for low energy
  Future<void> showLowEnergyAlert({
    required String userName,
    required int currentEnergy,
    required int maxEnergy,
  }) async {
    if (kIsWeb) return;
    try {
      await init();
      final title = '$userName, Knightly Energy is Weary ($currentEnergy/$maxEnergy)';
      const body = 'Even Rocinante rests. Recover stamina to restore hearts or undertake safe Practice levels without penalty.';
      final details = _getNotificationDetails(
        channelId: 'quixoria_energy',
        channelName: 'Quixoria Energy Alerts',
        channelDescription: 'Alerts when knight energy hearts are depleted',
        bigTitle: title,
        bigBody: body,
      );

      await _notificationsPlugin.show(
        id: 1001,
        title: title,
        body: body,
        notificationDetails: details,
        payload: 'low_energy',
      );
    } catch (e) {
      debugPrint('Failed to show low energy notification: $e');
    }
  }

  /// Sends a personalized push notification to the phone when energy is fully restored
  Future<void> showEnergyRestoredAlert({
    required String userName,
    required int maxEnergy,
    String? activeBook,
  }) async {
    if (kIsWeb) return;
    try {
      await init();
      final bookSnippet = activeBook != null ? ' in $activeBook' : '';
      final title = '$userName, Energy is Fully Restored ($maxEnergy/$maxEnergy)';
      final body = 'Your knightly vigor has returned. The quest$bookSnippet awaits your steady hand.';
      final details = _getNotificationDetails(
        channelId: 'quixoria_energy_restored',
        channelName: 'Quixoria Energy Restored',
        channelDescription: 'Alerts when stamina has fully recovered',
        bigTitle: title,
        bigBody: body,
      );

      await _notificationsPlugin.show(
        id: 1002,
        title: title,
        body: body,
        notificationDetails: details,
        payload: 'energy_restored',
      );
    } catch (e) {
      debugPrint('Failed to show energy restored notification: $e');
    }
  }

  /// Sends an immediate heads-up push notification (e.g. Leaderboard rank-up or Top 1% Legendary Chest).
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String payload = 'leaderboard_update',
  }) async {
    if (kIsWeb) return;
    try {
      await init();
      final details = _getNotificationDetails(
        channelId: 'quixoria_leaderboard_v2',
        channelName: 'Quixoria Leaderboard & Rewards',
        channelDescription: 'Rank-up milestones and Top 1% Legendary Chest alerts',
        bigTitle: title,
        bigBody: body,
      );
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show instant notification: $e');
    }
  }

  /// Sends a personalized push notification to the phone for 12:00 AM streak deadline
  Future<void> showStreakWarning({
    required String userName,
    required int streakDays,
    String? activeBook,
  }) async {
    if (kIsWeb) return;
    try {
      await init();
      final workMention = activeBook != null ? ' in $activeBook' : '';
      final title = '$userName, Midnight Hour Approaches (12:00 AM Deadline)';
      final body = 'Complete today\'s chapter$workMention before the stroke of midnight to keep your $streakDays-day campfire blazing before it turns to ash.';
      final details = _getNotificationDetails(
        channelId: 'quixoria_streak',
        channelName: 'Quixoria Streak Warnings',
        channelDescription: 'Alerts before midnight 12:00 AM reset',
        bigTitle: title,
        bigBody: body,
      );

      await _notificationsPlugin.show(
        id: 1003,
        title: title,
        body: body,
        notificationDetails: details,
        payload: 'streak_warning',
      );
    } catch (e) {
      debugPrint('Failed to show streak warning notification: $e');
    }
  }

  /// Sends a personalized push notification to the phone when streak is lost
  Future<void> showStreakLostAlert({
    required String userName,
    required int previousStreak,
  }) async {
    if (kIsWeb) return;
    try {
      await init();
      final title = '$userName, The Campfire Has Gone Cold';
      final body = 'Midnight has passed and your $previousStreak-day flame turned to ash. Return to Quixoria to kindle it anew today.';
      final details = _getNotificationDetails(
        channelId: 'quixoria_streak_loss',
        channelName: 'Quixoria Campfire Extinguished',
        channelDescription: 'Alert when streak flame has burned down',
        bigTitle: title,
        bigBody: body,
      );

      await _notificationsPlugin.show(
        id: 1004,
        title: title,
        body: body,
        notificationDetails: details,
        payload: 'streak_lost',
      );
    } catch (e) {
      debugPrint('Failed to show streak lost notification: $e');
    }
  }

  /// Sends a personalized push notification when daily reading goal is fulfilled
  Future<void> showReadingGoalAchievedAlert({
    required String userName,
    required int minutes,
    String? activeBook,
  }) async {
    if (kIsWeb) return;
    try {
      await init();
      final workMention = activeBook != null ? ' with $activeBook' : '';
      final title = '$userName, Daily Reading Goal Fulfilled';
      final body = 'You completed your $minutes-minute pledge$workMention for today. Don Quixote salutes your scholarly discipline.';
      final details = _getNotificationDetails(
        channelId: 'quixoria_reading_goal',
        channelName: 'Quixoria Reading Goal Alerts',
        channelDescription: 'Alerts when daily reading minute goal is fulfilled',
        bigTitle: title,
        bigBody: body,
      );

      await _notificationsPlugin.show(
        id: 1005,
        title: title,
        body: body,
        notificationDetails: details,
        payload: 'reading_goal_achieved',
      );
    } catch (e) {
      debugPrint('Failed to show reading goal notification: $e');
    }
  }

  /// Sends a personalized push notification when morning expeditions reset
  Future<void> showExpeditionReadyAlert({
    required String userName,
  }) async {
    if (kIsWeb) return;
    try {
      await init();
      final title = '$userName, Morning Expeditions Await';
      const body = 'The morning herald brings fresh literary quests. Advance your chronicle to earn bonus guild gems.';
      final details = _getNotificationDetails(
        channelId: 'quixoria_expeditions',
        channelName: 'Quixoria Daily Expeditions',
        channelDescription: 'Alerts when fresh daily reading expeditions are ready',
        bigTitle: title,
        bigBody: body,
      );

      await _notificationsPlugin.show(
        id: 1006,
        title: title,
        body: body,
        notificationDetails: details,
        payload: 'expedition_ready',
      );
    } catch (e) {
      debugPrint('Failed to show expedition notification: $e');
    }
  }

  /// Sends a personalized push notification when a Golden Key is earned
  Future<void> showGoldenKeyAlert({
    required String userName,
    required String bookTitle,
  }) async {
    if (kIsWeb) return;
    try {
      await init();
      final title = '$userName, Golden Key of Masterwork Awarded';
      final body = 'Your perfect mastery of $bookTitle has forged a Golden Key. Any volume in the realm may now be unlocked.';
      final details = _getNotificationDetails(
        channelId: 'quixoria_golden_key',
        channelName: 'Quixoria Masterwork Rewards',
        channelDescription: 'Alerts when a Golden Key is earned for masterwork unlock',
        bigTitle: title,
        bigBody: body,
      );

      await _notificationsPlugin.show(
        id: 1007,
        title: title,
        body: body,
        notificationDetails: details,
        payload: 'golden_key',
      );
    } catch (e) {
      debugPrint('Failed to show golden key notification: $e');
    }
  }

  /// Sends a personalized push notification for marginalia and reflection
  Future<void> showMarginaliaReminderAlert({
    required String userName,
    required String bookTitle,
  }) async {
    if (kIsWeb) return;
    try {
      await init();
      final title = '$userName, Marginalia Awaits Contemplation';
      final body = 'Revisit your thoughtful notes and reflections on $bookTitle to deepen your literary understanding.';
      final details = _getNotificationDetails(
        channelId: 'quixoria_marginalia',
        channelName: 'Quixoria Reading Notebook Reflections',
        channelDescription: 'Reminders to revisit notebook musings and quotes',
        bigTitle: title,
        bigBody: body,
      );

      await _notificationsPlugin.show(
        id: 1008,
        title: title,
        body: body,
        notificationDetails: details,
        payload: 'marginalia_reflection',
      );
    } catch (e) {
      debugPrint('Failed to show marginalia notification: $e');
    }
  }

  /// Schedules REAL repeating daily Android/iOS heads-up phone notifications in
  /// the user's true local timezone at 7:00 AM, 1:00 PM, and 9:30 PM, plus
  /// 2 randomized Duolingo-style encouragement nudges per day for 7 days.
  /// Fires even when the app is completely closed or after device reboot!
  Future<void> scheduleDailyStreakReminders({
    required String userName,
    required int streakDays,
    String? activeBook,
  }) async {
    if (kIsWeb) return;
    try {
      await init();
      _configureLocalTimeZone();

      final cleanName = userName.trim().isEmpty ? 'Scholar' : userName.trim();
      final bookText = (activeBook != null && activeBook.trim().isNotEmpty)
          ? activeBook.trim()
          : 'your active classic';

      // Clear previous anchor schedules before updating with latest streak/name
      await _notificationsPlugin.cancel(id: morningReminderId);
      await _notificationsPlugin.cancel(id: middayReminderId);
      await _notificationsPlugin.cancel(id: eveningReminderId);

      final morningTime = _nextInstanceOfTime(7, 0);
      final middayTime = _nextInstanceOfTime(13, 0);
      final eveningTime = _nextInstanceOfTime(21, 30);

      Future<void> scheduleSafely({
        required int id,
        required String title,
        required String body,
        required tz.TZDateTime scheduledDate,
        required NotificationDetails details,
        required String payload,
        DateTimeComponents? matchDateTimeComponents,
      }) async {
        try {
          await _notificationsPlugin.zonedSchedule(
            id: id,
            title: title,
            body: body,
            scheduledDate: scheduledDate,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: matchDateTimeComponents,
            payload: payload,
          );
        } catch (_) {
          // Graceful fallback if Android exact alarm permission is disabled by user
          await _notificationsPlugin.zonedSchedule(
            id: id,
            title: title,
            body: body,
            scheduledDate: scheduledDate,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: matchDateTimeComponents,
            payload: payload,
          );
        }
      }

      // 1. 7:00 AM Daily Morning Reading Reminder (Heads-Up Pop-Up)
      final morningTitle = '🌅 Good Morning, $cleanName! Day $streakDays Awaits';
      final morningBody = 'Start your morning with a quick chapter in $bookText to keep your $streakDays-day streak glowing and earn bonus Gems!';
      await scheduleSafely(
        id: morningReminderId,
        title: morningTitle,
        body: morningBody,
        scheduledDate: morningTime,
        details: _getNotificationDetails(
          channelId: 'quixoria_daily_morning',
          channelName: 'Quixoria 7:00 AM Morning Reminders',
          channelDescription: 'Daily 7:00 AM reading and streak reminder',
          bigTitle: morningTitle,
          bigBody: morningBody,
        ),
        payload: 'daily_7am_reminder',
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // 2. 1:00 PM Daily Midday Reading Break (Heads-Up Pop-Up)
      final middayTitle = '📖 Midday Quest Break, $cleanName!';
      final middayBody = 'Take a 3-minute break with $bookText — Don Quixote saved your page and a treasure chest awaits!';
      await scheduleSafely(
        id: middayReminderId,
        title: middayTitle,
        body: middayBody,
        scheduledDate: middayTime,
        details: _getNotificationDetails(
          channelId: 'quixoria_daily_midday',
          channelName: 'Quixoria Midday Reading Break',
          channelDescription: 'Daily 1:00 PM reading check-in',
          bigTitle: middayTitle,
          bigBody: middayBody,
        ),
        payload: 'daily_1pm_reminder',
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // 3. 9:30 PM Daily Evening Streak Guard (Heads-Up Pop-Up)
      final eveningTitle = '🔥 Streak Guard: Protect Your $streakDays-Day Flame!';
      final eveningBody = 'Midnight is approaching, $cleanName! Read a quick chapter or finish a quiz in $bookText to keep your streak alive.';
      await scheduleSafely(
        id: eveningReminderId,
        title: eveningTitle,
        body: eveningBody,
        scheduledDate: eveningTime,
        details: _getNotificationDetails(
          channelId: 'quixoria_daily_evening',
          channelName: 'Quixoria Evening Streak Guard',
          channelDescription: 'Daily 9:30 PM reminder to protect your reading streak before midnight',
          bigTitle: eveningTitle,
          bigBody: eveningBody,
        ),
        payload: 'daily_930pm_streak_guard',
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // 4. Duolingo-Style Random Live Phone Nudges (7 Days Ahead, 2 Heads-Up Slots/Day)
      await _scheduleRandomEncouragementNudges(
        userName: cleanName,
        streakDays: streakDays,
        activeBook: bookText,
        scheduleSafely: scheduleSafely,
      );
    } catch (e) {
      debugPrint('Failed to schedule daily notifications: $e');
    }
  }

  /// Schedules 2 gentle, randomized Duolingo-style heads-up pop-up notifications
  /// per day for the next 7 days (IDs 2100..2113) during waking hours.
  Future<void> _scheduleRandomEncouragementNudges({
    required String userName,
    required int streakDays,
    required String activeBook,
    required Future<void> Function({
      required int id,
      required String title,
      required String body,
      required tz.TZDateTime scheduledDate,
      required NotificationDetails details,
      required String payload,
      DateTimeComponents? matchDateTimeComponents,
    }) scheduleSafely,
  }) async {
    // Clear old 7-day random slots before refreshing
    for (int id = 2100; id < 2114; id++) {
      await _notificationsPlugin.cancel(id: id);
    }

    final pool = <(String, String)>[
      ('📖 Ready for a 3-minute chapter?', '$userName, $activeBook is waiting right where you left off!'),
      ('🗡️ Don Quixote spotted a windmill!', 'Quick! Come read one page of $activeBook and earn Gems.'),
      ('✨ A Legendary Chest awaits!', 'Ace a quick quiz today to unlock a Royal Legendary Chest, $userName.'),
      ('☕ Taking a quick break?', 'A single chapter of $activeBook is the best way to recharge.'),
      ('🏆 Climb the Global Leaderboard!', 'Earn Leaderboard XP today and show off your Scholar Title, $userName.'),
      ('🔥 $streakDays-day streak energy!', 'Don’t break the rhythm — one quick reading session keeps your flame strong.'),
      ('🦉 Lexicon Check-In', 'A few words in your Word Bank are ready for a quick spaced-repetition boost.'),
      ('💎 Easy Gems Waiting', 'Complete one level or claim a Trophy Case medal in Quixoria today!'),
      ('🌿 Step into your reading realm', 'Your chapters, ambience rain, and notes are ready whenever you are, $userName.'),
      ('📜 A quote worth keeping?', 'Read a few paragraphs of $activeBook and save a styled Quote Card!'),
      ('🎯 Can you hit 100% accuracy?', 'Test your memory with freshly shuffled questions for a Legendary Chest.'),
      ('🌙 Cozy reading mood', 'Try Dark Mode Candlelight + Fireplace ambience for a relaxing 5-minute read.'),
      ('🔑 Closer to a Golden Key!', 'Every level finished in $activeBook brings you closer to your next Golden Key.'),
      ('📚 5 minutes beats 0 minutes', 'Small daily reading habits build mighty scholars, $userName!'),
      ('🎨 New Profile Icons in the Shop', 'Earn a few more Gems today and customize your Community Feed look.'),
      ('🧭 Adventure calls, $userName!', 'Your next zone in $activeBook is unlocked and ready to explore.'),
      ('💡 Feed your curiosity', 'Ask Don Quixote a Socratic question while reading $activeBook today.'),
      ('🌟 You’re doing great, $userName!', 'Keep your 30-day Reading Heatmap glowing with one quick session.'),
      ('📖 Just one page?', 'That’s all it takes to keep your literary momentum alive today!'),
      ('🏅 Medal progress waiting', 'Check your Trophy Case in Profile — you might be close to bonus Gems!'),
      ('🎵 Rainy library vibes?', 'Put on your headphones, play the Scriptorium soundscape, and read a chapter.'),
      ('⚡ Combo Streak Challenge', 'How many quiz questions in a row can you nail today, $userName?'),
      ('🌻 A breath of classic literature', 'Unwind for a few minutes inside $activeBook — your bookmark is saved.'),
      ('👑 Royal Scribes miss you!', 'Drop into Quixoria for a quick chapter and keep your streak shining.'),
    ];

    final rng = Random();
    pool.shuffle(rng);

    final now = tz.TZDateTime.now(tz.local);
    int msgIdx = 0;

    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final baseDay = tz.TZDateTime(tz.local, now.year, now.month, now.day).add(Duration(days: dayOffset));

      // Slot A: Random late-morning nudge (9:30 AM – 11:45 AM)
      final amHour = 9 + rng.nextInt(3); // 9, 10, 11
      final amMin = (amHour == 9) ? (30 + rng.nextInt(30)) : rng.nextInt(45);
      final slotA = tz.TZDateTime(tz.local, baseDay.year, baseDay.month, baseDay.day, amHour, amMin);
      if (slotA.isAfter(now.add(const Duration(minutes: 2)))) {
        final msg = pool[msgIdx % pool.length];
        msgIdx++;
        await scheduleSafely(
          id: 2100 + dayOffset * 2,
          title: msg.$1,
          body: msg.$2,
          scheduledDate: slotA,
          details: _getNotificationDetails(
            channelId: 'quixoria_smart_nudges',
            channelName: 'Quixoria Reading Nudges',
            channelDescription: 'Friendly heads-up reading reminders & encouragement from Don Quixote',
            bigTitle: msg.$1,
            bigBody: msg.$2,
            importance: Importance.max,
            priority: Priority.max,
          ),
          payload: 'random_nudge_am_$dayOffset',
        );
      }

      // Slot B: Random afternoon / evening nudge (4:00 PM – 7:45 PM)
      final pmHour = 16 + rng.nextInt(4); // 16, 17, 18, 19
      final pmMin = rng.nextInt(45);
      final slotB = tz.TZDateTime(tz.local, baseDay.year, baseDay.month, baseDay.day, pmHour, pmMin);
      if (slotB.isAfter(now.add(const Duration(minutes: 2)))) {
        final msg = pool[msgIdx % pool.length];
        msgIdx++;
        await scheduleSafely(
          id: 2101 + dayOffset * 2,
          title: msg.$1,
          body: msg.$2,
          scheduledDate: slotB,
          details: _getNotificationDetails(
            channelId: 'quixoria_smart_nudges',
            channelName: 'Quixoria Reading Nudges',
            channelDescription: 'Friendly heads-up reading reminders & encouragement from Don Quixote',
            bigTitle: msg.$1,
            bigBody: msg.$2,
            importance: Importance.max,
            priority: Priority.max,
          ),
          payload: 'random_nudge_pm_$dayOffset',
        );
      }
    }
  }

  /// Cancels scheduled daily & random encouragement phone reminders.
  Future<void> cancelDailyStreakReminders() async {
    if (kIsWeb) return;
    try {
      await init();
      await _notificationsPlugin.cancel(id: morningReminderId);
      await _notificationsPlugin.cancel(id: middayReminderId);
      await _notificationsPlugin.cancel(id: eveningReminderId);
      for (int id = 2100; id < 2114; id++) {
        await _notificationsPlugin.cancel(id: id);
      }
    } catch (_) {}
  }

  /// Schedules a real heads-up test pop-up notification in [delay] (default 5s)
  /// so the user can minimize/lock their phone and verify background delivery!
  Future<bool> scheduleTestNotificationIn({
    Duration delay = const Duration(seconds: 5),
    String userName = 'Scholar',
    String? activeBook,
  }) async {
    if (kIsWeb) return false;
    try {
      await init();
      final permitted = await requestPermissions();
      _configureLocalTimeZone();

      final target = tz.TZDateTime.now(tz.local).add(delay);
      final title = '🗡️ Don Quixote Calling, $userName!';
      final body = activeBook != null
          ? 'Your Quixoria pop-up alerts are working! $activeBook awaits your next chapter.'
          : 'Your Quixoria heads-up phone notifications are active and working!';
      final details = _getNotificationDetails(
        channelId: 'quixoria_test',
        channelName: 'Quixoria Test Alerts',
        channelDescription: 'Verification heads-up test notifications',
        bigTitle: title,
        bigBody: body,
      );

      try {
        await _notificationsPlugin.zonedSchedule(
          id: 1098,
          title: title,
          body: body,
          scheduledDate: target,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'scheduled_test_alert',
        );
      } catch (_) {
        await _notificationsPlugin.zonedSchedule(
          id: 1098,
          title: title,
          body: body,
          scheduledDate: target,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'scheduled_test_alert',
        );
      }
      return permitted;
    } catch (e) {
      debugPrint('Failed to schedule test notification: $e');
      return false;
    }
  }

  /// Sends an immediate test heads-up pop-up notification to verify phone delivery.
  Future<void> showTestNotification({
    required String title,
    required String message,
  }) async {
    if (kIsWeb) return;
    try {
      await init();
      await requestPermissions();
      final details = _getNotificationDetails(
        channelId: 'quixoria_test',
        channelName: 'Quixoria Test Alerts',
        channelDescription: 'Verification test notifications',
        bigTitle: title,
        bigBody: message,
      );

      await _notificationsPlugin.show(
        id: 1099,
        title: title,
        body: message,
        notificationDetails: details,
        payload: 'test_alert',
      );
    } catch (e) {
      debugPrint('Failed to show test notification: $e');
    }
  }
}
