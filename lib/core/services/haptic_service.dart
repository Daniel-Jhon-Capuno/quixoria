import 'package:flutter/services.dart';
import 'haptics/haptic_stub.dart' if (dart.library.js_interop) 'haptics/haptic_web.dart' as platform;

enum HapticFeedbackType {
  selection,
  light,
  medium,
  heavy,
  error,
  celebration,
}

/// Universal cross-platform haptic vibration service.
///
/// Triggers native mobile haptics via [HapticFeedback] and web haptics
/// via the Web Vibration API ([navigator.vibrate]) so that clicks, touches,
/// quiz answers, rewards, and error shakes physically vibrate on every device.
class HapticService {
  HapticService._();
  static final HapticService instance = HapticService._();

  bool enabled = true;

  void trigger(HapticFeedbackType type) {
    if (!enabled) return;

    switch (type) {
      case HapticFeedbackType.selection:
        try {
          HapticFeedback.selectionClick();
        } catch (_) {}
        platform.platformVibrate(12);
        break;

      case HapticFeedbackType.light:
        try {
          HapticFeedback.lightImpact();
        } catch (_) {}
        platform.platformVibrate(22);
        break;

      case HapticFeedbackType.medium:
        try {
          HapticFeedback.mediumImpact();
        } catch (_) {}
        platform.platformVibrate(45);
        break;

      case HapticFeedbackType.heavy:
        try {
          HapticFeedback.heavyImpact();
        } catch (_) {}
        platform.platformVibrate(75);
        break;

      case HapticFeedbackType.error:
        try {
          HapticFeedback.vibrate();
        } catch (_) {}
        platform.platformVibratePattern([50, 40, 100]);
        break;

      case HapticFeedbackType.celebration:
        try {
          HapticFeedback.heavyImpact();
        } catch (_) {}
        platform.platformVibratePattern([30, 40, 30, 40, 70]);
        break;
    }
  }

  void selection() => trigger(HapticFeedbackType.selection);
  void light() => trigger(HapticFeedbackType.light);
  void medium() => trigger(HapticFeedbackType.medium);
  void heavy() => trigger(HapticFeedbackType.heavy);
  void error() => trigger(HapticFeedbackType.error);
  void celebration() => trigger(HapticFeedbackType.celebration);
}
