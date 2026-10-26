import 'leaderboard_model.dart';

Future<int> loadBestScore() async => 0;
Future<void> saveBestScore(int score) async {}

Future<List<LeaderboardEntry>> loadLeaderboard() async =>
    LeaderboardEntry.defaultLeaderboard;
Future<void> saveLeaderboard(List<LeaderboardEntry> list) async {}

Future<PlayerStats> loadPlayerStats() async => const PlayerStats();
Future<void> savePlayerStats(PlayerStats stats) async {}

Future<String> loadLastPlayerName() async => 'PILOT';
Future<void> saveLastPlayerName(String name) async {}
