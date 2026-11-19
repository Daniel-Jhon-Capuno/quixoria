import 'dart:async';
import 'package:flutter/foundation.dart';
import '../neural_tts_service.dart';
import '../sound_service.dart';

abstract class TtsAdapter {
  Future<void> speak(
    String text,
    double rate,
    String persona,
    VoidCallback onDone, {
    String? apiKey,
    String provider = 'google',
  });
  void stop();
  void pause();
  void resume();
}

TtsAdapter getTtsAdapter() => ManuscriptAudioAdapter();

/// Cross-platform studio neural voice adapter.
///
/// Uses Google Cloud Studio TTS (1,000,000 chars/mo free) or ElevenLabs
/// to stream lifelike human voice narration via AudioPlayer. Completely
/// eliminates robotic OS synthesizers.
class ManuscriptAudioAdapter implements TtsAdapter {
  Timer? _timer;
  VoidCallback? _pendingCallback;

  @override
  Future<void> speak(
    String text,
    double rate,
    String persona,
    VoidCallback onDone, {
    String? apiKey,
    String provider = 'google',
  }) async {
    stop();
    _pendingCallback = onDone;

    SoundService.instance.play(Sfx.tap);

    final success = await NeuralTtsService.instance.speak(
      text: text,
      personaId: persona,
      rate: rate,
      apiKey: apiKey,
      providerId: provider,
      onDone: () {
        _pendingCallback?.call();
        _pendingCallback = null;
      },
    );

    if (success) return;

    // Graceful acoustic pacing fallback when offline or no API key is set yet
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final baseDurationMs = ((words / (140 * rate)) * 60 * 1000).toInt();
    final duration = baseDurationMs.clamp(500, 30000);

    _timer = Timer(Duration(milliseconds: duration), () {
      _pendingCallback?.call();
      _pendingCallback = null;
    });
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
    _pendingCallback = null;
    NeuralTtsService.instance.stop();
  }

  @override
  void pause() {
    _timer?.cancel();
    _timer = null;
    NeuralTtsService.instance.pause();
  }

  @override
  void resume() {
    NeuralTtsService.instance.resume();
  }
}
