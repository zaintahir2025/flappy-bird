// Standard math library for trigonometry, randomness, and clamps
import 'dart:async';
import 'dart:math';

// Core Flutter UI and layout widgets
import 'package:flutter/material.dart';

// Ticker class for screen-synchronized 60-120 FPS game loops
import 'package:flutter/scheduler.dart';

// Hardware keyboard handling, system sounds, and haptic feedback
import 'package:flutter/services.dart';

// Multi-channel audio engine
import 'audio_manager.dart';

// High-tech 3D obstacle pylons
import 'barriers.dart';

// Animated flyer sprite with GPU skin shaders, wings, shield bubble, and trails
import 'bird.dart';

// Game models for worlds, 14 birds, quests, achievements, power-ups, and settings
import 'game_models.dart';

// Modal dialogs
import 'leaderboard_dialog.dart';
import 'leaderboard_model.dart';
import 'name_input_dialog.dart';
import 'particle_effects.dart';
import 'quests_dialog.dart';
import 'settings_dialog.dart';
import 'skin_shop_dialog.dart';
import 'world_select_dialog.dart';

// Cross-platform persistence adapter (File I/O on mobile/desktop, localStorage on web)
import 'score_storage.dart' as score_storage;

/// The distinct operating states of the Skybound game engine.
enum GameStatus {
  ready,    // Idle hover in the sky, world intro banner, waiting for first tap
  playing,  // Active flight with live physics, scrolling obstacles, collectibles & power-ups
  paused,   // Ticker physics suspended; pause modal shown
  gameOver, // Flyer crashed; falling to ground and opening score results card
}

/// Represents an obstacle column pair with a clearance gap.
class PipePair {
  double x;
  double topHeight;
  double gapHeight;
  bool passed;

  PipePair({
    required this.x,
    required this.topHeight,
    required this.gapHeight,
    this.passed = false,
  });
}

