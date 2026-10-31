// Native File I/O Storage Implementation for Mobile (Android, iOS) & Desktop (Windows, macOS, Linux).
// Persists game records, high scores, player statistics, gems, unlocks, challenges, and settings.

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'game_models.dart';
import 'leaderboard_model.dart';

// Fast in-memory caches to avoid repeated disk reads during active gameplay frames
int _inMemoryBest = 0;
int? _inMemoryGems;
List<LeaderboardEntry>? _inMemoryLeaderboard;
PlayerStats? _inMemoryStats;
String? _inMemoryName;
List<String>? _inMemorySkins;
List<String>? _inMemoryWorlds;
String? _inMemoryActiveSkin;
String? _inMemoryActiveWorld;
List<DailyChallenge>? _inMemoryDailyChallenges;
String? _inMemoryDailyChallengesDate;
List<WeeklyChallenge>? _inMemoryWeeklyChallenges;
String? _inMemoryWeeklyChallengesKey;
List<Achievement>? _inMemoryAchievements;
GameSettings? _inMemorySettings;

/// Loads the player's personal best score from disk ('flappy_best.txt').
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

/// Saves the player's personal best score to disk ('flappy_best.txt').
Future<void> saveBestScore(int score) async {
  _inMemoryBest = score;
  try {
    final file = File('flappy_best.txt');
    await file.writeAsString(score.toString());
  } catch (_) {}
}

/// Loads total accumulated Sky Gems wallet balance ('flappy_gems.txt').
Future<int> loadTotalGems() async {
  if (_inMemoryGems != null) return _inMemoryGems!;

  try {
    final file = File('flappy_gems.txt');
    if (await file.exists()) {
      final content = await file.readAsString();
      _inMemoryGems = int.tryParse(content.trim()) ?? 0;
      return _inMemoryGems!;
    }
  } catch (_) {}
  _inMemoryGems = 0;
  return _inMemoryGems!;
}

/// Saves total Sky Gems wallet balance ('flappy_gems.txt').
Future<void> saveTotalGems(int gems) async {
  _inMemoryGems = max(0, gems);
  try {
    final file = File('flappy_gems.txt');
    await file.writeAsString(_inMemoryGems.toString());
  } catch (_) {}
}

/// Loads the Hall of Fame leaderboard entries from disk ('flappy_leaderboard.json').
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

/// Saves the updated Hall of Fame leaderboard list to disk ('flappy_leaderboard.json').
Future<void> saveLeaderboard(List<LeaderboardEntry> list) async {
  _inMemoryLeaderboard = List.from(list);
  try {
    final file = File('flappy_leaderboard.json');
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
      _inMemoryStats =
          PlayerStats.fromJson(jsonDecode(content) as Map<String, dynamic>);
      return _inMemoryStats!;
    }
  } catch (_) {}

  _inMemoryStats = const PlayerStats();
  return _inMemoryStats!;
}

