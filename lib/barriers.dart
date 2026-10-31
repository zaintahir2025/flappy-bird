// Flutter Material Design library for drawing shapes, containers, and gradient borders
import 'package:flutter/material.dart';

// Game models for biome palettes
import 'game_models.dart';

/// The visual barrier obstacle widget, rendered as a high-tech Neo-Arcade Aero Pylon
/// with a luminous energy conduit, emitter capacitor tip, and metallic chassis paneling.
/// Adapts dynamically to each of the 7 world biomes.
class MyBarriers extends StatelessWidget {
  // Legacy size parameter supported for backward compatibility
  final double? size;

  // Main column shaft width in logical pixels (default: 68.0)
  final double width;

  // Full height of this barrier pylon in logical pixels
  final double? height;

  // If true, this is a bottom pylon rising from the ground; if false, it hangs from the ceiling
  final bool isBottom;

  // Highlight color for the energy core and pylon accents (varies with the active environment theme)
  final Color? primaryColor;

  // Secondary chassis body tone
  final Color? secondaryColor;

  // Dark chassis outline border color
  final Color? borderColor;

  // Optional active biome for environmental accents
  final WorldBiome? biome;

  // Constructor with sensible defaults
  const MyBarriers({
    super.key,
    this.size,
    this.width = 68.0,
    this.height,
    this.isBottom = true,
    this.primaryColor,
    this.secondaryColor,
    this.borderColor,
    this.biome,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the target height from height or size, ensuring it is non-negative
    final double pipeHeight =
        (height ?? size ?? 200.0).clamp(0.0, double.infinity);

    // If height is zero or negative, render an empty invisible widget
    if (pipeHeight <= 0) return const SizedBox.shrink();

    // Constant height of the protruding emitter capacitor cap
    const double capHeight = 24.0;

    // The capacitor cap protrudes by 10 pixels total (5px on left, 5px on right)
    const double capExtraWidth = 10.0;
    final double totalWidth = width + capExtraWidth;

    // The remaining vertical height of the main pylon shaft
    final double shaftHeight =
        (pipeHeight - capHeight).clamp(0.0, double.infinity);

    // Resolve color overrides, falling back to energetic neon aero hues
    final Color primary = primaryColor ?? const Color(0xFF00E5FF);
    final Color secondary = secondaryColor ?? const Color(0xFF0D47A1);
    final Color border = borderColor ?? const Color(0xFF0A192F);

    // 6-stop horizontal metallic chassis gradient for the main pylon
    final pylonChassisGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color.lerp(secondary, Colors.white, 0.35)!, // Specular rim
        Color.lerp(secondary, Colors.white, 0.12)!, // Upper bevel
        secondary,                                 // Base body
        Color.lerp(secondary, Colors.black, 0.20)!,// Shadow slope
        Color.lerp(secondary, Colors.black, 0.45)!,// Ambient occluded shadow
      ],
      stops: const [0.0, 0.15, 0.50, 0.85, 1.0],
    );

    // The protruding emitter capacitor cap facing the flight channel
    final capWidget = Container(
      width: totalWidth,
      height: capHeight.clamp(0.0, pipeHeight),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isBottom ? Alignment.topCenter : Alignment.bottomCenter,
          end: isBottom ? Alignment.bottomCenter : Alignment.topCenter,
          colors: [
            Color.lerp(primary, Colors.white, 0.40)!,
            primary,
            secondary,
          ],
        ),
        borderRadius: isBottom
            ? const BorderRadius.vertical(top: Radius.circular(8))
            : const BorderRadius.vertical(bottom: Radius.circular(8)),
        border: Border.all(color: border, width: 2.2),
        boxShadow: [
          // Luminous halo cast by the energy emitter into the gap
          BoxShadow(
            color: primary.withValues(alpha: 0.45),
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, isBottom ? -2 : 2),
          ),
        ],
      ),
      child: Center(
        // Central glowing emitter diode lens
        child: Container(
          width: totalWidth * 0.55,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: primary,
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );

    // The main vertical pylon body with glowing conduit and tech panel lines
    final shaftWidget = Container(
      width: width,
      height: shaftHeight,
      decoration: BoxDecoration(
        gradient: pylonChassisGradient,
        border: Border(
          left: BorderSide(color: border, width: 2.2),
          right: BorderSide(color: border, width: 2.2),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Central glowing energy conduit strip
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 6.0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      primary.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0.8),
                      primary.withValues(alpha: 0.3),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Subtle horizontal structural panel seamlines every 48px
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final count = (constraints.maxHeight / 48.0).floor();
                if (count <= 0) return const SizedBox.shrink();
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    count,
                    (_) => Container(
                      height: 1.5,
                      color: border.withValues(alpha: 0.4),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    // Assemble the complete obstacle pylon inside an isolated GPU RepaintBoundary
    return RepaintBoundary(
      child: SizedBox(
        width: totalWidth,
        height: pipeHeight,
        child: Stack(
          alignment: Alignment.center,
          children: isBottom
              ? [
                  // Cap on top of bottom pylon
                  Positioned(
                    top: 0,
                    child: capWidget,
                  ),
                  // Shaft beneath cap
                  Positioned(
                    top: capHeight,
                    bottom: 0,
                    child: shaftWidget,
                  ),
                ]
              : [
                  // Shaft above hanging cap
                  Positioned(
                    top: 0,
                    bottom: capHeight,
                    child: shaftWidget,
                  ),
                  // Cap at bottom of hanging pylon
                  Positioned(
                    bottom: 0,
                    child: capWidget,
                  ),
                ],
        ),
      ),
    );
  }
}
