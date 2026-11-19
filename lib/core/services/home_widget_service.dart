import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'streak_service.dart';

/// Syncs the user's live streak, active classic, and daily reading goal to the
/// native Android Home Screen Streak Widget (`QuixoriaStreakWidgetProvider`).
class HomeWidgetService {
  static final HomeWidgetService instance = HomeWidgetService._();
  HomeWidgetService._();

  static const MethodChannel _channel =
      MethodChannel('com.example.quixoria/home_widget');

  Future<void> syncStreakWidget({
    required int streakDays,
    required StreakStatus status,
    required String activeBook,
    required int minutesToday,
    required int goalMinutes,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final isActiveToday = status == StreakStatus.activeToday;
    final statusText = switch (status) {
      StreakStatus.activeToday => 'Flame Secured ✓',
      StreakStatus.atRiskToday => 'Read Today!',
      StreakStatus.broken => 'Rekindle Flame',
      StreakStatus.fresh => 'Start Quest',
    };
    try {
      await _channel.invokeMethod<bool>('updateStreakWidget', {
        'streakDays': streakDays,
        'isActiveToday': isActiveToday,
        'statusText': statusText,
        'activeBook': activeBook,
        'minutesToday': minutesToday,
        'goalMinutes': goalMinutes,
      });
    } catch (_) {
      // Safe no-op in tests or unsupported environments
    }
  }
}