/// Master game widget hosting the physics engine, render stack, and user controls.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // Screen-synchronized VSYNC game loop ticker
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // Keyboard capture focus node for desktop/web
  final FocusNode _focusNode = FocusNode();

  // Current operating state (starts in 'ready' mode)
  GameStatus _status = GameStatus.ready;

  // Round stats & scores
  int _score = 0;
  int _bestScore = 0;
  bool _isNewHighScore = false;
  int _flapsThisGame = 0;
  int _streak = 0;
  int _gemsThisGame = 0;
  int _totalGems = 0;

  // Sound enabled state
  bool _soundEnabled = true;

  // Input debounce timestamp on crash
  DateTime? _gameOverTime;

  // Active Bird Skin & World
  String _activeSkinId = 'classic';
  String _activeWorldId = 'sunrise_valley';
  List<String> _unlockedSkins = ['classic'];
  List<String> _unlockedWorlds = ['sunrise_valley'];

  // Quests, Achievements, Leaderboard & Settings
  List<DailyChallenge> _dailyChallenges = [];
  List<WeeklyChallenge> _weeklyChallenges = [];
  List<Achievement> _achievements = [];
  List<LeaderboardEntry> _leaderboard = List.from(LeaderboardEntry.defaultLeaderboard);
  PlayerStats _playerStats = const PlayerStats();
  String _pilotName = 'PILOT';
  GameSettings _settings = const GameSettings();
  bool _recordSubmittedThisRound = false;

  // Viewport dimensions
  double _arenaWidth = 400.0;
  double _skyHeight = 560.0;

  // Bird physics & dimensions
  static const double _birdVisualSize = 64.0;
  static const double _birdCollisionRadius = 8.5; // Precision circular hitbox (ultra-forgiving, perfectly matches visual body core)

  double _birdX = 100.0;
  double _birdY = 250.0;
  double _velocity = 0.0;
  double _rotation = 0.0;
  double _readyHoverTime = 0.0;
  double _worldTime = 0.0;
  double _flapPulse = 1.0;
  double _wingCycle = 0.0;

  // Screen shake effect
  double _screenShakeIntensity = 0.0;

  // World intro banner timer
  double _worldIntroTimer = 0.0;

  // In-flight achievement unlock notification
  String? _unlockedToastMessage;
  double _toastTimer = 0.0;

  // Physics constants & dimensions
  static const double _pipeWidth = 68.0;

  // Modal safety flag to freeze ticker when dialogs are open
  bool _isModalOpen = false;

  // Timers
  Timer? _gameOverSfxTimer;
  Timer? _callSignTimer;

  // Dynamic progressive difficulty curve:
  // Starts ultra-welcoming, floaty & easy at score 0, gradually scaling up to master arcade challenge at score 40+
  double get _difficultyProgress => (_score / 40.0).clamp(0.0, 1.0);

  // Progressive physics:
  // At score 0: gentle floaty gravity (460 px/s²) and buoyant jump (-240 px/s)
  // At score 40+: classic snappy arcade gravity (740 px/s²) and fast jump (-305 px/s)
  double get _currentGravity => 460.0 + (_difficultyProgress * 280.0);
  double get _currentJumpVelocity => -240.0 - (_difficultyProgress * 65.0);
  double get _currentMaxFallSpeed => 290.0 + (_difficultyProgress * 110.0);

  // Pipe horizontal scrolling speed (starts very gentle at 90 px/s, scales up to 165 px/s)
  double get _currentPipeSpeed {
    final base = 90.0 + (_difficultyProgress * 75.0);
    return _isSlowMo ? base * 0.60 : base;
  }

  // Pipe gap (starts very generous at 270px, scales down to 160px at score 40+)
  // Dynamically bounds to available sky height so ultra-compact landscape screens never throw
  double _getDynamicGap(double skyH) {
    final double absoluteMax = (skyH - 65.0).clamp(90.0, 280.0);
    final double maxGap = min(absoluteMax, (skyH * 0.44).clamp(190.0, 270.0));
    final double minGap = min(maxGap - 30.0, (skyH * 0.27).clamp(120.0, 160.0));
    return (maxGap - (_difficultyProgress * (maxGap - minGap))).clamp(85.0, absoluteMax);
  }

  // Pipe horizontal spacing (starts wide at 360px, scales down to 230px)
  double _getDynamicSpacing(double arenaW) {
    return (arenaW * 0.95 - (_difficultyProgress * 90.0)).clamp(230.0, 380.0);
  }

  // Active Power-Ups
  final List<ActivePowerUp> _activePowerUps = [];
  final List<PowerUpItem> _powerUpItems = [];
  double _shieldInvulnerableTime = 0.0;

  // Obstacles, Collectibles, and Particles
  final Random _random = Random();
  final List<PipePair> _pipes = [];
  final List<FloatingGem> _gems = [];
  final List<FloatingPopupText> _floatingTexts = [];
  final List<FlapRing> _flapRings = [];
  final List<Particle> _particles = [];
  final List<AmbientParticle> _ambientParticles = [];
  late final List<NightStar> _stars;
  double _pipeSpacing = 240.0;

  // Scrolling parallax offsets
  double _groundScroll = 0.0;
  double _cloudScroll = 0.0;
  double _mountainScroll = 0.0;
  double _scoreScale = 1.0;

  @override
  void initState() {
    super.initState();
    _stars = NightStar.generate(45);
    _loadAllData();
    AudioManager.instance.init();

    _ticker = createTicker(_onTick);
    _ticker.start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _gameOverSfxTimer?.cancel();
    _callSignTimer?.cancel();
    _ticker.dispose();
    _focusNode.dispose();
    AudioManager.instance.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    try {
      final best = await score_storage.loadBestScore();
      if (mounted) {
        setState(() {
          _bestScore = best;
        });
      }
    } catch (_) {}

    try {
      final gems = await score_storage.loadTotalGems();
      final board = await score_storage.loadLeaderboard();
      final stats = await score_storage.loadPlayerStats();
      final name = await score_storage.loadLastPlayerName();
      final skins = await score_storage.loadUnlockedSkins();
      final worlds = await score_storage.loadUnlockedWorlds();
      final skinId = await score_storage.loadActiveSkin();
      final worldId = await score_storage.loadActiveWorld();
      final now = DateTime.now();
      final daily = await score_storage.loadDailyChallenges(now);
      final weekly = await score_storage.loadWeeklyChallenges(now);
      final achievements = await score_storage.loadAchievements();
      final settings = await score_storage.loadGameSettings();

      if (mounted) {
        setState(() {
          _totalGems = gems;
          _leaderboard = board;
          _playerStats = stats;
          _pilotName = name;
          _unlockedSkins = skins;
          _unlockedWorlds = worlds;
          _activeSkinId = skinId;
          _activeWorldId = worldId;
          _dailyChallenges = daily;
          _weeklyChallenges = weekly;
          _achievements = achievements;
          _settings = settings;

          _soundEnabled = !AudioManager.instance.isMuted;
          AudioManager.instance.setVolumes(
            musicVolume: settings.isMusicEnabled ? settings.musicVolume : 0.0,
            sfxVolume: settings.isSfxEnabled ? settings.sfxVolume : 0.0,
          );
        });
      }
    } catch (_) {}
  }

  WorldBiomeData get _currentWorldData => WorldBiomeData.fromId(_activeWorldId);
  BirdSkinConfig get _currentSkinConfig => BirdSkinConfig.fromStringId(_activeSkinId);

  bool get _hasShield => _activePowerUps.any((p) => p.type == PowerUpType.shield);
  bool get _isGhost => _activePowerUps.any((p) => p.type == PowerUpType.ghost);
  bool get _isSlowMo => _activePowerUps.any((p) => p.type == PowerUpType.slowMotion);
  bool get _isMagnet => _activePowerUps.any((p) => p.type == PowerUpType.magnet);
  bool get _is2xMultiplier => _activePowerUps.any((p) => p.type == PowerUpType.scoreMultiplier);

  void _triggerHaptic(HapticFeedbackType type) {
    if (!_settings.isHapticsEnabled) return;
    switch (type) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
        break;
    }
  }

  void _cycleWorld() {
    const allWorlds = WorldBiomeData.all;
    final currentIndex = allWorlds.indexWhere((w) => w.id == _activeWorldId);
    final nextWorld = allWorlds[(currentIndex + 1) % allWorlds.length];

    setState(() {
      _activeWorldId = nextWorld.id;
      _worldIntroTimer = 2.2;
      _initPipes(_skyHeight, _arenaWidth);
    });

    AudioManager.instance.playClick();
    _triggerHaptic(HapticFeedbackType.selection);
    score_storage.saveActiveWorld(_activeWorldId);
  }

  void _cycleSkin() {
    const allSkins = BirdSkinConfig.all;
    final currentIndex = allSkins.indexWhere((s) => s.id.name == _activeSkinId);
    final nextSkin = allSkins[(currentIndex + 1) % allSkins.length];

    setState(() {
      _activeSkinId = nextSkin.id.name;
    });

    AudioManager.instance.playClick();
    _triggerHaptic(HapticFeedbackType.selection);
    score_storage.saveActiveSkin(_activeSkinId);
  }

  void _toggleSound() {
    AudioManager.instance.toggleMute();
    final bool active = !AudioManager.instance.isMuted;
    setState(() {
      _soundEnabled = active;
    });

    if (active) {
      AudioManager.instance.playClick();
      SystemSound.play(SystemSoundType.click);
      if (_status == GameStatus.playing) {
        AudioManager.instance.playBgm();
      }
    } else {
      AudioManager.instance.stopBgm();
    }
    _triggerHaptic(HapticFeedbackType.selection);
  }

  void _initPipes(double skyH, double arenaW) {
    _pipes.clear();
    _gems.clear();
    _powerUpItems.clear();
    _floatingTexts.clear();
    _activePowerUps.clear();
    _pipeSpacing = _getDynamicSpacing(arenaW);

    // Initial setup:
    // First pipe is placed comfortably on the right side of the arena (arenaW * 0.90) in all display sizes,
    // with a massive, welcoming 270px canyon gap centered directly at the bird's cruising height (skyH * 0.40).
    final double firstPipeX = arenaW * 0.90;
    for (int i = 0; i < 3; i++) {
      final pipe = PipePair(
        x: firstPipeX + (i * _pipeSpacing),
        topHeight: 120.0,
        gapHeight: 270.0,
      );
      _randomizePipe(pipe, skyH, isFirstPipe: i == 0);
      _pipes.add(pipe);
    }

    _ambientParticles.clear();
    _ambientParticles.addAll(
      AmbientParticle.generateForWorld(_currentWorldData.biome, arenaW, skyH),
    );
  }

  void _randomizePipe(PipePair pipe, double skyH, {bool isFirstPipe = false}) {
    // Dynamic progressive gap: starts super wide (270px) and smoothly scales with score
    // Constrained so that it never exceeds available sky space on ultra-compact landscape displays
    final double maxPossibleGap = (skyH - 65.0).clamp(85.0, 280.0);
    final double rawGap = isFirstPipe
        ? (skyH * 0.44).clamp(190.0, 275.0)
        : _getDynamicGap(skyH);
    final double gap = rawGap.clamp(85.0, maxPossibleGap);

    final double minPipe = (skyH * 0.08).clamp(25.0, 45.0);
    final double maxTop = max(minPipe, skyH - gap - minPipe);

    double top;
    if (isFirstPipe) {
      // First pipe gap is centered directly on the bird's initial cruising height (skyH * 0.40)
      final double targetTop = (skyH * 0.40) - (gap / 2);
      top = targetTop.clamp(minPipe, maxTop);
    } else {
      final double available = max(0.0, maxTop - minPipe);
      top = minPipe + (available > 0 ? _random.nextDouble() * available : 0.0);
    }

    pipe.topHeight = top;
    pipe.gapHeight = gap;
    pipe.passed = false;

    // 70% chance to spawn a Sky Gem
    if (_random.nextDouble() < 0.70) {
      _gems.add(
        FloatingGem(
          x: pipe.x + (_pipeWidth / 2),
          baseY: top + (gap / 2),
          value: 2,
        ),
      );
    }

    // 18% chance to spawn a special Power-Up Item in the flight channel
    if (_random.nextDouble() < 0.18) {
      const types = PowerUpType.values;
      final type = types[_random.nextInt(types.length)];
      _powerUpItems.add(
        PowerUpItem(
          x: pipe.x + (_pipeWidth / 2) + 40.0,
          baseY: top + (gap / 2) + (_random.nextDouble() - 0.5) * 40.0,
          type: type,
        ),
      );
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final double dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1000000.0).clamp(0.001, 0.033);
    _lastElapsed = elapsed;

    if (!mounted || _status == GameStatus.paused || _isModalOpen) return;

    setState(() {
      _updateGame(dt);
    });
  }

  void _updateGame(double dt) {
    _worldTime += dt;
    _wingCycle = (_wingCycle + dt * 4.0) % 1.0;

    if (_worldIntroTimer > 0) {
      _worldIntroTimer -= dt;
    }

    if (_toastTimer > 0) {
      _toastTimer -= dt;
      if (_toastTimer <= 0) {
        _unlockedToastMessage = null;
      }
    }

    if (_screenShakeIntensity > 0) {
      _screenShakeIntensity = (_screenShakeIntensity - dt * 25.0).clamp(0.0, 20.0);
    }

    if (_shieldInvulnerableTime > 0) {
      _shieldInvulnerableTime -= dt;
    }

    // Prune particles
    _flapRings.removeWhere((ring) => !ring.update(dt));
    _particles.removeWhere((p) => !p.update(dt));
    _floatingTexts.removeWhere((t) => !t.update(dt));

    for (final ap in _ambientParticles) {
      ap.update(dt, _arenaWidth, _skyHeight);
    }

    _activePowerUps.removeWhere((p) => !p.update(dt));

    final effectivePipeSpeed = _currentPipeSpeed;
    final effectiveGravity = _isSlowMo ? _currentGravity * 0.70 : _currentGravity;

    if (_status != GameStatus.gameOver) {
      _groundScroll = (_groundScroll + effectivePipeSpeed * dt) % 24.0;
      _cloudScroll = (_cloudScroll + 20.0 * dt) % 360.0;
      _mountainScroll = (_mountainScroll + 35.0 * dt) % 720.0;
    }

    if (_scoreScale > 1.0) {
      _scoreScale = (_scoreScale - dt * 2.0).clamp(1.0, 1.4);
    }
    if (_flapPulse > 1.0) {
      _flapPulse = (_flapPulse - dt * 2.5).clamp(1.0, 1.25);
    }

    switch (_status) {
      case GameStatus.ready:
        _readyHoverTime += dt;
        _birdY = (_skyHeight * 0.40) + sin(_readyHoverTime * 5.0) * 8.0;
        _rotation = sin(_readyHoverTime * 5.0) * 0.08;
        _velocity = 0.0;
        _flapPulse = 1.0 + (sin(_readyHoverTime * 10.0).abs() * 0.05);
        break;

      case GameStatus.playing:
        _velocity += effectiveGravity * dt;
        if (_velocity > _currentMaxFallSpeed) {
          _velocity = _currentMaxFallSpeed;
        }
        _birdY += _velocity * dt;

        // Ceiling clamping: Keep flyer safely within the sky, NEVER trigger game over on ceiling
        if (_birdY < _birdCollisionRadius) {
          _birdY = _birdCollisionRadius;
          if (_velocity < 0) _velocity = 0.0;
        }

        if (_velocity < -50.0) {
          _rotation = -0.38;
        } else {
          _rotation = (_rotation + 2.8 * dt).clamp(-0.38, 1.20);
        }

        // Pylons
        for (final pipe in _pipes) {
          pipe.x -= effectivePipeSpeed * dt;

          if (!pipe.passed && (_birdX > pipe.x + (_pipeWidth / 2))) {
            pipe.passed = true;
            final pts = _is2xMultiplier ? 2 : 1;
            _score += pts;
            _streak++;
            _scoreScale = 1.35;

            if (_soundEnabled) {
              AudioManager.instance.playScore();
              SystemSound.play(SystemSoundType.click);
            }
            _triggerHaptic(HapticFeedbackType.light);
            _burstSparkles(_birdX + 20, _birdY, _currentSkinConfig.particleColor);

            _checkComboMilestones();
            _updateMissionProgress(scoreAdd: pts, streakVal: _streak);

            if (_score > _bestScore) {
              _bestScore = _score;
              _isNewHighScore = true;
              score_storage.saveBestScore(_bestScore);
            }
          }

          if (pipe.x < -_pipeWidth - 20.0) {
            final double rightmostX = _pipes.map((p) => p.x).reduce(max);
            _pipeSpacing = _getDynamicSpacing(_arenaWidth);
            pipe.x = rightmostX + _pipeSpacing;
            _randomizePipe(pipe, _skyHeight);
          }
        }

        // Gems
        for (final gem in _gems) {
          gem.x -= effectivePipeSpeed * dt;

          if (_isMagnet && !gem.collected) {
            final dx = _birdX - gem.x;
            final dy = _birdY - gem.y;
            final dist = sqrt(dx * dx + dy * dy);
            if (dist < 180.0) {
              gem.x += (dx / dist) * 240.0 * dt;
              gem.y += (dy / dist) * 240.0 * dt;
            }
          }

          gem.update(dt);

          if (!gem.collected) {
            final double dx = (gem.x - _birdX).abs();
            final double dy = (gem.y - _birdY).abs();
            if (dx < 30.0 && dy < 30.0) {
              gem.collected = true;
              final gemVal = _is2xMultiplier ? gem.value * 2 : gem.value;
              _score += gemVal;
              _gemsThisGame += gemVal;
              _totalGems += gemVal;
              _scoreScale = 1.38;

              if (_soundEnabled) {
                AudioManager.instance.playGem();
                SystemSound.play(SystemSoundType.click);
              }
              _triggerHaptic(HapticFeedbackType.medium);
              _burstSparkles(gem.x, gem.y, const Color(0xFFFFD700));

              _floatingTexts.add(
                FloatingPopupText(
                  x: gem.x,
                  y: gem.y - 14,
                  text: '+$gemVal GEM!',
                  color: const Color(0xFFFFD54F),
                ),
              );

              score_storage.saveTotalGems(_totalGems);
              _updateMissionProgress(gemsAdd: gemVal);

              if (_score > _bestScore) {
                _bestScore = _score;
                _isNewHighScore = true;
                score_storage.saveBestScore(_bestScore);
              }
            }
          }
        }
        _gems.removeWhere((g) => g.x < -40.0 || (g.collected && g.hoverTime > 0.35));

        // Power-Ups
        for (final pup in _powerUpItems) {
          pup.x -= effectivePipeSpeed * dt;
          pup.update(dt);

          if (!pup.collected) {
            final double dx = (pup.x - _birdX).abs();
            final double dy = (pup.y - _birdY).abs();
            if (dx < 32.0 && dy < 32.0) {
              pup.collected = true;
              _activatePowerUp(pup.type);
            }
          }
        }
        _powerUpItems.removeWhere((p) => p.x < -40.0 || p.collected);

        _checkCollisions();
        break;

      case GameStatus.gameOver:
        final double groundLimit = _skyHeight - _birdCollisionRadius;
        if (_birdY < groundLimit) {
          _velocity += _currentGravity * 1.5 * dt;
          _birdY = (_birdY + _velocity * dt).clamp(0.0, groundLimit);
          _rotation = 1.3;
        }
        break;

      case GameStatus.paused:
        break;
    }
  }

  void _activatePowerUp(PowerUpType type) {
    final data = PowerUpData.of(type);
    if (_soundEnabled) {
      AudioManager.instance.playPowerUp();
    }
    _triggerHaptic(HapticFeedbackType.heavy);
    _screenShakeIntensity = 6.0;

    _activePowerUps.removeWhere((p) => p.type == type);
    _activePowerUps.add(
      ActivePowerUp(
        type: type,
        remainingSeconds: data.durationSeconds,
        totalSeconds: data.durationSeconds,
      ),
    );

    _floatingTexts.add(
      FloatingPopupText(
        x: _birdX + 20,
        y: _birdY - 28,
        text: data.label,
        color: data.color,
      ),
    );

    _burstSparkles(_birdX, _birdY, data.color);
    _updateMissionProgress(powerUpAdd: 1);
  }

  void _checkComboMilestones() {
    if (_streak == 3) {
      if (_soundEnabled) AudioManager.instance.playCombo();
      _floatingTexts.add(FloatingPopupText(
        x: _birdX + 30,
        y: _birdY - 26,
        text: 'x3 STREAK!',
        color: const Color(0xFF00E5FF),
      ));
    } else if (_streak == 5) {
      if (_soundEnabled) AudioManager.instance.playCombo();
      _floatingTexts.add(FloatingPopupText(
        x: _birdX + 30,
        y: _birdY - 26,
        text: 'PERFECT!',
        color: const Color(0xFFFF9100),
      ));
    } else if (_streak >= 10 && _streak % 5 == 0) {
      if (_soundEnabled) AudioManager.instance.playCombo();
      _floatingTexts.add(FloatingPopupText(
        x: _birdX + 30,
        y: _birdY - 26,
        text: 'UNSTOPPABLE!',
        color: const Color(0xFFFFD700),
      ));
    }
  }

  void _checkCollisions() {
    if (_shieldInvulnerableTime > 0) return;

    // Ceiling safety: Keep flyer bounded safely within the sky, never lethal
    if (_birdY < _birdCollisionRadius) {
      _birdY = _birdCollisionRadius;
      if (_velocity < 0) _velocity = 0.0;
    }

    // Ground collision test (precise circular contact)
    final double groundLimit = _skyHeight - _birdCollisionRadius;
    if (_birdY >= groundLimit) {
      _birdY = groundLimit;
      _handleCollisionImpact();
      return;
    }

    if (_isGhost) return;

    // Precision Circle-to-AABB pipe collision:
    // Completely eliminates the 21px "phantom air death" / invisible corner killzone!
    for (final pipe in _pipes) {
      // Early broad-phase rejection: skip math if pipe is far away
      if (pipe.x > _birdX + _birdCollisionRadius + 12.0 ||
          pipe.x + _pipeWidth < _birdX - _birdCollisionRadius - 12.0) {
        continue;
      }

      // Top pipe: from y = 0 to y = topHeight
      // Inset by 5.0px horizontally and 4.0px vertically so decorative bevels/glows NEVER cause unfair hits
      final bool topHit = _checkCircleRectCollision(
        cx: _birdX,
        cy: _birdY,
        radius: _birdCollisionRadius,
        rx: pipe.x + 5.0,
        ry: 0.0,
        rw: _pipeWidth - 10.0,
        rh: max(0.0, pipe.topHeight - 4.0),
      );

      // Bottom pipe: from y = topHeight + gapHeight down to ground
      final double bottomPipeY = pipe.topHeight + pipe.gapHeight;
      final double bottomPipeH = max(45.0, _skyHeight - bottomPipeY);
      final bool bottomHit = _checkCircleRectCollision(
        cx: _birdX,
        cy: _birdY,
        radius: _birdCollisionRadius,
        rx: pipe.x + 5.0,
        ry: bottomPipeY + 4.0,
        rw: _pipeWidth - 10.0,
        rh: bottomPipeH,
      );

      if (topHit || bottomHit) {
        _handleCollisionImpact();
        return;
      }
    }
  }

  /// Calculates exact Euclidean distance between circle center and the closest point
  /// on an Axis-Aligned Bounding Box (AABB). Returns true if distance < circle radius.
  bool _checkCircleRectCollision({
    required double cx,
    required double cy,
    required double radius,
    required double rx,
    required double ry,
    required double rw,
    required double rh,
  }) {
    final double closestX = cx.clamp(rx, rx + rw);
    final double closestY = cy.clamp(ry, ry + rh);
    final double dx = cx - closestX;
    final double dy = cy - closestY;
    return (dx * dx + dy * dy) < (radius * radius);
  }

  void _handleCollisionImpact() {
    if (_hasShield) {
      _activePowerUps.removeWhere((p) => p.type == PowerUpType.shield);
      _shieldInvulnerableTime = 1.2;
      _screenShakeIntensity = 10.0;
      if (_soundEnabled) AudioManager.instance.playShield();
      _triggerHaptic(HapticFeedbackType.heavy);
      _burstSparkles(_birdX, _birdY, const Color(0xFF00E5FF));

      _floatingTexts.add(
        FloatingPopupText(
          x: _birdX,
          y: _birdY - 20,
          text: 'SHIELD DEFLECTED!',
          color: const Color(0xFF00E5FF),
        ),
      );

      _velocity = -220.0;
      return;
    }

    _triggerGameOver();
  }

  void _triggerGameOver() {
    if (_status == GameStatus.gameOver) return;

    _gameOverTime = DateTime.now();
    _streak = 0;
    _screenShakeIntensity = 12.0;

    _gameOverSfxTimer?.cancel();
    _callSignTimer?.cancel();
    AudioManager.instance.stopBgm();
    if (_soundEnabled) {
      AudioManager.instance.playHit();
      _gameOverSfxTimer = Timer(const Duration(milliseconds: 220), () {
        if (mounted && _status == GameStatus.gameOver && _soundEnabled) {
          AudioManager.instance.playGameOver();
        }
      });
      SystemSound.play(SystemSoundType.alert);
    }

    _triggerHaptic(HapticFeedbackType.heavy);
    _burstSparkles(_birdX, _birdY, const Color(0xFFFF5252));

    final newStats = _playerStats.copyWith(
      gamesPlayed: _playerStats.gamesPlayed + 1,
      totalFlaps: _playerStats.totalFlaps + _flapsThisGame,
      totalScore: _playerStats.totalScore + _score,
      bestScore: max(_playerStats.bestScore, _bestScore),
    );
    _playerStats = newStats;
    score_storage.savePlayerStats(newStats);

    setState(() {
      _status = GameStatus.gameOver;
      _velocity = 80.0;
      _recordSubmittedThisRound = false;
    });

    if (_score > 0 && _isHighScoreQualified(_score)) {
      _callSignTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted && _status == GameStatus.gameOver) {
          _showCallSignPrompt();
        }
      });
    }
  }

  bool _isHighScoreQualified(int score) {
    if (_leaderboard.length < 10) return true;
    return score > _leaderboard.last.score;
  }

  void _showCallSignPrompt() {
    _showModalSafe(
      (context) => NameInputDialog(
        score: _score,
        initialName: _pilotName,
        onSubmit: (name) {
          _submitScoreToLeaderboard(name);
        },
      ),
    );
  }

  void _submitScoreToLeaderboard(String name) {
    final medal = _getMedalString(_score);
    final entry = LeaderboardEntry(
      name: name,
      score: _score,
      date: 'Today',
      medal: medal,
      skin: _activeSkinId,
    );

    final updated = List<LeaderboardEntry>.from(_leaderboard)..add(entry);
    updated.sort((a, b) => b.score.compareTo(a.score));
    final trimmed = updated.take(10).toList();

    setState(() {
      _pilotName = name;
      _leaderboard = trimmed;
      _recordSubmittedThisRound = true;
    });

    score_storage.saveLeaderboard(trimmed);
    score_storage.saveLastPlayerName(name);

    if (_soundEnabled) {
      AudioManager.instance.playCombo();
    }
    _triggerHaptic(HapticFeedbackType.heavy);
    _burstSparkles(_birdX, _birdY, const Color(0xFFFFD700));
  }

  String _getMedalString(int score) {
    if (score >= 40) return 'Platinum';
    if (score >= 25) return 'Gold';
    if (score >= 10) return 'Silver';
    if (score >= 3) return 'Bronze';
    return 'None';
  }

  void _jump() {
    _flapsThisGame++;
    setState(() {
      _velocity = _currentJumpVelocity;
      _rotation = -0.38;
      _flapPulse = 1.14;
    });

    _flapRings.add(
      FlapRing(
        x: _birdX,
        y: _birdY,
        color: _currentSkinConfig.particleColor,
      ),
    );

    final skin = _currentSkinConfig;
    for (int i = 0; i < 5; i++) {
      final angle = pi * 0.5 + (_random.nextDouble() - 0.5) * 1.2;
      final speed = 60.0 + _random.nextDouble() * 120.0;
      _particles.add(
        Particle(
          x: _birdX - 12,
          y: _birdY + 6,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          size: 2.5 + _random.nextDouble() * 2.5,
          color: skin.particleColor,
          trailType: skin.trailType,
        ),
      );
    }

    if (_soundEnabled) {
      AudioManager.instance.playFlap();
      SystemSound.play(SystemSoundType.click);
    }
    _triggerHaptic(HapticFeedbackType.selection);
    _updateMissionProgress(flapsAdd: 1);
  }

  void _burstSparkles(double x, double y, Color color) {
    for (int i = 0; i < 16; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 80.0 + _random.nextDouble() * 160.0;
      _particles.add(
        Particle(
          x: x,
          y: y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          size: 2.0 + _random.nextDouble() * 3.5,
          color: color,
        ),
      );
    }
  }

  void _updateMissionProgress({
    int scoreAdd = 0,
    int gemsAdd = 0,
    int flapsAdd = 0,
    int powerUpAdd = 0,
    int streakVal = 0,
  }) {
    for (final q in _dailyChallenges) {
      if (q.isCompleted) continue;
      if (q.id.contains('score')) q.currentProgress += scoreAdd;
      if (q.id.contains('gems')) q.currentProgress += gemsAdd;
      if (q.id.contains('flaps')) q.currentProgress += flapsAdd;
      if (q.id.contains('powerup')) q.currentProgress += powerUpAdd;
      if (q.id.contains('combo') && streakVal >= q.target) {
        q.currentProgress = q.target;
      }
    }

    for (final w in _weeklyChallenges) {
      if (w.isCompleted) continue;
      if (w.id.contains('points')) w.currentProgress += scoreAdd;
      if (w.id.contains('gems')) w.currentProgress += gemsAdd;
      if (w.id.contains('flaps')) w.currentProgress += flapsAdd;
    }

    for (final a in _achievements) {
      if (a.isUnlocked) continue;

      if (a.id == 'first_flight' && flapsAdd > 0) a.currentProgress = 1;
      if (a.id == 'sky_explorer' && _score >= 20) a.currentProgress = 20;
      if (a.id == 'cloud_veteran' && _score >= 50) a.currentProgress = 50;
      if (a.id.contains('gem_collector')) a.currentProgress += gemsAdd;
      if (a.id == 'powerup_junkie') a.currentProgress += powerUpAdd;
      if (a.id == 'combo_streak_5' && streakVal >= 5) a.currentProgress = 5;
      if (a.id == 'combo_streak_10' && streakVal >= 10) a.currentProgress = 10;
      if (a.id == 'combo_streak_15' && streakVal >= 15) a.currentProgress = 15;

      if (a.progressRatio >= 1.0 && !a.isUnlocked) {
        a.isUnlocked = true;
        _showAchievementToast(a);
      }
    }
  }

  void _showAchievementToast(Achievement achievement) {
    if (_soundEnabled) AudioManager.instance.playUnlock();
    _triggerHaptic(HapticFeedbackType.heavy);
    setState(() {
      _unlockedToastMessage = '🏆 UNLOCKED: ${achievement.title} (+${achievement.rewardGems} Gems)';
      _toastTimer = 3.5;
    });
  }

  void _handleUserInput() {
    switch (_status) {
      case GameStatus.ready:
        setState(() {
          _status = GameStatus.playing;
          _shieldInvulnerableTime = 1.5; // 1.5s initial spawn grace period
          // Shift pipes forward to guarantee a wide, calm, safe takeoff runway for new players
          final double firstPipeX = max(_arenaWidth * 1.15, _arenaWidth + 80.0);
          for (int i = 0; i < _pipes.length; i++) {
            _pipes[i].x = firstPipeX + (i * _pipeSpacing);
            _pipes[i].passed = false;
          }
        });
        if (_soundEnabled) {
          AudioManager.instance.playBgm();
        }
        _jump();
        break;

      case GameStatus.playing:
        _jump();
        break;

      case GameStatus.paused:
        _togglePause();
        break;

      case GameStatus.gameOver:
        if (_gameOverTime != null &&
            DateTime.now().difference(_gameOverTime!).inMilliseconds < 450) {
          return;
        }
        _restartGame();
        break;
    }
  }

  void _restartGame() {
    _gameOverSfxTimer?.cancel();
    _callSignTimer?.cancel();
    AudioManager.instance.stopBgm();
    AudioManager.instance.playClick();
    setState(() {
      _status = GameStatus.ready;
      _score = 0;
      _streak = 0;
      _flapsThisGame = 0;
      _gemsThisGame = 0;
      _isNewHighScore = false;
      _velocity = 0.0;
      _rotation = 0.0;
      _readyHoverTime = 0.0;
      _gameOverTime = null;
      _flapPulse = 1.0;
      _birdY = _skyHeight * 0.40;
      _worldIntroTimer = 0.0;
      _flapRings.clear();
      _particles.clear();
      _gems.clear();
      _powerUpItems.clear();
      _activePowerUps.clear();
      _floatingTexts.clear();
      _initPipes(_skyHeight, _arenaWidth);
    });
  }

  void _togglePause() {
    if (_status == GameStatus.playing) {
      setState(() {
        _status = GameStatus.paused;
      });
      AudioManager.instance.pauseBgm();
      AudioManager.instance.playClick();
      _triggerHaptic(HapticFeedbackType.light);
    } else if (_status == GameStatus.paused) {
      setState(() {
        _status = GameStatus.playing;
        _lastElapsed = Duration.zero;
      });
      if (_soundEnabled) {
        AudioManager.instance.resumeBgm();
      }
      AudioManager.instance.playClick();
      _triggerHaptic(HapticFeedbackType.light);
    }
  }

  // Safe modal dialog runner: freezes game ticker and prevents background pipe scrolling
  Future<void> _showModalSafe(WidgetBuilder builder) async {
    final wasPlaying = _status == GameStatus.playing;
    if (wasPlaying) {
      setState(() {
        _status = GameStatus.paused;
      });
      AudioManager.instance.pauseBgm();
    }
    _isModalOpen = true;
    _lastElapsed = Duration.zero;

    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: builder,
    );

    _isModalOpen = false;
    _lastElapsed = Duration.zero;
  }

  // Dialog openers
  void _openWorldsDialog() {
    AudioManager.instance.playClick();
    _triggerHaptic(HapticFeedbackType.selection);
    _showModalSafe(
      (ctx) => WorldSelectDialog(
        unlockedWorlds: _unlockedWorlds,
        activeWorldId: _activeWorldId,
        totalGems: _totalGems,
        bestScore: _bestScore,
        onWorldChanged: (newWorldId, newGems, newUnlocked) {
          setState(() {
            _activeWorldId = newWorldId;
            _totalGems = newGems;
            _unlockedWorlds = newUnlocked;
            _worldIntroTimer = 2.5;
            _initPipes(_skyHeight, _arenaWidth);
          });
        },
      ),
    );
  }

  void _openAviaryDialog() {
    AudioManager.instance.playClick();
    _triggerHaptic(HapticFeedbackType.selection);
    _showModalSafe(
      (ctx) => SkinShopDialog(
        unlockedSkins: _unlockedSkins,
        activeSkinId: _activeSkinId,
        totalGems: _totalGems,
        onSkinChanged: (newSkinId, newGems, newUnlocked) {
          setState(() {
            _activeSkinId = newSkinId;
            _totalGems = newGems;
            _unlockedSkins = newUnlocked;
          });
        },
      ),
    );
  }

  void _openQuestsDialog() {
    AudioManager.instance.playClick();
    _triggerHaptic(HapticFeedbackType.selection);
    _showModalSafe(
      (ctx) => QuestsDialog(
        dailyChallenges: _dailyChallenges,
        weeklyChallenges: _weeklyChallenges,
        achievements: _achievements,
        totalGems: _totalGems,
        onGemsUpdated: (newGems, daily, weekly, achievements) {
          setState(() {
            _totalGems = newGems;
            _dailyChallenges = daily;
            _weeklyChallenges = weekly;
            _achievements = achievements;
          });
        },
      ),
    );
  }

  void _openLeaderboard() {
    AudioManager.instance.playClick();
    _triggerHaptic(HapticFeedbackType.selection);
    _showModalSafe(
      (context) => LeaderboardDialog(
        leaderboard: _leaderboard,
        stats: _playerStats,
      ),
    );
  }

  void _openSettingsDialog() {
    AudioManager.instance.playClick();
    _triggerHaptic(HapticFeedbackType.selection);
    _showModalSafe(
      (ctx) => SettingsDialog(
        settings: _settings,
        pilotName: _pilotName,
        onSettingsSaved: (newSettings, newName) {
          setState(() {
            _settings = newSettings;
            _pilotName = newName;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final worldData = _currentWorldData;
    final skinConfig = _currentSkinConfig;

    return Scaffold(
      backgroundColor: const Color(0xFF14181D),
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.space ||
                key == LogicalKeyboardKey.arrowUp ||
                key == LogicalKeyboardKey.keyW) {
              _handleUserInput();
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.keyP ||
                key == LogicalKeyboardKey.escape) {
              _togglePause();
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.keyO) {
              _openSettingsDialog();
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.keyL) {
              _openLeaderboard();
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.keyT) {
              _cycleWorld();
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.keyS) {
              _cycleSkin();
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.keyM) {
              _toggleSound();
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.enter ||
                key == LogicalKeyboardKey.keyR) {
              if (_status == GameStatus.gameOver) {
                _restartGame();
                return KeyEventResult.handled;
              }
            }
          }
          return KeyEventResult.ignored;
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double availableWidth = constraints.maxWidth;
            final double availableHeight = constraints.maxHeight;

            final mediaQuery = MediaQuery.of(context);
            final double topPadding = mediaQuery.padding.top;
            final double bottomPadding = mediaQuery.padding.bottom;

            final bool isLargeScreen = availableWidth > 520.0;
            final double arenaW = isLargeScreen ? 420.0 : availableWidth;
            final double arenaH = isLargeScreen
                ? min(availableHeight - 32.0, max(580.0, arenaW * 1.78))
                : availableHeight;

            final double groundH =
                (arenaH * 0.16).clamp(70.0, 130.0) + (isLargeScreen ? 0.0 : bottomPadding);
            final double skyH = arenaH - groundH;

            if (_arenaWidth != arenaW || _skyHeight != skyH) {
              _arenaWidth = arenaW;
              _skyHeight = skyH;
              _birdX = arenaW * 0.28;

              if (_status == GameStatus.ready || _pipes.isEmpty) {
                _initPipes(skyH, arenaW);
                _birdY = skyH * 0.40;
              }
            } else if (_pipes.isEmpty) {
              _initPipes(skyH, arenaW);
            }

            final double shakeOffsetX = _screenShakeIntensity > 0
                ? (_random.nextDouble() - 0.5) * _screenShakeIntensity
                : 0.0;
            final double shakeOffsetY = _screenShakeIntensity > 0
                ? (_random.nextDouble() - 0.5) * _screenShakeIntensity
                : 0.0;

            return Container(
              color: const Color(0xFF14181D),
              child: Center(
                child: Transform.translate(
                  offset: Offset(shakeOffsetX, shakeOffsetY),
                  child: Container(
                    width: arenaW,
                    height: arenaH,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(isLargeScreen ? 20.0 : 0.0),
                      border: isLargeScreen
                          ? Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 2.0,
                            )
                          : null,
                      boxShadow: isLargeScreen
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.7),
                                blurRadius: 36,
                                spreadRadius: 6,
                                offset: const Offset(0, 14),
                              ),
                              BoxShadow(
                                color: worldData.pipePrimary.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _handleUserInput,
                      child: Stack(
                        children: [
                          // 1. Dynamic World Sky & Parallax Landscape
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: skyH,
                            child: RepaintBoundary(
                              child: _buildSky(worldData),
                            ),
                          ),

                          // 2. Obstacle Aero Pylons
                          for (final pipe in _pipes) ...[
                            Positioned(
                              left: pipe.x - 5.0,
                              top: 0,
                              child: MyBarriers(
                                width: _pipeWidth,
                                height: pipe.topHeight,
                                isBottom: false,
                                primaryColor: worldData.pipePrimary,
                                secondaryColor: worldData.pipeSecondary,
                                borderColor: worldData.pipeBorder,
                                biome: worldData.biome,
                              ),
                            ),
                            Positioned(
                              left: pipe.x - 5.0,
                              top: pipe.topHeight + pipe.gapHeight,
                              child: MyBarriers(
                                width: _pipeWidth,
                                height: max(40.0, skyH - (pipe.topHeight + pipe.gapHeight)),
                                isBottom: true,
                                primaryColor: worldData.pipePrimary,
                                secondaryColor: worldData.pipeSecondary,
                                borderColor: worldData.pipeBorder,
                                biome: worldData.biome,
                              ),
                            ),
                          ],

                          // 3. Particles, Gems, Power-Ups, and Ambient Sparkles
                          Positioned.fill(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: ParticlePainter(
                                  rings: _flapRings,
                                  particles: _particles,
                                  gems: _gems,
                                  powerUps: _powerUpItems,
                                  ambientParticles: _ambientParticles,
                                  floatingTexts: _floatingTexts,
                                ),
                              ),
                            ),
                          ),

                          // 4. Legendary Flyer
                          Positioned(
                            left: _birdX - (_birdVisualSize / 2),
                            top: _birdY - (_birdVisualSize / 2),
                            child: MyBird(
                              rotation: _rotation,
                              width: _birdVisualSize,
                              height: _birdVisualSize,
                              skinConfig: skinConfig,
                              flapPulse: _flapPulse,
                              hasShield: _hasShield,
                              isGhost: _isGhost,
                              wingCycle: _wingCycle,
                            ),
                          ),

                          // 5. World Ground
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: groundH,
                            child: RepaintBoundary(
                              child: _buildGround(
                                arenaW,
                                groundH,
                                worldData,
                                bottomPadding: isLargeScreen ? 0.0 : bottomPadding,
                              ),
                            ),
                          ),

                          // 6. In-Game Live Score HUD & Power-Up Counters
                          if (_status == GameStatus.playing ||
                              _status == GameStatus.paused)
                            Positioned(
                              top: isLargeScreen ? 60 : max(58.0, topPadding + 46.0),
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Transform.scale(
                                      scale: _scoreScale,
                                      child: Text(
                                        '$_score',
                                        style: const TextStyle(
                                          fontSize: 52,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(offset: Offset(-2, -2), color: Colors.black),
                                            Shadow(offset: Offset(2, -2), color: Colors.black),
                                            Shadow(offset: Offset(2, 2), color: Colors.black),
                                            Shadow(offset: Offset(-2, 2), color: Colors.black),
                                            Shadow(offset: Offset(0, 4), blurRadius: 6, color: Colors.black45),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (_streak > 1) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.65),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFFFFD54F),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.bolt_rounded, color: Color(0xFFFFD54F), size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              'STREAK: $_streak',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFFFFD54F),
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (_activePowerUps.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        children: _activePowerUps.map((p) {
                                          final data = PowerUpData.of(p.type);
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.black87,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: data.color, width: 1.2),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(data.icon, color: data.color, size: 12),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${p.remainingSeconds.toStringAsFixed(1)}s',
                                                  style: TextStyle(
                                                    color: data.color,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                          // 7. World Intro Banner
                          if (_worldIntroTimer > 0)
                            Positioned(
                              top: isLargeScreen ? 64 : max(60.0, topPadding + 50.0),
                              left: 20,
                              right: 20,
                              child: _buildWorldIntroBanner(worldData),
                            ),

                          // 8. In-Flight Achievement Unlock Toast
                          if (_unlockedToastMessage != null)
                            Positioned(
                              top: isLargeScreen ? 14 : max(12.0, topPadding + 4.0),
                              left: 20,
                              right: 20,
                              child: _buildAchievementToast(),
                            ),

                          // 9. State Overlays
                          if (_status == GameStatus.ready) _buildReadyOverlay(worldData),
                          if (_status == GameStatus.paused) _buildPausedOverlay(),
                          if (_status == GameStatus.gameOver) _buildGameOverOverlay(),

                          // 10. Top Bar HUD (Interactive during ready and playing)
                          Positioned(
                            top: isLargeScreen ? 14 : max(12.0, topPadding + 4.0),
                            left: 12,
                            right: 12,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {}, // Absorb taps so HUD touches NEVER trigger background flaps
                              child: _buildTopControlBar(worldData, skinConfig),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- TOP HUD BAR ---
  Widget _buildTopControlBar(WorldBiomeData worldData, BirdSkinConfig skinConfig) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side: Hall of Fame & Settings
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHudIconButton(
              icon: Icons.emoji_events_rounded,
              tooltip: 'Hall of Fame (L)',
              color: const Color(0xFFFFB300),
              onTap: _openLeaderboard,
            ),
            const SizedBox(width: 8),
            _buildHudIconButton(
              icon: Icons.settings_rounded,
              tooltip: 'Settings (O)',
              color: Colors.white70,
              onTap: _openSettingsDialog,
            ),
          ],
        ),

        // Center Button: Pause / Audio toggle
        if (_status == GameStatus.playing || _status == GameStatus.paused)
          _buildHudIconButton(
            icon: _status == GameStatus.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            tooltip: _status == GameStatus.paused ? 'Resume (P)' : 'Pause (P)',
            color: Colors.white,
            onTap: _togglePause,
          )
        else
          _buildHudIconButton(
            icon: _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            tooltip: _soundEnabled ? 'Mute Audio (M)' : 'Unmute Audio (M)',
            color: _soundEnabled ? Colors.white : Colors.white54,
            onTap: _toggleSound,
          ),

        // Right side: Sound toggle (during gameplay) + Skin Picker + World Picker
        Row(
          children: [
            if (_status == GameStatus.playing || _status == GameStatus.paused) ...[
              _buildHudIconButton(
                icon: _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                tooltip: _soundEnabled ? 'Mute Audio (M)' : 'Unmute Audio (M)',
                color: _soundEnabled ? Colors.white : Colors.white54,
                onTap: _toggleSound,
              ),
              const SizedBox(width: 8),
            ],
            _buildHudIconButton(
              icon: skinConfig.icon,
              tooltip: 'Skin: ${skinConfig.name} (S)',
              color: skinConfig.particleColor,
              onTap: _openAviaryDialog,
            ),
            const SizedBox(width: 8),
            _buildHudIconButton(
              icon: worldData.icon,
              tooltip: 'Theme: ${worldData.name} (T)',
              color: Colors.white,
              onTap: _openWorldsDialog,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHudIconButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }

  // --- SKY & GROUND ---
  Widget _buildSky(WorldBiomeData worldData) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: worldData.skyGradient,
        ),
      ),
      child: Stack(
        children: [
          // Twinkling procedural stars for cosmic, neon city, and dreamland skies
          if (worldData.biome == WorldBiome.cosmicGalaxy ||
              worldData.biome == WorldBiome.neonCity ||
              worldData.biome == WorldBiome.dreamland)
            Positioned.fill(
              child: CustomPaint(
                painter: _StarPainter(stars: _stars, time: _worldTime),
              ),
            ),
          Positioned.fill(
            child: CustomPaint(
              painter: WorldCelestialPainter(biome: worldData.biome, time: _worldTime),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: ParallaxMountainPainter(
                scrollOffset: _mountainScroll,
                biome: worldData.biome,
                mountainColor: Color.lerp(worldData.pipeSecondary, Colors.black, 0.45)!
                    .withValues(alpha: 0.32),
                ridgeColor: Color.lerp(worldData.pipePrimary, Colors.black, 0.30)!
                    .withValues(alpha: 0.22),
              ),
            ),
          ),
          ClipRect(
            child: CustomPaint(
              painter: _CloudPainter(
                offset: _cloudScroll,
                cloudColor: worldData.cloudColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGround(
    double arenaW,
    double groundH,
    WorldBiomeData worldData, {
    double bottomPadding = 0.0,
  }) {
    return Column(
      children: [
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: worldData.grassColor,
            border: Border(
              top: BorderSide(
                color: Color.lerp(worldData.grassColor, Colors.white, 0.35)!,
                width: 2.0,
              ),
              bottom: BorderSide(color: worldData.grassBorder, width: 2.0),
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: worldData.soilColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: ClipRect(
              child: CustomPaint(
                painter: _GroundStripePainter(
                  offset: _groundScroll,
                  stripeColor: worldData.stripeColor,
                  grassColor: worldData.grassColor,
                  grassBorder: worldData.grassBorder,
                ),
                size: Size(arenaW, groundH - 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorldIntroBanner(WorldBiomeData worldData) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: (_worldIntroTimer / 2.0).clamp(0.0, 1.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: worldData.pipePrimary, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: worldData.pipePrimary.withValues(alpha: 0.4),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(worldData.icon, color: worldData.pipePrimary, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worldData.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      worldData.subtitle,
                      style: TextStyle(
                        color: worldData.pipePrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementToast() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66FFD700),
            blurRadius: 18,
          ),
        ],
      ),
      child: Text(
        _unlockedToastMessage ?? '',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // --- READY OVERLAY ---
  Widget _buildReadyOverlay(WorldBiomeData worldData) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 460.0;
            if (isCompact) {
              return Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 6),
                      _buildReadyTitle(),
                      const SizedBox(height: 10),
                      _buildReadyInstructions(),
                      const SizedBox(height: 10),
                      _buildReadyBottomRow(),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              );
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                _buildReadyTitle(),
                const SizedBox(height: 22),
                _buildReadyInstructions(),
                const Spacer(flex: 3),
                _buildReadyBottomRow(),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildReadyTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF9800),
                Color(0xFFF57C00),
                Color(0xFFE65100),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: const Text(
            'FLAPPY BIRD',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: const Text(
            'NEO ARCADE • SKYBOUND EXPANSION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
              color: Color(0xFFFFD54F),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadyInstructions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'TAP OR PRESS SPACE TO FLY',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Clear Aero Pylons • Collect Sky Gems (+2) • Rule the Ranks!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFFFFE082),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildKeyBadge('[SPACE] Fly'),
              _buildKeyBadge('[P] Pause'),
              _buildKeyBadge('[L] Ranks'),
              _buildKeyBadge('[T] World'),
              _buildKeyBadge('[S] Skin'),
              _buildKeyBadge('[M] Audio'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadyBottomRow() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        if (_bestScore > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 18),
                const SizedBox(width: 6),
                Text(
                  'BEST SCORE: $_bestScore',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ElevatedButton.icon(
          onPressed: _openLeaderboard,
          icon: const Icon(Icons.emoji_events_rounded, size: 16),
          label: const Text(
            'LEADERBOARD',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF09030),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _openQuestsDialog,
          icon: const Icon(Icons.stars_rounded, size: 16),
          label: const Text(
            'MISSIONS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // --- PAUSED OVERLAY ---
  Widget _buildPausedOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.70),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2630),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00E5FF), width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black87,
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'GAME PAUSED',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _togglePause,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('RESUME', style: TextStyle(fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(180, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _openLeaderboard,
                    icon: const Icon(Icons.emoji_events_rounded),
                    label: const Text('LEADERBOARD', style: TextStyle(fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF09030),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(180, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _openSettingsDialog,
                    icon: const Icon(Icons.settings_rounded),
                    label: const Text('SETTINGS', style: TextStyle(fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF607D8B),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(180, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _restartGame,
                    child: const Text('RESTART TO READY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- GAME OVER OVERLAY ---
  Widget _buildGameOverOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.65),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2630),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF5252), width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black87,
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'GAME OVER',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Color(0xFFFF5252),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Scoreboard inner card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141920),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'MEDAL',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _buildMedalBadge(_score),
                              ],
                            ),
                            Container(width: 1.5, height: 50, color: Colors.white12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    const Text('SCORE: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
                                    Text('$_score', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (_isNewHighScore)
                                      Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('NEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                                      ),
                                    const Text('BEST: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
                                    Text('$_bestScore', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (_recordSubmittedThisRound) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B3B22),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF4CAF50)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Score recorded for pilot $_pilotName!',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF81C784),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.diamond_rounded, color: Color(0xFFFFD700), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '+$_gemsThisGame Sky Gems Collected',
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _restartGame,
                          icon: const Icon(Icons.replay_rounded),
                          label: const Text(
                            'PLAY AGAIN',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _openLeaderboard,
                        icon: const Icon(Icons.emoji_events_rounded, size: 18),
                        label: const Text(
                          'RANKS',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF09030),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (!_recordSubmittedThisRound && _score > 0)
                    TextButton.icon(
                      onPressed: _showCallSignPrompt,
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: Text(
                        'Record Call-Sign [$_pilotName]',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFB300),
                        ),
                      ),
                    )
                  else
                    const Text(
                      'or press Space to restart',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedalBadge(int score) {
    Color medalColor;
    String label;

    if (score >= 40) {
      medalColor = const Color(0xFFE5E4E2);
      label = 'PLATINUM';
    } else if (score >= 25) {
      medalColor = const Color(0xFFFFD700);
      label = 'GOLD';
    } else if (score >= 10) {
      medalColor = const Color(0xFFC0C0C0);
      label = 'SILVER';
    } else if (score >= 3) {
      medalColor = const Color(0xFFCD7F32);
      label = 'BRONZE';
    } else {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade800),
        child: const Icon(Icons.lock_outline, size: 22, color: Colors.white54),
      );
    }

    return Tooltip(
      message: label,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: medalColor,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: const Icon(Icons.emoji_events, size: 24, color: Colors.white),
      ),
    );
  }
}

enum HapticFeedbackType { light, medium, heavy, selection }

/// Custom GPU painter that renders moving diagonal ground stripes & stepped grass teeth.
class _GroundStripePainter extends CustomPainter {
  final double offset;
  final Color stripeColor;
  final Color grassColor;
  final Color grassBorder;

  const _GroundStripePainter({
    required this.offset,
    required this.stripeColor,
    required this.grassColor,
    required this.grassBorder,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final toothPaint = Paint()
      ..color = grassBorder
      ..style = PaintingStyle.fill;

    const double toothWidth = 8.0;
    const double toothHeight = 4.0;
    final double toothStartX = -toothWidth + (-offset % (toothWidth * 2));

    for (double x = toothStartX; x < size.width + toothWidth * 2; x += toothWidth * 2) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, toothWidth, toothHeight),
        toothPaint,
      );
    }

    final stripePaint = Paint()
      ..color = stripeColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    const double stripeGap = 24.0;
    final double startX = -stripeGap + (-offset % stripeGap);

    for (double x = startX; x < size.width + stripeGap; x += stripeGap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + 18, toothHeight),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GroundStripePainter oldDelegate) {
    return oldDelegate.offset != offset ||
        oldDelegate.stripeColor != stripeColor ||
        oldDelegate.grassColor != grassColor ||
        oldDelegate.grassBorder != grassBorder;
  }
}

/// Custom GPU painter that draws authentic procedurally scrolling multi-puff clouds.
class _CloudPainter extends CustomPainter {
  final double offset;
  final Color cloudColor;

  const _CloudPainter({
    required this.offset,
    required this.cloudColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = cloudColor
      ..style = PaintingStyle.fill;

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    const double spacing = 180.0;
    const double cloudW = 95.0;
    const double baseY = 36.0;
    final double startX = -cloudW * 2 - (offset % spacing);

    for (double x = startX; x < size.width + spacing * 2; x += spacing) {
      final double y = size.height - baseY;

      final baseRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y + 6, cloudW, 22),
        const Radius.circular(11),
      );
      canvas.drawRRect(baseRRect, cloudPaint);

      canvas.drawCircle(Offset(x + 24, y + 8), 15, cloudPaint);
      canvas.drawCircle(Offset(x + 24, y + 7), 12, highlightPaint);

      canvas.drawCircle(Offset(x + 50, y + 3), 20, cloudPaint);
      canvas.drawCircle(Offset(x + 50, y + 1), 16, highlightPaint);

      canvas.drawCircle(Offset(x + 74, y + 10), 13, cloudPaint);
      canvas.drawCircle(Offset(x + 74, y + 9), 10, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) {
    return oldDelegate.offset != offset || oldDelegate.cloudColor != cloudColor;
  }
}

/// Procedural starfield painter rendering twinkling stars in cosmic and nighttime worlds.
class _StarPainter extends CustomPainter {
  final List<NightStar> stars;
  final double time;

  const _StarPainter({
    required this.stars,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in stars) {
      final double alpha =
          (0.3 + 0.7 * sin(s.twinklePhase + time * s.twinkleSpeed))
              .clamp(0.0, 1.0);
      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(s.xRatio * size.width, s.yRatio * size.height),
        s.baseRadius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) =>
      oldDelegate.time != time;
}

