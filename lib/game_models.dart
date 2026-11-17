// Standard Dart library for JSON serialization, date math, and randomness
import 'dart:math';

// Flutter Material Design library for colors, icons, and UI metadata
import 'package:flutter/material.dart';

// =============================================================================
// 1. POWER-UPS & SPECIAL ABILITIES
// =============================================================================

/// Enumeration of collectible special abilities that spawn during active flight.
enum PowerUpType {
  shield,          // Protects the flyer from a single collision impact
  slowMotion,      // Temporarily reduces flight and obstacle speed by 40%
  magnet,          // Pulls nearby gems toward the bird automatically
  scoreMultiplier, // Doubles all gate clearances and gem points (2x)
  ghost,           // Allows passing through obstacles safely without collision
}

/// Metadata and visual definitions for each power-up ability.
class PowerUpData {
  final PowerUpType type;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final double durationSeconds;

  const PowerUpData({
    required this.type,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.durationSeconds,
  });

  static const Map<PowerUpType, PowerUpData> all = {
    PowerUpType.shield: PowerUpData(
      type: PowerUpType.shield,
      label: 'ENERGY SHIELD',
      description: 'Absorbs one collision impact without crashing.',
      icon: Icons.shield_rounded,
      color: Color(0xFF00E5FF),
      durationSeconds: 15.0,
    ),
    PowerUpType.slowMotion: PowerUpData(
      type: PowerUpType.slowMotion,
      label: 'TIME WARP',
      description: 'Slows down world physics by 40% for precision navigation.',
      icon: Icons.speed_rounded,
      color: Color(0xFF7C4DFF),
      durationSeconds: 8.0,
    ),
    PowerUpType.magnet: PowerUpData(
      type: PowerUpType.magnet,
      label: 'GEM MAGNET',
      description: 'Attracts all floating Sky Gems directly to your flyer.',
      icon: Icons.all_inclusive_rounded,
      color: Color(0xFFFFD600),
      durationSeconds: 10.0,
    ),
    PowerUpType.scoreMultiplier: PowerUpData(
      type: PowerUpType.scoreMultiplier,
      label: '2x MULTIPLIER',
      description: 'Doubles all points awarded from gates and gems.',
      icon: Icons.bolt_rounded,
      color: Color(0xFFFF9100),
      durationSeconds: 12.0,
    ),
    PowerUpType.ghost: PowerUpData(
      type: PowerUpType.ghost,
      label: 'PHASE SHIFT',
      description: 'Flyer becomes intangible, gliding safely through obstacles.',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFF00E676),
      durationSeconds: 6.0,
    ),
  };

  static PowerUpData of(PowerUpType type) => all[type]!;
}

/// Active power-up instance running on the player during gameplay.
class ActivePowerUp {
  final PowerUpType type;
  double remainingSeconds;
  final double totalSeconds;

  ActivePowerUp({
    required this.type,
    required this.remainingSeconds,
    required this.totalSeconds,
  });

  double get progress => (remainingSeconds / totalSeconds).clamp(0.0, 1.0);

  bool update(double dt) {
    remainingSeconds -= dt;
    return remainingSeconds > 0.0;
  }
}

/// A collectible power-up orb floating in the game world.
class PowerUpItem {
  double x;
  double y;
  final double baseY;
  final PowerUpType type;
  double hoverTime = 0.0;
  bool collected = false;

  PowerUpItem({
    required this.x,
    required this.baseY,
    required this.type,
  }) : y = baseY;

  void update(double dt) {
    hoverTime += dt;
    y = baseY + sin(hoverTime * 4.5) * 8.0;
  }
}

// =============================================================================
// 2. DYNAMIC WORLDS & BIOMES (7 UNIQUE WORLDS)
// =============================================================================

/// The 7 unlockable atmospheric game worlds.
enum WorldBiome {
  sunriseValley, // Warm morning hues, puffy golden clouds, lush aero pylons
  neonCity,      // Cyberpunk skyline, glowing obsidian pylons, neon grid
  enchantedForest,// Mystical twilight, emerald flora, floating fireflies
  frozenKingdom, // Glacial peaks, crystalline obstacles, falling snow
  cosmicGalaxy,  // Deep interstellar nebulae, starfields, cosmic pylons
  volcanicSkies, // Magma caldera, rising embers, obsidian pillars
  dreamland,     // Pastel cloudscape, floating sparkles, marshmallow pillars
}

/// Holds all visual palettes, ambient particle types, and progression requirements for a biome.
class WorldBiomeData {
  final WorldBiome biome;
  final String id;
  final String name;
  final String subtitle;
  final String description;
  final int unlockGems;
  final int unlockScore;
  final List<Color> skyGradient;
  final Color cloudColor;
  final Color pipePrimary;
  final Color pipeSecondary;
  final Color pipeBorder;
  final Color grassColor;
  final Color grassBorder;
  final Color soilColor;
  final Color stripeColor;
  final IconData icon;

  const WorldBiomeData({
    required this.biome,
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.unlockGems,
    required this.unlockScore,
    required this.skyGradient,
    required this.cloudColor,
    required this.pipePrimary,
    required this.pipeSecondary,
    required this.pipeBorder,
    required this.grassColor,
    required this.grassBorder,
    required this.soilColor,
    required this.stripeColor,
    required this.icon,
  });

