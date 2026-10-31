// Math library for trigonometric calculations, randomness, and min/max clamps
import 'dart:math';

// Core Flutter UI and layout widgets
import 'package:flutter/material.dart';

// Provides Ticker class for screen-synchronized 60-120 FPS game loops
import 'package:flutter/scheduler.dart';

// Services for hardware keyboard handling, system sound, and haptic vibration feedback
import 'package:flutter/services.dart';

// Central multi-channel audio manager for background music and sound effects
import 'audio_manager.dart';

// High-tech 3D obstacle pylons
import 'barriers.dart';

// Animated flyer sprite with GPU skin color filters, wind trails, and pixel-fidelity filtering
import 'bird.dart';

// Hall of Fame modal dialog
import 'leaderboard_dialog.dart';

// High score and career stats data models
import 'leaderboard_model.dart';

// Pilot callsign input dialog
import 'name_input_dialog.dart';

// Procedural particle engine (shockwaves, sparkles, feathers, stars, gems, popup text, parallax mountains)
import 'particle_effects.dart';

// Cross-platform data persistence adapter (local file on mobile/desktop, localStorage on web)
import 'score_storage.dart' as score_storage;

// Dynamic environment themes (Day, Sunset, Midnight)
import 'theme_data.dart';

/// The four distinct operating states of the game engine.
enum GameStatus {
  ready,    // Idle hover in the center of the sky, waiting for first tap
  playing,  // Active flight with live physics, scrolling pylons, gems, and scoring
  paused,   // Ticker physics suspended; paused overlay shown
  gameOver, // Flyer crashed; falling to ground and opening score dialog
}

/// Represents a single obstacle column containing a top pylon, a bottom pylon, and the clearance gap between them.
class PipePair {
  // Horizontal X coordinate in the arena
  double x;

  // Height of the upper pylon hanging from the ceiling
  double topHeight;

  // Vertical clearance gap opening for the bird to fly through
  double gapHeight;

  // Flag ensuring points are only awarded once when passing this pylon
  bool passed;

  PipePair({
    required this.x,
    required this.topHeight,
    required this.gapHeight,
    this.passed = false,
  });
}

