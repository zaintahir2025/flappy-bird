// Abstract fallback / stub implementation of the score storage interface.
// Used as the baseline definition and default fallback in environments where neither
// native file I/O nor browser DOM storage is available.

import 'leaderboard_model.dart';

/// Loads the player's all-time personal best score (returns 0 by default).
Future<int> loadBestScore() async => 0;

/// Persists the player's all-time personal best score.
Future<void> saveBestScore(int score) async {}

/// Loads the list of high score entries for the Hall of Fame (returns seeded champions by default).
Future<List<LeaderboardEntry>> loadLeaderboard() async =>
    LeaderboardEntry.defaultLeaderboard;

/// Persists the updated leaderboard entries list.
Future<void> saveLeaderboard(List<LeaderboardEntry> list) async {}

/// Loads the cumulative player career statistics (returns fresh 0-stats by default).
Future<PlayerStats> loadPlayerStats() async => const PlayerStats();

/// Persists the updated cumulative player career statistics.
Future<void> savePlayerStats(PlayerStats stats) async {}

/// Loads the last used pilot callsign / name (defaults to 'PILOT').
Future<String> loadLastPlayerName() async => 'PILOT';

/// Persists the pilot's callsign / name.
Future<void> saveLastPlayerName(String name) async {}