  static const WorldBiomeData sunriseValley = WorldBiomeData(
    biome: WorldBiome.sunriseValley,
    id: 'sunrise_valley',
    name: 'Sunrise Valley',
    subtitle: 'Dawn of Flight',
    description: 'Golden morning skies with gentle updrafts and emerald terrain.',
    unlockGems: 0,
    unlockScore: 0,
    icon: Icons.wb_sunny_rounded,
    skyGradient: [
      Color(0xFF38A3A5),
      Color(0xFF57CC99),
      Color(0xFF80ED99),
    ],
    cloudColor: Color(0x66FFFFFF),
    pipePrimary: Color(0xFF2EC4B6),
    pipeSecondary: Color(0xFF011627),
    pipeBorder: Color(0xFF003840),
    grassColor: Color(0xFF57CC99),
    grassBorder: Color(0xFF22577A),
    soilColor: Color(0xFFE9D8A6),
    stripeColor: Color(0xFFD4B483),
  );

  static const WorldBiomeData neonCity = WorldBiomeData(
    biome: WorldBiome.neonCity,
    id: 'neon_city',
    name: 'Neon Cyber City',
    subtitle: 'Cyberpunk Metropol',
    description: 'Towering holographic skyscrapers and electric aero pylons.',
    unlockGems: 35,
    unlockScore: 15,
    icon: Icons.location_city_rounded,
    skyGradient: [
      Color(0xFF0F0C29),
      Color(0xFF302B63),
      Color(0xFF24243E),
    ],
    cloudColor: Color(0x33FF007F),
    pipePrimary: Color(0xFF00E5FF),
    pipeSecondary: Color(0xFF651FFF),
    pipeBorder: Color(0xFF0A0E2A),
    grassColor: Color(0xFF1B003A),
    grassBorder: Color(0xFFFF007F),
    soilColor: Color(0xFF140727),
    stripeColor: Color(0xFF2D0A4E),
  );

  static const WorldBiomeData enchantedForest = WorldBiomeData(
    biome: WorldBiome.enchantedForest,
    id: 'enchanted_forest',
    name: 'Enchanted Forest',
    subtitle: 'Mythic Canopy',
    description: 'Luminous flora and mystical floating fireflies in twilight.',
    unlockGems: 75,
    unlockScore: 30,
    icon: Icons.forest_rounded,
    skyGradient: [
      Color(0xFF134E5E),
      Color(0xFF235A53),
      Color(0xFF71B280),
    ],
    cloudColor: Color(0x44B2FFD6),
    pipePrimary: Color(0xFF00E676),
    pipeSecondary: Color(0xFF1B5E20),
    pipeBorder: Color(0xFF052B10),
    grassColor: Color(0xFF2E7D32),
    grassBorder: Color(0xFF1B5E20),
    soilColor: Color(0xFF3E2723),
    stripeColor: Color(0xFF271612),
  );

  static const WorldBiomeData frozenKingdom = WorldBiomeData(
    biome: WorldBiome.frozenKingdom,
    id: 'frozen_kingdom',
    name: 'Frozen Kingdom',
    subtitle: 'Glacial Heights',
    description: 'Brisk snowfall, crystalline obstacles, and aurora borealis.',
    unlockGems: 120,
    unlockScore: 45,
    icon: Icons.ac_unit_rounded,
    skyGradient: [
      Color(0xFF1A2980),
      Color(0xFF26D0CE),
      Color(0xFFB0F3F1),
    ],
    cloudColor: Color(0x77FFFFFF),
    pipePrimary: Color(0xFF80D8FF),
    pipeSecondary: Color(0xFF0091EA),
    pipeBorder: Color(0xFF01579B),
    grassColor: Color(0xFFE1F5FE),
    grassBorder: Color(0xFF81D4FA),
    soilColor: Color(0xFFB0BEC5),
    stripeColor: Color(0xFF90A4AE),
  );

  static const WorldBiomeData cosmicGalaxy = WorldBiomeData(
    biome: WorldBiome.cosmicGalaxy,
    id: 'cosmic_galaxy',
    name: 'Cosmic Galaxy',
    subtitle: 'Deep Void',
    description: 'Interstellar nebulas, planets, and gravitational anomalies.',
    unlockGems: 180,
    unlockScore: 60,
    icon: Icons.auto_awesome_rounded,
    skyGradient: [
      Color(0xFF05050A),
      Color(0xFF1A0B2E),
      Color(0xFF3B145E),
    ],
    cloudColor: Color(0x33DA70D6),
    pipePrimary: Color(0xFFFFD700),
    pipeSecondary: Color(0xFF9C27B0),
    pipeBorder: Color(0xFF1A032E),
    grassColor: Color(0xFF2D124D),
    grassBorder: Color(0xFFBA68C8),
    soilColor: Color(0xFF180A29),
    stripeColor: Color(0xFF331557),
  );

  static const WorldBiomeData volcanicSkies = WorldBiomeData(
    biome: WorldBiome.volcanicSkies,
    id: 'volcanic_skies',
    name: 'Volcanic Skies',
    subtitle: 'Magma Caldera',
    description: 'Molten rock conduits, fiery updrafts, and rising ash embers.',
    unlockGems: 250,
    unlockScore: 80,
    icon: Icons.local_fire_department_rounded,
    skyGradient: [
      Color(0xFF200101),
      Color(0xFF4A0E0E),
      Color(0xFF8B2500),
    ],
    cloudColor: Color(0x44FF3D00),
    pipePrimary: Color(0xFFFF5722),
    pipeSecondary: Color(0xFFBF360C),
    pipeBorder: Color(0xFF3E0A00),
    grassColor: Color(0xFF37474F),
    grassBorder: Color(0xFFFF3D00),
    soilColor: Color(0xFF212121),
    stripeColor: Color(0xFF424242),
  );

