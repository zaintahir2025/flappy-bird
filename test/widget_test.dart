import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
