enum NotificationType {
  lowEnergy,
  energyRestored,
  streakExpiring,
  streakLost,
  streakRekindled,
  readingGoalAchieved,
  expeditionReady,
  goldenKeyAwarded,
  marginaliaReflection,
  literatureRecommendation,
  themeEquipped,
  offlineWarning,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final String? recipientName;
  final String? relatedWorkTitle;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.recipientName,
    this.relatedWorkTitle,
    this.isRead = false,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