  static const WorldBiomeData dreamland = WorldBiomeData(
    biome: WorldBiome.dreamland,
    id: 'dreamland',
    name: 'Dreamland',
    subtitle: 'Pastel Cloudscape',
    description: 'Weightless pastel clouds, stardust sparkles, and candy pylons.',
    unlockGems: 350,
    unlockScore: 100,
    icon: Icons.cloud_circle_rounded,
    skyGradient: [
      Color(0xFF4A148C),
      Color(0xFF880E4F),
      Color(0xFFF48FB1),
    ],
    cloudColor: Color(0x66FFFFFF),
    pipePrimary: Color(0xFFF06292),
    pipeSecondary: Color(0xFFBA68C8),
    pipeBorder: Color(0xFF4A148C),
    grassColor: Color(0xFFCE93D8),
    grassBorder: Color(0xFFF48FB1),
    soilColor: Color(0xFFE1BEE7),
    stripeColor: Color(0xFFD1C4E9),
  );

  static const List<WorldBiomeData> all = [
    sunriseValley,
    neonCity,
    enchantedForest,
    frozenKingdom,
    cosmicGalaxy,
    volcanicSkies,
    dreamland,
  ];

  static WorldBiomeData of(WorldBiome biome) {
    switch (biome) {
      case WorldBiome.sunriseValley:
        return sunriseValley;
      case WorldBiome.neonCity:
        return neonCity;
      case WorldBiome.enchantedForest:
        return enchantedForest;
      case WorldBiome.frozenKingdom:
        return frozenKingdom;
      case WorldBiome.cosmicGalaxy:
        return cosmicGalaxy;
      case WorldBiome.volcanicSkies:
        return volcanicSkies;
      case WorldBiome.dreamland:
        return dreamland;
    }
  }

  static WorldBiomeData fromId(String id) {
    return all.firstWhere((w) => w.id == id, orElse: () => sunriseValley);
  }
}

// =============================================================================
// 3. LEGENDARY BIRD COLLECTION (14 BIRDS ACROSS 5 RARITIES)
// =============================================================================

/// The 5 collectible rarity tiers.
enum BirdRarity {
  common,
  rare,
  epic,
  legendary,
  mythical,
}

/// Metadata and visual flair for each rarity tier.
class BirdRarityData {
  final BirdRarity rarity;
  final String label;
  final Color color;
  final Color badgeBackground;
  final Color badgeBorder;

  const BirdRarityData({
    required this.rarity,
    required this.label,
    required this.color,
    required this.badgeBackground,
    required this.badgeBorder,
  });

  static const Map<BirdRarity, BirdRarityData> all = {
    BirdRarity.common: BirdRarityData(
      rarity: BirdRarity.common,
      label: 'COMMON',
      color: Color(0xFF90A4AE),
      badgeBackground: Color(0x3390A4AE),
      badgeBorder: Color(0xFF90A4AE),
    ),
    BirdRarity.rare: BirdRarityData(
      rarity: BirdRarity.rare,
      label: 'RARE',
      color: Color(0xFF29B6F6),
      badgeBackground: Color(0x3329B6F6),
      badgeBorder: Color(0xFF29B6F6),
    ),
    BirdRarity.epic: BirdRarityData(
      rarity: BirdRarity.epic,
      label: 'EPIC',
      color: Color(0xFFAB47BC),
      badgeBackground: Color(0x33AB47BC),
      badgeBorder: Color(0xFFAB47BC),
    ),
    BirdRarity.legendary: BirdRarityData(
      rarity: BirdRarity.legendary,
      label: 'LEGENDARY',
      color: Color(0xFFFFB300),
      badgeBackground: Color(0x33FFB300),
      badgeBorder: Color(0xFFFFB300),
    ),
    BirdRarity.mythical: BirdRarityData(
      rarity: BirdRarity.mythical,
      label: 'MYTHICAL',
      color: Color(0xFFFF1744),
      badgeBackground: Color(0x33FF1744),
      badgeBorder: Color(0xFFFF1744),
    ),
  };

  static BirdRarityData of(BirdRarity rarity) => all[rarity]!;
}

/// Identifiers for all 14 unlockable flyer skins.
enum BirdSkinId {
  // Common
  classic,
  bluebird,
  yellowbird,

  // Rare
  golden,
  jungle,
  arctic,

  // Epic
  phoenix,
  cyber,
  shadow,

  // Legendary
  galaxyPhoenix,
  thunderBird,
  dragonBird,

  // Mythical
  celestialBird,
  eternalPhoenix,
}

/// Particle trail aesthetic emitted by each bird in flight.
enum ParticleTrailType {
  feathers,
  stardust,
  fireEmbers,
  digitalSparks,
  frostMist,
  lightningArcs,
  shadowSmoke,
  prismaticGlow,
}

/// Visual, particle, and progression data for flyer skins.
class BirdSkinConfig {
  final BirdSkinId id;
  final String name;
  final String title;
  final String description;
  final BirdRarity rarity;
  final int gemCost;
  final Color particleColor;
  final Color? glowColor;
  final Color? shaderColor;
  final BlendMode blendMode;
  final IconData icon;
  final ParticleTrailType trailType;

