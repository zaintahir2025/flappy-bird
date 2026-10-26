import 'package:flutter/material.dart';
import 'leaderboard_model.dart';

class LeaderboardDialog extends StatefulWidget {
  final List<LeaderboardEntry> leaderboard;
  final PlayerStats stats;
  final VoidCallback? onClose;

  const LeaderboardDialog({
    super.key,
    required this.leaderboard,
    required this.stats,
    this.onClose,
  });

  @override
  State<LeaderboardDialog> createState() => _LeaderboardDialogState();
}

class _LeaderboardDialogState extends State<LeaderboardDialog> {
  int _selectedTab = 0; // 0 = Leaderboard, 1 = Pilot Stats

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
          decoration: BoxDecoration(
            color: const Color(0xFFDED895), // Retro Flappy parchment gold
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF558022), width: 4),
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
              // Header banner with Title & Close button
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF09030),
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
                    const SizedBox(width: 28),
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

              // Segmented Tab Selector
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFCFB86A),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFB8AE67), width: 2),
                  ),
                ),
                child: Row(
                  children: [
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

              // Tab Views
              Expanded(
                child: _selectedTab == 0
                    ? _buildLeaderboardTab()
                    : _buildStatsTab(),
              ),

              // Bottom Done Button
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

        if (rank == 1) {
          rankColor = const Color(0xFFFFB300);
          rankWidget = const Icon(Icons.workspace_premium,
              color: Color(0xFFFFB300), size: 26);
        } else if (rank == 2) {
          rankColor = const Color(0xFF9E9E9E);
          rankWidget = const Icon(Icons.military_tech,
              color: Color(0xFF9E9E9E), size: 24);
        } else if (rank == 3) {
          rankColor = const Color(0xFFCD7F32);
          rankWidget = const Icon(Icons.military_tech,
              color: Color(0xFFCD7F32), size: 22);
        } else {
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
              SizedBox(width: 28, child: Center(child: rankWidget)),
              const SizedBox(width: 8),
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

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildStatRow('Best High Score', '${widget.stats.bestScore}',
              Icons.emoji_events, const Color(0xFFFFB300)),
          const SizedBox(height: 8),
          _buildStatRow('Games Played', '${widget.stats.gamesPlayed}',
              Icons.sports_esports, const Color(0xFF2196F3)),
          const SizedBox(height: 8),
          _buildStatRow('Total Flaps', '${widget.stats.totalFlaps}',
              Icons.touch_app, const Color(0xFF4CAF50)),
          const SizedBox(height: 8),
          _buildStatRow(
            'Average Score',
            widget.stats.averageScore.toStringAsFixed(1),
            Icons.speed_rounded,
            const Color(0xFF9C27B0),
          ),
          const SizedBox(height: 12),
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
