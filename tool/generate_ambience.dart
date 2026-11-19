import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  print('Generating Quixoria Ambience Audio tracks (44100 Hz Stereo)...');

  final soundsDir = Directory('assets/sounds');
  if (!soundsDir.existsSync()) {
    soundsDir.createSync(recursive: true);
  }

  // 1. Classical Lute: Gentle Renaissance acoustic melody (8 seconds loop)
  _generateLuteAmbience(File('assets/sounds/ambience_lute.wav'));

  // 2. Knight's Hearth: Warm crackling fireplace with soft background drone (8 seconds loop)
  _generateFireplaceAmbience(File('assets/sounds/ambience_fireplace.wav'));

  // 3. Rainy Library: Soothing rainfall with gentle resonance (8 seconds loop)
  _generateRainAmbience(File('assets/sounds/ambience_rain.wav'));

  // 4. Ancient Scriptorium: Peaceful meditative chimes & gentle wind harp (8 seconds loop)
  _generateScriptoriumAmbience(File('assets/sounds/ambience_scriptorium.wav'));

  // Synchronize copies to build asset caches if present
  for (final buildDir in ['build/flutter_assets/assets/sounds', 'build/unit_test_assets/assets/sounds']) {
    final d = Directory(buildDir);
    if (d.existsSync()) {
      for (final f in soundsDir.listSync().whereType<File>()) {
        if (f.path.contains('ambience_')) {
          final target = File('$buildDir/${f.uri.pathSegments.last}');
          f.copySync(target.path);
        }
      }
      print('Synchronized ambience files to $buildDir');
    }
  }

  print('All Ambience tracks generated successfully in 44.1kHz Stereo!');
}

void _generateLuteAmbience(File file) {
  const sampleRate = 44100;
  const durationSec = 8.0;
  final numSamples = (sampleRate * durationSec).toInt();
  final left = Float64List(numSamples);
  final right = Float64List(numSamples);

  void pluck(double timeSec, double freq, double amplitude, double decayRate, double pan) {
    final startIdx = (timeSec * sampleRate).toInt();
    final leftGain = cos((pan + 1.0) * pi / 4.0);
    final rightGain = sin((pan + 1.0) * pi / 4.0);

    for (int i = 0; i < sampleRate * 3.5 && (startIdx + i) < numSamples; i++) {
      final t = i / sampleRate;
      final envelope = exp(-decayRate * t);
      final s = sin(2 * pi * freq * t) +
          0.45 * sin(2 * pi * (freq * 2.0) * t) +
          0.20 * sin(2 * pi * (freq * 3.0) * t) +
          0.10 * sin(2 * pi * (freq * 4.0) * t);
      final sampleVal = s * amplitude * envelope;
      left[startIdx + i] += sampleVal * leftGain;
      right[startIdx + i] += sampleVal * rightGain;
    }
  }

  // Renaissance chord progression arpeggio with spatial panning
  final notes = [
    // Am bar (0.0s - 2.0s)
    (0.00, 110.0, 0.40, 1.4, -0.2),
    (0.25, 164.81, 0.32, 1.8, 0.1),
    (0.50, 220.0, 0.35, 1.9, -0.15),
    (0.75, 261.63, 0.38, 2.0, 0.25),
    (1.00, 329.63, 0.42, 1.6, 0.0),
    (1.35, 261.63, 0.30, 2.2, -0.2),
    (1.65, 220.0, 0.28, 2.3, 0.15),

    // G bar (2.0s - 4.0s)
    (2.00, 98.0, 0.38, 1.4, -0.25),
    (2.25, 146.83, 0.30, 1.8, 0.2),
    (2.50, 196.0, 0.34, 1.9, -0.1),
    (2.75, 246.94, 0.36, 2.0, 0.3),
    (3.00, 293.66, 0.40, 1.6, 0.0),
    (3.35, 246.94, 0.28, 2.2, -0.15),
    (3.65, 196.0, 0.26, 2.3, 0.1),

    // F bar (4.0s - 6.0s)
    (4.00, 87.31, 0.38, 1.4, -0.2),
    (4.25, 130.81, 0.30, 1.8, 0.15),
    (4.50, 174.61, 0.34, 1.9, -0.25),
    (4.75, 220.0, 0.36, 2.0, 0.2),
    (5.00, 261.63, 0.40, 1.6, 0.0),
    (5.35, 220.0, 0.28, 2.2, -0.1),
    (5.65, 174.61, 0.26, 2.3, 0.15),

    // E7 bar resolving into next loop (6.0s - 8.0s)
    (6.00, 82.41, 0.40, 1.4, -0.15),
    (6.25, 123.47, 0.30, 1.8, 0.25),
    (6.50, 164.81, 0.33, 1.9, -0.2),
    (6.75, 207.65, 0.36, 2.0, 0.15),
    (7.00, 246.94, 0.38, 1.6, 0.0),
    (7.35, 207.65, 0.26, 2.4, -0.1),
    (7.65, 164.81, 0.24, 2.5, 0.2),
  ];

  for (final n in notes) {
    pluck(n.$1, n.$2, n.$3, n.$4, n.$5);
  }

  _applyLoopCrossfade(left, sampleRate, 0.3);
  _applyLoopCrossfade(right, sampleRate, 0.3);
  _writeStereoWav(file, left, right, sampleRate);
}

