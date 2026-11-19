import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AmbienceTrack {
  lute(
    id: 'lute',
    title: 'Classical Lute',
    subtitle: 'Gentle Renaissance acoustic lute & guitar ballad',
    assetFile: 'sounds/ambience_lute.wav',
    icon: Icons.music_note_rounded,
  ),
  fireplace(
    id: 'fireplace',
    title: "Knight's Hearth",
    subtitle: 'Warm crackling fireplace with gentle strings',
    assetFile: 'sounds/ambience_fireplace.wav',
    icon: Icons.fireplace_rounded,
  ),
  rain(
    id: 'rain',
    title: 'Rainy Library',
    subtitle: 'Soothing rain against cathedral glass',
    assetFile: 'sounds/ambience_rain.wav',
    icon: Icons.water_drop_rounded,
  ),
  scriptorium(
    id: 'scriptorium',
    title: 'Ancient Scriptorium',
    subtitle: 'Quiet study, gentle breeze & meditative chimes',
    assetFile: 'sounds/ambience_scriptorium.wav',
    icon: Icons.auto_stories_rounded,
  );

  final String id;
  final String title;
  final String subtitle;
  final String assetFile;
  final IconData icon;

  const AmbienceTrack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetFile,
    required this.icon,
  });

  static AmbienceTrack fromId(String id) {
    return AmbienceTrack.values.firstWhere(
      (t) => t.id == id,
      orElse: () => AmbienceTrack.lute,
    );
  }
}

/// Atmospheric background music and reading ambience service.
///
/// Provides seamless looping acoustic music and environmental soundscapes
/// (Classical Lute, Knight's Hearth, Rainy Library, Ancient Scriptorium) across
/// Web, Windows, Android, and iOS. Automatically ducks volume when the Audio
/// Narrator speaks aloud so the reader's voice is crystal-clear.
class AmbienceService extends ChangeNotifier {
  AmbienceService._();
  static final AmbienceService instance = AmbienceService._();

  AudioPlayer? _player;
  bool _isPlaying = false;
  bool _isDucked = false;
  double _volume = 0.65;
  AmbienceTrack _currentTrack = AmbienceTrack.lute;
  bool _enabled = true;

  bool get isPlaying => _isPlaying;
  bool get isDucked => _isDucked;
  double get volume => _volume;
  AmbienceTrack get currentTrack => _currentTrack;
  bool get enabled => _enabled;

  double get _effectiveVolume {
    if (!_enabled) return 0.0;
    if (_isDucked) return (_volume * 0.28).clamp(0.04, 0.20);
    return _volume;
  }

  bool get _isFlutterTest {
    final binding = WidgetsBinding.instance;
    return binding.runtimeType.toString().contains('TestWidgetsFlutterBinding') ||
        binding.runtimeType.toString().contains('AutomatedTestWidgetsFlutterBinding');
  }

  void syncWithSettings({required bool musicEnabled}) {
    _enabled = musicEnabled;
    if (!musicEnabled) {
      pause();
    }
  }

  void setEnabled(bool value) {
    _enabled = value;
    if (!value) {
      pause();
    } else if (!_isPlaying) {
      resume();
    }
    notifyListeners();
  }

  Future<void> playTrack(AmbienceTrack track) async {
    _currentTrack = track;
    _isPlaying = true;
    _enabled = true;
    notifyListeners();

    if (_isFlutterTest) return;

    await runZonedGuarded(() async {
      try {
        _player ??= AudioPlayer();
        if (_player!.state == PlayerState.playing) {
          await _player!.stop();
        }

        // Attempt in-memory byte playback first for instant zero-latency desktop support
        Source source;
        try {
          final bytes = await rootBundle.load('assets/${track.assetFile}');
          source = BytesSource(bytes.buffer.asUint8List());
        } catch (_) {
          source = AssetSource(track.assetFile);
        }

        await _player!.play(source, volume: _effectiveVolume);
        await _player!.setReleaseMode(ReleaseMode.loop);
        if (kDebugMode) {
          debugPrint('[AmbienceService] Playing ${track.title} (vol: $_effectiveVolume)');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[AmbienceService] playTrack exception: $e');
        try {
          await _player?.dispose();
          _player = AudioPlayer();
          await _player!.play(AssetSource(track.assetFile), volume: _effectiveVolume);
          await _player!.setReleaseMode(ReleaseMode.loop);
        } catch (retryError) {
          if (kDebugMode) debugPrint('[AmbienceService] retry error: $retryError');
        }
      }
    }, (error, stack) {
      if (kDebugMode) debugPrint('[AmbienceService] async error: $error');
    });
  }

  Future<void> resume() async {
    _enabled = true;
    _isPlaying = true;
    notifyListeners();

    if (_isFlutterTest) return;

    await runZonedGuarded(() async {
      try {
        if (_player == null || _player!.state == PlayerState.stopped || _player!.state == PlayerState.completed) {
          await playTrack(_currentTrack);
        } else {
          await _player!.setVolume(_effectiveVolume);
          await _player!.resume();
        }
      } catch (e) {
        // Fallback: re-initialize track if resume fails
        await playTrack(_currentTrack);
      }
    }, (error, stack) {
      if (kDebugMode) debugPrint('[AmbienceService] resume error: $error');
    });
  }

  Future<void> pause() async {
    _isPlaying = false;
    notifyListeners();

    if (_isFlutterTest) return;

    await runZonedGuarded(() async {
      try {
        await _player?.pause();
      } catch (_) {}
    }, (error, stack) {});
  }

  Future<void> stop() async {
    _isPlaying = false;
    notifyListeners();

    if (_isFlutterTest) return;

    await runZonedGuarded(() async {
      try {
        await _player?.stop();
      } catch (_) {}
    }, (error, stack) {});
  }

  Future<void> setVolume(double newVolume) async {
    _volume = newVolume.clamp(0.0, 1.0);
    notifyListeners();

    if (_isFlutterTest || _player == null) return;

    await runZonedGuarded(() async {
      try {
        await _player!.setVolume(_effectiveVolume);
      } catch (_) {}
    }, (error, stack) {});
  }

  /// Automatically lowers ambient music volume when narration speaks
  void duck() {
    if (_isDucked) return;
    _isDucked = true;
    notifyListeners();

    if (_isFlutterTest || _player == null || !_isPlaying) return;

    runZonedGuarded(() async {
      try {
        await _player!.setVolume(_effectiveVolume);
      } catch (_) {}
    }, (error, stack) {});
  }

  /// Restores normal ambient volume once narration completes or pauses
  void unduck() {
    if (!_isDucked) return;
    _isDucked = false;
    notifyListeners();

    if (_isFlutterTest || _player == null || !_isPlaying) return;

    runZonedGuarded(() async {
      try {
        await _player!.setVolume(_effectiveVolume);
      } catch (_) {}
    }, (error, stack) {});
  }
}
