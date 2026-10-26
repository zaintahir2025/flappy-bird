import 'dart:convert';
import 'package:web/web.dart' as web;
import 'leaderboard_model.dart';

Future<int> loadBestScore() async {
  try {
    final val = web.window.localStorage.getItem('flappy_best_score');
    if (val != null) {
      return int.tryParse(val) ?? 0;
    }
  } catch (_) {}
  return 0;
}

Future<void> saveBestScore(int score) async {
  try {
    web.window.localStorage.setItem('flappy_best_score', score.toString());
  } catch (_) {}
}

Future<List<LeaderboardEntry>> loadLeaderboard() async {
  try {
    final val = web.window.localStorage.getItem('flappy_leaderboard');
    if (val != null && val.isNotEmpty) {
      return LeaderboardEntry.decodeList(val);
    }
  } catch (_) {}
  return List.from(LeaderboardEntry.defaultLeaderboard);
}

Future<void> saveLeaderboard(List<LeaderboardEntry> list) async {
  try {
    web.window.localStorage.setItem(
      'flappy_leaderboard',
      LeaderboardEntry.encodeList(list),
    );
  } catch (_) {}
}

Future<PlayerStats> loadPlayerStats() async {
  try {
    final val = web.window.localStorage.getItem('flappy_stats');
    if (val != null && val.isNotEmpty) {
      return PlayerStats.fromJson(jsonDecode(val) as Map<String, dynamic>);
    }
  } catch (_) {}
  return const PlayerStats();
}

Future<void> savePlayerStats(PlayerStats stats) async {
  try {
    web.window.localStorage.setItem(
      'flappy_stats',
      jsonEncode(stats.toJson()),
    );
  } catch (_) {}
}

Future<String> loadLastPlayerName() async {
  try {
    final val = web.window.localStorage.getItem('flappy_pilot_name');
    if (val != null && val.trim().isNotEmpty) {
      return val.trim();
    }
  } catch (_) {}
  return 'PILOT';
}

Future<void> saveLastPlayerName(String name) async {
  try {
    web.window.localStorage.setItem('flappy_pilot_name', name.trim());
  } catch (_) {}
}
