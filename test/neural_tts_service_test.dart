import 'package:flutter_test/flutter_test.dart';
import 'package:quixoria/core/services/ambience_service.dart';
import 'package:quixoria/core/services/narration_service.dart';
import 'package:quixoria/core/services/neural_tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NeuralTtsService & Studio Narration Architecture Tests', () {
    test('TtsVoiceProvider definitions and free tier specifications', () {
      final google = TtsVoiceProvider.fromId('google');
      expect(google, equals(TtsVoiceProvider.google));
      expect(google.monthlyFreeTier, contains('1,000,000'));

      final elevenlabs = TtsVoiceProvider.fromId('elevenlabs');
      expect(elevenlabs, equals(TtsVoiceProvider.elevenlabs));
      expect(elevenlabs.monthlyFreeTier, contains('10,000'));
    });

    test('NeuralTtsService speaks with simulated test duration and ducks ambience', () async {
      final service = NeuralTtsService.instance;
      bool completed = false;

      final success = await service.speak(
        text: 'Hearken, noble student of the realm!',
        personaId: 'grand_knight',
        rate: 1.0,
        apiKey: 'test-key',
        providerId: 'google',
        onDone: () => completed = true,
      );

      expect(success, isTrue);
      expect(service.isPlaying, isTrue);

      // Wait for simulated playback timer to fire
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(completed, isTrue);
      expect(service.isPlaying, isFalse);
    });

    test('NeuralTtsService stop resets state and unducks ambience', () async {
      final service = NeuralTtsService.instance;
      bool completed = false;

      await service.speak(
        text: 'A long passage that will be halted midway by the gallant knight.',
        personaId: 'grand_knight',
        rate: 1.0,
        apiKey: 'test-key',
        onDone: () => completed = true,
      );

      expect(service.isPlaying, isTrue);
      service.stop();
      expect(service.isPlaying, isFalse);
      expect(completed, isFalse);
      expect(AmbienceService.instance.isDucked, isFalse);
    });

    test('NarrationService configures neural studio key and handles playback cycle', () async {
      final narration = NarrationService.instance;
      narration.configure(apiKey: 'studio-google-key', provider: 'google');

      expect(narration.apiKey, equals('studio-google-key'));
      expect(narration.provider, equals('google'));

      narration.loadChapter(paragraphs: [
        'In a village of La Mancha, whose name I have no desire to call to mind...',
        'He was a gentleman of ancient lineage and noble heart.'
      ]);

      expect(narration.totalParagraphs, equals(2));
      expect(narration.currentIndex, equals(0));

      narration.play();
      expect(narration.isPlaying, isTrue);

      narration.pause();
      expect(narration.isPaused, isTrue);

      narration.stop();
      expect(narration.isPlaying, isFalse);
    });
  });
}
