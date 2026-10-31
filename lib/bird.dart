// Math library for wing flapping sinusoidal calculations and angles
import 'dart:math';

// Flutter Material Design library for rendering widgets, transforms, and image filters
import 'package:flutter/material.dart';

// Game models for 14 bird skin configurations and rarities
import 'game_models.dart';

/// Legacy enum maintained for backward compatibility, mapped directly to BirdSkinId.
enum BirdSkin {
  classic,
  phoenix,
  cyber,
  gold,
}

/// The visual widget responsible for drawing the flyer, applying skin shaders,
/// rendering trailing aerodynamic wind streams, shield energy bubbles,
/// ghost phase shift translucency, and animating flap squash-and-stretch.
class MyBird extends StatelessWidget {
  // Rotation angle in radians (negative = nose tilted up on flap; positive = nose tilted down in dive)
  final double rotation;

  // Width of the bird's rendered box in logical pixels (default: 64.0)
  final double width;

  // Height of the bird's rendered box in logical pixels (default: 64.0)
  final double height;

  // Active flyer skin configuration
  final BirdSkinConfig skinConfig;

  // Elastic squash-and-stretch scale pulse triggered on flap jumps (1.0 = neutral)
  final double flapPulse;

  // True if the flyer currently possesses an active Energy Shield
  final bool hasShield;

  // True if the flyer is currently in Phase Shift / Ghost mode (intangible)
  final bool isGhost;

  // Wing flap animation cycle [0.0 .. 1.0]
  final double wingCycle;

  // Constructor with sensible defaults
  const MyBird({
    super.key,
    this.rotation = 0.0,
    this.width = 64.0,
    this.height = 64.0,
    required this.skinConfig,
    this.flapPulse = 1.0,
    this.hasShield = false,
    this.isGhost = false,
    this.wingCycle = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Base flyer sprite loaded from assets with medium filtering for pixel clarity
    Widget birdImage = Image.asset(
      'images/flappybg.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      alignment: const Alignment(-0.034, 0.0),
    );

    // 2. GPU Shader Color Filter
    if (skinConfig.shaderColor != null) {
      birdImage = ColorFiltered(
        colorFilter: ColorFilter.mode(
          skinConfig.shaderColor!,
          skinConfig.blendMode,
        ),
        child: birdImage,
      );
    }

    // 3. Optional ambient glow / aura
    Widget body = birdImage;
    if (skinConfig.glowColor != null) {
      body = DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: skinConfig.glowColor!,
              blurRadius: 18,
              spreadRadius: 3,
            ),
          ],
        ),
        child: birdImage,
      );
    }

    // 4. Wing flap procedural overlay
    // Dynamically draws custom articulated wings that flap up and down with wingCycle
    body = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        body,
        Positioned(
          left: width * 0.18,
          top: height * 0.28 + sin(wingCycle * pi * 2) * 5.0,
          child: CustomPaint(
            size: Size(width * 0.38, height * 0.28),
            painter: _WingPainter(
              color: skinConfig.shaderColor ?? const Color(0xFFFFD54F),
              wingAngle: sin(wingCycle * pi * 2) * 0.45,
            ),
          ),
        ),
      ],
    );

    // 5. Apply squash-and-stretch flap bounce
    if (flapPulse != 1.0) {
      body = Transform.scale(
        scaleX: flapPulse,
        scaleY: 1.0 / (flapPulse * 0.95 + 0.05),
        alignment: Alignment.center,
        child: body,
      );
    }

    // 6. Phase Shift (Ghost Mode) translucency & ethereal green shimmer
    if (isGhost) {
      body = Opacity(
        opacity: 0.55,
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Color(0xFF00E676),
            BlendMode.modulate,
          ),
          child: body,
        ),
      );
    }

    // 7. Energy Shield bubble encapsulation
    if (hasShield) {
      body = Stack(
        alignment: Alignment.center,
        children: [
          body,
          // Pulsing cyan plasma shield sphere
          Container(
            width: width + 18.0,
            height: height + 18.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.9),
                width: 2.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x6600E5FF),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
              gradient: const RadialGradient(
                colors: [
                  Color(0x2200E5FF),
                  Color(0x5500E5FF),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // 8. Flight jetstream trail and RepaintBoundary containment
    return RepaintBoundary(
      child: SizedBox(
        width: width + 30.0,
        height: height + 16.0,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerRight,
          children: [
            // Aerodynamic wind jetstream ribbon trailing behind the flyer
            Positioned(
              left: 0,
              top: height * 0.28,
              width: 34.0,
              height: height * 0.45,
              child: CustomPaint(
                painter: _WindTrailPainter(
                  trailColor: skinConfig.particleColor,
                  rotation: rotation,
                ),
              ),
            ),

            // The main flyer sprite with rotation transform
            Positioned(
              right: 0,
              width: width,
              height: height,
              child: Transform.rotate(
                angle: rotation,
                alignment: Alignment.center,
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for articulated wing flapping.
class _WingPainter extends CustomPainter {
  final Color color;
  final double wingAngle;

  const _WingPainter({
    required this.color,
    required this.wingAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width * 0.2, size.height * 0.5);
    canvas.rotate(wingAngle);

    final wingPaint = Paint()
      ..color = Color.lerp(color, Colors.white, 0.25)!
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Color.lerp(color, Colors.black, 0.35)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width * 0.6, -size.height * 0.8, size.width, -size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.6, 0, size.height * 0.2)
      ..close();

    canvas.drawPath(path, wingPaint);
    canvas.drawPath(path, borderPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WingPainter oldDelegate) =>
      oldDelegate.wingAngle != wingAngle || oldDelegate.color != color;
}

/// Custom painter that draws dual horizontal speed contrails tapering off behind the bird.
class _WindTrailPainter extends CustomPainter {
  final Color trailColor;
  final double rotation;

  const _WindTrailPainter({
    required this.trailColor,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          trailColor.withValues(alpha: 0.0),
          trailColor.withValues(alpha: 0.45),
          trailColor.withValues(alpha: 0.85),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;

    final double yOffset = (rotation * 8.0).clamp(-6.0, 6.0);

    // Upper wind stream
    final path1 = Path()
      ..moveTo(0, size.height * 0.3 - yOffset)
      ..lineTo(size.width, size.height * 0.3);
    canvas.drawPath(path1, trailPaint);

    // Lower wind stream
    final path2 = Path()
      ..moveTo(size.width * 0.25, size.height * 0.7 - yOffset)
      ..lineTo(size.width, size.height * 0.7);
    canvas.drawPath(path2, trailPaint);
  }

  @override
  bool shouldRepaint(covariant _WindTrailPainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.trailColor != trailColor;
}
