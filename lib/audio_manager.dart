// Core Flutter framework and foundation bindings
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// Audioplayers package for multi-channel BGM looping and low-latency sound effects
import 'package:audioplayers/audioplayers.dart';

/// Central audio manager responsible for looping background music and
/// triggering low-latency sound effects across all supported platforms.
class AudioManager {
  // Private constructor for singleton
  AudioManager._internal();
  static final AudioManager instance = AudioManager._internal();

  // BGM audio player instance (runs in looping release mode)
  AudioPlayer? _bgmPlayer;

  // Sound effects pool allowing overlapping sounds (e.g., flap + gem + chime)
  final List<AudioPlayer> _sfxPool = [];
  int _nextSfxIndex = 0;
  static const int _sfxPoolSize = 6;

  // Master audio mute state
  bool _isMuted = false;
  bool get isMuted => _isMuted;

  // Volume levels
  double _musicVolume = 0.60;
  double _sfxVolume = 0.85;

  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  bool _initialized = false;

  /// Detects if running in a headless Flutter widget test environment
  bool get _isTestEnvironment {
    return WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
  }

  /// Initializes audio players and configures playback modes.
  Future<void> init() async {
    if (_initialized || _isTestEnvironment) return;

    try {
      _bgmPlayer = AudioPlayer();
      await _bgmPlayer?.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer?.setVolume(_isMuted ? 0.0 : _musicVolume);

      // Pre-instantiate SFX pool players for instant low-latency playback
      for (int i = 0; i < _sfxPoolSize; i++) {
        final player = AudioPlayer();
        try {
          await player.setReleaseMode(ReleaseMode.stop);
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
            await player.setPlayerMode(PlayerMode.lowLatency);
          }
          await player.setVolume(_isMuted ? 0.0 : _sfxVolume);
        } catch (_) {}
        _sfxPool.add(player);
      }

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('AudioManager init warning (handled gracefully): $e');
      }
    }
  }

  /// Toggles master mute state on/off.
  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isTestEnvironment) return;

    try {
      if (_isMuted) {
        _bgmPlayer?.setVolume(0.0);
        for (final p in _sfxPool) {
          p.setVolume(0.0);
        }
      } else {
        _bgmPlayer?.setVolume(_musicVolume);
        for (final p in _sfxPool) {
          p.setVolume(_sfxVolume);
        }
      }
    } catch (_) {}
  }

  /// Sets whether audio is muted explicitly.
  void setMuted(bool muted) {
    if (_isMuted != muted) {
      toggleMute();
    }
  }

  /// Dynamically updates volume levels for BGM and SFX.
  void setVolumes({double? musicVolume, double? sfxVolume}) {
    if (musicVolume != null) {
      _musicVolume = musicVolume.clamp(0.0, 1.0);
      if (!_isMuted && !_isTestEnvironment) {
        _bgmPlayer?.setVolume(_musicVolume);
      }
    }
    if (sfxVolume != null) {
      _sfxVolume = sfxVolume.clamp(0.0, 1.0);
      if (!_isMuted && !_isTestEnvironment) {
        for (final p in _sfxPool) {
          p.setVolume(_sfxVolume);
        }
      }
    }
  }

  /// Starts or resumes playing the upbeat arcade background music loop.
  Future<void> playBgm() async {
    if (_isMuted || _isTestEnvironment) return;

    try {
      if (_bgmPlayer == null) {
        await init();
      }
      await _bgmPlayer?.setVolume(_musicVolume);
      await _bgmPlayer?.play(AssetSource('audio/bgm.mp3'));
    } catch (_) {}
  }

  /// Pauses background music (e.g., when the game is paused or lost focus).
  Future<void> pauseBgm() async {
    if (_isTestEnvironment) return;
    try {
      await _bgmPlayer?.pause();
    } catch (_) {}
  }

  /// Resumes background music from paused position.
  Future<void> resumeBgm() async {
    if (_isMuted || _isTestEnvironment) return;
    try {
      await _bgmPlayer?.resume();
    } catch (_) {}
  }

  /// Stops background music completely.
  Future<void> stopBgm() async {
    if (_isTestEnvironment) return;
    try {
      await _bgmPlayer?.stop();
    } catch (_) {}
  }

  /// Plays a sound effect from assets through the cyclic player pool.
  Future<void> _playSfx(String soundName) async {
    if (_isMuted || _isTestEnvironment) return;

    try {
      if (!_initialized) {
        await init();
      }

      if (_sfxPool.isEmpty) return;

      final player = _sfxPool[_nextSfxIndex];
      _nextSfxIndex = (_nextSfxIndex + 1) % _sfxPool.length;

      await player.stop();
      await player.setVolume(_sfxVolume);
      await player.play(AssetSource('audio/$soundName.mp3'));
    } catch (_) {}
  }

  // --- Convenience Sound Effect Triggers ---

  /// Jump / wing flap sound
  void playFlap() => _playSfx('flap');

  /// Passed through obstacle pylons / score point chime
  void playScore() => _playSfx('score');

  /// Collected floating Sky Gem bonus (+2)
  void playGem() => _playSfx('gem');

  /// Combo streak milestone fanfare (3x, 5x, 10x)
  void playCombo() => _playSfx('combo');

  /// Obstacle or ground collision impact thud
  void playHit() => _playSfx('hit');

  /// Game over descending melody
  void playGameOver() => _playSfx('gameover');

  /// Mechanical UI button tap click
  void playClick() => _playSfx('click');

  /// Power-up ability collected
  void playPowerUp() => _playSfx('powerup');

  /// Shield deflection / absorption
  void playShield() => _playSfx('shield');

  /// Unlocking bird skin, achievement, or world
  void playUnlock() => _playSfx('unlock');

  /// Releases audio players on app disposal
  void dispose() {
    try {
      _bgmPlayer?.dispose();
      for (final p in _sfxPool) {
        p.dispose();
      }
      _sfxPool.clear();
      _initialized = false;
    } catch (_) {}
  }
}