/// Saves cumulative player career statistics to disk ('flappy_stats.json').
Future<void> savePlayerStats(PlayerStats stats) async {
  _inMemoryStats = stats;
  try {
    final file = File('flappy_stats.json');
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

/// Loads unlocked skin IDs ('flappy_skins.json').
Future<List<String>> loadUnlockedSkins() async {
  if (_inMemorySkins != null) return _inMemorySkins!;

  try {
    final file = File('flappy_skins.json');
    if (await file.exists()) {
      final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
      _inMemorySkins = decoded.cast<String>();
      if (!_inMemorySkins!.contains('classic')) {
        _inMemorySkins!.add('classic');
      }
      return _inMemorySkins!;
    }
  } catch (_) {}

  _inMemorySkins = ['classic'];
  return _inMemorySkins!;
}

/// Saves unlocked skin IDs ('flappy_skins.json').
Future<void> saveUnlockedSkins(List<String> skins) async {
  _inMemorySkins = List.from(skins);
  try {
    final file = File('flappy_skins.json');
    await file.writeAsString(jsonEncode(_inMemorySkins));
  } catch (_) {}
}

/// Loads unlocked world IDs ('flappy_worlds.json').
Future<List<String>> loadUnlockedWorlds() async {
  if (_inMemoryWorlds != null) return _inMemoryWorlds!;

  try {
    final file = File('flappy_worlds.json');
    if (await file.exists()) {
      final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
      _inMemoryWorlds = decoded.cast<String>();
      if (!_inMemoryWorlds!.contains('sunrise_valley')) {
        _inMemoryWorlds!.add('sunrise_valley');
      }
      return _inMemoryWorlds!;
    }
  } catch (_) {}

  _inMemoryWorlds = ['sunrise_valley'];
  return _inMemoryWorlds!;
}

/// Saves unlocked world IDs ('flappy_worlds.json').
Future<void> saveUnlockedWorlds(List<String> worlds) async {
  _inMemoryWorlds = List.from(worlds);
  try {
    final file = File('flappy_worlds.json');
    await file.writeAsString(jsonEncode(_inMemoryWorlds));
  } catch (_) {}
}

/// Loads currently equipped skin ID ('flappy_active_skin.txt').
Future<String> loadActiveSkin() async {
  if (_inMemoryActiveSkin != null) return _inMemoryActiveSkin!;

  try {
    final file = File('flappy_active_skin.txt');
    if (await file.exists()) {
      final id = (await file.readAsString()).trim();
      if (id.isNotEmpty) {
        _inMemoryActiveSkin = id;
        return _inMemoryActiveSkin!;
      }
    }
  } catch (_) {}

  _inMemoryActiveSkin = 'classic';
  return _inMemoryActiveSkin!;
}

/// Saves currently equipped skin ID ('flappy_active_skin.txt').
Future<void> saveActiveSkin(String skinId) async {
  _inMemoryActiveSkin = skinId;
  try {
    final file = File('flappy_active_skin.txt');
    await file.writeAsString(skinId);
  } catch (_) {}
}

/// Loads currently selected world ID ('flappy_active_world.txt').
Future<String> loadActiveWorld() async {
  if (_inMemoryActiveWorld != null) return _inMemoryActiveWorld!;

  try {
    final file = File('flappy_active_world.txt');
    if (await file.exists()) {
      final id = (await file.readAsString()).trim();
      if (id.isNotEmpty) {
        _inMemoryActiveWorld = id;
        return _inMemoryActiveWorld!;
      }
    }
  } catch (_) {}

  _inMemoryActiveWorld = 'sunrise_valley';
  return _inMemoryActiveWorld!;
}

/// Saves currently selected world ID ('flappy_active_world.txt').
Future<void> saveActiveWorld(String worldId) async {
  _inMemoryActiveWorld = worldId;
  try {
    final file = File('flappy_active_world.txt');
    await file.writeAsString(worldId);
  } catch (_) {}
}

/// Loads daily challenges for today's date ('flappy_daily.json').
Future<List<DailyChallenge>> loadDailyChallenges(DateTime now) async {
  final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  if (_inMemoryDailyChallenges != null && _inMemoryDailyChallengesDate == dateKey) {
    return _inMemoryDailyChallenges!;
  }

  try {
    final file = File('flappy_daily.json');
    if (await file.exists()) {
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final savedDate = map['date'] as String?;
      if (savedDate == dateKey) {
        final list = (map['challenges'] as List<dynamic>)
            .map((c) => DailyChallenge.fromJson(c as Map<String, dynamic>))
            .toList();
        _inMemoryDailyChallenges = list;
        _inMemoryDailyChallengesDate = dateKey;
        return list;
      }
    }
  } catch (_) {}

  // Generate fresh quests for today
  final fresh = DailyChallenge.generateForDate(now);
  await saveDailyChallenges(now, fresh);
  return fresh;
}

/// Saves daily challenges with today's date ('flappy_daily.json').
Future<void> saveDailyChallenges(DateTime now, List<DailyChallenge> list) async {
  final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  _inMemoryDailyChallenges = List.from(list);
  _inMemoryDailyChallengesDate = dateKey;

  try {
    final file = File('flappy_daily.json');
    await file.writeAsString(jsonEncode({
      'date': dateKey,
      'challenges': list.map((c) => c.toJson()).toList(),
    }));
  } catch (_) {}
}

/// Loads weekly challenges for the current week ('flappy_weekly.json').
Future<List<WeeklyChallenge>> loadWeeklyChallenges(DateTime now) async {
  final dayOfYear = int.parse("${now.difference(DateTime(now.year, 1, 1)).inDays}");
  final weekNumber = ((dayOfYear - now.weekday + 10) / 7).floor();
  final weekKey = '${now.year}-W$weekNumber';

  if (_inMemoryWeeklyChallenges != null && _inMemoryWeeklyChallengesKey == weekKey) {
    return _inMemoryWeeklyChallenges!;
  }

  try {
    final file = File('flappy_weekly.json');
    if (await file.exists()) {
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final savedWeek = map['week'] as String?;
      if (savedWeek == weekKey) {
        final list = (map['challenges'] as List<dynamic>)
            .map((c) => WeeklyChallenge.fromJson(c as Map<String, dynamic>))
            .toList();
        _inMemoryWeeklyChallenges = list;
        _inMemoryWeeklyChallengesKey = weekKey;
        return list;
      }
    }
  } catch (_) {}

  // Generate fresh weekly quests
  final fresh = WeeklyChallenge.generateForWeek(now);
  await saveWeeklyChallenges(now, fresh);
  return fresh;
}

/// Saves weekly challenges with current week ('flappy_weekly.json').
Future<void> saveWeeklyChallenges(DateTime now, List<WeeklyChallenge> list) async {
  final dayOfYear = int.parse("${now.difference(DateTime(now.year, 1, 1)).inDays}");
  final weekNumber = ((dayOfYear - now.weekday + 10) / 7).floor();
  final weekKey = '${now.year}-W$weekNumber';

  _inMemoryWeeklyChallenges = List.from(list);
  _inMemoryWeeklyChallengesKey = weekKey;

  try {
    final file = File('flappy_weekly.json');
    await file.writeAsString(jsonEncode({
      'week': weekKey,
      'challenges': list.map((c) => c.toJson()).toList(),
    }));
  } catch (_) {}
}

/// Loads career achievements from disk ('flappy_achievements.json').
Future<List<Achievement>> loadAchievements() async {
  if (_inMemoryAchievements != null) return _inMemoryAchievements!;

  final defaults = Achievement.initialList();
  try {
    final file = File('flappy_achievements.json');
    if (await file.exists()) {
      final list = jsonDecode(await file.readAsString()) as List<dynamic>;
      final Map<String, Map<String, dynamic>> savedMap = {
        for (final item in list)
          (item as Map<String, dynamic>)['id'] as String: item,
      };

      for (final a in defaults) {
        if (savedMap.containsKey(a.id)) {
          final s = savedMap[a.id]!;
          a.currentProgress = (s['currentProgress'] as num?)?.toInt() ?? 0;
          a.isUnlocked = s['isUnlocked'] as bool? ?? false;
          a.isClaimed = s['isClaimed'] as bool? ?? false;
        }
      }
    }
  } catch (_) {}

  _inMemoryAchievements = defaults;
  return defaults;
}

/// Saves career achievements to disk ('flappy_achievements.json').
Future<void> saveAchievements(List<Achievement> list) async {
  _inMemoryAchievements = List.from(list);
  try {
    final file = File('flappy_achievements.json');
    await file.writeAsString(jsonEncode(list.map((a) => a.toJson()).toList()));
  } catch (_) {}
}

/// Loads game settings from disk ('flappy_settings.json').
Future<GameSettings> loadGameSettings() async {
  if (_inMemorySettings != null) return _inMemorySettings!;

  try {
    final file = File('flappy_settings.json');
    if (await file.exists()) {
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _inMemorySettings = GameSettings.fromJson(map);
      return _inMemorySettings!;
    }
  } catch (_) {}

  _inMemorySettings = const GameSettings();
  return _inMemorySettings!;
}

/// Saves game settings to disk ('flappy_settings.json').
Future<void> saveGameSettings(GameSettings settings) async {
  _inMemorySettings = settings;
  try {
    final file = File('flappy_settings.json');
    await file.writeAsString(jsonEncode(settings.toJson()));
  } catch (_) {}
}