/// The master game screen hosting the game loop, physics engine, and user controls.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // Game loop ticker synchronized directly with the hardware display's VSYNC refresh rate
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // FocusNode allowing desktop and web browsers to capture physical keyboard key presses
  final FocusNode _focusNode = FocusNode();

  // Current game state (starts in 'ready' mode)
  GameStatus _status = GameStatus.ready;

  // Active round score
  int _score = 0;

  // All-time personal best score loaded from storage
  int _bestScore = 0;

  // True if the current score has surpassed the previous record
  bool _isNewHighScore = false;

  // Total flaps made in the current round
  int _flapsThisGame = 0;

  // Clean gate pass combo streak in current round
  int _streak = 0;

  // Audio / Sound FX toggle
  bool _soundEnabled = true;

  // Timestamp when Game Over was triggered (used for input debounce cooldown)
  DateTime? _gameOverTime;

  // Persistent Hall of Fame entries
  List<LeaderboardEntry> _leaderboard =
      List.from(LeaderboardEntry.defaultLeaderboard);
  PlayerStats _playerStats = const PlayerStats();
  String _pilotName = 'PILOT';
  bool _recordSubmittedThisRound = false;

  // Theme & Skins
  EnvironmentTheme _currentTheme = EnvironmentTheme.day;
  BirdSkin _currentSkin = BirdSkin.classic;

  // Viewport dimensions
  double _arenaWidth = 400.0;
  double _skyHeight = 560.0;

  // Bird physics & geometry
  static const double _birdVisualSize = 64.0;
  static const double _birdHitboxW = 34.0;
  static const double _birdHitboxH = 26.0;

  double _birdX = 100.0;
  double _birdY = 250.0;
  double _velocity = 0.0;
  double _rotation = 0.0;
  double _readyHoverTime = 0.0;
  double _worldTime = 0.0;
  double _flapPulse = 1.0;

  // Physics constants
  static const double _gravity = 980.0;
  static const double _jumpVelocity = -350.0;
  static const double _maxFallSpeed = 520.0;
  static const double _pipeSpeed = 160.0;
  static const double _pipeWidth = 68.0;

  // Obstacles & Collectibles
  final Random _random = Random();
  final List<PipePair> _pipes = [];
  final List<FloatingGem> _gems = [];
  final List<FloatingPopupText> _floatingTexts = [];
  double _pipeSpacing = 240.0;

  // Visual effects & particles
  final List<FlapRing> _flapRings = [];
  final List<Particle> _particles = [];
  late final List<NightStar> _stars;

  // Decorative offsets
  double _groundScroll = 0.0;
  double _cloudScroll = 0.0;
  double _mountainScroll = 0.0;
  double _scoreScale = 1.0;

  @override
  void initState() {
    super.initState();
    _stars = NightStar.generate(45);
    _loadAllUserData();
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
    _ticker.dispose();
    _focusNode.dispose();
    AudioManager.instance.dispose();
    super.dispose();
  }

  Future<void> _loadAllUserData() async {
    try {
      final best = await score_storage.loadBestScore();
      if (mounted) {
        setState(() {
          _bestScore = best;
        });
      }
    } catch (_) {}

    try {
      final board = await score_storage.loadLeaderboard();
      final stats = await score_storage.loadPlayerStats();
      final name = await score_storage.loadLastPlayerName();
      if (mounted) {
        setState(() {
          _leaderboard = board;
          _playerStats = stats;
          _pilotName = name;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveBestScore(int newBest) async {
    try {
      await score_storage.saveBestScore(newBest);
    } catch (_) {}
  }

  void _cycleTheme() {
    setState(() {
      _currentTheme = EnvironmentTheme.values[
          (_currentTheme.index + 1) % EnvironmentTheme.values.length];
    });
    AudioManager.instance.playClick();
    HapticFeedback.selectionClick();
  }

  void _cycleSkin() {
    setState(() {
      _currentSkin =
          BirdSkin.values[(_currentSkin.index + 1) % BirdSkin.values.length];
    });
    AudioManager.instance.playClick();
    HapticFeedback.selectionClick();
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
    HapticFeedback.selectionClick();
  }

  void _togglePause() {
    if (_status == GameStatus.playing) {
      setState(() {
        _status = GameStatus.paused;
      });
      AudioManager.instance.pauseBgm();
      AudioManager.instance.playClick();
      HapticFeedback.lightImpact();
    } else if (_status == GameStatus.paused) {
      setState(() {
        _status = GameStatus.playing;
        _lastElapsed = Duration.zero; // Prevent frame delta spike
      });
      if (_soundEnabled) {
        AudioManager.instance.resumeBgm();
      }
      AudioManager.instance.playClick();
      HapticFeedback.lightImpact();
    }
  }

  void _openLeaderboard() {
    AudioManager.instance.playClick();
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => LeaderboardDialog(
        leaderboard: _leaderboard,
        stats: _playerStats,
      ),
    );
  }

  void _initPipes(double skyH, double arenaW) {
    _pipes.clear();
    _gems.clear();
    _floatingTexts.clear();
    _pipeSpacing = (arenaW * 0.65).clamp(210.0, 280.0);

    for (int i = 0; i < 2; i++) {
      final pipe = PipePair(
        x: arenaW + 80.0 + (i * _pipeSpacing),
        topHeight: 150.0,
        gapHeight: 150.0,
      );
      _randomizePipe(pipe, skyH);
      _pipes.add(pipe);
    }
  }

  void _randomizePipe(PipePair pipe, double skyH) {
    final double gap = (skyH * 0.28).clamp(130.0, 180.0);
    const double minPipe = 45.0;
    final double available =
        (skyH - gap - (minPipe * 2)).clamp(20.0, double.infinity);
    final double top = minPipe + _random.nextDouble() * available;

    pipe.topHeight = top;
    pipe.gapHeight = gap;
    pipe.passed = false;

    // 70% chance to spawn a bonus Sky Gem (+2 points) in the center of the opening
    if (_random.nextDouble() < 0.70) {
      _gems.add(
        FloatingGem(
          x: pipe.x + (_pipeWidth / 2),
          baseY: top + (gap / 2),
          value: 2,
        ),
      );
    }
  }

  /// Hardware VSYNC Tick callback fired on every display frame refresh (60-120 FPS).
  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final double dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1000000.0).clamp(0.001, 0.033);
    _lastElapsed = elapsed;

    if (!mounted || _status == GameStatus.paused) return;

    setState(() {
      _updateGame(dt);
    });
  }

  /// Master game state machine updating world positions, particles, and scoring for this frame.
  void _updateGame(double dt) {
    _worldTime += dt;

    // Prune expired shockwave rings, particles, and popup texts
    _flapRings.removeWhere((ring) => !ring.update(dt));
    _particles.removeWhere((p) => !p.update(dt));
    _floatingTexts.removeWhere((t) => !t.update(dt));

    // Scroll ground, clouds, and distant parallax mountains
    if (_status != GameStatus.gameOver) {
      _groundScroll = (_groundScroll + _pipeSpeed * dt) % 24.0;
      _cloudScroll = (_cloudScroll + 20.0 * dt) % 360.0;
      _mountainScroll = (_mountainScroll + 35.0 * dt) % 720.0;
    }

    // Decay the score text pop animation smoothly back to normal scale 1.0
    if (_scoreScale > 1.0) {
      _scoreScale = (_scoreScale - dt * 2.0).clamp(1.0, 1.4);
    }

    // Decay flap squash & stretch elasticity
    if (_flapPulse > 1.0) {
      _flapPulse = (_flapPulse - dt * 2.5).clamp(1.0, 1.25);
    }

    switch (_status) {
      case GameStatus.ready:
        _readyHoverTime += dt;
        _birdY = (_skyHeight * 0.44) + sin(_readyHoverTime * 5.0) * 8.0;
        _rotation = sin(_readyHoverTime * 5.0) * 0.08;
        _velocity = 0.0;
        // Subtle resting wing flutter on idle hover
        _flapPulse = 1.0 + (sin(_readyHoverTime * 10.0).abs() * 0.05);
        break;

      case GameStatus.playing:
        // Flyer physics
        _velocity += _gravity * dt;
        if (_velocity > _maxFallSpeed) {
          _velocity = _maxFallSpeed;
        }
        _birdY += _velocity * dt;

        // Smooth rotation
        if (_velocity < -50.0) {
          _rotation = -0.42;
        } else {
          _rotation = (_rotation + 3.2 * dt).clamp(-0.42, 1.25);
        }

        // Pylon obstacle movement & recycling
        for (final pipe in _pipes) {
          pipe.x -= _pipeSpeed * dt;

          if (!pipe.passed && (_birdX > pipe.x + (_pipeWidth / 2))) {
            pipe.passed = true;
            _score++;
            _streak++;
            _scoreScale = 1.35;

            if (_soundEnabled) {
              AudioManager.instance.playScore();
              SystemSound.play(SystemSoundType.click);
            }
            HapticFeedback.lightImpact();

            // Burst score sparkle particles
            _burstSparkles(_birdX + 20, _birdY, const Color(0xFFFFD700));

            // Combo streak milestones
            if (_streak == 3) {
              AudioManager.instance.playCombo();
              _floatingTexts.add(FloatingPopupText(
                x: _birdX + 30,
                y: _birdY - 26,
                text: 'x3 STREAK!',
                color: const Color(0xFF00E5FF),
              ));
            } else if (_streak == 5) {
              AudioManager.instance.playCombo();
              _floatingTexts.add(FloatingPopupText(
                x: _birdX + 30,
                y: _birdY - 26,
                text: 'PERFECT!',
                color: const Color(0xFFFF9100),
              ));
            } else if (_streak >= 10 && _streak % 5 == 0) {
              AudioManager.instance.playCombo();
              _floatingTexts.add(FloatingPopupText(
                x: _birdX + 30,
                y: _birdY - 26,
                text: 'UNSTOPPABLE!',
                color: const Color(0xFFFFD700),
              ));
            }

            if (_score > _bestScore) {
              _bestScore = _score;
              _isNewHighScore = true;
              _saveBestScore(_bestScore);
            }
          }

          if (pipe.x < -_pipeWidth - 20.0) {
            final double rightmostX = _pipes.map((p) => p.x).reduce(max);
            pipe.x = rightmostX + _pipeSpacing;
            _randomizePipe(pipe, _skyHeight);
          }
        }

        // Sky Gem movement & collection check
        for (final gem in _gems) {
          gem.x -= _pipeSpeed * dt;
          gem.update(dt);

          if (!gem.collected) {
            final double dx = (gem.x - _birdX).abs();
            final double dy = (gem.y - _birdY).abs();
            if (dx < 28.0 && dy < 28.0) {
              gem.collected = true;
              _score += gem.value;
              _scoreScale = 1.38;

              if (_soundEnabled) {
                AudioManager.instance.playGem();
                SystemSound.play(SystemSoundType.click);
              }
              HapticFeedback.mediumImpact();
              _burstSparkles(gem.x, gem.y, const Color(0xFFFFD700));

              _floatingTexts.add(FloatingPopupText(
                x: gem.x,
                y: gem.y - 14,
                text: '+${gem.value} GEM!',
                color: const Color(0xFFFFD54F),
              ));

              if (_score > _bestScore) {
                _bestScore = _score;
                _isNewHighScore = true;
                _saveBestScore(_bestScore);
              }
            }
          }
        }
        _gems.removeWhere((g) => g.x < -40.0 || (g.collected && g.hoverTime > 0.35));

        _checkCollisions();
        break;

      case GameStatus.gameOver:
        final double groundLimit = _skyHeight - (_birdHitboxH / 2);
        if (_birdY < groundLimit) {
          _velocity += _gravity * 1.5 * dt;
          _birdY = (_birdY + _velocity * dt).clamp(0.0, groundLimit);
          _rotation = 1.3;
        }
        break;

      case GameStatus.paused:
        break;
    }
  }

  /// 2D Axis-Aligned Bounding Box (AABB) collision detection checking bounds and pylons.
  void _checkCollisions() {
    final double birdLeft = _birdX - (_birdHitboxW / 2);
    final double birdRight = _birdX + (_birdHitboxW / 2);
    final double birdTop = _birdY - (_birdHitboxH / 2);
    final double birdBottom = _birdY + (_birdHitboxH / 2);

    // Ceiling collision check
    if (birdTop <= 0) {
      _triggerGameOver();
      return;
    }

    // Ground collision check
    if (birdBottom >= _skyHeight) {
      _birdY = _skyHeight - (_birdHitboxH / 2);
      _triggerGameOver();
      return;
    }

    // Pylon obstacle collision check
    for (final pipe in _pipes) {
      // Inset pylon hitbox slightly by 2px for forgiving, polished arcade gameplay
      final double pipeLeft = pipe.x + 2.0;
      final double pipeRight = pipe.x + _pipeWidth - 2.0;

      if (birdRight > pipeLeft && birdLeft < pipeRight) {
        final double topPipeBottom = pipe.topHeight;
        final double bottomPipeTop = pipe.topHeight + pipe.gapHeight;

        if (birdTop < topPipeBottom || birdBottom > bottomPipeTop) {
          _triggerGameOver();
          return;
        }
      }
    }
  }

  void _triggerGameOver() {
    if (_status == GameStatus.gameOver) return;

    _gameOverTime = DateTime.now();
    _streak = 0;

    AudioManager.instance.stopBgm();
    if (_soundEnabled) {
      AudioManager.instance.playHit();
      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted && _status == GameStatus.gameOver && _soundEnabled) {
          AudioManager.instance.playGameOver();
        }
      });
      SystemSound.play(SystemSoundType.alert);
    }
    HapticFeedback.mediumImpact();

    // Burst collision particles
    _burstSparkles(_birdX, _birdY, const Color(0xFFFF5252));

    // Update cumulative player stats
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

    // Check if score qualifies for Hall of Fame
    if (_score > 0 && _isHighScoreQualified(_score)) {
      Future.delayed(const Duration(milliseconds: 600), () {
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NameInputDialog(
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
      skin: _currentSkin.name,
    );

    final updated = List<LeaderboardEntry>.from(_leaderboard)..add(entry);
    updated.sort((a, b) => b.score.compareTo(a.score));

    // Keep top 10
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
    HapticFeedback.heavyImpact();
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
      _velocity = _jumpVelocity;
      _rotation = -0.42;
      _flapPulse = 1.14; // Elastic squash & stretch jump impulse
    });

    // Trigger visual flap ring shockwave
    _flapRings.add(FlapRing(x: _birdX, y: _birdY));

    // Burst feather particles
    final skinData = BirdSkinData.fromSkin(_currentSkin);
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
          color: skinData.particleColor,
        ),
      );
    }

    if (_soundEnabled) {
      AudioManager.instance.playFlap();
      SystemSound.play(SystemSoundType.click);
    }
    HapticFeedback.selectionClick();
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

  void _handleUserInput() {
    switch (_status) {
      case GameStatus.ready:
        setState(() {
          _status = GameStatus.playing;
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
        // Debounce: prevent rapid collision taps from instantly dismissing the score screen
        if (_gameOverTime != null &&
            DateTime.now().difference(_gameOverTime!).inMilliseconds < 450) {
          return;
        }
        _restartGame();
        break;
    }
  }

  void _restartGame() {
    AudioManager.instance.stopBgm();
    AudioManager.instance.playClick();
    setState(() {
      _status = GameStatus.ready;
      _score = 0;
      _streak = 0;
      _flapsThisGame = 0;
      _isNewHighScore = false;
      _velocity = 0.0;
      _rotation = 0.0;
      _readyHoverTime = 0.0;
      _gameOverTime = null;
      _flapPulse = 1.0;
      _birdY = _skyHeight * 0.44;
      _flapRings.clear();
      _particles.clear();
      _gems.clear();
      _floatingTexts.clear();
      _initPipes(_skyHeight, _arenaWidth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeData = EnvironmentThemeData.fromTheme(_currentTheme);

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
            } else if (key == LogicalKeyboardKey.keyL) {
              _openLeaderboard();
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.keyT) {
              _cycleTheme();
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

            // Maintain authentic mobile/arcade aspect ratio on desktop/tablets without stretching infinitely
            final double arenaH = isLargeScreen
                ? min(availableHeight - 32.0, max(580.0, arenaW * 1.78))
                : availableHeight;

            // Ground height adapts: scales proportionally and includes safe area bottom padding
            final double groundH =
                (arenaH * 0.16).clamp(70.0, 130.0) + (isLargeScreen ? 0.0 : bottomPadding);
            final double skyH = arenaH - groundH;

            if (_arenaWidth != arenaW || _skyHeight != skyH) {
              _arenaWidth = arenaW;
              _skyHeight = skyH;
              _birdX = arenaW * 0.28;

              if (_pipes.isEmpty) {
                _initPipes(skyH, arenaW);
                _birdY = skyH * 0.44;
              }
            }

            return Container(
              color: const Color(0xFF14181D),
              child: Center(
                child: Container(
                  width: arenaW,
                  height: arenaH,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius:
                        BorderRadius.circular(isLargeScreen ? 20.0 : 0.0),
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
                              color: themeData.pipePrimary.withValues(alpha: 0.15),
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
                        // 1. Sky area with gradient, stars, parallax mountains, and scrolling clouds
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: skyH,
                          child: RepaintBoundary(
                            child: _buildSky(themeData),
                          ),
                        ),

                        // 2. Obstacle Aero Pylons (Caps extend symmetrically by 5px on left and right)
                        for (final pipe in _pipes) ...[
                          Positioned(
                            left: pipe.x - 5.0,
                            top: 0,
                            child: MyBarriers(
                              width: _pipeWidth,
                              height: pipe.topHeight,
                              isBottom: false,
                              primaryColor: themeData.pipePrimary,
                              secondaryColor: themeData.pipeSecondary,
                              borderColor: themeData.pipeBorder,
                            ),
                          ),
                          Positioned(
                            left: pipe.x - 5.0,
                            top: pipe.topHeight + pipe.gapHeight,
                            child: MyBarriers(
                              width: _pipeWidth,
                              height: skyH - (pipe.topHeight + pipe.gapHeight),
                              isBottom: true,
                              primaryColor: themeData.pipePrimary,
                              secondaryColor: themeData.pipeSecondary,
                              borderColor: themeData.pipeBorder,
                            ),
                          ),
                        ],

                        // 3. Particles, shockwaves, floating sky gems, and combo text popups
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: ParticlePainter(
                                rings: _flapRings,
                                particles: _particles,
                                gems: _gems,
                                floatingTexts: _floatingTexts,
                              ),
                            ),
                          ),
                        ),

                        // 4. Flyer character with aerodynamic wind jetstream & skin shaders
                        Positioned(
                          left: _birdX - (_birdVisualSize / 2),
                          top: _birdY - (_birdVisualSize / 2),
                          child: MyBird(
                            rotation: _rotation,
                            width: _birdVisualSize,
                            height: _birdVisualSize,
                            skin: _currentSkin,
                            flapPulse: _flapPulse,
                          ),
                        ),

                        // 5. Ground with stepped teeth & textured scrolling soil
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: groundH,
                          child: RepaintBoundary(
                            child: _buildGround(
                              arenaW,
                              groundH,
                              themeData,
                              bottomPadding:
                                  isLargeScreen ? 0.0 : bottomPadding,
                            ),
                          ),
                        ),

                        // 6. In-Game Live Score HUD & Streak Counter
                        if (_status == GameStatus.playing ||
                            _status == GameStatus.paused)
                          Positioned(
                            top: isLargeScreen
                                ? 60
                                : max(58.0, topPadding + 46.0),
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
                                          Shadow(offset: Offset(0, -2.5), color: Colors.black),
                                          Shadow(offset: Offset(0, 2.5), color: Colors.black),
                                          Shadow(offset: Offset(-2.5, 0), color: Colors.black),
                                          Shadow(offset: Offset(2.5, 0), color: Colors.black),
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
                                          color: const Color(0xFFFFD54F).withValues(alpha: 0.8),
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
                                ],
                              ),
                            ),
                          ),

                        // 7. Ready prompt overlay
                        if (_status == GameStatus.ready) _buildReadyOverlay(),

                        // 8. Paused overlay
                        if (_status == GameStatus.paused) _buildPausedOverlay(),

                        // 9. Game over dialog overlay
                        if (_status == GameStatus.gameOver)
                          _buildGameOverOverlay(),

                        // 10. Quick Control HUD (Top Bar) - Safe Area padded
                        // RENDERED ON TOP OF OVERLAYS SO TOP HUD BUTTONS ARE NEVER BLOCKED!
                        Positioned(
                          top: isLargeScreen
                              ? 14
                              : max(12.0, topPadding + 4.0),
                          left: 12,
                          right: 12,
                          child: _buildTopControlBar(themeData),
                        ),
                      ],
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

  Widget _buildTopControlBar(EnvironmentThemeData themeData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Leaderboard Button
        _buildHudIconButton(
          icon: Icons.emoji_events_rounded,
          tooltip: 'Hall of Fame (L)',
          color: const Color(0xFFFFB300),
          onTap: _openLeaderboard,
        ),

        // Center: Pause Button during play / Audio toggle during ready or game over
        if (_status == GameStatus.playing || _status == GameStatus.paused)
          _buildHudIconButton(
            icon: _status == GameStatus.paused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
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

        // Right side: Sound toggle (during gameplay) + Skin Picker & Theme Toggle
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
              icon: BirdSkinData.fromSkin(_currentSkin).icon,
              tooltip:
                  'Skin: ${BirdSkinData.fromSkin(_currentSkin).label} (S)',
              color: BirdSkinData.fromSkin(_currentSkin).particleColor,
              onTap: _cycleSkin,
            ),
            const SizedBox(width: 8),
            _buildHudIconButton(
              icon: themeData.icon,
              tooltip: 'Theme: ${themeData.label} (T)',
              color: Colors.white,
              onTap: _cycleTheme,
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
        color: Colors.black.withValues(alpha: 0.55),
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

  Widget _buildSky(EnvironmentThemeData themeData) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: themeData.skyGradient,
        ),
      ),
      child: Stack(
        children: [
          // Night stars & moon
          if (themeData.hasStars)
            Positioned.fill(
              child: CustomPaint(
                painter: StarsPainter(stars: _stars, time: _worldTime),
              ),
            ),
          // Distant parallax mountain horizon ridge
          Positioned.fill(
            child: CustomPaint(
              painter: ParallaxMountainPainter(
                scrollOffset: _mountainScroll,
                mountainColor: Color.lerp(themeData.pipeSecondary, Colors.black, 0.45)!
                    .withValues(alpha: 0.32),
                ridgeColor: Color.lerp(themeData.pipePrimary, Colors.black, 0.30)!
                    .withValues(alpha: 0.22),
              ),
            ),
          ),
          // Scrolling clouds
          ClipRect(
            child: CustomPaint(
              painter: _CloudPainter(
                offset: _cloudScroll,
                cloudColor: themeData.cloudColor,
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
    EnvironmentThemeData themeData, {
    double bottomPadding = 0.0,
  }) {
    return Column(
      children: [
        // Top lush green grass strip with highlight rim
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: themeData.grassColor,
            border: Border(
              top: BorderSide(
                color: Color.lerp(themeData.grassColor, Colors.white, 0.35)!,
                width: 2.0,
              ),
              bottom: BorderSide(color: themeData.grassBorder, width: 2.0),
            ),
          ),
        ),
        // Soil area with stepped pixel teeth & scrolling diagonal stripes
        Expanded(
          child: Container(
            color: themeData.soilColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: ClipRect(
              child: CustomPaint(
                painter: _GroundStripePainter(
                  offset: _groundScroll,
                  stripeColor: themeData.stripeColor,
                  grassColor: themeData.grassColor,
                  grassBorder: themeData.grassBorder,
                ),
                size: Size(arenaW, groundH - 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadyOverlay() {
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
            'NEO ARCADE • SKY ODYSSEY',
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
          // Hotkeys pill
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildKeyBadge('[SPACE] Fly'),
              _buildKeyBadge('[P] Pause'),
              _buildKeyBadge('[L] Ranks'),
              _buildKeyBadge('[T] Theme'),
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
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFFFD54F), size: 18),
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
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
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
                    label: const Text(
                      'RESUME',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
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
                    label: const Text(
                      'LEADERBOARD',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
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
                  TextButton(
                    onPressed: _restartGame,
                    child: const Text(
                      'QUIT TO MENU',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
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
                            // Medal indicator
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
                            Container(
                              width: 1.5,
                              height: 50,
                              color: Colors.white12,
                            ),
                            // Score stats
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'SCORE: ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Text(
                                      '$_score',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (_isNewHighScore)
                                      Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'NEW',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    const Text(
                                      'BEST: ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Text(
                                      '$_bestScore',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Record submission status
                        if (_recordSubmittedThisRound) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B3B22),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF4CAF50)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: Color(0xFF4CAF50), size: 16),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons: Play Again & Leaderboard
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
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF09030),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Prompt to enter Call-sign if not submitted yet
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
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade800,
        ),
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
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.emoji_events,
          size: 24,
          color: Colors.white,
        ),
      ),
    );
  }
}

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
    // 1. Draw stepped pixel teeth on the grass bottom border for retro authenticity
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

    // 2. Draw moving diagonal ground stripes across the soil
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

      // Base pill
      final baseRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y + 6, cloudW, 22),
        const Radius.circular(11),
      );
      canvas.drawRRect(baseRRect, cloudPaint);

      // Left puff
      canvas.drawCircle(Offset(x + 24, y + 8), 15, cloudPaint);
      canvas.drawCircle(Offset(x + 24, y + 7), 12, highlightPaint);

      // Center tall puff
      canvas.drawCircle(Offset(x + 50, y + 3), 20, cloudPaint);
      canvas.drawCircle(Offset(x + 50, y + 1), 16, highlightPaint);

      // Right puff
      canvas.drawCircle(Offset(x + 74, y + 10), 13, cloudPaint);
      canvas.drawCircle(Offset(x + 74, y + 9), 10, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) {
    return oldDelegate.offset != offset || oldDelegate.cloudColor != cloudColor;
  }
}
