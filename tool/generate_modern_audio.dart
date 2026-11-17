import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() async {
  final outDir = Directory('assets/audio');
  final tempDir = Directory('tool/wav_modern');
  if (!tempDir.existsSync()) tempDir.createSync(recursive: true);

  stdout.writeln('Synthesizing Modern Arcade Audio Suite...');

  // =========================================================================
  // 1. MODERN BGM: 128 BPM Upbeat Electro-Arcade Groove
  // =========================================================================
  const int sampleRate = 44100;
  const double bpm = 128.0;
  const double beatSec = 60.0 / bpm; // ~0.46875s per beat
  const int numBars = 8;             // 8-bar loop = 32 beats = 15.0 seconds
  const double loopDuration = numBars * 4 * beatSec; // 15.0 sec
  final int totalSamples = (loopDuration * sampleRate).round();

  final bgmBuffer = Float64List(totalSamples);

  // Bass notes: Am (A1=55Hz), F (F1=43.65Hz), C (C2=65.41Hz), G (G1=49.0Hz)
  final bassFreqs = [55.0, 55.0, 43.65, 43.65, 65.41, 65.41, 49.0, 49.0];

  // Melody pattern (16th note steps): Catchy modern electro hook
  final melodyNotes = [
    // Bar 1-2: A minor
    440.0, 0.0, 523.25, 659.25, 0.0, 587.33, 523.25, 440.0,
    0.0, 659.25, 783.99, 0.0, 659.25, 587.33, 523.25, 0.0,
    // Bar 3-4: F major
    349.23, 0.0, 440.0, 523.25, 0.0, 659.25, 523.25, 440.0,
    0.0, 523.25, 659.25, 783.99, 0.0, 659.25, 523.25, 0.0,
    // Bar 5-6: C major
    523.25, 0.0, 659.25, 783.99, 0.0, 880.0, 783.99, 659.25,
    0.0, 783.99, 987.77, 0.0, 783.99, 659.25, 587.33, 0.0,
    // Bar 7-8: G major / turnaround
    392.0, 0.0, 493.88, 587.33, 0.0, 783.99, 659.25, 587.33,
    659.25, 0.0, 783.99, 880.0, 0.0, 987.77, 1046.50, 0.0,
  ];

  final rand = Random(42);

  for (int i = 0; i < totalSamples; i++) {
    final double t = i / sampleRate;
    final double beatTime = t / beatSec;
    final int beatIndex = beatTime.floor();
    final double beatFrac = beatTime - beatIndex;

    double mix = 0.0;

    // --- A. KICK DRUM (Every beat: 4-on-the-floor) ---
    final double kickEnv = exp(-beatFrac * 18.0);
    final double kickFreq = 140.0 * exp(-beatFrac * 28.0) + 48.0;
    final double kick = sin(2 * pi * kickFreq * beatFrac * beatSec) * kickEnv;
    mix += kick * 0.55;

    // --- B. HI-HAT (Off-beats: 16th / 8th notes) ---
    final double hatFrac = (beatTime * 2.0) % 1.0;
    if (hatFrac < 0.4) {
      final double hatEnv = exp(-hatFrac * 24.0);
      final double hatNoise = (rand.nextDouble() * 2.0 - 1.0);
      mix += hatNoise * hatEnv * 0.12;
    }

    // --- C. CLAP / SNARE (Beats 2 and 4) ---
    final int beatInBar = beatIndex % 4;
    if (beatInBar == 1 || beatInBar == 3) {
      final double clapEnv = exp(-beatFrac * 14.0);
      final double clapNoise = (rand.nextDouble() * 2.0 - 1.0);
      final double clapTone = sin(2 * pi * 220.0 * beatFrac * beatSec);
      mix += (clapNoise * 0.7 + clapTone * 0.3) * clapEnv * 0.28;
    }

    // --- D. ROLLING SYNTH BASSLINE (Syncopated 16th notes) ---
    final int barIndex = (beatIndex ~/ 4) % bassFreqs.length;
    final double baseBassFreq = bassFreqs[barIndex];
    final double bass16th = (beatTime * 4.0) % 1.0;
    final double bassEnv = exp(-bass16th * 8.0);
    // Square/Saw harmonics for modern electro punch
    final double bPhase = 2 * pi * baseBassFreq * t;
    final double bassWave = sin(bPhase) * 0.6 + sin(bPhase * 2) * 0.3 + sin(bPhase * 3) * 0.1;
    mix += bassWave * bassEnv * 0.32;

    // --- E. CATCHY LEAD ARCADIAN SYNTH ---
    final int step16 = ((beatTime * 2.0).floor()) % melodyNotes.length;
    final double noteFreq = melodyNotes[step16];
    if (noteFreq > 0.0) {
      final double stepFrac = (beatTime * 2.0) % 1.0;
      final double leadEnv = exp(-stepFrac * 5.0);
      final double lPhase = 2 * pi * noteFreq * t;
      // Rich supersaw lead
      final double lead = (sin(lPhase) * 0.5 + sin(lPhase * 1.008) * 0.25 + sin(lPhase * 0.992) * 0.25);
      mix += lead * leadEnv * 0.26;
    }

    bgmBuffer[i] = mix.clamp(-1.0, 1.0);
  }

  _writeWav('${tempDir.path}/bgm.wav', bgmBuffer, sampleRate);

  // =========================================================================
  // 2. MODERN SOUND EFFECTS
  // =========================================================================

  // A. FLAP: Modern aerodynamic swoosh / whip with low-end punch
  _generateSound('${tempDir.path}/flap.wav', duration: 0.16, generator: (t) {
    final double env = exp(-t * 22.0);
    final double f = 380.0 * exp(-t * 18.0) + 110.0;
    final double noise = (rand.nextDouble() * 2.0 - 1.0) * exp(-t * 30.0);
    final double tone = sin(2 * pi * f * t);
    return (tone * 0.65 + noise * 0.35) * env;
  });

  // B. SCORE: Modern rewarding double-chime (E6 + B6)
  _generateSound('${tempDir.path}/score.wav', duration: 0.32, generator: (t) {
    final double env1 = exp(-t * 10.0);
    final double env2 = t > 0.07 ? exp(-(t - 0.07) * 8.0) : 0.0;
    final double c1 = sin(2 * pi * 1318.51 * t) * env1; // E6
    final double c2 = sin(2 * pi * 1975.53 * (t - 0.07)) * env2; // B6
    return (c1 * 0.5 + c2 * 0.6).clamp(-1.0, 1.0);
  });

  // C. GEM: Bright crystalline glissando ding
  _generateSound('${tempDir.path}/gem.wav', duration: 0.38, generator: (t) {
    final double f = 1400.0 + 800.0 * (t / 0.38);
    final double env = exp(-t * 7.5);
    final double s1 = sin(2 * pi * f * t);
    final double s2 = sin(2 * pi * f * 2.0 * t) * 0.3;
    return (s1 + s2) * env * 0.7;
  });

  // D. HIT: Punchy modern impact (bass kick + metallic snap)
  _generateSound('${tempDir.path}/hit.wav', duration: 0.28, generator: (t) {
    final double f = 160.0 * exp(-t * 28.0) + 45.0;
    final double env = exp(-t * 16.0);
    final double noise = (rand.nextDouble() * 2.0 - 1.0) * exp(-t * 35.0);
    final double bass = sin(2 * pi * f * t);
    return (bass * 0.75 + noise * 0.25) * env;
  });

  // E. GAMEOVER: Modern arcade sweep drop (descending sci-fi powerdown)
  _generateSound('${tempDir.path}/gameover.wav', duration: 0.75, generator: (t) {
    final double f = 580.0 * exp(-t * 3.5) + 60.0;
    final double env = (1.0 - t / 0.75).clamp(0.0, 1.0) * exp(-t * 2.0);
    final double w1 = sin(2 * pi * f * t);
    final double w2 = sin(2 * pi * (f * 0.75) * t) * 0.4;
    return (w1 + w2) * env * 0.8;
  });

  // F. CLICK: Crisp tactile UI pop
  _generateSound('${tempDir.path}/click.wav', duration: 0.06, generator: (t) {
    final double env = exp(-t * 80.0);
    final double f = 900.0 * exp(-t * 40.0) + 400.0;
    return sin(2 * pi * f * t) * env;
  });

  // G. COMBO: Modern dual-tone energetic riser
  _generateSound('${tempDir.path}/combo.wav', duration: 0.45, generator: (t) {
    final double f1 = 660.0 + 800.0 * pow(t / 0.45, 1.5);
    final double env = exp(-t * 5.0);
    return (sin(2 * pi * f1 * t) * 0.7 + sin(2 * pi * f1 * 1.5 * t) * 0.3) * env;
  });

  // H. POWERUP: Futuristic charging riser sweep
  _generateSound('${tempDir.path}/powerup.wav', duration: 0.45, generator: (t) {
    final double f = 350.0 + 1100.0 * pow(t / 0.45, 1.3);
    final double env = exp(-t * 4.5);
    final double p = 2 * pi * f * t;
    return (sin(p) * 0.65 + sin(p * 2.0) * 0.35) * env * 0.85;
  });

  // I. SHIELD: Sci-fi metallic forcefield deflection
  _generateSound('${tempDir.path}/shield.wav', duration: 0.40, generator: (t) {
    final double f = 320.0 * exp(-t * 9.0) + 110.0;
    final double env = exp(-t * 8.0);
    final double wave = sin(2 * pi * f * t) * 0.7 + sin(2 * pi * f * 2.2 * t) * 0.3;
    return wave * env * 0.9;
  });

  // J. UNLOCK: Heroic modern 4-note EDM fanfare
  _generateSound('${tempDir.path}/unlock.wav', duration: 0.65, generator: (t) {
    final notes = [587.33, 739.99, 880.00, 1174.66]; // D5, F#5, A5, D6
    const double noteDur = 0.12;
    double s = 0.0;
    for (int i = 0; i < notes.length; i++) {
      final double start = i * noteDur;
      if (t >= start) {
        final double dt = t - start;
        final double env = exp(-dt * 4.5);
        s += sin(2 * pi * notes[i] * dt) * env * 0.38;
      }
    }
    return s.clamp(-1.0, 1.0);
  });

  // =========================================================================
  // 3. CONVERT ALL WAVs TO ULTRA-OPTIMIZED MP3 VIA FFMPEG
  // =========================================================================
  final allAudioNames = [
    'bgm',
    'flap',
    'score',
    'gem',
    'hit',
    'gameover',
    'click',
    'combo',
    'powerup',
    'shield',
    'unlock',
  ];

  for (final name in allAudioNames) {
    final wavPath = '${tempDir.path}/$name.wav';
    final mp3Path = '${outDir.path}/$name.mp3';
    await Process.run('ffmpeg', [
      '-y',
      '-i',
      wavPath,
      '-codec:a',
      'libmp3lame',
      '-b:a',
      name == 'bgm' ? '96k' : '64k',
      mp3Path,
    ]);
    stdout.writeln('Rendered $name.mp3');
  }

  tempDir.deleteSync(recursive: true);
  stdout.writeln('Modern Arcade Audio Suite Ready!');
}

