// Dart math library for trigonometric functions (sin, cos, pi) and random generators
import 'dart:math';

// Flutter Material Design library for GPU 2D Canvas rendering and color manipulation
import 'package:flutter/material.dart';

// Game models for biomes, power-ups, and skin configs
import 'game_models.dart';

// =============================================================================
// 1. DYNAMIC FLAP & JUMP PARTICLES
// =============================================================================

/// Represents an expanding circular shockwave ripple spawned behind the bird on each jump.
class FlapRing {
  final double x;
  final double y;
  double radius;
  double opacity;
  final Color color;

  FlapRing({
    required this.x,
    required this.y,
    this.radius = 10.0,
    this.opacity = 0.8,
    this.color = Colors.white,
  });

  bool update(double dt) {
    radius += 130.0 * dt;
    opacity -= 1.8 * dt;
    return opacity > 0.0;
  }
}

/// Represents an individual flying spark, floating feather, contrail drop, or coin fragment.
class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double opacity;
  Color color;
  final ParticleTrailType trailType;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.opacity = 1.0,
    this.trailType = ParticleTrailType.feathers,
  });

  bool update(double dt) {
    x += vx * dt;
    y += vy * dt;

    switch (trailType) {
      case ParticleTrailType.fireEmbers:
      case ParticleTrailType.shadowSmoke:
        vy -= 90.0 * dt; // Fire and smoke drift upwards
        opacity -= 1.4 * dt;
        break;
      case ParticleTrailType.frostMist:
      case ParticleTrailType.stardust:
      case ParticleTrailType.prismaticGlow:
        vy += 40.0 * dt; // Gentle float
        opacity -= 1.3 * dt;
        break;
      case ParticleTrailType.lightningArcs:
      case ParticleTrailType.digitalSparks:
        vx += (Random().nextDouble() - 0.5) * 60.0;
        opacity -= 2.2 * dt; // Fast jitter
        break;
      case ParticleTrailType.feathers:
        vy += 220.0 * dt; // Standard gravity fall
        opacity -= 1.5 * dt;
        break;
    }

    return opacity > 0.0;
  }
}

// =============================================================================
// 2. AMBIENT ENVIRONMENTAL PARTICLES (7 WORLDS)
// =============================================================================

/// Ambient atmospheric particle floating across the screen according to the active world.
class AmbientParticle {
  double x;
  double y;
  double speedX;
  double speedY;
  double size;
  double phase;
  final Color color;

  AmbientParticle({
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.phase,
    required this.color,
  });

  static List<AmbientParticle> generateForWorld(WorldBiome biome, double arenaW, double arenaH) {
    final rand = Random();
    const count = 18;

    return List.generate(count, (index) {
      final x = rand.nextDouble() * arenaW;
      final y = rand.nextDouble() * arenaH;
      final phase = rand.nextDouble() * pi * 2;

      switch (biome) {
        case WorldBiome.sunriseValley:
          return AmbientParticle(
            x: x,
            y: y,
            speedX: -20.0 - rand.nextDouble() * 30.0,
            speedY: 10.0 + sin(phase) * 12.0,
            size: 2.5 + rand.nextDouble() * 2.5,
            phase: phase,
            color: Color.lerp(const Color(0xFFFFF176), const Color(0xFF81C784), rand.nextDouble())!,
          );
        case WorldBiome.neonCity:
          return AmbientParticle(
            x: x,
            y: y,
            speedX: -50.0 - rand.nextDouble() * 40.0,
            speedY: (rand.nextDouble() - 0.5) * 20.0,
            size: 2.0 + rand.nextDouble() * 2.0,
            phase: phase,
            color: rand.nextBool() ? const Color(0xFF00E5FF) : const Color(0xFFFF007F),
          );
        case WorldBiome.enchantedForest:
          return AmbientParticle(
            x: x,
            y: y,
            speedX: -15.0 - rand.nextDouble() * 20.0,
            speedY: -10.0 + sin(phase) * 25.0,
            size: 3.0 + rand.nextDouble() * 3.0,
            phase: phase,
            color: const Color(0xFFB2FF59),
          );
        case WorldBiome.frozenKingdom:
          return AmbientParticle(
            x: x,
            y: y,
            speedX: -30.0 - rand.nextDouble() * 30.0,
            speedY: 40.0 + rand.nextDouble() * 35.0,
            size: 2.0 + rand.nextDouble() * 3.5,
            phase: phase,
            color: const Color(0xFFE1F5FE),
          );
        case WorldBiome.cosmicGalaxy:
          return AmbientParticle(
            x: x,
            y: y,
            speedX: -10.0 - rand.nextDouble() * 15.0,
            speedY: (rand.nextDouble() - 0.5) * 10.0,
            size: 1.5 + rand.nextDouble() * 2.5,
            phase: phase,
            color: Color.lerp(const Color(0xFFEA80FC), const Color(0xFF80D8FF), rand.nextDouble())!,
          );
        case WorldBiome.volcanicSkies:
          return AmbientParticle(
            x: x,
            y: y,
            speedX: -25.0 - rand.nextDouble() * 35.0,
            speedY: -35.0 - rand.nextDouble() * 45.0, // Upward rising magma embers
            size: 2.0 + rand.nextDouble() * 3.0,
            phase: phase,
            color: rand.nextBool() ? const Color(0xFFFF3D00) : const Color(0xFFFFAB00),
          );
        case WorldBiome.dreamland:
          return AmbientParticle(
            x: x,
            y: y,
            speedX: -15.0 - rand.nextDouble() * 20.0,
            speedY: sin(phase) * 20.0,
            size: 3.0 + rand.nextDouble() * 3.0,
            phase: phase,
            color: Color.lerp(const Color(0xFFF48FB1), const Color(0xFFCE93D8), rand.nextDouble())!,
          );
      }
    });
  }

