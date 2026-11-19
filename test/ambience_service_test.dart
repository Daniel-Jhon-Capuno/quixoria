import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quixoria/core/services/ambience_service.dart';
import 'package:quixoria/features/reader/ambience_soundscape_sheet.dart';

void main() {
  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Ambience Sound Service & Asset Verification Tests', () {
    test('All ambience audio files exist on disk with valid 44.1kHz stereo headers', () {
      for (final track in AmbienceTrack.values) {
        final f = File('assets/${track.assetFile}');
        expect(f.existsSync(), isTrue, reason: 'File assets/${track.assetFile} should exist');
        final bytes = f.readAsBytesSync();
        expect(bytes.length, greaterThan(100000), reason: 'Audio file should have valid length');

        // Verify RIFF header
        expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');

        // Verify Channels = 2 (stereo)
        final numChannels = bytes[22] | (bytes[23] << 8);
        expect(numChannels, 2, reason: 'Ambience track ${track.id} must be 2-channel stereo');

        // Verify Sample Rate = 44100 Hz
        final sampleRate = bytes[24] | (bytes[25] << 8) | (bytes[26] << 16) | (bytes[27] << 24);
        expect(sampleRate, 44100, reason: 'Ambience track ${track.id} must be 44100 Hz');
      }
    });

    test('AmbienceService state updates correctly on playTrack, setVolume, and duck/unduck', () async {
      final ambience = AmbienceService.instance;

      // Select track
      await ambience.playTrack(AmbienceTrack.rain);
      expect(ambience.currentTrack, AmbienceTrack.rain);
      expect(ambience.isPlaying, isTrue);
      expect(ambience.enabled, isTrue);

      // Volume control
      await ambience.setVolume(0.70);
      expect(ambience.volume, closeTo(0.70, 0.001));

      // Ducking for narration
      ambience.duck();
      expect(ambience.isDucked, isTrue);

      // Unduck when narration finishes
      ambience.unduck();
      expect(ambience.isDucked, isFalse);

      // Pause and resume
      await ambience.pause();
      expect(ambience.isPlaying, isFalse);

      await ambience.resume();
      expect(ambience.isPlaying, isTrue);

      await ambience.stop();
      expect(ambience.isPlaying, isFalse);
    });

    testWidgets('AmbienceSoundscapeSheet renders 4 atmospheres and controls', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmbienceSoundscapeSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reading Ambience & Music'), findsOneWidget);
      expect(find.text('Classical Lute'), findsOneWidget);
      expect(find.text("Knight's Hearth"), findsOneWidget);
      expect(find.text('Rainy Library'), findsOneWidget);
      expect(find.text('Ancient Scriptorium'), findsOneWidget);

      // Tap on Knight's Hearth
      await tester.tap(find.text("Knight's Hearth"));
      await tester.pumpAndSettle();

      expect(AmbienceService.instance.currentTrack, AmbienceTrack.fireplace);
    });
  });
}
