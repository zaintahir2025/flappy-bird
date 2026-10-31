// Core Flutter UI and layout widgets
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Audio manager for UI feedback and reward chimes
import 'audio_manager.dart';

// Game models for quests and achievements
import 'game_models.dart';

// Score storage for persisting quest claims
import 'score_storage.dart' as score_storage;

/// Dialog presenting Daily Challenges, Weekly Endurance Quests, and Career Achievements.
class QuestsDialog extends StatefulWidget {
  final List<DailyChallenge> dailyChallenges;
  final List<WeeklyChallenge> weeklyChallenges;
  final List<Achievement> achievements;
  final int totalGems;
  final Function(int newGems, List<DailyChallenge> updatedDaily, List<WeeklyChallenge> updatedWeekly, List<Achievement> updatedAchievements) onGemsUpdated;

  const QuestsDialog({
    super.key,
    required this.dailyChallenges,
    required this.weeklyChallenges,
    required this.achievements,
    required this.totalGems,
    required this.onGemsUpdated,
  });

  @override
  State<QuestsDialog> createState() => _QuestsDialogState();
}

class _QuestsDialogState extends State<QuestsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<DailyChallenge> _daily;
  late List<WeeklyChallenge> _weekly;
  late List<Achievement> _achievements;
  late int _gems;

  AchievementCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _daily = List.from(widget.dailyChallenges);
    _weekly = List.from(widget.weeklyChallenges);
    _achievements = List.from(widget.achievements);
    _gems = widget.totalGems;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _claimDaily(DailyChallenge challenge) async {
    if (!challenge.isCompleted || challenge.isClaimed) return;

    setState(() {
      challenge.isClaimed = true;
      _gems += challenge.rewardGems;
    });

    AudioManager.instance.playUnlock();
    HapticFeedback.heavyImpact();

    await score_storage.saveTotalGems(_gems);
    await score_storage.saveDailyChallenges(DateTime.now(), _daily);
    widget.onGemsUpdated(_gems, _daily, _weekly, _achievements);
  }

  Future<void> _claimWeekly(WeeklyChallenge challenge) async {
    if (!challenge.isCompleted || challenge.isClaimed) return;

    setState(() {
      challenge.isClaimed = true;
      _gems += challenge.rewardGems;
    });

    AudioManager.instance.playUnlock();
    HapticFeedback.heavyImpact();

    await score_storage.saveTotalGems(_gems);
    await score_storage.saveWeeklyChallenges(DateTime.now(), _weekly);
    widget.onGemsUpdated(_gems, _daily, _weekly, _achievements);
  }

  Future<void> _claimAchievement(Achievement achievement) async {
    if (!achievement.isUnlocked || achievement.isClaimed) return;

    setState(() {
      achievement.isClaimed = true;
      _gems += achievement.rewardGems;
    });

    AudioManager.instance.playUnlock();
    HapticFeedback.heavyImpact();

    await score_storage.saveTotalGems(_gems);
    await score_storage.saveAchievements(_achievements);
    widget.onGemsUpdated(_gems, _daily, _weekly, _achievements);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF10B981), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x6610B981),
              blurRadius: 28,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.stars_rounded, color: Color(0xFF10B981), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MISSIONS & TROPHIES',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'Quests, Weekly Marathons & Career Feats',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Gem wallet
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond_rounded, color: Color(0xFFFFD700), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$_gems',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF10B981),
                ),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                tabs: const [
                  Tab(text: 'DAILY'),
                  Tab(text: 'WEEKLY'),
                  Tab(text: 'CAREER'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF1E293B), height: 1),

            // Tab view content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Daily
                  _buildDailyTab(),

                  // Tab 2: Weekly
                  _buildWeeklyTab(),

                  // Tab 3: Achievements
                  _buildAchievementsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _daily.length,
      itemBuilder: (context, index) {
        final q = _daily[index];
        final canClaim = q.isCompleted && !q.isClaimed;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: canClaim ? const Color(0xFF10B981) : const Color(0xFF334155),
              width: canClaim ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wb_sunny_rounded, color: Color(0xFF10B981), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      q.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond_rounded, color: Color(0xFFFFD700), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '+${q.rewardGems}',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                q.description,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: q.progressRatio,
                        minHeight: 8,
                        backgroundColor: const Color(0xFF0F172A),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${q.currentProgress} / ${q.target}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: canClaim ? () => _claimDaily(q) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canClaim ? const Color(0xFF10B981) : const Color(0xFF334155),
                      foregroundColor: canClaim ? Colors.black : Colors.white54,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(60, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      q.isClaimed ? 'CLAIMED' : (canClaim ? 'CLAIM' : 'ACTIVE'),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeeklyTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _weekly.length,
      itemBuilder: (context, index) {
        final q = _weekly[index];
        final canClaim = q.isCompleted && !q.isClaimed;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: canClaim ? const Color(0xFFF59E0B) : const Color(0xFF334155),
              width: canClaim ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.timer_rounded, color: Color(0xFFF59E0B), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      q.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond_rounded, color: Color(0xFFFFD700), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '+${q.rewardGems}',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                q.description,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: q.progressRatio,
                        minHeight: 8,
                        backgroundColor: const Color(0xFF0F172A),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${q.currentProgress} / ${q.target}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: canClaim ? () => _claimWeekly(q) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canClaim ? const Color(0xFFF59E0B) : const Color(0xFF334155),
                      foregroundColor: canClaim ? Colors.black : Colors.white54,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(60, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      q.isClaimed ? 'CLAIMED' : (canClaim ? 'CLAIM' : 'ACTIVE'),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementsTab() {
    final filtered = _selectedCategory == null
        ? _achievements
        : _achievements.where((a) => a.category == _selectedCategory).toList();

    return Column(
      children: [
        // Category chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildCategoryChip('ALL', null),
              for (final cat in AchievementCategory.values)
                _buildCategoryChip(AchievementCategoryData.of(cat).label, cat),
            ],
          ),
        ),

        // Achievements list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final a = filtered[index];
              final canClaim = a.isUnlocked && !a.isClaimed;
              final catData = AchievementCategoryData.of(a.category);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: canClaim
                        ? catData.color
                        : (a.isUnlocked ? const Color(0xFF334155) : const Color(0xFF0F172A)),
                    width: canClaim ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: catData.color.withValues(alpha: a.isUnlocked ? 0.25 : 0.08),
                        border: Border.all(
                          color: a.isUnlocked ? catData.color : Colors.white24,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        a.icon,
                        color: a.isUnlocked ? catData.color : Colors.white38,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  a.title,
                                  style: TextStyle(
                                    color: a.isUnlocked ? Colors.white : Colors.white54,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+${a.rewardGems} Gems',
                                  style: const TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a.description,
                            style: TextStyle(
                              color: a.isUnlocked ? Colors.white70 : Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: a.progressRatio,
                              minHeight: 6,
                              backgroundColor: const Color(0xFF0F172A),
                              valueColor: AlwaysStoppedAnimation<Color>(catData.color),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: canClaim ? () => _claimAchievement(a) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canClaim ? catData.color : const Color(0xFF334155),
                        foregroundColor: canClaim ? Colors.black : Colors.white54,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(54, 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        a.isClaimed ? 'DONE' : (canClaim ? 'CLAIM' : '${(a.progressRatio * 100).toInt()}%'),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, AchievementCategory? category) {
    final isSelected = _selectedCategory == category;
    final color = category != null ? AchievementCategoryData.of(category).color : const Color(0xFF10B981);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedCategory = category;
          });
          AudioManager.instance.playClick();
        },
        selectedColor: color,
        backgroundColor: const Color(0xFF1E293B),
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white70,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? color : const Color(0xFF334155),
            width: 1.2,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }
}