  const BirdSkinConfig({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.rarity,
    required this.gemCost,
    required this.particleColor,
    required this.icon,
    required this.trailType,
    this.glowColor,
    this.shaderColor,
    this.blendMode = BlendMode.srcATop,
  });

  // --- COMMON BIRDS ---
  static const BirdSkinConfig classic = BirdSkinConfig(
    id: BirdSkinId.classic,
    name: 'Classic Flyer',
    title: 'The Pioneer',
    description: 'The authentic arcade standard with timeless aerodynamics.',
    rarity: BirdRarity.common,
    gemCost: 0,
    particleColor: Color(0xFFFFD54F),
    icon: Icons.flutter_dash,
    trailType: ParticleTrailType.feathers,
    shaderColor: null,
    glowColor: null,
  );

  static const BirdSkinConfig bluebird = BirdSkinConfig(
    id: BirdSkinId.bluebird,
    name: 'Bluebird',
    title: 'Azure Breeze',
    description: 'Swift cerulean glider riding early morning wind currents.',
    rarity: BirdRarity.common,
    gemCost: 20,
    particleColor: Color(0xFF29B6F6),
    icon: Icons.air_rounded,
    trailType: ParticleTrailType.feathers,
    shaderColor: Color(0xFF1E88E5),
    glowColor: Color(0x4429B6F6),
    blendMode: BlendMode.color,
  );

  static const BirdSkinConfig yellowbird = BirdSkinConfig(
    id: BirdSkinId.yellowbird,
    name: 'Yellowbird',
    title: 'Sunny Darter',
    description: 'High-visibility canary flyer bursting with buoyant energy.',
    rarity: BirdRarity.common,
    gemCost: 35,
    particleColor: Color(0xFFFFEE58),
    icon: Icons.wb_sunny_outlined,
    trailType: ParticleTrailType.feathers,
    shaderColor: Color(0xFFFFD600),
    glowColor: Color(0x44FFEE58),
    blendMode: BlendMode.color,
  );

  // --- RARE BIRDS ---
  static const BirdSkinConfig golden = BirdSkinConfig(
    id: BirdSkinId.golden,
    name: 'Golden Champion',
    title: 'Hall of Famer',
    description: 'Forged from pure championship gold with radiant sparkle trails.',
    rarity: BirdRarity.rare,
    gemCost: 75,
    particleColor: Color(0xFFFFD700),
    glowColor: Color(0x88FFD700),
    shaderColor: Color(0xFFFFB300),
    blendMode: BlendMode.color,
    icon: Icons.military_tech_rounded,
    trailType: ParticleTrailType.stardust,
  );

  static const BirdSkinConfig jungle = BirdSkinConfig(
    id: BirdSkinId.jungle,
    name: 'Jungle Bird',
    title: 'Canopy Glider',
    description: 'Emerald and lime plumage adapted for dodging rainforest roots.',
    rarity: BirdRarity.rare,
    gemCost: 90,
    particleColor: Color(0xFF00E676),
    glowColor: Color(0x5500E676),
    shaderColor: Color(0xFF43A047),
    blendMode: BlendMode.color,
    icon: Icons.nature_rounded,
    trailType: ParticleTrailType.feathers,
  );

  static const BirdSkinConfig arctic = BirdSkinConfig(
    id: BirdSkinId.arctic,
    name: 'Arctic Bird',
    title: 'Frostwing',
    description: 'Glacial cryo flyer enveloped in a soothing subzero aura.',
    rarity: BirdRarity.rare,
    gemCost: 110,
    particleColor: Color(0xFF80D8FF),
    glowColor: Color(0x6680D8FF),
    shaderColor: Color(0xFF00B0FF),
    blendMode: BlendMode.color,
    icon: Icons.ac_unit_rounded,
    trailType: ParticleTrailType.frostMist,
  );

  // --- EPIC BIRDS ---
  static const BirdSkinConfig phoenix = BirdSkinConfig(
    id: BirdSkinId.phoenix,
    name: 'Phoenix Bird',
    title: 'Solar Flare',
    description: 'Blazing thermal core emitting fiery ember sparks in flight.',
    rarity: BirdRarity.epic,
    gemCost: 160,
    particleColor: Color(0xFFFF3D00),
    glowColor: Color(0x77FF3D00),
    shaderColor: Color(0xFFFF3D00),
    blendMode: BlendMode.color,
    icon: Icons.local_fire_department_rounded,
    trailType: ParticleTrailType.fireEmbers,
  );

  static const BirdSkinConfig cyber = BirdSkinConfig(
    id: BirdSkinId.cyber,
    name: 'Cyber Bird',
    title: 'Grid Runner',
    description: 'High-frequency electric cyan hull trailing digital telemetry.',
    rarity: BirdRarity.epic,
    gemCost: 190,
    particleColor: Color(0xFF00E5FF),
    glowColor: Color(0x7700E5FF),
    shaderColor: Color(0xFF00E5FF),
    blendMode: BlendMode.color,
    icon: Icons.electric_bolt_rounded,
    trailType: ParticleTrailType.digitalSparks,
  );

  static const BirdSkinConfig shadow = BirdSkinConfig(
    id: BirdSkinId.shadow,
    name: 'Shadow Bird',
    title: 'Night Stalker',
    description: 'Enigmatic dark matter shroud trailing spectral violet tendrils.',
    rarity: BirdRarity.epic,
    gemCost: 220,
    particleColor: Color(0xFF7C4DFF),
    glowColor: Color(0x887C4DFF),
    shaderColor: Color(0xFF311B92),
    blendMode: BlendMode.color,
    icon: Icons.visibility_off_rounded,
    trailType: ParticleTrailType.shadowSmoke,
  );