  void update(double dt, double arenaW, double arenaH) {
    x += speedX * dt;
    y += speedY * dt;
    phase += dt * 2.0;

    // Wrap around screen boundaries
    if (x < -20) x = arenaW + 20;
    if (x > arenaW + 20) x = -20;
    if (y < -20) y = arenaH + 20;
    if (y > arenaH + 20) y = -20;
  }
}

// =============================================================================
// 3. COLLECTIBLES & POPUP TEXTS
// =============================================================================

/// Collectible Sky Gem floating in the center of gate openings.
class FloatingGem {
  double x;
  double y;
  final double baseY;
  double hoverTime = 0.0;
  bool collected = false;
  final int value;

  FloatingGem({
    required this.x,
    required this.baseY,
    this.value = 2,
  }) : y = baseY;

  void update(double dt) {
    hoverTime += dt;
    y = baseY + sin(hoverTime * 5.0) * 7.0;
  }
}

/// Floating combat-style text for combo notifications and score milestones.
class FloatingPopupText {
  double x;
  double y;
  final String text;
  final Color color;
  double opacity = 1.0;
  double scale = 1.25;

  FloatingPopupText({
    required this.x,
    required this.y,
    required this.text,
    required this.color,
  });

  bool update(double dt) {
    y -= 45.0 * dt;
    opacity -= 1.1 * dt;
    if (scale > 1.0) {
      scale = (scale - dt * 1.5).clamp(1.0, 1.4);
    }
    return opacity > 0.0;
  }
}

/// Procedural night star definition.
class NightStar {
  final double xRatio;
  final double yRatio;
  final double baseRadius;
  double twinklePhase;
  final double twinkleSpeed;

  NightStar({
    required this.xRatio,
    required this.yRatio,
    required this.baseRadius,
    required this.twinklePhase,
    required this.twinkleSpeed,
  });

  static List<NightStar> generate(int count) {
    final random = Random(42);
    return List.generate(count, (index) {
      return NightStar(
        xRatio: random.nextDouble(),
        yRatio: random.nextDouble() * 0.75,
        baseRadius: 1.0 + random.nextDouble() * 2.0,
        twinklePhase: random.nextDouble() * pi * 2,
        twinkleSpeed: 2.0 + random.nextDouble() * 4.0,
      );
    });
  }
}

// =============================================================================
// 4. MASTER GPU PARTICLE PAINTER
// =============================================================================

/// High-performance GPU painter that renders shockwaves, particles, power-up items,
/// floating gems, ambient particles, and combo texts.
class ParticlePainter extends CustomPainter {
  final List<FlapRing> rings;
  final List<Particle> particles;
  final List<FloatingGem> gems;
  final List<PowerUpItem> powerUps;
  final List<AmbientParticle> ambientParticles;
  final List<FloatingPopupText> floatingTexts;