void _generateFireplaceAmbience(File file) {
  const sampleRate = 44100;
  const durationSec = 8.0;
  final numSamples = (sampleRate * durationSec).toInt();
  final left = Float64List(numSamples);
  final right = Float64List(numSamples);
  final rng = Random(42);

  // Warm gentle low drone rumble (hearth warmth)
  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final rumble = 0.12 * sin(2 * pi * 55.0 * t) +
        0.08 * sin(2 * pi * 82.4 * t) +
        0.05 * sin(2 * pi * 110.0 * t);
    // Soft gentle air hiss
    final hiss = (rng.nextDouble() - 0.5) * 0.04;
    left[i] = rumble + hiss;
    right[i] = rumble - hiss;
  }

  // Periodic wood crackles and popping embers
  const numPops = 48;
  for (int p = 0; p < numPops; p++) {
    final popTime = (p * (durationSec / numPops)) + (rng.nextDouble() * 0.12);
    final popIdx = (popTime * sampleRate).toInt().clamp(0, numSamples - 1);
    final popAmp = 0.25 + rng.nextDouble() * 0.35;
    final popPan = (rng.nextDouble() - 0.5) * 0.8;
    final lGain = cos((popPan + 1.0) * pi / 4.0);
    final rGain = sin((popPan + 1.0) * pi / 4.0);
    final popLen = (sampleRate * (0.015 + rng.nextDouble() * 0.025)).toInt();

    for (int i = 0; i < popLen && (popIdx + i) < numSamples; i++) {
      final t = i / sampleRate;
      final env = exp(-280.0 * t);
      final noise = (rng.nextDouble() - 0.5) * 2.0;
      final val = noise * popAmp * env;
      left[popIdx + i] += val * lGain;
      right[popIdx + i] += val * rGain;
    }
  }

  _applyLoopCrossfade(left, sampleRate, 0.3);
  _applyLoopCrossfade(right, sampleRate, 0.3);
  _writeStereoWav(file, left, right, sampleRate);
}

void _generateRainAmbience(File file) {
  const sampleRate = 44100;
  const durationSec = 8.0;
  final numSamples = (sampleRate * durationSec).toInt();
  final left = Float64List(numSamples);
  final right = Float64List(numSamples);
  final rng = Random(1337);

  // Filtered pink-noise rain bed
  double b0L = 0, b1L = 0, b2L = 0;
  double b0R = 0, b1R = 0, b2R = 0;
  for (int i = 0; i < numSamples; i++) {
    final whiteL = rng.nextDouble() - 0.5;
    final whiteR = rng.nextDouble() - 0.5;

    b0L = 0.99886 * b0L + whiteL * 0.0555179;
    b1L = 0.99332 * b1L + whiteL * 0.0750759;
    b2L = 0.96900 * b2L + whiteL * 0.1538520;
    left[i] = (b0L + b1L + b2L + whiteL * 0.5362) * 0.16;

    b0R = 0.99886 * b0R + whiteR * 0.0555179;
    b1R = 0.99332 * b1R + whiteR * 0.0750759;
    b2R = 0.96900 * b2R + whiteR * 0.1538520;
    right[i] = (b0R + b1R + b2R + whiteR * 0.5362) * 0.16;
  }

  // Individual subtle rain droplet taps on window panes
  const numDrops = 60;
  for (int d = 0; d < numDrops; d++) {
    final dropTime = rng.nextDouble() * (durationSec - 0.1);
    final dropIdx = (dropTime * sampleRate).toInt();
    final dropFreq = 600.0 + rng.nextDouble() * 1200.0;
    final dropAmp = 0.08 + rng.nextDouble() * 0.12;
    final dropPan = (rng.nextDouble() - 0.5) * 0.9;
    final lGain = cos((dropPan + 1.0) * pi / 4.0);
    final rGain = sin((dropPan + 1.0) * pi / 4.0);

    for (int i = 0; i < sampleRate * 0.04 && (dropIdx + i) < numSamples; i++) {
      final t = i / sampleRate;
      final env = exp(-120.0 * t);
      final s = sin(2 * pi * dropFreq * t) * dropAmp * env;
      left[dropIdx + i] += s * lGain;
      right[dropIdx + i] += s * rGain;
    }
  }

  _applyLoopCrossfade(left, sampleRate, 0.3);
  _applyLoopCrossfade(right, sampleRate, 0.3);
  _writeStereoWav(file, left, right, sampleRate);
}

