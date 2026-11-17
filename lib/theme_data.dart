// Flutter Material Design library for colors, gradients, and icon definitions
import 'package:flutter/material.dart';

/// Enumeration representing the three selectable dynamic environment themes.
enum EnvironmentTheme {
  day,
  sunset,
  midnight,
}

/// Holds all visual parameters, color palettes, and celestial configurations for an environment theme.
class EnvironmentThemeData {
  // Enum identifier for this theme
  final EnvironmentTheme theme;

  // Short display label shown in HUD toggles (e.g., 'DAY', 'SUNSET', 'NIGHT')
  final String label;

  // Icon displayed on the theme switcher button
  final IconData icon;

  // Vertical sky gradient color stops from top (sky zenith) to bottom (horizon)
  final List<Color> skyGradient;

  // Tint and opacity applied to scrolling background clouds
  final Color cloudColor;

  // Highlight color for the left side of 3D pipes
  final Color pipePrimary;

  // Shadow color for the right side of 3D pipes
  final Color pipeSecondary;

  // Dark border outline color for pipes
  final Color pipeBorder;

  // Surface grass color for the ground strip
  final Color grassColor;

  // Shadow outline border separating grass from sky
  final Color grassBorder;

  // Base earth/dirt color beneath the grass
  final Color soilColor;

  // Diagonal moving stripe color painted across the ground
  final Color stripeColor;

  // Whether to render the twinkling night starfield
  final bool hasStars;

  // Whether to render the crescent moon in the sky
  final bool hasMoon;

  // Immutable constructor configuring all theme attributes
  const EnvironmentThemeData({
    required this.theme,
    required this.label,
    required this.icon,
    required this.skyGradient,
    required this.cloudColor,
    required this.pipePrimary,
    required this.pipeSecondary,
    required this.pipeBorder,
    required this.grassColor,
    required this.grassBorder,
    required this.soilColor,
    required this.stripeColor,
    this.hasStars = false,
    this.hasMoon = false,
  });

  /// The classic retro Flappy Bird day theme: bright cyan skies, puffy white clouds, and green pipes.
  static const EnvironmentThemeData day = EnvironmentThemeData(
    theme: EnvironmentTheme.day,
    label: 'DAY',
    icon: Icons.wb_sunny_rounded,
    skyGradient: [
      Color(0xFF4EC0CA), // Classic Flappy cyan
      Color(0xFF71C5CF),
      Color(0xFF8AD1DA),
    ],
    cloudColor: Color(0x66FFFFFF),
    pipePrimary: Color(0xFF73BF2E),
    pipeSecondary: Color(0xFF558022),
    pipeBorder: Color(0xFF2E4E11),
    grassColor: Color(0xFF73BF2E),
    grassBorder: Color(0xFF558022),
    soilColor: Color(0xFFDED895),
    stripeColor: Color(0xFFC8BC70),
    hasStars: false,
    hasMoon: false,
  );

  /// Vibrant sunset theme: twilight purple to fiery coral gradients, amber pipes, and warm evening clouds.
  static const EnvironmentThemeData sunset = EnvironmentThemeData(
    theme: EnvironmentTheme.sunset,
    label: 'SUNSET',
    icon: Icons.wb_twilight_rounded,
    skyGradient: [
      Color(0xFFE65C40), // Radiant fiery crimson/amber
      Color(0xFFD35269),
      Color(0xFF7D4685),
    ],
    cloudColor: Color(0x44FFA07A),
    pipePrimary: Color(0xFFD97724),
    pipeSecondary: Color(0xFF9E4B0B),
    pipeBorder: Color(0xFF572704),
    grassColor: Color(0xFFB57022),
    grassBorder: Color(0xFF754511),
    soilColor: Color(0xFFC4A26C),
    stripeColor: Color(0xFFA6854F),
    hasStars: false,
    hasMoon: false,
  );

  /// Cyberpunk midnight theme: deep interstellar obsidian sky, glowing crescent moon, starfield, and cyan pipes.
  static const EnvironmentThemeData midnight = EnvironmentThemeData(
    theme: EnvironmentTheme.midnight,
    label: 'NIGHT',
    icon: Icons.nightlight_round,
    skyGradient: [
      Color(0xFF090D1A), // Deep interstellar obsidian
      Color(0xFF131C31),
      Color(0xFF1D2B4A),
    ],
    cloudColor: Color(0x2290CAF9),
    pipePrimary: Color(0xFF00E5FF), // Cyber neon glowing pipes
    pipeSecondary: Color(0xFF0091EA),
    pipeBorder: Color(0xFF004D40),
    grassColor: Color(0xFF1E3A2F),
    grassBorder: Color(0xFF0F1E18),
    soilColor: Color(0xFF2B3A42),
    stripeColor: Color(0xFF1F2B32),
    hasStars: true,
    hasMoon: true,
  );

  /// Helper factory mapping an EnvironmentTheme enum value to its corresponding theme data bundle.
  static EnvironmentThemeData fromTheme(EnvironmentTheme theme) {
    switch (theme) {
      case EnvironmentTheme.day:
        return day;
      case EnvironmentTheme.sunset:
        return sunset;
      case EnvironmentTheme.midnight:
        return midnight;
    }
  }
}
