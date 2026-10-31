import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_bird/audio_manager.dart';
import 'package:flappy_bird/game_models.dart';
import 'package:flappy_bird/main.dart';
import 'package:flappy_bird/score_storage.dart' as score_storage;

void main() {
  setUp(() async {
    await score_storage.saveBestScore(5);
  });

  tearDown(() {
    try {
      final f = File('flappy_best.txt');
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  });

  testWidgets('Flappy bird initial state and tap to start test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // Allow async _loadBestScore() to resolve and rebuild
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    // Verify title and prompt are displayed
    expect(find.text('FLAPPY BIRD'), findsOneWidget);
    expect(find.text('TAP OR PRESS SPACE TO FLY'), findsOneWidget);
    expect(find.text('BEST SCORE: 5'), findsOneWidget);

    // Tap to start the game
    await tester.tap(find.text('TAP OR PRESS SPACE TO FLY'));
    await tester.pump();

    // Verify in-game score HUD is now visible
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('Flappy bird keyboard spacebar control test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 50));

    // Send Spacebar key event
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    // Game should transition to playing state
    expect(find.text('0'), findsOneWidget);
    expect(find.text('FLAPPY BIRD'), findsNothing);
  });

  testWidgets('Game Over triggers when bird falls and restarts cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 50));

    // Start game
    await tester.tap(find.text('TAP OR PRESS SPACE TO FLY'));
    await tester.pump();

    // Advance time without jumping so bird falls into the ground
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    // Verify Game Over overlay appears with scoreboard and Play Again button
    expect(find.text('GAME OVER'), findsOneWidget);
    expect(find.text('PLAY AGAIN'), findsOneWidget);
    expect(find.text('SCORE: '), findsOneWidget);
    expect(find.text('BEST: '), findsOneWidget);

    // Tap PLAY AGAIN to restart
    await tester.tap(find.text('PLAY AGAIN'));
    await tester.pump();

    // Verify game returned to Ready state seamlessly without softlocking
    expect(find.text('FLAPPY BIRD'), findsOneWidget);
    expect(find.text('TAP OR PRESS SPACE TO FLY'), findsOneWidget);
    expect(find.text('GAME OVER'), findsNothing);
  });

  testWidgets('Responsive LayoutBuilder works on small and large screens', (WidgetTester tester) async {
    // Test on small screen (phone in portrait)
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(MyApp), findsOneWidget);

    // Test on wide desktop screen
    tester.view.physicalSize = const Size(1920, 1080);
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(MyApp), findsOneWidget);

    // Test on tablet/landscape screen
    tester.view.physicalSize = const Size(1024, 768);
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(MyApp), findsOneWidget);
  });

  testWidgets('Leaderboard dialog opens, displays seeded rankings and closes cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 50));

    // Tap LEADERBOARD button
    await tester.tap(find.text('LEADERBOARD'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Leaderboard Dialog is visible with title and seeded player names
    expect(find.text('HALL OF FAME'), findsOneWidget);
    expect(find.text('SKY_KING'), findsOneWidget);
    expect(find.text('PHOENIX'), findsOneWidget);

    // Switch to PILOT STATS tab
    await tester.tap(find.text('PILOT STATS'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    // Verify stats tab items
    expect(find.text('Games Played'), findsOneWidget);
    expect(find.text('Best High Score'), findsOneWidget);

    // Close the dialog using the close icon in the header
    await tester.tap(find.byKey(const Key('dialog_close_icon')));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Dialog should be dismissed
    expect(find.text('HALL OF FAME'), findsNothing);
  });

  testWidgets('Theme and skin shortcuts cycle successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 50));

    // Press 'T' to cycle theme to Sunset
    await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
    await tester.pump();

    // Press 'S' to cycle skin to Phoenix
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.pump();

    // Game stays in ready state with no errors
    expect(find.text('FLAPPY BIRD'), findsOneWidget);
  });

  testWidgets('Pause and resume toggle during active gameplay', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 50));

    // Start flying
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('0'), findsOneWidget);

    // Press 'P' to pause
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.pump(const Duration(milliseconds: 50));

    // Verify Pause dialog overlay
    expect(find.text('GAME PAUSED'), findsOneWidget);
    expect(find.text('RESUME'), findsOneWidget);

    // Tap RESUME
    await tester.tap(find.text('RESUME'));
    await tester.pump(const Duration(milliseconds: 50));

    // Game unpaused and score is visible
    expect(find.text('GAME PAUSED'), findsNothing);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('Screen adaptation with safe area padding and notch does not overflow', (WidgetTester tester) async {
    // Simulate iPhone 14/15/16 Pro with Dynamic Island (safe area top = 59, bottom = 34)
    tester.view.physicalSize = const Size(393, 852);
    tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetPadding();
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('FLAPPY BIRD'), findsOneWidget);
    expect(find.text('TAP OR PRESS SPACE TO FLY'), findsOneWidget);

    // Start game and verify HUD renders without clipping
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('Ultra-compact landscape mobile screen renders cleanly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('FLAPPY BIRD'), findsOneWidget);
    expect(find.byType(MyApp), findsOneWidget);
  });

  testWidgets('Top HUD buttons are interactive on Ready screen without starting game', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 50));

    // Tap Top Bar Trophy Icon (Hall of Fame) directly on Ready screen
    final trophyFinder = find.byTooltip('Hall of Fame (L)');
    expect(trophyFinder, findsOneWidget);
    await tester.tap(trophyFinder);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify dialog opens instead of game starting
    expect(find.text('HALL OF FAME'), findsOneWidget);

    // Close dialog
    await tester.tap(find.byKey(const Key('dialog_close_icon')));
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Verify game is still in ready state (did not accidentally start)
    expect(find.text('FLAPPY BIRD'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('Audio toggle hotkey and HUD button toggle successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 50));

    // Press 'M' to mute audio
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.pump();

    // Verify mute icon is displayed
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

    // Press 'M' again to unmute audio
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.pump();

    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
  });

  test('AudioManager triggers all sound effects and handles mute states safely', () async {
    final audio = AudioManager.instance;
    await audio.init();

    expect(audio.isMuted, isFalse);
    audio.toggleMute();
    expect(audio.isMuted, isTrue);
    audio.toggleMute();
    expect(audio.isMuted, isFalse);

    // Verify all sound effects execute without throwing
    audio.playFlap();
    audio.playScore();
    audio.playGem();
    audio.playCombo();
    audio.playHit();
    audio.playGameOver();
    audio.playClick();
    audio.playPowerUp();
    audio.playShield();
    audio.playUnlock();

    // Verify BGM state transitions
    await audio.playBgm();
    await audio.pauseBgm();
    await audio.resumeBgm();
    await audio.stopBgm();
  });

  test('World Biomes system provides all 7 distinct atmospheric worlds with progression requirements', () {
    expect(WorldBiome.values.length, 7);
    expect(WorldBiomeData.all.length, 7);

    final expectedBiomes = [
      WorldBiome.sunriseValley,
      WorldBiome.neonCity,
      WorldBiome.enchantedForest,
      WorldBiome.frozenKingdom,
      WorldBiome.cosmicGalaxy,
      WorldBiome.volcanicSkies,
      WorldBiome.dreamland,
    ];

    for (final b in expectedBiomes) {
      final data = WorldBiomeData.of(b);
      expect(data.name.isNotEmpty, isTrue);
      expect(data.subtitle.isNotEmpty, isTrue);
      expect(data.skyGradient.length, greaterThanOrEqualTo(2));
      expect(data.unlockGems, greaterThanOrEqualTo(0));
    }

    expect(WorldBiomeData.of(WorldBiome.sunriseValley).unlockGems, 0);
    expect(WorldBiomeData.of(WorldBiome.dreamland).unlockGems, 350);
  });

  test('Legendary Bird Collection features 14 birds across 5 distinct rarities', () {
    expect(BirdRarity.values.length, 5);
    expect(BirdSkinId.values.length, 14);
    expect(BirdSkinConfig.all.length, 14);

    final rarities = BirdSkinConfig.all.map((b) => b.rarity).toSet();
    expect(rarities.length, 5);
    expect(rarities.contains(BirdRarity.common), isTrue);
    expect(rarities.contains(BirdRarity.rare), isTrue);
    expect(rarities.contains(BirdRarity.epic), isTrue);
    expect(rarities.contains(BirdRarity.legendary), isTrue);
    expect(rarities.contains(BirdRarity.mythical), isTrue);

    expect(BirdSkinConfig.of(BirdSkinId.classic).gemCost, 0);
    expect(BirdSkinConfig.of(BirdSkinId.eternalPhoenix).gemCost, 700);
    expect(BirdSkinConfig.of(BirdSkinId.eternalPhoenix).rarity, BirdRarity.mythical);
  });

  test('Power-Up system metadata and active progress calculations are mathematically sound', () {
    expect(PowerUpType.values.length, 5);

    for (final type in PowerUpType.values) {
      final data = PowerUpData.of(type);
      expect(data.label.isNotEmpty, isTrue);
      expect(data.durationSeconds, greaterThan(0));
    }

    final active = ActivePowerUp(
      type: PowerUpType.shield,
      remainingSeconds: 10.0,
      totalSeconds: 15.0,
    );
    expect(active.progress, closeTo(10.0 / 15.0, 0.01));
    expect(active.update(5.0), isTrue);
    expect(active.remainingSeconds, closeTo(5.0, 0.01));
    expect(active.update(6.0), isFalse);
  });

  test('Daily and Weekly challenges generate deterministically with valid targets', () {
    final now = DateTime(2026, 11, 1);
    final daily = DailyChallenge.generateForDate(now);
    expect(daily.length, 3);
    for (final q in daily) {
      expect(q.target, greaterThan(0));
      expect(q.rewardGems, greaterThan(0));
      expect(q.progressRatio, 0.0);
    }

    final weekly = WeeklyChallenge.generateForWeek(now);
    expect(weekly.length, 3);
    for (final w in weekly) {
      expect(w.target, greaterThan(0));
      expect(w.rewardGems, greaterThan(0));
    }
  });

  test('Achievements system provides 7 distinct categories with career trophies', () {
    expect(AchievementCategory.values.length, 7);
    final achievements = Achievement.initialList();
    expect(achievements.length, greaterThanOrEqualTo(20));

    final categories = achievements.map((a) => a.category).toSet();
    expect(categories.length, 7);
  });
}