  const ParticlePainter({
    required this.rings,
    required this.particles,
    this.gems = const [],
    this.powerUps = const [],
    this.ambientParticles = const [],
    this.floatingTexts = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw ambient environmental particles
    for (final ap in ambientParticles) {
      final double glowAlpha = 0.4 + 0.4 * sin(ap.phase);
      final pPaint = Paint()
        ..color = ap.color.withValues(alpha: glowAlpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(ap.x, ap.y), ap.size, pPaint);
    }

    // 2. Draw expanding shockwave rings
    for (final ring in rings) {
      final ringPaint = Paint()
        ..color = ring.color.withValues(alpha: ring.opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset(ring.x, ring.y), ring.radius, ringPaint);
    }

    // 3. Draw active bird trail particles
    for (final p in particles) {
      final pPaint = Paint()
        ..color = p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      if (p.trailType == ParticleTrailType.lightningArcs) {
        // Draw tiny spark jagged diamond
        canvas.drawRect(
          Rect.fromCenter(center: Offset(p.x, p.y), width: p.size * 1.5, height: p.size * 0.8),
          pPaint,
        );
      } else {
        canvas.drawCircle(Offset(p.x, p.y), p.size, pPaint);
      }
    }

    // 4. Draw collectible Sky Gems with luminous diamond glow
    for (final gem in gems) {
      if (gem.collected) continue;

      final gemCenter = Offset(gem.x, gem.y);
      const double gemR = 12.0;

      // Outer luminous glow
      final glowPaint = Paint()
        ..color = const Color(0x66FFD700)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(gemCenter, gemR + 3, glowPaint);

      // Diamond path
      final path = Path()
        ..moveTo(gemCenter.dx, gemCenter.dy - gemR)
        ..lineTo(gemCenter.dx + gemR, gemCenter.dy)
        ..lineTo(gemCenter.dx, gemCenter.dy + gemR)
        ..lineTo(gemCenter.dx - gemR, gemCenter.dy)
        ..close();

      // Shiny Gold Gradient Fill
      final gemPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF9C4),
            Color(0xFFFFD54F),
            Color(0xFFFFB300),
          ],
        ).createShader(Rect.fromCircle(center: gemCenter, radius: gemR))
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, gemPaint);

      // Inner facet highlight
      final facetPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawLine(
        Offset(gemCenter.dx - 4, gemCenter.dy - 4),
        Offset(gemCenter.dx + 4, gemCenter.dy + 4),
        facetPaint,
      );
    }

    // 5. Draw collectible Power-Up Orbs
    for (final pup in powerUps) {
      if (pup.collected) continue;

      final center = Offset(pup.x, pup.y);
      const double orbR = 14.0;
      final pupData = PowerUpData.of(pup.type);

      // Luminous pulsing aura
      final haloPaint = Paint()
        ..color = pupData.color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(center, orbR + 4, haloPaint);

      // Outer energy bubble
      final bubblePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white,
            pupData.color,
            Color.lerp(pupData.color, Colors.black, 0.4)!,
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: orbR))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, orbR, bubblePaint);

      // Rotating orbital ring
      final ringPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawOval(
        Rect.fromCenter(center: center, width: orbR * 2.4, height: orbR * 0.9),
        ringPaint,
      );
    }

    // 6. Draw floating combo / bonus popup texts
    for (final item in floatingTexts) {
      final textSpan = TextSpan(
        text: item.text,
        style: TextStyle(
          fontSize: 14 * item.scale,
          fontWeight: FontWeight.w900,
          color: item.color.withValues(alpha: item.opacity.clamp(0.0, 1.0)),
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: item.opacity.clamp(0.0, 1.0) * 0.8),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(item.x - textPainter.width / 2, item.y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}

// =============================================================================
// 5. PARALLAX ENVIRONMENT & SCENERY PAINTERS
// =============================================================================

/// Dynamic celestial body & skyline painter adapting to all 7 worlds.
class WorldCelestialPainter extends CustomPainter {
  final WorldBiome biome;
  final double time;

  const WorldCelestialPainter({
    required this.biome,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final celestialCenter = Offset(size.width * 0.82, size.height * 0.16);

    switch (biome) {
      case WorldBiome.sunriseValley:
        // Radiant golden sun
        const double sunR = 26.0;
        final glowPaint = Paint()
          ..color = const Color(0x55FFE082)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
        canvas.drawCircle(celestialCenter, sunR + 12, glowPaint);

        final sunPaint = Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFFFFF9C4), Color(0xFFFFCA28)],
          ).createShader(Rect.fromCircle(center: celestialCenter, radius: sunR));
        canvas.drawCircle(celestialCenter, sunR, sunPaint);
        break;

      case WorldBiome.neonCity:
        // Digital holographic grid sun
        const double neonR = 24.0;
        final glow = Paint()
          ..color = const Color(0x66FF007F)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
        canvas.drawCircle(celestialCenter, neonR + 8, glow);

        final fill = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF007F), Color(0xFF7C4DFF)],
          ).createShader(Rect.fromCircle(center: celestialCenter, radius: neonR));
        canvas.drawCircle(celestialCenter, neonR, fill);
        break;

      case WorldBiome.enchantedForest:
        // Luminous emerald twilight crescent moon
        const double moonR = 20.0;
        final glow = Paint()
          ..color = const Color(0x44B2FF59)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawCircle(celestialCenter, moonR + 8, glow);

        final moon = Paint()..color = const Color(0xFFF1F8E9);
        canvas.drawCircle(celestialCenter, moonR, moon);
        final cutout = Paint()..color = const Color(0xFF134E5E);
        canvas.drawCircle(celestialCenter.translate(-6.0, -3.0), moonR * 0.9, cutout);
        break;

      case WorldBiome.frozenKingdom:
        // Pale crystalline sun with subzero halo
        const double iceR = 22.0;
        final glow = Paint()
          ..color = const Color(0x5580D8FF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
        canvas.drawCircle(celestialCenter, iceR + 10, glow);

        final icePaint = Paint()..color = const Color(0xFFE1F5FE);
        canvas.drawCircle(celestialCenter, iceR, icePaint);

        // Sun dogs / ring
        final ringPaint = Paint()
          ..color = const Color(0x4480D8FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(celestialCenter, iceR + 16, ringPaint);
        break;

      case WorldBiome.cosmicGalaxy:
        // Ringed cosmic planet
        const double planetR = 20.0;
        final glow = Paint()
          ..color = const Color(0x66EA80FC)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
        canvas.drawCircle(celestialCenter, planetR + 8, glow);

        final planetPaint = Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFFE040FB), Color(0xFF311B92)],
          ).createShader(Rect.fromCircle(center: celestialCenter, radius: planetR));
        canvas.drawCircle(celestialCenter, planetR, planetPaint);

        // Planetary rings
        final ringPaint = Paint()
          ..color = const Color(0xAAFFD700)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawOval(
          Rect.fromCenter(center: celestialCenter, width: planetR * 3.2, height: planetR * 0.9),
          ringPaint,
        );
        break;

      case WorldBiome.volcanicSkies:
        // Blood-red ash moon
        const double volR = 22.0;
        final glow = Paint()
          ..color = const Color(0x66FF3D00)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
        canvas.drawCircle(celestialCenter, volR + 10, glow);

        final volPaint = Paint()..color = const Color(0xFFFF5722);
        canvas.drawCircle(celestialCenter, volR, volPaint);
        break;

      case WorldBiome.dreamland:
        // Dreamy golden pastel moon
        const double dR = 22.0;
        final glow = Paint()
          ..color = const Color(0x55F48FB1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
        canvas.drawCircle(celestialCenter, dR + 8, glow);

        final dMoon = Paint()..color = const Color(0xFFFFF9C4);
        canvas.drawCircle(celestialCenter, dR, dMoon);
        final dCutout = Paint()..color = const Color(0xFF4A148C);
        canvas.drawCircle(celestialCenter.translate(-7.0, -3.0), dR * 0.92, dCutout);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant WorldCelestialPainter oldDelegate) =>
      oldDelegate.biome != biome || oldDelegate.time != time;
}

