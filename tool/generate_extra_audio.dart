import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() async {
  final outDir = Directory('assets/audio');
  final tempDir = Directory('tool/wav_extra');
  if (!tempDir.existsSync()) tempDir.createSync(recursive: true);

  // 1. Power-up collected chime
  _generateWav(
    '${tempDir.path}/powerup.wav',
    durationSeconds: 0.45,
    generator: (t) {
      // Ascending futuristic powerup glide
      final f = 350.0 + 900.0 * pow(t / 0.45, 1.2);
      final env = exp(-t * 5.0);
      final p = 2 * pi * f * t;
      final wave = sin(p) * 0.7 + sin(p * 2.0) * 0.3;
      return wave * env * 0.8;
    },
  );

  // 2. Shield collision absorb sound
  _generateWav(
    '${tempDir.path}/shield.wav',
    durationSeconds: 0.40,
    generator: (t) {
      // Metallic resonant pulse (damped sine + low boing)
      final f = 280.0 * exp(-t * 8.0) + 90.0;
      final env = exp(-t * 7.5);
      final wave = sin(2 * pi * f * t) * 0.7 + sin(2 * pi * f * 2.5 * t) * 0.3;
      return wave * env * 0.85;
    },
  );

  // 3. Achievement / Unlock fanfare
  _generateWav(
    '${tempDir.path}/unlock.wav',
    durationSeconds: 0.65,
    generator: (t) {
      // 4-note ascending heroic fanfare: C5, E5, G5, C6
      final notes = [523.25, 659.25, 783.99, 1046.50];
      const dur = 0.12;
      double s = 0.0;
      for (int i = 0; i < notes.length; i++) {
        final start = i * dur;
        if (t >= start) {
          final dt = t - start;
          final env = exp(-dt * 4.5);
          s += sin(2 * pi * notes[i] * dt) * env * 0.35;
        }
      }
      return s.clamp(-1.0, 1.0);
    },
  );

  for (final name in ['powerup', 'shield', 'unlock']) {
    final wavPath = '${tempDir.path}/$name.wav';
    final mp3Path = '${outDir.path}/$name.mp3';
    await Process.run('ffmpeg', [
      '-y',
      '-i',
      wavPath,
      '-codec:a',
      'libmp3lame',
      '-b:a',
      '64k',
      mp3Path,
    ]);
    stdout.writeln('Generated $name.mp3');
  }

  tempDir.deleteSync(recursive: true);
  stdout.writeln('Extra audio ready!');
}

void _generateWav(
  String filePath, {
  required double durationSeconds,
  required double Function(double t) generator,
  int sampleRate = 44100,
}) {
  final numSamples = (durationSeconds * sampleRate).round();
  final byteData = ByteData(44 + numSamples * 2);

  byteData.setUint8(0, 0x52);
  byteData.setUint8(1, 0x49);
  byteData.setUint8(2, 0x46);
  byteData.setUint8(3, 0x46);
  byteData.setUint32(4, 36 + numSamples * 2, Endian.little);
  byteData.setUint8(8, 0x57);
  byteData.setUint8(9, 0x41);
  byteData.setUint8(10, 0x56);
  byteData.setUint8(11, 0x45);

  byteData.setUint8(12, 0x66);
  byteData.setUint8(13, 0x6D);
  byteData.setUint8(14, 0x74);
  byteData.setUint8(15, 0x20);
  byteData.setUint32(16, 16, Endian.little);
  byteData.setUint16(20, 1, Endian.little);
  byteData.setUint16(22, 1, Endian.little);
  byteData.setUint32(24, sampleRate, Endian.little);
  byteData.setUint32(28, sampleRate * 2, Endian.little);
  byteData.setUint16(32, 2, Endian.little);
  byteData.setUint16(34, 16, Endian.little);

  byteData.setUint8(36, 0x64);
  byteData.setUint8(37, 0x61);
  byteData.setUint8(38, 0x74);
  byteData.setUint8(39, 0x61);
  byteData.setUint32(40, numSamples * 2, Endian.little);

  int offset = 44;
  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final sample = generator(t).clamp(-1.0, 1.0);
    final intSample = (sample * 32767.0).round().clamp(-32768, 32767);
    byteData.setInt16(offset, intSample, Endian.little);
    offset += 2;
  }

  File(filePath).writeAsBytesSync(byteData.buffer.asUint8List());
}
