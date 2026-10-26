import 'dart:convert';

/// Represents a single score record in the Hall of Fame.
class LeaderboardEntry {
  final String name;
  final int score;
  final String date;
  final String medal;
  final String skin;

  const LeaderboardEntry({
    required this.name,
    required this.score,
    required this.date,
    required this.medal,
    this.skin = 'classic',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'date': date,
        'medal': medal,
        'skin': skin,
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        name: json['name'] as String? ?? 'PILOT',
        score: (json['score'] as num?)?.toInt() ?? 0,
        date: json['date'] as String? ?? 'Today',
        medal: json['medal'] as String? ?? 'None',
        skin: json['skin'] as String? ?? 'classic',
      );

  static List<LeaderboardEntry> decodeList(String raw) {
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return defaultLeaderboard;
    }
  }

  static String encodeList(List<LeaderboardEntry> list) {
    return jsonEncode(list.map((e) => e.toJson()).toList());
  }

  static const List<LeaderboardEntry> defaultLeaderboard = [
    LeaderboardEntry(
      name: 'SKY_KING',
      score: 52,
      date: 'Champion',
      medal: 'Platinum',
      skin: 'gold',
    ),
    LeaderboardEntry(
      name: 'PHOENIX',
      score: 38,
      date: 'Master',
      medal: 'Gold',
      skin: 'phoenix',
    ),
    LeaderboardEntry(
      name: 'NEO_PILOT',
      score: 25,
      date: 'Veteran',
      medal: 'Gold',
      skin: 'cyber',
    ),
    LeaderboardEntry(
      name: 'MAVERICK',
      score: 16,
      date: 'Ace',
      medal: 'Silver',
      skin: 'classic',
    ),
    LeaderboardEntry(
      name: 'WINGMAN',
      score: 10,
      date: 'Cadet',
      medal: 'Silver',
      skin: 'classic',
    ),
    LeaderboardEntry(
      name: 'ROOKIE',
      score: 5,
      date: 'Trainee',
      medal: 'Bronze',
      skin: 'classic',
    ),
  ];
}

/// Cumulative career statistics for the local player.
class PlayerStats {
  final int gamesPlayed;
  final int totalFlaps;
  final int totalScore;
  final int bestScore;

  const PlayerStats({
    this.gamesPlayed = 0,
    this.totalFlaps = 0,
    this.totalScore = 0,
    this.bestScore = 0,
  });

  double get averageScore =>
      gamesPlayed > 0 ? (totalScore / gamesPlayed) : 0.0;

  Map<String, dynamic> toJson() => {
        'gamesPlayed': gamesPlayed,
        'totalFlaps': totalFlaps,
        'totalScore': totalScore,
        'bestScore': bestScore,
      };

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
        gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
        totalFlaps: (json['totalFlaps'] as num?)?.toInt() ?? 0,
        totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
        bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
      );

  PlayerStats copyWith({
    int? gamesPlayed,
    int? totalFlaps,
    int? totalScore,
    int? bestScore,
  }) {
    return PlayerStats(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      totalFlaps: totalFlaps ?? this.totalFlaps,
      totalScore: totalScore ?? this.totalScore,
      bestScore: bestScore ?? this.bestScore,
    );
  }
}