void _generateSound(
  String path, {
  required double duration,
  required double Function(double t) generator,
}) {
  const int sampleRate = 44100;
  final int totalSamples = (duration * sampleRate).round();
  final buffer = Float64List(totalSamples);
  for (int i = 0; i < totalSamples; i++) {
    final double t = i / sampleRate;
    buffer[i] = generator(t).clamp(-1.0, 1.0);
  }
  _writeWav(path, buffer, sampleRate);
}

void _writeWav(String path, Float64List samples, int sampleRate) {
  final int byteLength = samples.length * 2;
  final bytes = ByteData(44 + byteLength);

  void writeString(int offset, String str) {
    for (int i = 0; i < str.length; i++) {
      bytes.setUint8(offset + i, str.codeUnitAt(i));
    }
  }

  writeString(0, 'RIFF');
  bytes.setUint32(4, 36 + byteLength, Endian.little);
  writeString(8, 'WAVE');
  writeString(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little); // PCM
  bytes.setUint16(22, 1, Endian.little); // Mono
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  writeString(36, 'data');
  bytes.setUint32(40, byteLength, Endian.little);

  for (int i = 0; i < samples.length; i++) {
    final int s = (samples[i] * 32767).round().clamp(-32768, 32767);
    bytes.setInt16(44 + i * 2, s, Endian.little);
  }

  File(path).writeAsBytesSync(bytes.buffer.asUint8List());
}
