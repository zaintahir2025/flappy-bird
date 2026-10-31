// Dart math library for trigonometric functions (sin, cos, pi) and random generators
import 'dart:math';

// Flutter Material Design library for GPU 2D Canvas rendering and color manipulation
import 'package:flutter/material.dart';

/// Represents an expanding circular shockwave ripple spawned behind the bird on each jump.
class FlapRing {
  final double x;
  final double y;
  double radius;
  double opacity;

  FlapRing({
    required this.x,
    required this.y,
    this.radius = 10.0,
    this.opacity = 0.8,
  });

  bool update(double dt) {
    radius += 120.0 * dt;
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

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.opacity = 1.0,
  });

  bool update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += 280.0 * dt;
    opacity -= 1.6 * dt;
    return opacity > 0.0;
  }
}

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

/// Represents a single procedurally placed star in the Midnight theme sky.
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

/// High-performance GPU painter that renders shockwaves, particles, floating gems, and combo text.
class ParticlePainter extends CustomPainter {
  final List<FlapRing> rings;
  final List<Particle> particles;
  final List<FloatingGem> gems;
  final List<FloatingPopupText> floatingTexts;

  const ParticlePainter({
    required this.rings,
    required this.particles,
    this.gems = const [],
    this.floatingTexts = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw expanding shockwave rings
    for (final ring in rings) {
      final ringPaint = Paint()
        ..color = Colors.white.withValues(alpha: ring.opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset(ring.x, ring.y), ring.radius, ringPaint);
    }

    // 2. Draw active particles
    for (final p in particles) {
      final pPaint = Paint()
        ..color = p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.size, pPaint);
    }

    // 3. Draw collectible Sky Gems with luminous diamond glow
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

    // 4. Draw floating combo / bonus popup texts
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

/// Low-level GPU painter that renders twinkling stars and glowing crescent moon.
class StarsPainter extends CustomPainter {
  final List<NightStar> stars;
  final double time;

  const StarsPainter({
    required this.stars,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final double brightness =
          0.3 + 0.7 * ((sin(star.twinklePhase + time * star.twinkleSpeed) + 1.0) / 2.0);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: brightness.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(star.xRatio * size.width, star.yRatio * size.height),
        star.baseRadius,
        paint,
      );
    }

    final moonCenter = Offset(size.width * 0.82, size.height * 0.16);
    const double moonR = 18.0;

    final glowPaint = Paint()
      ..color = const Color(0x33FFF9C4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(moonCenter, moonR + 6, glowPaint);

    final moonPaint = Paint()..color = const Color(0xFFFFFDE7);
    canvas.drawCircle(moonCenter, moonR, moonPaint);

    final cutoutPaint = Paint()..color = const Color(0xFF090D1A);
    canvas.drawCircle(
      moonCenter.translate(-6.0, -3.0),
      moonR * 0.92,
      cutoutPaint,
    );
  }

  @override
  bool shouldRepaint(covariant StarsPainter oldDelegate) => true;
}

/// Parallax mountain ridge painter that gives the sky rich depth and a distinct scenic atmosphere.
class ParallaxMountainPainter extends CustomPainter {
  final double scrollOffset;
  final Color mountainColor;
  final Color ridgeColor;

  const ParallaxMountainPainter({
    required this.scrollOffset,
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
        oldDelegate.mountainColor != mountainColor ||
        oldDelegate.ridgeColor != ridgeColor;
  }
}
