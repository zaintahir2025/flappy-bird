// Flutter Material Design library for modal dialogs, tab switching, and custom lists
import 'package:flutter/material.dart';

// Leaderboard and PlayerStats data models
import 'leaderboard_model.dart';

/// Modal dialog displaying the Hall of Fame Leaderboard and cumulative Pilot Career Statistics.
class LeaderboardDialog extends StatefulWidget {
  // The sorted list of top score entries to display
  final List<LeaderboardEntry> leaderboard;

  // The local player's cumulative career stats
  final PlayerStats stats;

  // The local player's current total Sky Gems wallet balance
  final int totalGems;

  // Optional callback executed when the dialog is dismissed
  final VoidCallback? onClose;

  const LeaderboardDialog({
    super.key,
    required this.leaderboard,
    required this.stats,
    this.totalGems = 0,
    this.onClose,
  });

  @override
  State<LeaderboardDialog> createState() => _LeaderboardDialogState();
}

class _LeaderboardDialogState extends State<LeaderboardDialog> {
  // Tracks active segmented tab: 0 = High Score Leaderboard, 1 = Career Pilot Stats
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final maxH = (screenH * 0.88).clamp(280.0, 540.0);

    return Dialog(
      backgroundColor: Colors.transparent, // Allows custom rounded parchment background
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: Container(
          // Constraints ensure dialog looks crisp on mobile screens and does not over-expand on desktop
          constraints: BoxConstraints(maxWidth: 420, maxHeight: maxH),
          decoration: BoxDecoration(
            color: const Color(0xFFDED895), // Retro Flappy parchment gold background
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF558022), width: 4), // Chunky green arcade border
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Header banner with Title & Close (X) button
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF09030), // Warm amber header bar
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF558022), width: 3),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 28), // Balances the close button on the right for true centering
                    const Expanded(
                      child: Text(
                        'HALL OF FAME',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Close button icon
                    InkWell(
                      key: const Key('dialog_close_icon'),
                      onTap: () {
                        widget.onClose?.call();
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.2),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Segmented Tab Selector (LEADERBOARD vs PILOT STATS)
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFCFB86A),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFB8AE67), width: 2),
                  ),
                ),
                child: Row(
                  children: [
                    // Leaderboard Tab Button
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTab = 0;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? const Color(0xFFDED895)
                                : const Color(0xFFCFB86A),
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedTab == 0
                                    ? const Color(0xFFD32F2F)
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emoji_events, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'LEADERBOARD',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Pilot Stats Tab Button
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTab = 1;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? const Color(0xFFDED895)
                                : const Color(0xFFCFB86A),
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedTab == 1
                                    ? const Color(0xFFD32F2F)
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.analytics_rounded, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'PILOT STATS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Tab Body View (Scrollable list of scores or stats cards)
              Expanded(
                child: _selectedTab == 0
                    ? _buildLeaderboardTab()
                    : _buildStatsTab(),
              ),

              // 4. Bottom Dismiss Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton.icon(
                  key: const Key('dialog_done_button'),
                  onPressed: () {
                    widget.onClose?.call();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text(
                    'DONE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the scrollable list of Top 10 high scores with rank medals.
  Widget _buildLeaderboardTab() {
    if (widget.leaderboard.isEmpty) {
      return const Center(
        child: Text(
          'No records yet. Be the first!',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF554A18),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: widget.leaderboard.length,
      itemBuilder: (context, index) {
        final entry = widget.leaderboard[index];
        final rank = index + 1;

        Color rankColor = const Color(0xFF706733);
        Widget rankWidget;

        // Visual distinction for Top 3 podium ranks
        if (rank == 1) {
          rankColor = const Color(0xFFFFB300); // Gold
          rankWidget = const Icon(Icons.workspace_premium,
              color: Color(0xFFFFB300), size: 26);
        } else if (rank == 2) {
          rankColor = const Color(0xFF9E9E9E); // Silver
          rankWidget = const Icon(Icons.military_tech,
              color: Color(0xFF9E9E9E), size: 24);
        } else if (rank == 3) {
          rankColor = const Color(0xFFCD7F32); // Bronze
          rankWidget = const Icon(Icons.military_tech,
              color: Color(0xFFCD7F32), size: 22);
        } else {
          // Standard numbered circle badge for 4th and below
          rankWidget = Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.08),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: rankColor,
              ),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color:
                rank == 1 ? const Color(0xFFFFF9C4) : const Color(0xFFF7F3D0),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: rank == 1
                  ? const Color(0xFFFFB300)
                  : const Color(0xFFB8AE67),
              width: rank == 1 ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Rank badge / medal
              SizedBox(width: 28, child: Center(child: rankWidget)),
              const SizedBox(width: 8),

              // Pilot Name & Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${entry.date} • ${entry.medal} Medal',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF706733),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Score tag pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${entry.score}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the cumulative career statistics tab.
  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Best Score row
          _buildStatRow('Best High Score', '${widget.stats.bestScore}',
              Icons.emoji_events, const Color(0xFFFFB300)),
          const SizedBox(height: 8),

          // Total games played
          _buildStatRow('Games Played', '${widget.stats.gamesPlayed}',
              Icons.sports_esports, const Color(0xFF2196F3)),
          const SizedBox(height: 8),

          // Total flaps / taps
          _buildStatRow('Total Flaps', '${widget.stats.totalFlaps}',
              Icons.touch_app, const Color(0xFF4CAF50)),
          const SizedBox(height: 8),

          // Average score per game
          _buildStatRow(
            'Average Score',
            widget.stats.averageScore.toStringAsFixed(1),
            Icons.speed_rounded,
            const Color(0xFF9C27B0),
          ),
          const SizedBox(height: 8),

          // Total Lifetime Sky Gems Collected
          _buildStatRow(
            'Sky Gems Collected',
            '${widget.stats.totalGemsCollected}',
            Icons.diamond_rounded,
            const Color(0xFFFFD700),
          ),
          const SizedBox(height: 8),

          // Current Sky Gems Wallet Balance
          _buildStatRow(
            'Current Gem Wallet',
            '${widget.totalGems}',
            Icons.account_balance_wallet_rounded,
            const Color(0xFF00E5FF),
          ),
          const SizedBox(height: 12),

          // Pro-pilot tip banner
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3D0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFB8AE67), width: 1.5),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    color: Color(0xFFF09030), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: Tap lightly and time your flaps right as the bird descends for maximum control!',
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF554A18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget building a consistent visual row for a career statistic card.
  Widget _buildStatRow(
      String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3D0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB8AE67)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF554A18),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