  // --- LEGENDARY BIRDS ---
  static const BirdSkinConfig galaxyPhoenix = BirdSkinConfig(
    id: BirdSkinId.galaxyPhoenix,
    name: 'Galaxy Phoenix',
    title: 'Void Drifter',
    description: 'Interstellar nebula flyer infused with cosmic starlight and gravity rings.',
    rarity: BirdRarity.legendary,
    gemCost: 320,
    particleColor: Color(0xFFE040FB),
    glowColor: Color(0x88E040FB),
    shaderColor: Color(0xFF9C27B0),
    blendMode: BlendMode.color,
    icon: Icons.auto_awesome_rounded,
    trailType: ParticleTrailType.stardust,
  );

  static const BirdSkinConfig thunderBird = BirdSkinConfig(
    id: BirdSkinId.thunderBird,
    name: 'Thunder Bird',
    title: 'Stormbringer',
    description: 'Crackling with supersonic electrostatic potential and lightning.',
    rarity: BirdRarity.legendary,
    gemCost: 360,
    particleColor: Color(0xFFFFD600),
    glowColor: Color(0x99FFD600),
    shaderColor: Color(0xFFFFAB00),
    blendMode: BlendMode.color,
    icon: Icons.flash_on_rounded,
    trailType: ParticleTrailType.lightningArcs,
  );

  static const BirdSkinConfig dragonBird = BirdSkinConfig(
    id: BirdSkinId.dragonBird,
    name: 'Dragon Bird',
    title: 'Drakon',
    description: 'Ancient scaled aerodynamic titan emitting molten magma fireballs.',
    rarity: BirdRarity.legendary,
    gemCost: 420,
    particleColor: Color(0xFFFF1744),
    glowColor: Color(0x88FF1744),
    shaderColor: Color(0xFFC62828),
    blendMode: BlendMode.color,
    icon: Icons.shield_moon_rounded,
    trailType: ParticleTrailType.fireEmbers,
  );

  // --- MYTHICAL BIRDS ---
  static const BirdSkinConfig celestialBird = BirdSkinConfig(
    id: BirdSkinId.celestialBird,
    name: 'Celestial Bird',
    title: 'Star Sovereign',
    description: 'Transcendent starlight entity that glides upon cosmic aurora currents.',
    rarity: BirdRarity.mythical,
    gemCost: 550,
    particleColor: Color(0xFFFFFFFF),
    glowColor: Color(0xAA00E5FF),
    shaderColor: Color(0xFFE0F7FA),
    blendMode: BlendMode.color,
    icon: Icons.star_rounded,
    trailType: ParticleTrailType.prismaticGlow,
  );

  static const BirdSkinConfig eternalPhoenix = BirdSkinConfig(
    id: BirdSkinId.eternalPhoenix,
    name: 'Eternal Phoenix',
    title: 'Immortal Flame',
    description: 'The supreme celestial deity of the skies. Reborn endlessly from stardust.',
    rarity: BirdRarity.mythical,
    gemCost: 700,
    particleColor: Color(0xFFFFAB00),
    glowColor: Color(0xCCFF6D00),
    shaderColor: Color(0xFFFF6D00),
    blendMode: BlendMode.color,
    icon: Icons.whatshot_rounded,
    trailType: ParticleTrailType.prismaticGlow,
  );

  static const List<BirdSkinConfig> all = [
    classic,
    bluebird,
    yellowbird,
    golden,
    jungle,
    arctic,
    phoenix,
    cyber,
    shadow,
    galaxyPhoenix,
    thunderBird,
    dragonBird,
    celestialBird,
    eternalPhoenix,
  ];

  static BirdSkinConfig of(BirdSkinId id) {
    return all.firstWhere((b) => b.id == id, orElse: () => classic);
  }

  static BirdSkinConfig fromStringId(String idStr) {
    for (final skin in all) {
      if (skin.id.name == idStr || skin.name.toLowerCase() == idStr.toLowerCase()) {
        return skin;
      }
    }
    return classic;
  }
}

// =============================================================================
// 4. DAILY & WEEKLY CHALLENGES (PERSISTENT QUEST SYSTEM)
// =============================================================================

