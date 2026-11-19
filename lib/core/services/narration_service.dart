import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ambience_service.dart';
import 'sound_service.dart';
import 'tts/tts_adapter.dart';

enum NarrationState { stopped, playing, paused }

enum NarratorPersona {
  grandKnight(
    id: 'grand_knight',
    name: 'Sir Quixote',
    subtitle: 'Warm Storyteller',
    description: 'Distinguished British baritone with stately literary cadence',
    icon: '🛡️',
  ),
  gentleBard(
    id: 'gentle_bard',
    name: 'Lady Dulcinea',
    subtitle: 'Gentle Bard',
    description: 'Melodic, warm and expressive lyrical voice',
    icon: '✨',
  ),
  classicScholar(
    id: 'classic_scholar',
    name: 'Royal Scholar',
    subtitle: 'Studio Clarity',
    description: 'Crisp, articulate natural studio cadence',
    icon: '📜',
  );

  final String id;
  final String name;
  final String subtitle;
  final String description;
  final String icon;

  const NarratorPersona({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.icon,
  });

  static NarratorPersona fromId(String? id) {
    return NarratorPersona.values.firstWhere(
      (p) => p.id == id,
      orElse: () => NarratorPersona.grandKnight,
    );
  }
}

class NarrationService extends ChangeNotifier {
  NarrationService._() {
    _loadSavedPersona();
  }
  static final NarrationService instance = NarrationService._();

  static const String _prefKey = 'quixoria_narrator_persona';

  final TtsAdapter _tts = getTtsAdapter();

  List<String> _paragraphs = [];
  int _currentIndex = 0;
  NarrationState _state = NarrationState.stopped;
  double _speechRate = 1.0;
  NarratorPersona _persona = NarratorPersona.grandKnight;

  String? _apiKey;
  String _provider = 'google';

  List<String> get paragraphs => _paragraphs;
  int get currentIndex => _currentIndex;
  NarrationState get state => _state;
  bool get isPlaying => _state == NarrationState.playing;
  bool get isPaused => _state == NarrationState.paused;
  double get speechRate => _speechRate;
  int get totalParagraphs => _paragraphs.length;
  NarratorPersona get persona => _persona;
  String? get apiKey => _apiKey;
  String get provider => _provider;

  void configure({String? apiKey, String? provider}) {
    if (apiKey != null) _apiKey = apiKey;
    if (provider != null) _provider = provider;
  }

  Future<void> _loadSavedPersona() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_prefKey);
      if (savedId != null && savedId.isNotEmpty) {
        _persona = NarratorPersona.fromId(savedId);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setPersona(NarratorPersona newPersona) async {
    if (_persona != newPersona) {
      _persona = newPersona;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKey, newPersona.id);
      } catch (_) {}

      // If currently playing, seamlessly restart current passage with the new natural voice
      if (_state == NarrationState.playing) {
        _speakCurrent();
      }
    }
  }

  /// Loads text paragraphs for a chapter.
  void loadChapter({required List<String> paragraphs, int startIndex = 0}) {
    stop();
    _paragraphs = paragraphs.where((p) => p.trim().isNotEmpty).toList();
    _currentIndex = startIndex.clamp(0, (_paragraphs.length - 1).clamp(0, 9999));
    notifyListeners();
  }

  /// Begins or resumes narration.
  void play({String? apiKey, String? provider}) {
    if (_paragraphs.isEmpty) return;
    if (apiKey != null) _apiKey = apiKey;
    if (provider != null) _provider = provider;

    AmbienceService.instance.duck();

    if (_state == NarrationState.paused) {
      _state = NarrationState.playing;
      _tts.resume();
      notifyListeners();
      return;
    }

    _state = NarrationState.playing;
    notifyListeners();
    _speakCurrent();
  }

  void pause() {
    if (_state == NarrationState.playing) {
      _state = NarrationState.paused;
      _tts.pause();
      AmbienceService.instance.unduck();
      notifyListeners();
    }
  }

  void stop() {
    _state = NarrationState.stopped;
    _tts.stop();
    AmbienceService.instance.unduck();
    notifyListeners();
  }

  void cycleSpeechRate() {
    if (_speechRate == 0.75) {
      _speechRate = 1.0;
    } else if (_speechRate == 1.0) {
      _speechRate = 1.25;
    } else if (_speechRate == 1.25) {
      _speechRate = 1.5;
    } else {
      _speechRate = 0.75;
    }

    notifyListeners();

    // If currently playing, restart current paragraph with new rate
    if (_state == NarrationState.playing) {
      _speakCurrent();
    }
  }

  void skipTo(int index) {
    if (_paragraphs.isEmpty) return;
    _currentIndex = index.clamp(0, _paragraphs.length - 1);
    notifyListeners();
    if (_state == NarrationState.playing) {
      _speakCurrent();
    }
  }

  void nextParagraph() {
    if (_currentIndex < _paragraphs.length - 1) {
      skipTo(_currentIndex + 1);
    } else {
      stop();
      SoundService.instance.play(Sfx.pageTurn);
    }
  }

  void previousParagraph() {
    if (_currentIndex > 0) {
      skipTo(_currentIndex - 1);
    }
  }

  /// Plays a short literary voice preview for testing personas.
  void playSample([NarratorPersona? samplePersona, String? apiKey, String? provider]) {
    final personaToUse = samplePersona ?? _persona;
    if (apiKey != null) _apiKey = apiKey;
    if (provider != null) _provider = provider;

    stop();
    final sampleText = personaToUse == NarratorPersona.grandKnight
        ? 'In a village of La Mancha, whose name I have no desire to call to mind, there lived not long since a gentleman of ancient lineage.'
        : personaToUse == NarratorPersona.gentleBard
            ? 'Listen closely, wanderer of legends. Let the gentle wind carry tales of nobility, beauty, and steadfast courage.'
            : 'Behold the chronicles of Quixoria: historical manuscripts transcribed with articulate clarity and scholarly cadence.';

    _state = NarrationState.playing;
    notifyListeners();
    _tts.speak(
      sampleText,
      1.0,
      personaToUse.id,
      () {
        _state = NarrationState.stopped;
        notifyListeners();
      },
      apiKey: _apiKey,
      provider: _provider,
    );
  }

  void _speakCurrent() {
    if (_currentIndex >= _paragraphs.length || _state != NarrationState.playing) return;

    final text = _paragraphs[_currentIndex];
    _tts.speak(
      text,
      _speechRate,
      _persona.id,
      () {
        if (_state != NarrationState.playing) return;

        if (_currentIndex < _paragraphs.length - 1) {
          _currentIndex++;
          notifyListeners();
          _speakCurrent();
        } else {
          stop();
          SoundService.instance.play(Sfx.pageTurn);
        }
      },
      apiKey: _apiKey,
      provider: _provider,
    );
  }
}
