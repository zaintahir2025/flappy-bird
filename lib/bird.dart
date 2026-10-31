// Flutter Material Design library for rendering widgets, transforms, and image filters
import 'package:flutter/material.dart';

/// Enumeration of all selectable bird skins in the game.
enum BirdSkin {
  classic,
  phoenix,
  cyber,
  gold,
}

/// Holds visual metadata, GPU shader color filtering, and particle colors for each bird skin.
class BirdSkinData {
  // Enum identifier for the skin
  final BirdSkin skin;

  // Display label shown in the UI HUD (e.g., 'CLASSIC', 'PHOENIX')
  final String label;

  // Color applied to the base sprite via Flutter's ColorFiltered widget (null if natural classic colors)
  final Color? colorFilter;

  // GPU blend mode used to combine the filter color with the original pixel artwork
  final BlendMode blendMode;

  // Color emitted by shockwave rings, feather bursts, and jump sparks
  final Color particleColor;

  // Optional ambient glow color behind the bird
  final Color? glowColor;

  // Icon representing this skin on the skin-selector button
  final IconData icon;

  // Constant constructor
  const BirdSkinData({
    required this.skin,
    required this.label,
    required this.particleColor,
    required this.icon,
    this.colorFilter,
    this.glowColor,
    this.blendMode = BlendMode.srcATop,
  });

  /// Classic retro yellow bird using the untouched original sprite pixels.
  static const BirdSkinData classic = BirdSkinData(
    skin: BirdSkin.classic,
    label: 'CLASSIC',
    particleColor: Color(0xFFFFD54F),
    icon: Icons.flight_rounded,
    colorFilter: null,
    glowColor: null,
  );

  /// Phoenix fiery bird: fiery red-orange hues with crimson jump sparks and warm ember glow.
  static const BirdSkinData phoenix = BirdSkinData(
    skin: BirdSkin.phoenix,
    label: 'PHOENIX',
    particleColor: Color(0xFFFF3D00),
    icon: Icons.local_fire_department_rounded,
    colorFilter: Color(0xFFFF3D00),
    glowColor: Color(0x66FF3D00),
    blendMode: BlendMode.color,
  );

  /// Cyber bird: electric neon-cyan hues with cyan energy particles and cyber glow.
  static const BirdSkinData cyber = BirdSkinData(
    skin: BirdSkin.cyber,
    label: 'CYBER',
    particleColor: Color(0xFF00E5FF),
    icon: Icons.electric_bolt_rounded,
    colorFilter: Color(0xFF00E5FF),
    glowColor: Color(0x6600E5FF),
    blendMode: BlendMode.color,
  );

  /// Golden champion bird: shimmering gold metallic sheen awarded to high scorers.
  static const BirdSkinData gold = BirdSkinData(
    skin: BirdSkin.gold,
    label: 'GOLDEN',
    particleColor: Color(0xFFFFD700),
    icon: Icons.military_tech_rounded,
    colorFilter: Color(0xFFFFB300),
    glowColor: Color(0x77FFD700),
    blendMode: BlendMode.color,
  );

  /// Factory helper to retrieve a BirdSkinData configuration given a BirdSkin enum value.
  static BirdSkinData fromSkin(BirdSkin skin) {
    switch (skin) {
      case BirdSkin.classic:
        return classic;
      case BirdSkin.phoenix:
        return phoenix;
      case BirdSkin.cyber:
        return cyber;
      case BirdSkin.gold:
        return gold;
    }
  }
}

/// The visual widget responsible for drawing the flyer, applying skin shaders,
/// rendering trailing aerodynamic wind streams, and animating flap squash-and-stretch.
class MyBird extends StatelessWidget {
  // Rotation angle in radians (negative = nose tilted up on flap; positive = nose tilted down in dive)
  final double rotation;

  // Width of the bird's rendered box in logical pixels (default: 64.0)
  final double width;

  // Height of the bird's rendered box in logical pixels (default: 64.0)
  final double height;

  // The active bird skin variant
  final BirdSkin skin;

  // Elastic squash-and-stretch scale pulse triggered on flap jumps (1.0 = neutral)
  final double flapPulse;

  // Constructor with sensible defaults
  const MyBird({
    super.key,
    this.rotation = 0.0,
    this.width = 64.0,
    this.height = 64.0,
    this.skin = BirdSkin.classic,
    this.flapPulse = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // Look up the shader and color configuration for the current skin
    final skinData = BirdSkinData.fromSkin(skin);

    // Base widget loading the sprite from assets with high-fidelity filtering
    Widget birdImage = Image.asset(
      'images/flappybg.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      alignment: const Alignment(-0.034, 0.0), // Compensates for slight sprite center offset
    );

    // If the skin specifies a color filter (Phoenix, Cyber, Gold), apply it directly on the GPU
    if (skinData.colorFilter != null) {
      birdImage = ColorFiltered(
        colorFilter: ColorFilter.mode(
          skinData.colorFilter!,
          skinData.blendMode,
        ),
        child: birdImage,
      );
    }

    // Optional aura glow for Phoenix, Cyber, and Golden skins
    Widget body = birdImage;
    if (skinData.glowColor != null) {
      body = DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: skinData.glowColor!,
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: birdImage,
      );
    }

    // Apply squash-and-stretch flap bounce: expands horizontally and compresses vertically slightly on flap
    if (flapPulse != 1.0) {
      body = Transform.scale(
        scaleX: flapPulse,
        scaleY: 1.0 / (flapPulse * 0.95 + 0.05),
        alignment: Alignment.center,
        child: body,
      );
    }

    // Constrain the bird to its visual dimensions, isolate GPU layer with RepaintBoundary,
    // and draw aerodynamic flight jetstream trails
    return RepaintBoundary(
      child: SizedBox(
        width: width + 24.0,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerRight,
          children: [
            // Aerodynamic wind jetstream ribbon trailing behind the flyer
            Positioned(
              left: 0,
              top: height * 0.25,
              width: 32.0,
              height: height * 0.5,
              child: CustomPaint(
                painter: _AeroJetstreamPainter(
                  color: (skinData.glowColor ?? skinData.particleColor)
                      .withValues(alpha: 0.55),
                  pulse: flapPulse,
                  diveAngle: rotation,
                ),
              ),
            ),

            // Bird main character
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

/// Draws dynamic high-speed jetstream wind ribbons behind the flyer
class _AeroJetstreamPainter extends CustomPainter {
  final Color color;
  final double pulse;
  final double diveAngle;

  const _AeroJetstreamPainter({
    required this.color,
    required this.pulse,
    required this.diveAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          color,
          color.withValues(alpha: 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2.4 * pulse
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double yOffset = (diveAngle * 8.0).clamp(-12.0, 12.0);

    // Upper wingtip trail
    final path1 = Path()
      ..moveTo(size.width, size.height * 0.35 + yOffset)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.35 + yOffset - 4,
        0,
        size.height * 0.30 + yOffset,
      );
    canvas.drawPath(path1, trailPaint);

    // Lower wingtip trail
    final path2 = Path()
      ..moveTo(size.width, size.height * 0.65 + yOffset)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.65 + yOffset + 4,
        4,
        size.height * 0.70 + yOffset,
      );
    canvas.drawPath(path2, trailPaint);
  }

  @override
  bool shouldRepaint(covariant _AeroJetstreamPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.pulse != pulse ||
        oldDelegate.diveAngle != diveAngle;
  }
}
