// Web Browser Storage Implementation using the W3C DOM Storage API (window.localStorage).
// Persists scores and stats directly into the browser's persistent key-value store,
// so progress is remembered across browser restarts and page refreshes.

import 'dart:convert';
import 'package:web/web.dart' as web;
import 'leaderboard_model.dart';

/// Loads the player's personal best score from browser localStorage ('flappy_best_score').
Future<int> loadBestScore() async {
  try {
    // Read the string item from the browser's localStorage
    final val = web.window.localStorage.getItem('flappy_best_score');
    if (val != null) {
      return int.tryParse(val) ?? 0;
    }
  } catch (_) {
    // Failsafe catch for private browsing mode or storage quota errors
  }
  return 0;
}

/// Saves the player's personal best score into browser localStorage.
Future<void> saveBestScore(int score) async {
  try {
    web.window.localStorage.setItem('flappy_best_score', score.toString());
  } catch (_) {}
}

/// Loads the Hall of Fame leaderboard from browser localStorage ('flappy_leaderboard').
Future<List<LeaderboardEntry>> loadLeaderboard() async {
  try {
    final val = web.window.localStorage.getItem('flappy_leaderboard');
    if (val != null && val.isNotEmpty) {
      // Decode the stored JSON string into strongly-typed LeaderboardEntry models
      return LeaderboardEntry.decodeList(val);
    }
  } catch (_) {}

  // Fallback to default champions if no records exist in browser storage yet
  return List.from(LeaderboardEntry.defaultLeaderboard);
}

/// Saves the Hall of Fame leaderboard list as a JSON string in browser localStorage.
Future<void> saveLeaderboard(List<LeaderboardEntry> list) async {
  try {
    web.window.localStorage.setItem(
      'flappy_leaderboard',
      LeaderboardEntry.encodeList(list),
    );
  } catch (_) {}
}

/// Loads cumulative player career statistics from browser localStorage ('flappy_stats').
Future<PlayerStats> loadPlayerStats() async {
  try {
    final val = web.window.localStorage.getItem('flappy_stats');
    if (val != null && val.isNotEmpty) {
      return PlayerStats.fromJson(jsonDecode(val) as Map<String, dynamic>);
    }
  } catch (_) {}
  return const PlayerStats();
}

/// Saves cumulative player career statistics as a JSON string in browser localStorage.
Future<void> savePlayerStats(PlayerStats stats) async {
  try {
    web.window.localStorage.setItem(
      'flappy_stats',
      jsonEncode(stats.toJson()),
    );
  } catch (_) {}
}

/// Loads the player's last entered pilot callsign from browser localStorage ('flappy_pilot_name').
Future<String> loadLastPlayerName() async {
  try {
    final val = web.window.localStorage.getItem('flappy_pilot_name');
    if (val != null && val.trim().isNotEmpty) {
      return val.trim();
    }
  } catch (_) {}
  return 'PILOT';
}

/// Persists the player's pilot callsign into browser localStorage.
Future<void> saveLastPlayerName(String name) async {
  try {
    web.window.localStorage.setItem('flappy_pilot_name', name.trim());
  } catch (_) {}
}
