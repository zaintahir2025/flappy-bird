# Flappy Bird: Skybound Edition

A neo-arcade Flappy Bird reimagined in Flutter featuring responsive multiplatform physics, seven atmospheric biomes, fourteen collectible skins, active power-ups, daily quest challenges, and complete local Hall of Fame leaderboards across mobile, desktop, and web.

---

## Live Web Demo

Play directly in your browser: [https://zaintahir2025.github.io/flappy-bird/](https://zaintahir2025.github.io/flappy-bird/)

---

## Overview

Flappy Bird: Skybound Edition modernizes the classic arcade flight formula with high-fidelity cross-platform graphics, progressive difficulty scaling, procedural world environments, and an extensive progression system. The game runs natively on Android, iOS, Windows, macOS, Linux, and Web browsers with zero external backend dependencies.

---

## Core Features

### 1. Dynamic World Biomes
The game features seven distinct atmospheric environments, each with bespoke color palettes, parallax backgrounds, and custom obstacle rendering:
- Sunrise Valley (Default tranquil hills)
- Neon City (Cyberpunk skyscraper skyline)
- Enchanted Forest (Luminous canopy)
- Frozen Kingdom (Glacial peaks and frosty pillars)
- Cosmic Galaxy (Deep space nebula and orbital celestial bodies)
- Cyber Void (Digital wireframe grid)
- Sunset Volcano (Volcanic magma plumes and basalt columns)

### 2. Aviary Skin Collection
Fly with 14 collectible bird skins spanning five rarity tiers (Common, Rare, Epic, Legendary, Mythic):
- Custom procedural wing-flap cycles
- Dynamic glow auras and GPU color shaders
- Squash-and-stretch flap animations

### 3. Tactical Power-Ups
In-flight item drops spawn dynamically to offer strategic mechanics:
- Shield: Absorbs a single obstacle or ground collision
- Slow-Motion: Dilates game physics by 50% for tight navigation
- Gem Magnet: Attracts surrounding Sky Gems automatically
- Ghost Phase: Provides temporary invulnerability to pass through pylons

### 4. Hall of Fame & Missions
- Local Leaderboard: Persistent top-score rankings with custom pilot callsigns
- Career Statistics: Track total flights, high score, gems collected, and milestones
- Daily & Weekly Quests: Deterministic challenge generator awarding bonus Sky Gems
- Career Achievements: Over 20 milestone trophies across 7 distinct categories

### 5. Multiplatform Architecture
- Platform-adaptive layout engine adjusting smoothly between mobile portrait and desktop widescreen
- Unified conditional storage facade utilizing dart:io on native platforms and localStorage on web
- Screen-synchronized VSYNC game loop via SingleTickerProviderStateMixin

---

## Controls

### Desktop and Web
- Spacebar / Left Mouse Click / Tap: Flap wings / Start flight / Navigate menus
- P: Toggle pause and resume
- L: Open Hall of Fame leaderboard
- T: Cycle environment biome
- S: Cycle active bird skin
- M: Toggle sound effects and background music
- Esc / Back: Close active modal dialog

### Mobile
- Single Tap: Flap wings / Start flight / Navigate menus
- On-Screen HUD Buttons: Access Avairy Shop, Worlds, Quests, Leaderboard, and Settings

---

## Getting Started

### Prerequisites
- Flutter SDK (version 3.16 or higher)
- Dart SDK (version 3.0 or higher)
- Git

### Installation
1. Clone the repository:
   git clone https://github.com/zaintahir2025/flappy-bird.git
   cd flappy-bird

2. Install dependencies:
   flutter pub get

3. Verify static analysis and test suite:
   flutter analyze
   flutter test

### Running the Game
- Run on Chrome Web:
  flutter run -d chrome

- Run on Windows Desktop:
  flutter run -d windows

- Run on Android / iOS Device or Emulator:
  flutter run

### Building Release Binaries
- Web:
  flutter build web

- Windows:
  flutter build windows

- Android APK:
  flutter build apk --split-per-abi

---

## Project Structure

- lib/main.dart: Application entry point and theme configuration
- lib/home_page.dart: Core game loop, collision detection, physics, and HUD overlays
- lib/bird.dart: Flyer rendering, wing flap animation, shader filters, and shield effects
- lib/barriers.dart: Procedural Aero Pylon obstacles adapting to biome themes
- lib/game_models.dart: Data models for biomes, skins, power-ups, quests, and achievements
- lib/leaderboard_model.dart: Leaderboard entries and career stats models
- lib/leaderboard_dialog.dart: Hall of Fame rankings and pilot stats modal
- lib/skin_shop_dialog.dart: Aviary skin store and preview interface
- lib/world_select_dialog.dart: World biome selector and unlock screen
- lib/quests_dialog.dart: Daily and weekly challenge tracker
- lib/settings_dialog.dart: Audio toggles, volume sliders, and pilot configuration
- lib/audio_manager.dart: Low-latency multi-channel audio playback and mute management
- lib/score_storage.dart: Storage facade with compile-time conditional exports
- lib/score_storage_io.dart: Native file I/O persistence implementation
- lib/score_storage_web.dart: Web browser localStorage persistence implementation
- lib/score_storage_stub.dart: Base storage contract definition
- test/widget_test.dart: Comprehensive unit and widget test suite

---

## License

This project is licensed under the MIT License. See the LICENSE file for details.
