// Abstract fallback / stub implementation of the score storage interface.
// Used as the baseline definition and default fallback in environments where neither
// native file I/O nor browser DOM storage is available.

import 'game_models.dart';
import 'leaderboard_model.dart';

Future<int> loadBestScore() async => 0;
Future<void> saveBestScore(int score) async {}

Future<int> loadTotalGems() async => 0;
Future<void> saveTotalGems(int gems) async {}

Future<List<LeaderboardEntry>> loadLeaderboard() async =>
    LeaderboardEntry.defaultLeaderboard;
Future<void> saveLeaderboard(List<LeaderboardEntry> list) async {}

Future<PlayerStats> loadPlayerStats() async => const PlayerStats();
Future<void> savePlayerStats(PlayerStats stats) async {}

Future<String> loadLastPlayerName() async => 'PILOT';
Future<void> saveLastPlayerName(String name) async {}
Future<bool> hasSavedPlayerName() async => false;
Future<bool> loadIsNameConfigured() async => false;
Future<void> saveIsNameConfigured(bool configured) async {}

Future<List<String>> loadUnlockedSkins() async => ['classic'];
Future<void> saveUnlockedSkins(List<String> skins) async {}

Future<List<String>> loadUnlockedWorlds() async => ['sunrise_valley'];
Future<void> saveUnlockedWorlds(List<String> worlds) async {}

Future<String> loadActiveSkin() async => 'classic';
Future<void> saveActiveSkin(String skinId) async {}

Future<String> loadActiveWorld() async => 'sunrise_valley';
Future<void> saveActiveWorld(String worldId) async {}

Future<List<DailyChallenge>> loadDailyChallenges(DateTime now) async =>
    DailyChallenge.generateForDate(now);
Future<void> saveDailyChallenges(DateTime now, List<DailyChallenge> list) async {}

Future<List<WeeklyChallenge>> loadWeeklyChallenges(DateTime now) async =>
    WeeklyChallenge.generateForWeek(now);
Future<void> saveWeeklyChallenges(DateTime now, List<WeeklyChallenge> list) async {}

Future<List<Achievement>> loadAchievements() async => Achievement.initialList();
Future<void> saveAchievements(List<Achievement> list) async {}

Future<GameSettings> loadGameSettings() async => const GameSettings();
Future<void> saveGameSettings(GameSettings settings) async {}