/// Represents a daily quest that refreshes every day based on the calendar date.
class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final int target;
  int currentProgress;
  final int rewardGems;
  bool isClaimed;

  DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    this.currentProgress = 0,
    required this.rewardGems,
    this.isClaimed = false,
  });

  bool get isCompleted => currentProgress >= target;
  double get progressRatio => (currentProgress / target).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'target': target,
        'currentProgress': currentProgress,
        'rewardGems': rewardGems,
        'isClaimed': isClaimed,
      };

  factory DailyChallenge.fromJson(Map<String, dynamic> json) => DailyChallenge(
        id: json['id'] as String? ?? 'daily_score',
        title: json['title'] as String? ?? 'Daily Flight',
        description: json['description'] as String? ?? '',
        target: (json['target'] as num?)?.toInt() ?? 10,
        currentProgress: (json['currentProgress'] as num?)?.toInt() ?? 0,
        rewardGems: (json['rewardGems'] as num?)?.toInt() ?? 15,
        isClaimed: json['isClaimed'] as bool? ?? false,
      );

  static List<DailyChallenge> generateForDate(DateTime date) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final rand = Random(seed);

    final pools = [
      DailyChallenge(
        id: 'daily_score_${date.day}',
        title: 'Sky Ace',
        description: 'Score ${15 + rand.nextInt(15)} points in a single flight.',
        target: 15 + rand.nextInt(15),
        rewardGems: 20,
      ),
      DailyChallenge(
        id: 'daily_gems_${date.day}',
        title: 'Gem Harvester',
        description: 'Collect ${10 + rand.nextInt(15)} Sky Gems across runs.',
        target: 10 + rand.nextInt(15),
        rewardGems: 25,
      ),
      DailyChallenge(
        id: 'daily_flaps_${date.day}',
        title: 'Endurance Pilot',
        description: 'Perform ${40 + rand.nextInt(40)} wing flaps today.',
        target: 40 + rand.nextInt(40),
        rewardGems: 15,
      ),
      DailyChallenge(
        id: 'daily_powerup_${date.day}',
        title: 'Ability Seeker',
        description: 'Activate 3 special power-up abilities.',
        target: 3,
        rewardGems: 30,
      ),
      DailyChallenge(
        id: 'daily_combo_${date.day}',
        title: 'Streak Master',
        description: 'Achieve a 5x or higher combo streak.',
        target: 5,
        rewardGems: 25,
      ),
    ];

    pools.shuffle(rand);
    return pools.take(3).toList();
  }
}

/// Represents a weekly endurance challenge that refreshes every calendar week.
class WeeklyChallenge {
  final String id;
  final String title;
  final String description;
  final int target;
  int currentProgress;
  final int rewardGems;
  bool isClaimed;

  WeeklyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    this.currentProgress = 0,
    required this.rewardGems,
    this.isClaimed = false,
  });

  bool get isCompleted => currentProgress >= target;
  double get progressRatio => (currentProgress / target).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'target': target,
        'currentProgress': currentProgress,
        'rewardGems': rewardGems,
        'isClaimed': isClaimed,
      };

  factory WeeklyChallenge.fromJson(Map<String, dynamic> json) => WeeklyChallenge(
        id: json['id'] as String? ?? 'weekly_marathon',
        title: json['title'] as String? ?? 'Weekly Marathon',
        description: json['description'] as String? ?? '',
        target: (json['target'] as num?)?.toInt() ?? 100,
        currentProgress: (json['currentProgress'] as num?)?.toInt() ?? 0,
        rewardGems: (json['rewardGems'] as num?)?.toInt() ?? 80,
        isClaimed: json['isClaimed'] as bool? ?? false,
      );

  static List<WeeklyChallenge> generateForWeek(DateTime date) {
    // Week number calculation
    final dayOfYear = int.parse("${date.difference(DateTime(date.year, 1, 1)).inDays}");
    final weekNumber = ((dayOfYear - date.weekday + 10) / 7).floor();

    return [
      WeeklyChallenge(
        id: 'weekly_points_${date.year}_$weekNumber',
        title: 'Weekly Grand Marathon',
        description: 'Score 120 cumulative points this week.',
        target: 120,
        rewardGems: 75,
      ),
      WeeklyChallenge(
        id: 'weekly_gems_${date.year}_$weekNumber',
        title: 'Treasury Hoarder',
        description: 'Collect 80 Sky Gems across all biomes this week.',
        target: 80,
        rewardGems: 85,
      ),
      WeeklyChallenge(
        id: 'weekly_flaps_${date.year}_$weekNumber',
        title: 'Skybound Titan',
        description: 'Log 400 total wing flaps this week.',
        target: 400,
        rewardGems: 60,
      ),
    ];
  }
}

// =============================================================================
// 5. ACHIEVEMENTS & CAREER TROPHIES (7 CATEGORIES)
// =============================================================================

/// The 7 distinct achievement categories.
enum AchievementCategory {
  flightMaster,
  collector,
  explorer,
  survivalExpert,
  comboMaster,
  worldTraveller,
  legendaryHunter,
}

/// Metadata for achievement categories.
class AchievementCategoryData {
  final AchievementCategory category;
  final String label;
  final IconData icon;
  final Color color;

  const AchievementCategoryData({
    required this.category,
    required this.label,
    required this.icon,
    required this.color,
  });

  static const Map<AchievementCategory, AchievementCategoryData> all = {
    AchievementCategory.flightMaster: AchievementCategoryData(
      category: AchievementCategory.flightMaster,
      label: 'Flight Master',
      icon: Icons.military_tech_rounded,
      color: Color(0xFF29B6F6),
    ),
    AchievementCategory.collector: AchievementCategoryData(
      category: AchievementCategory.collector,
      label: 'Collector',
      icon: Icons.diamond_rounded,
      color: Color(0xFFFFD54F),
    ),
    AchievementCategory.explorer: AchievementCategoryData(
      category: AchievementCategory.explorer,
      label: 'Explorer',
      icon: Icons.explore_rounded,
      color: Color(0xFF66BB6A),
    ),
    AchievementCategory.survivalExpert: AchievementCategoryData(
      category: AchievementCategory.survivalExpert,
      label: 'Survival Expert',
      icon: Icons.shield_rounded,
      color: Color(0xFF00E5FF),
    ),
    AchievementCategory.comboMaster: AchievementCategoryData(
      category: AchievementCategory.comboMaster,
      label: 'Combo Master',
      icon: Icons.bolt_rounded,
      color: Color(0xFFFF9100),
    ),
    AchievementCategory.worldTraveller: AchievementCategoryData(
      category: AchievementCategory.worldTraveller,
      label: 'World Traveller',
      icon: Icons.public_rounded,
      color: Color(0xFFAB47BC),
    ),
    AchievementCategory.legendaryHunter: AchievementCategoryData(
      category: AchievementCategory.legendaryHunter,
      label: 'Legendary Hunter',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFFF1744),
    ),
  };

  static AchievementCategoryData of(AchievementCategory cat) => all[cat]!;
}

