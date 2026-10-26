import 'package:flutter/material.dart';

enum EnvironmentTheme {
  day,
  sunset,
  midnight,
}

class EnvironmentThemeData {
  final EnvironmentTheme theme;
  final String label;
  final IconData icon;
  final List<Color> skyGradient;
  final Color cloudColor;
  final Color pipePrimary;
  final Color pipeSecondary;
  final Color pipeBorder;
  final Color grassColor;
  final Color grassBorder;
  final Color soilColor;
  final Color stripeColor;
  final bool hasStars;
  final bool hasMoon;

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
