// Native File I/O Storage Implementation for Mobile (Android, iOS) & Desktop (Windows, macOS, Linux).
// Persists game records, high scores, and player statistics as local JSON and text files.

import 'dart:convert';
import 'dart:io';
import 'leaderboard_model.dart';

// Fast in-memory caches to avoid repeated disk reads during active gameplay frames
int _inMemoryBest = 0;
List<LeaderboardEntry>? _inMemoryLeaderboard;
PlayerStats? _inMemoryStats;
String? _inMemoryName;

/// Loads the player's personal best score from disk ('flappy_best.txt').
Future<int> loadBestScore() async {
  // If already loaded in memory cache, return immediately without accessing the hard drive
  if (_inMemoryBest > 0) return _inMemoryBest;

  try {
    final file = File('flappy_best.txt');
    if (await file.exists()) {
      final content = await file.readAsString();
      // Parse the stored text into an integer, defaulting to 0 if invalid
      _inMemoryBest = int.tryParse(content.trim()) ?? 0;
      return _inMemoryBest;
    }
  } catch (_) {
    // Graceful catch for read or permissions exceptions
  }
  return _inMemoryBest;
}

/// Saves the player's personal best score to disk ('flappy_best.txt').
Future<void> saveBestScore(int score) async {
  // Update the in-memory cache first for instant UI response
  _inMemoryBest = score;
  try {
    final file = File('flappy_best.txt');
    // Overwrite the file with the new score integer as a string
    await file.writeAsString(score.toString());
  } catch (_) {
    // Silently ignore disk write issues so game flow is never interrupted
  }
}

/// Loads the Hall of Fame leaderboard entries from disk ('flappy_leaderboard.json').
Future<List<LeaderboardEntry>> loadLeaderboard() async {
  // Return cached entries if available
  if (_inMemoryLeaderboard != null) return _inMemoryLeaderboard!;

  try {
    final file = File('flappy_leaderboard.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      // Decode the JSON array into LeaderboardEntry models
      _inMemoryLeaderboard = LeaderboardEntry.decodeList(content);
      return _inMemoryLeaderboard!;
    }
  } catch (_) {}

  // If file doesn't exist yet, populate memory with default arcade champions
  _inMemoryLeaderboard = List.from(LeaderboardEntry.defaultLeaderboard);
  return _inMemoryLeaderboard!;
}

/// Saves the updated Hall of Fame leaderboard list to disk ('flappy_leaderboard.json').
Future<void> saveLeaderboard(List<LeaderboardEntry> list) async {
  _inMemoryLeaderboard = List.from(list);
  try {
    final file = File('flappy_leaderboard.json');
    // Serialize the list of entries to a formatted JSON string
    await file.writeAsString(LeaderboardEntry.encodeList(list));
  } catch (_) {}
}

/// Loads cumulative player career statistics from disk ('flappy_stats.json').
Future<PlayerStats> loadPlayerStats() async {
  if (_inMemoryStats != null) return _inMemoryStats!;

  try {
    final file = File('flappy_stats.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      // Parse JSON into a PlayerStats model
      _inMemoryStats =
          PlayerStats.fromJson(jsonDecode(content) as Map<String, dynamic>);
      return _inMemoryStats!;
    }
  } catch (_) {}

  // If no stats file exists yet, start with fresh 0-stats
  _inMemoryStats = const PlayerStats();
  return _inMemoryStats!;
}

/// Saves cumulative player career statistics to disk ('flappy_stats.json').
Future<void> savePlayerStats(PlayerStats stats) async {
  _inMemoryStats = stats;
  try {
    final file = File('flappy_stats.json');
    // Convert stats to JSON map and write to disk
    await file.writeAsString(jsonEncode(stats.toJson()));
  } catch (_) {}
}

/// Loads the player's last entered pilot callsign from disk ('flappy_name.txt').
Future<String> loadLastPlayerName() async {
  if (_inMemoryName != null) return _inMemoryName!;

  try {
    final file = File('flappy_name.txt');
    if (await file.exists()) {
      final content = (await file.readAsString()).trim();
      if (content.isNotEmpty) {
        _inMemoryName = content;
        return _inMemoryName!;
      }
    }
  } catch (_) {}

  _inMemoryName = 'PILOT';
  return _inMemoryName!;
}

/// Persists the player's pilot callsign to disk ('flappy_name.txt').
Future<void> saveLastPlayerName(String name) async {
  _inMemoryName = name.trim();
  try {
    final file = File('flappy_name.txt');
    await file.writeAsString(name.trim());
  } catch (_) {}
}
