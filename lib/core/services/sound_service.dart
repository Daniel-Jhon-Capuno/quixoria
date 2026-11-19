import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

enum Sfx {
  correct,
  wrong,
  tap,
  levelComplete,
  streak,
  reward,
  pageTurn,
  purchase,
  dialog,
  notification,
  appOpen,
  bookAcquired,
  guide,
  welcome,
  streakRekindle,
  themeDownload,
  toggle,
}

/// Plays Quixoria's short UI sound effects.
///
/// All sounds are original or user-provided files in assets/sounds/. Failures
/// (e.g. no audio device, unsupported platform, tests) are swallowed so a
/// sound can never crash the app or fail unit tests.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  bool enabled = true;

  final Map<Sfx, AudioPlayer> _players = {};

  static const Map<Sfx, String> _files = {
    Sfx.correct: 'sounds/correct.wav',
    Sfx.wrong: 'sounds/wrong.wav',
    Sfx.tap: 'sounds/tap.wav',
    Sfx.levelComplete: 'sounds/level_complete.wav',
    Sfx.streak: 'sounds/streak.wav',
    Sfx.reward: 'sounds/reward.wav',
    Sfx.pageTurn: 'sounds/page_turn.wav',
    Sfx.purchase: 'sounds/purchase.wav',
    Sfx.dialog: 'sounds/dialog.wav',
    Sfx.notification: 'sounds/notification.wav',
    Sfx.appOpen: 'sounds/app_open.wav',
    Sfx.bookAcquired: 'sounds/book_acquired.wav',
    Sfx.guide: 'sounds/guide.wav',
    Sfx.welcome: 'sounds/welcome.wav',
    Sfx.streakRekindle: 'sounds/streak_rekindle.wav',
    Sfx.themeDownload: 'sounds/theme_download.wav',
    Sfx.toggle: 'sounds/toggle.mp3',
  };

  bool get _isFlutterTest {
    final binding = WidgetsBinding.instance;
    return binding.runtimeType.toString().contains('TestWidgetsFlutterBinding') ||
        binding.runtimeType.toString().contains('AutomatedTestWidgetsFlutterBinding');
  }

  Future<void> play(Sfx sfx) async {
    if (!enabled || _isFlutterTest) return;
    await runZonedGuarded(() async {
      try {
        var player = _players[sfx];
        if (player == null) {
          player = AudioPlayer();
          _players[sfx] = player;
          await player.setReleaseMode(ReleaseMode.stop);
        }
        if (player.state == PlayerState.playing) {
          await player.stop();
        }
        await player.setPlaybackRate(1.0);
        await player.play(AssetSource(_files[sfx]!), volume: 0.85);
      } catch (e) {
        if (kDebugMode) debugPrint('SoundService: could not play $sfx ($e)');
      }
    }, (error, stack) {
      if (kDebugMode) debugPrint('SoundService async error: $error');
    });
  }
}