void _generateScriptoriumAmbience(File file) {
  const sampleRate = 44100;
  const durationSec = 8.0;
  final numSamples = (sampleRate * durationSec).toInt();
  final left = Float64List(numSamples);
  final right = Float64List(numSamples);
  final rng = Random(888);

  // Soft library drone & quiet gentle wind harmony
  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final pad = 0.10 * sin(2 * pi * 130.81 * t) + // C3
        0.08 * sin(2 * pi * 196.00 * t) + // G3
        0.06 * sin(2 * pi * 261.63 * t); // C4
    final whisper = (rng.nextDouble() - 0.5) * 0.02;
    left[i] = pad + whisper;
    right[i] = pad - whisper;
  }

  // Wind chimes (Pentatonic: C, D, E, G, A in high octaves)
  void chime(double timeSec, double freq, double pan) {
    final startIdx = (timeSec * sampleRate).toInt();
    final lGain = cos((pan + 1.0) * pi / 4.0);
    final rGain = sin((pan + 1.0) * pi / 4.0);

    for (int i = 0; i < sampleRate * 2.8 && (startIdx + i) < numSamples; i++) {
      final t = i / sampleRate;
      final env = exp(-2.2 * t);
      // Pure sine with subtle shimmering harmonic
      final s = (sin(2 * pi * freq * t) + 0.25 * sin(2 * pi * (freq * 2.76) * t)) * 0.18 * env;
      left[startIdx + i] += s * lGain;
      right[startIdx + i] += s * rGain;
    }
  }

  final chimes = [
    (0.4, 1046.50, -0.4), // C6
    (1.8, 1318.51, 0.35), // E6
    (3.2, 1567.98, -0.2), // G6
    (4.6, 1760.00, 0.4),  // A6
    (6.0, 1318.51, -0.3), // E6
    (7.1, 1046.50, 0.2),  // C6
  ];

  for (final c in chimes) {
    chime(c.$1, c.$2, c.$3);
  }

  _applyLoopCrossfade(left, sampleRate, 0.3);
  _applyLoopCrossfade(right, sampleRate, 0.3);
  _writeStereoWav(file, left, right, sampleRate);
}

void _applyLoopCrossfade(Float64List samples, int sampleRate, double fadeTimeSec) {
  final fadeSamples = (fadeTimeSec * sampleRate).toInt();
  final len = samples.length;
  for (int i = 0; i < fadeSamples; i++) {
    final t = i / fadeSamples;
    final startVal = samples[i];
    final endVal = samples[len - fadeSamples + i];
    samples[i] = (1 - t) * startVal + t * endVal;
    samples[len - fadeSamples + i] = samples[i];
  }
}

void _writeStereoWav(File file, Float64List left, Float64List right, int sampleRate) {
  double maxAmp = 0.0001;
  final numFrames = left.length;
  for (int i = 0; i < numFrames; i++) {
    final l = left[i].abs();
    final r = right[i].abs();
    if (l > maxAmp) maxAmp = l;
    if (r > maxAmp) maxAmp = r;
  }

  final normFactor = 0.85 / maxAmp;
  const numChannels = 2;
  const bytesPerSample = 2; // 16-bit
  final dataSize = numFrames * numChannels * bytesPerSample;
  final byteData = ByteData(44 + dataSize);

  // RIFF Header
  byteData.setUint8(0, 0x52); // 'R'
  byteData.setUint8(1, 0x49); // 'I'
  byteData.setUint8(2, 0x46); // 'F'
  byteData.setUint8(3, 0x46); // 'F'
  byteData.setUint32(4, 36 + dataSize, Endian.little);
  byteData.setUint8(8, 0x57); // 'W'
  byteData.setUint8(9, 0x41); // 'A'
  byteData.setUint8(10, 0x56); // 'V'
  byteData.setUint8(11, 0x45); // 'E'

  // fmt chunk
  byteData.setUint8(12, 0x66); // 'f'
  byteData.setUint8(13, 0x6D); // 'm'
  byteData.setUint8(14, 0x74); // 't'
  byteData.setUint8(15, 0x20); // ' '
  byteData.setUint32(16, 16, Endian.little); // chunk size: 16 for PCM
  byteData.setUint16(20, 1, Endian.little); // PCM format
  byteData.setUint16(22, numChannels, Endian.little); // 2 channels
  byteData.setUint32(24, sampleRate, Endian.little); // 44100
  byteData.setUint32(28, sampleRate * numChannels * bytesPerSample, Endian.little); // byte rate (176400)
  byteData.setUint16(32, numChannels * bytesPerSample, Endian.little); // block align (4)
  byteData.setUint16(34, 16, Endian.little); // 16 bits per sample

  // data chunk
  byteData.setUint8(36, 0x64); // 'd'
  byteData.setUint8(37, 0x61); // 'a'
  byteData.setUint8(38, 0x74); // 't'
  byteData.setUint8(39, 0x61); // 'a'
  byteData.setUint32(40, dataSize, Endian.little);

  // Interleaved 16-bit PCM samples
  int offset = 44;
  for (int i = 0; i < numFrames; i++) {
    final lSample = (left[i] * normFactor).clamp(-1.0, 1.0);
    final rSample = (right[i] * normFactor).clamp(-1.0, 1.0);

    byteData.setInt16(offset, (lSample * 32767).toInt(), Endian.little);
    byteData.setInt16(offset + 2, (rSample * 32767).toInt(), Endian.little);
    offset += 4;
  }

  file.writeAsBytesSync(byteData.buffer.asUint8List());
  print('Wrote stereo ${file.path} (${file.lengthSync()} bytes)');
}