/// Represents a permanent unlockable achievement badge.
class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final IconData icon;
  final int target;
  int currentProgress;
  final int rewardGems;
  bool isUnlocked;
  bool isClaimed;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.target,
    this.currentProgress = 0,
    required this.rewardGems,
    this.isUnlocked = false,
    this.isClaimed = false,
  });

  double get progressRatio => (currentProgress / target).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.name,
        'target': target,
        'currentProgress': currentProgress,
        'rewardGems': rewardGems,
        'isUnlocked': isUnlocked,
        'isClaimed': isClaimed,
      };

  factory Achievement.fromJson(Map<String, dynamic> json, IconData defaultIcon, AchievementCategory defaultCategory) =>
      Achievement(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] != null
            ? AchievementCategory.values.firstWhere(
                (c) => c.name == json['category'],
                orElse: () => defaultCategory,
              )
            : defaultCategory,
        icon: defaultIcon,
        target: (json['target'] as num?)?.toInt() ?? 1,
        currentProgress: (json['currentProgress'] as num?)?.toInt() ?? 0,
        rewardGems: (json['rewardGems'] as num?)?.toInt() ?? 10,
        isUnlocked: json['isUnlocked'] as bool? ?? false,
        isClaimed: json['isClaimed'] as bool? ?? false,
      );

  static List<Achievement> initialList() => [
        // 1. Flight Master
        Achievement(
          id: 'first_flight',
          title: 'First Flight',
          description: 'Launch your flyer into the skies for the very first time.',
          category: AchievementCategory.flightMaster,
          icon: Icons.flight_takeoff_rounded,
          target: 1,
          rewardGems: 10,
        ),
        Achievement(
          id: 'sky_explorer',
          title: 'Sky Aviator',
          description: 'Reach a round score of 20 points in any world.',
          category: AchievementCategory.flightMaster,
          icon: Icons.explore_rounded,
          target: 20,
          rewardGems: 25,
        ),
        Achievement(
          id: 'cloud_veteran',
          title: 'Cloud Veteran',
          description: 'Reach an elite round score of 50 points.',
          category: AchievementCategory.flightMaster,
          icon: Icons.military_tech_rounded,
          target: 50,
          rewardGems: 50,
        ),

        // 2. Collector
        Achievement(
          id: 'gem_collector_1',
          title: 'Gem Seeker',
          description: 'Collect 25 total Sky Gems across your career.',
          category: AchievementCategory.collector,
          icon: Icons.diamond_outlined,
          target: 25,
          rewardGems: 20,
        ),
        Achievement(
          id: 'gem_collector_2',
          title: 'Gem Hoarder',
          description: 'Collect 100 total Sky Gems across your career.',
          category: AchievementCategory.collector,
          icon: Icons.diamond_rounded,
          target: 100,
          rewardGems: 50,
        ),
        Achievement(
          id: 'powerup_junkie',
          title: 'Arsenal Collector',
          description: 'Collect 15 special power-up abilities in flight.',
          category: AchievementCategory.collector,
          icon: Icons.bolt_rounded,
          target: 15,
          rewardGems: 30,
        ),

        // 3. Explorer
        Achievement(
          id: 'explore_neon',
          title: 'Cyber Voyager',
          description: 'Unlock and explore the Neon Cyber City world.',
          category: AchievementCategory.explorer,
          icon: Icons.location_city_rounded,
          target: 1,
          rewardGems: 25,
        ),
        Achievement(
          id: 'explore_forest',
          title: 'Canopy Wanderer',
          description: 'Unlock and explore the Enchanted Forest world.',
          category: AchievementCategory.explorer,
          icon: Icons.forest_rounded,
          target: 1,
          rewardGems: 30,
        ),
        Achievement(
          id: 'explore_cosmic',
          title: 'Cosmic Voyager',
          description: 'Unlock and explore the Cosmic Galaxy world.',
          category: AchievementCategory.explorer,
          icon: Icons.auto_awesome_rounded,
          target: 1,
          rewardGems: 50,
        ),

        // 4. Survival Expert
        Achievement(
          id: 'shield_deflect',
          title: 'Kinetic Deflector',
          description: 'Absorb a crash impact using the Energy Shield.',
          category: AchievementCategory.survivalExpert,
          icon: Icons.shield_rounded,
          target: 1,
          rewardGems: 20,
        ),
        Achievement(
          id: 'time_warp_pro',
          title: 'Chronos Pilot',
          description: 'Pass 5 obstacles while Time Warp slow motion is active.',
          category: AchievementCategory.survivalExpert,
          icon: Icons.speed_rounded,
          target: 5,
          rewardGems: 25,
        ),
        Achievement(
          id: 'ghost_pass',
          title: 'Phantom Glider',
          description: 'Pass through 3 barriers safely while in Phase Shift mode.',
          category: AchievementCategory.survivalExpert,
          icon: Icons.auto_awesome_motion_rounded,
          target: 3,
          rewardGems: 30,
        ),

        // 5. Combo Master
        Achievement(
          id: 'combo_streak_5',
          title: 'Rhythm Flyer',
          description: 'Achieve an unbroken 5x obstacle pass combo.',
          category: AchievementCategory.comboMaster,
          icon: Icons.flash_on_rounded,
          target: 5,
          rewardGems: 20,
        ),
        Achievement(
          id: 'combo_streak_10',
          title: 'Flawless Flight',
          description: 'Achieve an unbroken 10x obstacle pass combo.',
          category: AchievementCategory.comboMaster,
          icon: Icons.bolt_rounded,
          target: 10,
          rewardGems: 45,
        ),
        Achievement(
          id: 'combo_streak_15',
          title: 'Master of Flow',
          description: 'Achieve an unbroken 15x obstacle pass combo.',
          category: AchievementCategory.comboMaster,
          icon: Icons.all_inclusive_rounded,
          target: 15,
          rewardGems: 70,
        ),

        // 6. World Traveller
        Achievement(
          id: 'travel_3_worlds',
          title: 'Realm Hopper',
          description: 'Unlock at least 3 distinct world biomes.',
          category: AchievementCategory.worldTraveller,
          icon: Icons.map_rounded,
          target: 3,
          rewardGems: 40,
        ),
        Achievement(
          id: 'travel_all_worlds',
          title: 'Omnipresent Aviator',
          description: 'Unlock all 7 worlds in Flappy Bird: Skybound.',
          category: AchievementCategory.worldTraveller,
          icon: Icons.public_rounded,
          target: 7,
          rewardGems: 120,
        ),

        // 7. Legendary Hunter
        Achievement(
          id: 'unlock_rare_bird',
          title: 'Rare Wings',
          description: 'Acquire your first Rare tier flyer skin.',
          category: AchievementCategory.legendaryHunter,
          icon: Icons.pets_rounded,
          target: 1,
          rewardGems: 30,
        ),
        Achievement(
          id: 'unlock_epic_bird',
          title: 'Epic Flight',
          description: 'Acquire your first Epic tier flyer skin.',
          category: AchievementCategory.legendaryHunter,
          icon: Icons.whatshot_rounded,
          target: 1,
          rewardGems: 50,
        ),
        Achievement(
          id: 'unlock_legendary_bird',
          title: 'Legendary Ascendant',
          description: 'Acquire your first Legendary tier flyer skin.',
          category: AchievementCategory.legendaryHunter,
          icon: Icons.star_rounded,
          target: 1,
          rewardGems: 100,
        ),
        Achievement(
          id: 'unlock_mythical_bird',
          title: 'Mythic Deity',
          description: 'Acquire a Mythical tier flyer skin (Celestial or Eternal).',
          category: AchievementCategory.legendaryHunter,
          icon: Icons.workspace_premium_rounded,
          target: 1,
          rewardGems: 200,
        ),
      ];
}

