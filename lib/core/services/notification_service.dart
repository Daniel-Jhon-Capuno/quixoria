import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    try {
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

      // Request Android 13+ permission
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error (safe fallback): $e');
    }
  }

  NotificationDetails _getNotificationDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
    Importance importance = Importance.max,
    Priority priority = Priority.high,
  }) {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: importance,
      priority: priority,
      playSound: true,
      enableVibration: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
      styleInformation: const DefaultStyleInformation(true, true),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification.wav',
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
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
      final details = _getNotificationDetails(
        channelId: 'quixoria_energy',
        channelName: 'Quixoria Energy Alerts',
        channelDescription: 'Alerts when knight energy hearts are depleted',
      );

      await _notificationsPlugin.show(
        id: 1001,
        title: '$userName, Knightly Energy is Weary ($currentEnergy/$maxEnergy)',
        body: 'Even Rocinante rests. Recover stamina to restore hearts or undertake safe Practice levels without penalty.',
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
      final details = _getNotificationDetails(
        channelId: 'quixoria_energy_restored',
        channelName: 'Quixoria Energy Restored',
        channelDescription: 'Alerts when stamina has fully recovered',
      );

      final bookSnippet = activeBook != null ? ' in $activeBook' : '';
      await _notificationsPlugin.show(
        id: 1002,
        title: '$userName, Energy is Fully Restored ($maxEnergy/$maxEnergy)',
        body: 'Your knightly vigor has returned. The quest$bookSnippet awaits your steady hand.',
        notificationDetails: details,
        payload: 'energy_restored',
      );
    } catch (e) {
      debugPrint('Failed to show energy restored notification: $e');
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
      final details = _getNotificationDetails(
        channelId: 'quixoria_streak',
        channelName: 'Quixoria Streak Warnings',
        channelDescription: 'Alerts before midnight 12:00 AM reset',
      );

      final workMention = activeBook != null ? ' in $activeBook' : '';
      await _notificationsPlugin.show(
        id: 1003,
        title: '$userName, Midnight Hour Approaches (12:00 AM Deadline)',
        body: 'Complete today\'s chapter$workMention before the stroke of midnight to keep your $streakDays-day campfire blazing before it turns to ash.',
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
      final details = _getNotificationDetails(
        channelId: 'quixoria_streak_loss',
        channelName: 'Quixoria Campfire Extinguished',
        channelDescription: 'Alert when streak flame has burned down',
      );

      await _notificationsPlugin.show(
        id: 1004,
        title: '$userName, The Campfire Has Gone Cold',
        body: 'Midnight has passed and your $previousStreak-day flame turned to ash. Return to Quixoria to kindle it anew today.',
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
      final details = _getNotificationDetails(
        channelId: 'quixoria_reading_goal',
        channelName: 'Quixoria Reading Goal Alerts',
        channelDescription: 'Alerts when daily reading minute goal is fulfilled',
      );

      final workMention = activeBook != null ? ' with $activeBook' : '';
      await _notificationsPlugin.show(
        id: 1005,
        title: '$userName, Daily Reading Goal Fulfilled',
        body: 'You completed your $minutes-minute pledge$workMention for today. Don Quixote salutes your scholarly discipline.',
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
      final details = _getNotificationDetails(
        channelId: 'quixoria_expeditions',
        channelName: 'Quixoria Daily Expeditions',
        channelDescription: 'Alerts when fresh daily reading expeditions are ready',
      );

      await _notificationsPlugin.show(
        id: 1006,
        title: '$userName, Morning Expeditions Await',
        body: 'The morning herald brings fresh literary quests. Advance your chronicle to earn bonus guild gems.',
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
      final details = _getNotificationDetails(
        channelId: 'quixoria_golden_key',
        channelName: 'Quixoria Masterwork Rewards',
        channelDescription: 'Alerts when a Golden Key is earned for masterwork unlock',
      );

      await _notificationsPlugin.show(
        id: 1007,
        title: '$userName, Golden Key of Masterwork Awarded',
        body: 'Your perfect mastery of $bookTitle has forged a Golden Key. Any volume in the realm may now be unlocked.',
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
      final details = _getNotificationDetails(
        channelId: 'quixoria_marginalia',
        channelName: 'Quixoria Reading Notebook Reflections',
        channelDescription: 'Reminders to revisit notebook musings and quotes',
      );

      await _notificationsPlugin.show(
        id: 1008,
        title: '$userName, Marginalia Awaits Contemplation',
        body: 'Revisit your thoughtful notes and reflections on $bookTitle to deepen your literary understanding.',
        notificationDetails: details,
        payload: 'marginalia_reflection',
      );
    } catch (e) {
      debugPrint('Failed to show marginalia notification: $e');
    }
  }

  /// Sends an immediate test notification to verify the phone displays system notifications
  Future<void> showTestNotification({
    required String title,
    required String message,
  }) async {
    if (kIsWeb) return;
    try {
      await init();
      final details = _getNotificationDetails(
        channelId: 'quixoria_test',
        channelName: 'Quixoria Test Alerts',
        channelDescription: 'Verification test notifications',
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
