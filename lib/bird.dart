import 'package:flutter/material.dart';

enum BirdSkin {
  classic,
  phoenix,
  cyber,
  gold,
}

class BirdSkinData {
  final BirdSkin skin;
  final String label;
  final Color? colorFilter;
  final BlendMode blendMode;
  final Color particleColor;
  final IconData icon;

  const BirdSkinData({
    required this.skin,
    required this.label,
    required this.particleColor,
    required this.icon,
    this.colorFilter,
    this.blendMode = BlendMode.srcATop,
  });

  static const BirdSkinData classic = BirdSkinData(
    skin: BirdSkin.classic,
    label: 'CLASSIC',
    particleColor: Color(0xFFFFD54F),
    icon: Icons.flight_rounded,
    colorFilter: null,
  );

  static const BirdSkinData phoenix = BirdSkinData(
    skin: BirdSkin.phoenix,
    label: 'PHOENIX',
    particleColor: Color(0xFFFF3D00),
    icon: Icons.local_fire_department_rounded,
    colorFilter: Color(0xFFFF3D00),
    blendMode: BlendMode.color,
  );

  static const BirdSkinData cyber = BirdSkinData(
    skin: BirdSkin.cyber,
    label: 'CYBER',
    particleColor: Color(0xFF00E5FF),
    icon: Icons.electric_bolt_rounded,
    colorFilter: Color(0xFF00E5FF),
    blendMode: BlendMode.color,
  );

  static const BirdSkinData gold = BirdSkinData(
    skin: BirdSkin.gold,
    label: 'GOLDEN',
    particleColor: Color(0xFFFFD700),
    icon: Icons.military_tech_rounded,
    colorFilter: Color(0xFFFFB300),
    blendMode: BlendMode.color,
  );

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

class MyBird extends StatelessWidget {
  final double rotation;
  final double width;
  final double height;
  final BirdSkin skin;

  const MyBird({
    super.key,
    this.rotation = 0.0,
    this.width = 64.0,
    this.height = 64.0,
    this.skin = BirdSkin.classic,
  });

  @override
  Widget build(BuildContext context) {
    final skinData = BirdSkinData.fromSkin(skin);

    Widget birdImage = Image.asset(
      'images/flappybg.png',
      fit: BoxFit.contain,
    );

    if (skinData.colorFilter != null) {
      birdImage = ColorFiltered(
        colorFilter: ColorFilter.mode(
          skinData.colorFilter!,
          skinData.blendMode,
        ),
        child: birdImage,
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: Transform.rotate(
        angle: rotation,
        alignment: Alignment.center,
        child: birdImage,
      ),
    );
  }
}
