import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'barriers.dart';
import 'bird.dart';
import 'leaderboard_dialog.dart';
import 'leaderboard_model.dart';
import 'name_input_dialog.dart';
import 'particle_effects.dart';
import 'score_storage.dart' as score_storage;
import 'theme_data.dart';

enum GameStatus {
  ready,
  playing,
  paused,
  gameOver,
}

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // Game loop ticker
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // Keyboard focus node for Web & Desktop
  final FocusNode _focusNode = FocusNode();

  // Game Status & Scoring
  GameStatus _status = GameStatus.ready;
  int _score = 0;
  int _bestScore = 0;
  bool _isNewHighScore = false;
  int _flapsThisGame = 0;

  // Leaderboard & Player Stats
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

  // Physics constants
  static const double _gravity = 980.0;
  static const double _jumpVelocity = -350.0;
  static const double _maxFallSpeed = 520.0;
  static const double _pipeSpeed = 160.0;
  static const double _pipeWidth = 68.0;

  // Obstacles
  final Random _random = Random();
  final List<PipePair> _pipes = [];
  double _pipeSpacing = 240.0;

  // Visual effects & particles
  final List<FlapRing> _flapRings = [];
  final List<Particle> _particles = [];
  late final List<NightStar> _stars;

  // Decorative offsets
  double _groundScroll = 0.0;
  double _cloudScroll = 0.0;
  double _scoreScale = 1.0;

  @override
  void initState() {
    super.initState();
    _stars = NightStar.generate(45);
    _loadAllUserData();

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
  }

  void _cycleSkin() {
    setState(() {
      _currentSkin =
          BirdSkin.values[(_currentSkin.index + 1) % BirdSkin.values.length];
    });
  }

  void _togglePause() {
    if (_status == GameStatus.playing) {
      setState(() {
        _status = GameStatus.paused;
      });
    } else if (_status == GameStatus.paused) {
      setState(() {
        _status = GameStatus.playing;
        _lastElapsed = Duration.zero; // Prevent frame delta spike
      });
    }
  }

  void _openLeaderboard() {
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
    final double gap = (skyH * 0.28).clamp(135.0, 185.0);
    const double minPipe = 45.0;
    final double available =
        (skyH - gap - (minPipe * 2)).clamp(20.0, double.infinity);
    final double top = minPipe + _random.nextDouble() * available;

    pipe.topHeight = top;
    pipe.gapHeight = gap;
    pipe.passed = false;
  }

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

  void _updateGame(double dt) {
    _worldTime += dt;

    // Update particle systems
    _flapRings.removeWhere((ring) => !ring.update(dt));
    _particles.removeWhere((p) => !p.update(dt));

    // Ground & clouds scroll
    if (_status != GameStatus.gameOver) {
      _groundScroll = (_groundScroll + _pipeSpeed * dt) % 24.0;
      _cloudScroll = (_cloudScroll + 20.0 * dt) % 300.0;
    }

    // Score pop animation decay
    if (_scoreScale > 1.0) {
      _scoreScale = (_scoreScale - dt * 2.0).clamp(1.0, 1.4);
    }

    switch (_status) {
      case GameStatus.ready:
        _readyHoverTime += dt;
        _birdY = (_skyHeight * 0.44) + sin(_readyHoverTime * 5.0) * 8.0;
        _rotation = 0.0;
        _velocity = 0.0;
        break;

      case GameStatus.playing:
        // Bird physics
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

        // Pipe movement & recycling
        for (final pipe in _pipes) {
          pipe.x -= _pipeSpeed * dt;

          if (!pipe.passed && (_birdX > pipe.x + (_pipeWidth / 2))) {
            pipe.passed = true;
            _score++;
            _scoreScale = 1.35;
            HapticFeedback.lightImpact();

            // Burst score sparkle particles
            _burstSparkles(_birdX + 20, _birdY, const Color(0xFFFFD700));

            if (_score > _bestScore) {
              _bestScore = _score;
              _isNewHighScore = true;
              _saveBestScore(_bestScore);
            }
          }

          if (pipe.x < -_pipeWidth - 10.0) {
            final double rightmostX = _pipes.map((p) => p.x).reduce(max);
            pipe.x = rightmostX + _pipeSpacing;
            _randomizePipe(pipe, _skyHeight);
          }
        }

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

  void _checkCollisions() {
    final double birdLeft = _birdX - (_birdHitboxW / 2);
    final double birdRight = _birdX + (_birdHitboxW / 2);
    final double birdTop = _birdY - (_birdHitboxH / 2);
    final double birdBottom = _birdY + (_birdHitboxH / 2);

    if (birdTop <= 0) {
      _triggerGameOver();
      return;
    }

    if (birdBottom >= _skyHeight) {
      _birdY = _skyHeight - (_birdHitboxH / 2);
      _triggerGameOver();
      return;
    }

    for (final pipe in _pipes) {
      final double pipeLeft = pipe.x + 4.0;
      final double pipeRight = pipe.x + _pipeWidth - 4.0;

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
        _jump();
        break;
      case GameStatus.playing:
        _jump();
        break;
      case GameStatus.paused:
        _togglePause();
        break;
      case GameStatus.gameOver:
        _restartGame();
        break;
    }
  }

  void _restartGame() {
    setState(() {
      _status = GameStatus.ready;
      _score = 0;
      _flapsThisGame = 0;
      _isNewHighScore = false;
      _velocity = 0.0;
      _rotation = 0.0;
      _readyHoverTime = 0.0;
      _birdY = _skyHeight * 0.44;
      _flapRings.clear();
      _particles.clear();
      _initPipes(_skyHeight, _arenaWidth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeData = EnvironmentThemeData.fromTheme(_currentTheme);

    return Scaffold(
      backgroundColor: const Color(0xFF1E242B),
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

            final double arenaW =
                availableWidth > 480.0 ? 440.0 : availableWidth;
            final double arenaH = availableHeight;
            final double groundH = (arenaH * 0.18).clamp(90.0, 140.0);
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

            return Center(
              child: Container(
                width: arenaW,
                height: arenaH,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Colors.black,
                  boxShadow: availableWidth > 480.0
                      ? const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 20,
                            spreadRadius: 4,
                            offset: Offset(0, 8),
                          )
                        ]
                      : null,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _handleUserInput,
                  child: Stack(
                    children: [
                      // Sky area with animated backgrounds
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: skyH,
                        child: _buildSky(themeData),
                      ),

                      // Obstacle pipes
                      for (final pipe in _pipes) ...[
                        Positioned(
                          left: pipe.x,
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
                          left: pipe.x,
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

                      // Particles & shockwave layer
                      Positioned.fill(
                        child: CustomPaint(
                          painter: ParticlePainter(
                            rings: _flapRings,
                            particles: _particles,
                          ),
                        ),
                      ),

                      // Bird character
                      Positioned(
                        left: _birdX - (_birdVisualSize / 2),
                        top: _birdY - (_birdVisualSize / 2),
                        child: MyBird(
                          rotation: _rotation,
                          width: _birdVisualSize,
                          height: _birdVisualSize,
                          skin: _currentSkin,
                        ),
                      ),

                      // Ground
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: groundH,
                        child: _buildGround(arenaW, groundH, themeData),
                      ),

                      // Quick Control HUD (Top Bar)
                      Positioned(
                        top: 14,
                        left: 12,
                        right: 12,
                        child: _buildTopControlBar(themeData),
                      ),

                      // In-Game Live Score HUD
                      if (_status == GameStatus.playing ||
                          _status == GameStatus.paused)
                        Positioned(
                          top: 60,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Transform.scale(
                              scale: _scoreScale,
                              child: Text(
                                '$_score',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(2, 3),
                                      blurRadius: 4,
                                      color: Colors.black87,
                                    ),
                                    Shadow(
                                      offset: Offset(-1, -1),
                                      blurRadius: 1,
                                      color: Colors.black45,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Ready prompt overlay
                      if (_status == GameStatus.ready) _buildReadyOverlay(),

                      // Paused overlay
                      if (_status == GameStatus.paused) _buildPausedOverlay(),

                      // Game over dialog overlay
                      if (_status == GameStatus.gameOver)
                        _buildGameOverOverlay(),
                    ],
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

        // Center Pause Button (when playing)
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
          const SizedBox(width: 40),

        // Right side: Skin Picker & Theme Toggle
        Row(
          children: [
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
        color: Colors.black.withValues(alpha: 0.45),
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
      double arenaW, double groundH, EnvironmentThemeData themeData) {
    return Column(
      children: [
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: themeData.grassColor,
            border: Border(
              top: BorderSide(color: themeData.grassBorder, width: 2),
              bottom: BorderSide(
                  color: Color.lerp(themeData.grassBorder, Colors.black, 0.3)!,
                  width: 2),
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: themeData.soilColor,
            child: ClipRect(
              child: CustomPaint(
                painter: _GroundStripePainter(
                  offset: _groundScroll,
                  stripeColor: themeData.stripeColor,
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
        color: Colors.black.withValues(alpha: 0.15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF09030),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'FLAPPY BIRD',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Instructions Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                children: [
                  const Text(
                    'TAP OR PRESS SPACE TO FLY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Dodge pipes • Collect medals • Rule the leaderboard!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFFFE082),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Hotkeys pill
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      _buildKeyBadge('[SPACE] Fly'),
                      _buildKeyBadge('[P] Pause'),
                      _buildKeyBadge('[L] Ranks'),
                      _buildKeyBadge('[T] Theme'),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(flex: 3),

            // Best Score & Leaderboard Action Button
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                if (_bestScore > 0)
                  Text(
                    'BEST SCORE: $_bestScore',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          offset: Offset(0, 2),
                          color: Colors.black87,
                        ),
                      ],
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _openLeaderboard,
                  icon: const Icon(Icons.emoji_events, size: 16),
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
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
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
        color: Colors.black.withValues(alpha: 0.65),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFDED895),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF558022), width: 4),
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
                    color: Color(0xFF333333),
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
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _openLeaderboard,
                  icon: const Icon(Icons.emoji_events),
                  label: const Text(
                    'LEADERBOARD',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF09030),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(180, 44),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _restartGame,
                  child: const Text(
                    'QUIT TO MENU',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF706733),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFDED895),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF558022), width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 16,
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
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Scoreboard inner card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F3D0),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFFB8AE67), width: 2),
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
                                    color: Color(0xFF706733),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _buildMedalBadge(_score),
                              ],
                            ),
                            Container(
                              width: 2,
                              height: 50,
                              color: const Color(0xFFB8AE67),
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
                                        color: Color(0xFF706733),
                                      ),
                                    ),
                                    Text(
                                      '$_score',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black87,
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
                                        color: Color(0xFF706733),
                                      ),
                                    ),
                                    Text(
                                      '$_bestScore',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black87,
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
                              color: const Color(0xFFE8F5E9),
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
                                    color: Color(0xFF2E7D32),
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
                        icon: const Icon(Icons.emoji_events, size: 18),
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
                          color: Color(0xFF554A18),
                        ),
                      ),
                    )
                  else
                    const Text(
                      'or press Space to restart',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF706733),
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
          color: Colors.grey.shade400,
        ),
        child: const Icon(Icons.lock_outline, size: 22, color: Colors.white70),
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

class _GroundStripePainter extends CustomPainter {
  final double offset;
  final Color stripeColor;

  const _GroundStripePainter({
    required this.offset,
    required this.stripeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = stripeColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const double stripeGap = 24.0;
    final double startX = -stripeGap + (-offset % stripeGap);

    for (double x = startX; x < size.width + stripeGap; x += stripeGap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + 16, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GroundStripePainter oldDelegate) {
    return oldDelegate.offset != offset ||
        oldDelegate.stripeColor != stripeColor;
  }
}

class _CloudPainter extends CustomPainter {
  final double offset;
  final Color cloudColor;

  const _CloudPainter({
    required this.offset,
    required this.cloudColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cloudColor
      ..style = PaintingStyle.fill;

    const double spacing = 160.0;
    const double cloudW = 85.0;
    const double cloudH = 32.0;
    final double startX = -cloudW - (offset % spacing);

    for (double x = startX; x < size.width + spacing; x += spacing) {
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - cloudH - 24.0, cloudW, cloudH),
        const Radius.circular(16),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) {
    return oldDelegate.offset != offset || oldDelegate.cloudColor != cloudColor;
  }
}