// =============================================================================
// 6. PERSISTENT GAME SETTINGS
// =============================================================================

/// Holds user audio and accessibility settings with persistence support.
class GameSettings {
  final double musicVolume;
  final double sfxVolume;
  final bool isMusicEnabled;
  final bool isSfxEnabled;
  final bool isHapticsEnabled;
  final bool reducedMotion;

  const GameSettings({
    this.musicVolume = 0.65,
    this.sfxVolume = 0.85,
    this.isMusicEnabled = true,
    this.isSfxEnabled = true,
    this.isHapticsEnabled = true,
    this.reducedMotion = false,
  });

  GameSettings copyWith({
    double? musicVolume,
    double? sfxVolume,
    bool? isMusicEnabled,
    bool? isSfxEnabled,
    bool? isHapticsEnabled,
    bool? reducedMotion,
  }) {
    return GameSettings(
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      isMusicEnabled: isMusicEnabled ?? this.isMusicEnabled,
      isSfxEnabled: isSfxEnabled ?? this.isSfxEnabled,
      isHapticsEnabled: isHapticsEnabled ?? this.isHapticsEnabled,
      reducedMotion: reducedMotion ?? this.reducedMotion,
    );
  }

  Map<String, dynamic> toJson() => {
        'musicVolume': musicVolume,
        'sfxVolume': sfxVolume,
        'isMusicEnabled': isMusicEnabled,
        'isSfxEnabled': isSfxEnabled,
        'isHapticsEnabled': isHapticsEnabled,
        'reducedMotion': reducedMotion,
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
        musicVolume: (json['musicVolume'] as num?)?.toDouble() ?? 0.65,
        sfxVolume: (json['sfxVolume'] as num?)?.toDouble() ?? 0.85,
        isMusicEnabled: json['isMusicEnabled'] as bool? ?? true,
        isSfxEnabled: json['isSfxEnabled'] as bool? ?? true,
        isHapticsEnabled: json['isHapticsEnabled'] as bool? ?? true,
        reducedMotion: json['reducedMotion'] as bool? ?? false,
      );
}

// =============================================================================
// 7. SPECIAL IN-GAME EVENTS
// =============================================================================

/// Dynamic atmospheric events that periodically trigger during extended runs.
enum SpecialEventType {
  none,
  goldenGate, // Triple golden gem cluster between pylons
  starfall,   // Shower of falling star sparkles with bonus points
  windRush,   // Aerodynamic tailwind stream providing a gentle glide boost
}
