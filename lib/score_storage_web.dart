// Web Browser Storage Implementation using the W3C DOM Storage API (window.localStorage).
// Persists scores, stats, gems, unlocked items, daily & weekly challenges, and settings in browser storage.

import 'dart:convert';
import 'package:web/web.dart' as web;
import 'game_models.dart';
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

Future<int> loadTotalGems() async {
  try {
    final val = web.window.localStorage.getItem('flappy_total_gems');
    if (val != null) {
      return int.tryParse(val) ?? 0;
    }
  } catch (_) {}
  return 0;
}

Future<void> saveTotalGems(int gems) async {
  try {
    web.window.localStorage.setItem('flappy_total_gems', gems.toString());
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

Future<List<String>> loadUnlockedSkins() async {
  try {
    final val = web.window.localStorage.getItem('flappy_unlocked_skins');
    if (val != null && val.isNotEmpty) {
      final list = (jsonDecode(val) as List<dynamic>).cast<String>();
      if (!list.contains('classic')) list.add('classic');
      return list;
    }
  } catch (_) {}
  return ['classic'];
}

Future<void> saveUnlockedSkins(List<String> skins) async {
  try {
    web.window.localStorage.setItem('flappy_unlocked_skins', jsonEncode(skins));
  } catch (_) {}
}

Future<List<String>> loadUnlockedWorlds() async {
  try {
    final val = web.window.localStorage.getItem('flappy_unlocked_worlds');
    if (val != null && val.isNotEmpty) {
      final list = (jsonDecode(val) as List<dynamic>).cast<String>();
      if (!list.contains('sunrise_valley')) list.add('sunrise_valley');
      return list;
    }
  } catch (_) {}
  return ['sunrise_valley'];
}

Future<void> saveUnlockedWorlds(List<String> worlds) async {
  try {
    web.window.localStorage.setItem('flappy_unlocked_worlds', jsonEncode(worlds));
  } catch (_) {}
}

Future<String> loadActiveSkin() async {
  try {
    final val = web.window.localStorage.getItem('flappy_active_skin');
    if (val != null && val.isNotEmpty) return val;
  } catch (_) {}
  return 'classic';
}

Future<void> saveActiveSkin(String skinId) async {
  try {
    web.window.localStorage.setItem('flappy_active_skin', skinId);
  } catch (_) {}
}

Future<String> loadActiveWorld() async {
  try {
    final val = web.window.localStorage.getItem('flappy_active_world');
    if (val != null && val.isNotEmpty) return val;
  } catch (_) {}
  return 'sunrise_valley';
}

Future<void> saveActiveWorld(String worldId) async {
  try {
    web.window.localStorage.setItem('flappy_active_world', worldId);
  } catch (_) {}
}

Future<List<DailyChallenge>> loadDailyChallenges(DateTime now) async {
  final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  try {
    final val = web.window.localStorage.getItem('flappy_daily_challenges');
    if (val != null && val.isNotEmpty) {
      final map = jsonDecode(val) as Map<String, dynamic>;
      if (map['date'] == dateKey) {
        return (map['challenges'] as List<dynamic>)
            .map((c) => DailyChallenge.fromJson(c as Map<String, dynamic>))
            .toList();
      }
    }
  } catch (_) {}

  final fresh = DailyChallenge.generateForDate(now);
  await saveDailyChallenges(now, fresh);
  return fresh;
}

Future<void> saveDailyChallenges(DateTime now, List<DailyChallenge> list) async {
  final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  try {
    web.window.localStorage.setItem(
      'flappy_daily_challenges',
      jsonEncode({
        'date': dateKey,
        'challenges': list.map((c) => c.toJson()).toList(),
      }),
    );
  } catch (_) {}
}

Future<List<WeeklyChallenge>> loadWeeklyChallenges(DateTime now) async {
  final dayOfYear = int.parse("${now.difference(DateTime(now.year, 1, 1)).inDays}");
  final weekNumber = ((dayOfYear - now.weekday + 10) / 7).floor();
  final weekKey = '${now.year}-W$weekNumber';

  try {
    final val = web.window.localStorage.getItem('flappy_weekly_challenges');
    if (val != null && val.isNotEmpty) {
      final map = jsonDecode(val) as Map<String, dynamic>;
      if (map['week'] == weekKey) {
        return (map['challenges'] as List<dynamic>)
            .map((c) => WeeklyChallenge.fromJson(c as Map<String, dynamic>))
            .toList();
      }
    }
  } catch (_) {}

  final fresh = WeeklyChallenge.generateForWeek(now);
  await saveWeeklyChallenges(now, fresh);
  return fresh;
}

Future<void> saveWeeklyChallenges(DateTime now, List<WeeklyChallenge> list) async {
  final dayOfYear = int.parse("${now.difference(DateTime(now.year, 1, 1)).inDays}");
  final weekNumber = ((dayOfYear - now.weekday + 10) / 7).floor();
  final weekKey = '${now.year}-W$weekNumber';

  try {
    web.window.localStorage.setItem(
      'flappy_weekly_challenges',
      jsonEncode({
        'week': weekKey,
        'challenges': list.map((c) => c.toJson()).toList(),
      }),
    );
  } catch (_) {}
}

Future<List<Achievement>> loadAchievements() async {
  final defaults = Achievement.initialList();
  try {
    final val = web.window.localStorage.getItem('flappy_achievements');
    if (val != null && val.isNotEmpty) {
      final list = jsonDecode(val) as List<dynamic>;
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
  return defaults;
}

Future<void> saveAchievements(List<Achievement> list) async {
  try {
    web.window.localStorage.setItem(
      'flappy_achievements',
      jsonEncode(list.map((a) => a.toJson()).toList()),
    );
  } catch (_) {}
}

Future<GameSettings> loadGameSettings() async {
  try {
    final val = web.window.localStorage.getItem('flappy_settings');
    if (val != null && val.isNotEmpty) {
      return GameSettings.fromJson(jsonDecode(val) as Map<String, dynamic>);
    }
  } catch (_) {}
  return const GameSettings();
}

Future<void> saveGameSettings(GameSettings settings) async {
  try {
    web.window.localStorage.setItem(
      'flappy_settings',
      jsonEncode(settings.toJson()),
    );
  } catch (_) {}
}
