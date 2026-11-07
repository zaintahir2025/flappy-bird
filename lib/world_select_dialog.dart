// Core Flutter framework for UI layout, dialogs, and animations
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Audio manager for UI feedback and sound effects
import 'audio_manager.dart';

// Game models for biomes and progression
import 'game_models.dart';

// Score storage for persisting unlocks
import 'score_storage.dart' as score_storage;

/// Dialog allowing players to preview, unlock, and select among all 7 world biomes.
class WorldSelectDialog extends StatefulWidget {
  final List<String> unlockedWorlds;
  final String activeWorldId;
  final int totalGems;
  final int bestScore;
  final Function(String worldId, int newGems, List<String> newUnlocked) onWorldChanged;

  const WorldSelectDialog({
    super.key,
    required this.unlockedWorlds,
    required this.activeWorldId,
    required this.totalGems,
    required this.bestScore,
    required this.onWorldChanged,
  });

  @override
  State<WorldSelectDialog> createState() => _WorldSelectDialogState();
}

class _WorldSelectDialogState extends State<WorldSelectDialog> {
  late List<String> _unlockedWorlds;
  late String _activeWorldId;
  late int _gems;

  @override
  void initState() {
    super.initState();
    _unlockedWorlds = List.from(widget.unlockedWorlds);
    _activeWorldId = widget.activeWorldId;
    _gems = widget.totalGems;
  }

  Future<void> _unlockWorld(WorldBiomeData world) async {
    if (_gems < world.unlockGems) {
      _showInsufficientGemsDialog(world);
      return;
    }

    setState(() {
      _gems -= world.unlockGems;
      _unlockedWorlds.add(world.id);
      _activeWorldId = world.id;
    });

    AudioManager.instance.playUnlock();
    HapticFeedback.heavyImpact();

    await score_storage.saveTotalGems(_gems);
    await score_storage.saveUnlockedWorlds(_unlockedWorlds);
    await score_storage.saveActiveWorld(_activeWorldId);

    widget.onWorldChanged(_activeWorldId, _gems, _unlockedWorlds);
  }

  void _showInsufficientGemsDialog(WorldBiomeData world) {
    AudioManager.instance.playHit();
    HapticFeedback.mediumImpact();

    final deficit = world.unlockGems - _gems;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFF5252), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5252).withValues(alpha: 0.35),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with locked halo
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                      border: Border.all(color: const Color(0xFFFF5252), width: 2),
                    ),
                    child: Center(
                      child: Icon(
                        world.icon,
                        size: 38,
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5252),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Title
              const Text(
                'NOT ENOUGH GEMS!',
                style: TextStyle(
                  color: Color(0xFFFF5252),
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                'Cannot unlock "${world.name}" Realm',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // Cost breakdown card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Realm Unlock Cost:',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.diamond_rounded, color: Color(0xFFFFD700), size: 15),
                            const SizedBox(width: 4),
                            Text(
                              '${world.unlockGems}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Current Gems:',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.diamond_rounded, color: Color(0xFFFFD700), size: 15),
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
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Color(0xFF334155), height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Missing Gems Needed:',
                          style: TextStyle(
                            color: Color(0xFFFF5252),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.add_rounded, color: Color(0xFFFF5252), size: 15),
                            const SizedBox(width: 2),
                            const Icon(Icons.diamond_rounded, color: Color(0xFFFF5252), size: 14),
                            const SizedBox(width: 3),
                            Text(
                              '$deficit',
                              style: const TextStyle(
                                color: Color(0xFFFF5252),
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Helpful tip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF38BDF8), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fly through pipes to collect Sky Gems or complete daily quests to earn more!',
                        style: TextStyle(color: Color(0xFFBAE6FD), fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Got it button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'GOT IT',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectWorld(String worldId) async {
    setState(() {
      _activeWorldId = worldId;
    });

    AudioManager.instance.playClick();
    HapticFeedback.selectionClick();

    await score_storage.saveActiveWorld(worldId);
    widget.onWorldChanged(_activeWorldId, _gems, _unlockedWorlds);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF38BDF8), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x660284C7),
              blurRadius: 28,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.public_rounded, color: Color(0xFF38BDF8), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WORLD EXPEDITION',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '7 Dynamic Atmospheric Realms',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Gem balance badge
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
            const Divider(color: Color(0xFF1E293B), height: 1),

            // Worlds list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: WorldBiomeData.all.length,
                itemBuilder: (context, index) {
                  final world = WorldBiomeData.all[index];
                  final isUnlocked = _unlockedWorlds.contains(world.id);
                  final isSelected = _activeWorldId == world.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF38BDF8)
                            : (isUnlocked ? const Color(0xFF334155) : const Color(0xFF1E293B)),
                        width: isSelected ? 2.2 : 1.2,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          world.skyGradient.first.withValues(alpha: isUnlocked ? 0.45 : 0.15),
                          world.skyGradient.last.withValues(alpha: isUnlocked ? 0.30 : 0.08),
                        ],
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                                blurRadius: 14,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // World icon box
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: world.skyGradient,
                              ),
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.white24,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              world.icon,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // World description & metadata
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        world.name,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          shadows: isSelected
                                              ? const [
                                                  Shadow(
                                                    color: Color(0xFF38BDF8),
                                                    blurRadius: 8,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF38BDF8),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'ACTIVE',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  world.subtitle,
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  world.description,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 11,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Action button: Select or Unlock
                          if (isUnlocked)
                            ElevatedButton(
                              onPressed: isSelected ? null : () => _selectWorld(world.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                elevation: isSelected ? 0 : 4,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isSelected ? 'IN USE' : 'SELECT',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () => _unlockWorld(world),
                              icon: const Icon(Icons.diamond_rounded, size: 14, color: Color(0xFFFFD700)),
                              label: Text(
                                '${world.unlockGems}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _gems >= world.unlockGems
                                    ? const Color(0xFFE11D48)
                                    : const Color(0xFF475569),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
