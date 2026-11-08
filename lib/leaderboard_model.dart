// Standard Dart library for converting objects to and from JSON (JavaScript Object Notation) strings
import 'dart:convert';

/// Represents a single persistent score record in the Hall of Fame leaderboard.
class LeaderboardEntry {
  // The pilot's callsign or nickname (e.g., 'ACE', 'SKY_KING')
  final String name;

  // The total number of pipe pairs successfully passed in this run
  final int score;

  // The timestamp string or title rank when the score was set (e.g., 'Master', 'Champion')
  final String date;

  // Medal awarded for this achievement ('Platinum', 'Gold', 'Silver', 'Bronze')
  final String medal;

  // The bird skin identifier used during the flight ('classic', 'phoenix', 'cyber', 'gold')
  final String skin;

  // Constant constructor requiring core properties and defaulting skin to 'classic'
  const LeaderboardEntry({
    required this.name,
    required this.score,
    required this.date,
    required this.medal,
    this.skin = 'classic',
  });

  /// Serializes this LeaderboardEntry object into a standard Dart Map of key-value pairs.
  /// Used before converting to a JSON string for storage on disk or in the browser.
  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'date': date,
        'medal': medal,
        'skin': skin,
      };

  /// Factory constructor to reconstruct a LeaderboardEntry from a deserialized JSON Map.
  /// Includes safe null-coalescing defaults so corrupted data never crashes the app.
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        name: json['name'] as String? ?? 'PILOT',
        score: (json['score'] as num?)?.toInt() ?? 0,
        date: json['date'] as String? ?? 'Today',
        medal: json['medal'] as String? ?? 'None',
        skin: json['skin'] as String? ?? 'classic',
      );

  /// Decodes a raw JSON string into a strongly-typed List of LeaderboardEntry items.
  /// If parsing fails for any reason (e.g., corrupted file), falls back to the default champions list.
  static List<LeaderboardEntry> decodeList(String raw) {
    try {
      // Decode the raw JSON string into dynamic List elements
      final decoded = jsonDecode(raw) as List<dynamic>;

      // Map each JSON object to a LeaderboardEntry model instance
      return decoded
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Safe fallback if JSON structure is damaged or invalid
      return defaultLeaderboard;
    }
  }

  /// Encodes a List of LeaderboardEntry items into a formatted JSON string for saving.
  static String encodeList(List<LeaderboardEntry> list) {
    return jsonEncode(list.map((e) => e.toJson()).toList());
  }

  /// Seeded arcade champions displayed when the game is launched for the first time.
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

/// Cumulative lifetime career statistics for the local pilot across all games played.
class PlayerStats {
  // Total number of game rounds started
  final int gamesPlayed;

  // Total cumulative wing flaps / screen taps across all sessions
  final int totalFlaps;

  // Total points accumulated across all career games
  final int totalScore;

  // Highest individual score ever achieved
  final int bestScore;

  // Total lifetime Sky Gems collected across all flights
  final int totalGemsCollected;

  // Constant constructor initializing all fields to 0 by default
  const PlayerStats({
    this.gamesPlayed = 0,
    this.totalFlaps = 0,
    this.totalScore = 0,
    this.bestScore = 0,
    this.totalGemsCollected = 0,
  });

  /// Computes the lifetime average score per game played (avoids division by zero).
  double get averageScore =>
      gamesPlayed > 0 ? (totalScore / gamesPlayed) : 0.0;

  /// Serializes the career statistics into a JSON-compatible key-value Map.
  Map<String, dynamic> toJson() => {
        'gamesPlayed': gamesPlayed,
        'totalFlaps': totalFlaps,
        'totalScore': totalScore,
        'bestScore': bestScore,
        'totalGemsCollected': totalGemsCollected,
      };

  /// Deserializes a JSON Map into a strongly-typed PlayerStats object with safe defaults.
  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
        gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
        totalFlaps: (json['totalFlaps'] as num?)?.toInt() ?? 0,
        totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
        bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
        totalGemsCollected: (json['totalGemsCollected'] as num?)?.toInt() ?? 0,
      );

  /// Immutable update helper: creates a copy of this PlayerStats object with optional updated fields.
  PlayerStats copyWith({
    int? gamesPlayed,
    int? totalFlaps,
    int? totalScore,
    int? bestScore,
    int? totalGemsCollected,
  }) {
    return PlayerStats(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      totalFlaps: totalFlaps ?? this.totalFlaps,
      totalScore: totalScore ?? this.totalScore,
      bestScore: bestScore ?? this.bestScore,
      totalGemsCollected: totalGemsCollected ?? this.totalGemsCollected,
    );
  }
}