/// Parallax mountain / landscape ridge painter that gives the sky rich depth and a distinct scenic atmosphere.
class ParallaxMountainPainter extends CustomPainter {
  final double scrollOffset;
  final WorldBiome biome;
  final Color mountainColor;
  final Color ridgeColor;

  const ParallaxMountainPainter({
    required this.scrollOffset,
    required this.biome,
    required this.mountainColor,
    required this.ridgeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final mountainPaint = Paint()
      ..color = mountainColor
      ..style = PaintingStyle.fill;

    final ridgePaint = Paint()
      ..color = ridgeColor
      ..style = PaintingStyle.fill;

    // Distant mountain wave
    final path1 = Path();
    path1.moveTo(0, size.height);

    const double wavelength = 140.0;
    final double startX = -(scrollOffset % wavelength);

    for (double x = startX - wavelength; x <= size.width + wavelength; x += wavelength) {
      final double peakY = size.height - 48.0 - (sin(x * 0.02) * 16.0);
      path1.lineTo(x, peakY);
      path1.lineTo(x + wavelength * 0.5, size.height - 24.0);
    }
    path1.lineTo(size.width, size.height);
    path1.close();
    canvas.drawPath(path1, mountainPaint);

    // Closer foothills
    final path2 = Path();
    path2.moveTo(0, size.height);
    const double wavelength2 = 90.0;
    final double startX2 = -((scrollOffset * 1.5) % wavelength2);

    for (double x = startX2 - wavelength2; x <= size.width + wavelength2; x += wavelength2) {
      final double peakY = size.height - 28.0 - (cos(x * 0.03) * 10.0);
      path2.lineTo(x, peakY);
      path2.lineTo(x + wavelength2 * 0.5, size.height - 12.0);
    }
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, ridgePaint);
  }

  @override
  bool shouldRepaint(covariant ParallaxMountainPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.biome != biome ||
        oldDelegate.mountainColor != mountainColor ||
        oldDelegate.ridgeColor != ridgeColor;
  }
}
