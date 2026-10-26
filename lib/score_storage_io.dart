import 'dart:convert';
import 'dart:io';
import 'leaderboard_model.dart';

int _inMemoryBest = 0;
List<LeaderboardEntry>? _inMemoryLeaderboard;
PlayerStats? _inMemoryStats;
String? _inMemoryName;

Future<int> loadBestScore() async {
  if (_inMemoryBest > 0) return _inMemoryBest;
  try {
    final file = File('flappy_best.txt');
    if (await file.exists()) {
      final content = await file.readAsString();
      _inMemoryBest = int.tryParse(content.trim()) ?? 0;
      return _inMemoryBest;
    }
  } catch (_) {}
  return _inMemoryBest;
}

Future<void> saveBestScore(int score) async {
  _inMemoryBest = score;
  try {
    final file = File('flappy_best.txt');
    await file.writeAsString(score.toString());
  } catch (_) {}
}

Future<List<LeaderboardEntry>> loadLeaderboard() async {
  if (_inMemoryLeaderboard != null) return _inMemoryLeaderboard!;
  try {
    final file = File('flappy_leaderboard.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      _inMemoryLeaderboard = LeaderboardEntry.decodeList(content);
      return _inMemoryLeaderboard!;
    }
  } catch (_) {}
  _inMemoryLeaderboard = List.from(LeaderboardEntry.defaultLeaderboard);
  return _inMemoryLeaderboard!;
}

Future<void> saveLeaderboard(List<LeaderboardEntry> list) async {
  _inMemoryLeaderboard = List.from(list);
  try {
    final file = File('flappy_leaderboard.json');
    await file.writeAsString(LeaderboardEntry.encodeList(list));
  } catch (_) {}
}

Future<PlayerStats> loadPlayerStats() async {
  if (_inMemoryStats != null) return _inMemoryStats!;
  try {
    final file = File('flappy_stats.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      _inMemoryStats = PlayerStats.fromJson(jsonDecode(content) as Map<String, dynamic>);
      return _inMemoryStats!;
    }
  } catch (_) {}
  _inMemoryStats = const PlayerStats();
  return _inMemoryStats!;
}

Future<void> savePlayerStats(PlayerStats stats) async {
  _inMemoryStats = stats;
  try {
    final file = File('flappy_stats.json');
    await file.writeAsString(jsonEncode(stats.toJson()));
  } catch (_) {}
}

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

Future<void> saveLastPlayerName(String name) async {
  _inMemoryName = name.trim();
  try {
    final file = File('flappy_name.txt');
    await file.writeAsString(name.trim());
  } catch (_) {}
}
