import 'dart:math';
import 'package:flutter/material.dart';

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
    vy += 300.0 * dt; // gravity
    opacity -= 1.6 * dt;
    return opacity > 0.0;
  }
}

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
        yRatio: random.nextDouble() * 0.75, // top 75% of sky
        baseRadius: 1.0 + random.nextDouble() * 2.0,
        twinklePhase: random.nextDouble() * pi * 2,
        twinkleSpeed: 2.0 + random.nextDouble() * 4.0,
      );
    });
  }
}

class ParticlePainter extends CustomPainter {
  final List<FlapRing> rings;
  final List<Particle> particles;

  const ParticlePainter({
    required this.rings,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw expanding flap shockwave rings
    for (final ring in rings) {
      final ringPaint = Paint()
        ..color = Colors.white.withValues(alpha: ring.opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset(ring.x, ring.y), ring.radius, ringPaint);
    }

    // Draw bursting feather / sparkle particles
    for (final p in particles) {
      final pPaint = Paint()
        ..color = p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.size, pPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}

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

    // Crescent Moon
    final moonCenter = Offset(size.width * 0.82, size.height * 0.16);
    const double moonR = 18.0;

    final glowPaint = Paint()
      ..color = const Color(0x33FFF9C4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(moonCenter, moonR + 6, glowPaint);

    final moonPaint = Paint()..color = const Color(0xFFFFFDE7);
    canvas.drawCircle(moonCenter, moonR, moonPaint);

    // Dark cutout to create crescent effect
    final cutoutPaint = Paint()..color = const Color(0xFF0F1524);
    canvas.drawCircle(
      moonCenter.translate(-6.0, -3.0),
      moonR * 0.92,
      cutoutPaint,
    );
  }

  @override
  bool shouldRepaint(covariant StarsPainter oldDelegate) => true;
}
