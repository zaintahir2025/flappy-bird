// Dart math library for preview animations and sine oscillation
import 'dart:math';

// Core Flutter UI and layout widgets
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Audio manager for UI feedback and unlock fanfare
import 'audio_manager.dart';

// Animated flyer widget
import 'bird.dart';

// Game models for skins, rarities, and configs
import 'game_models.dart';

// Persistence adapter
import 'score_storage.dart' as score_storage;

/// Dialog displaying the Legendary Bird Collection across all 5 rarity tiers.
class SkinShopDialog extends StatefulWidget {
  final List<String> unlockedSkins;
  final String activeSkinId;
  final int totalGems;
  final Function(String skinId, int newGems, List<String> newUnlocked) onSkinChanged;

  const SkinShopDialog({
    super.key,
    required this.unlockedSkins,
    required this.activeSkinId,
    required this.totalGems,
    required this.onSkinChanged,
  });

  @override
  State<SkinShopDialog> createState() => _SkinShopDialogState();
}

class _SkinShopDialogState extends State<SkinShopDialog>
    with SingleTickerProviderStateMixin {
  late List<String> _unlockedSkins;
  late String _activeSkinId;
  late int _gems;
  BirdRarity? _filterRarity;

  late final AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    _unlockedSkins = List.from(widget.unlockedSkins);
    _activeSkinId = widget.activeSkinId;
    _gems = widget.totalGems;

    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  Future<void> _unlockSkin(BirdSkinConfig skin) async {
    if (_gems < skin.gemCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Need ${skin.gemCost - _gems} more Sky Gems!'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _gems -= skin.gemCost;
      _unlockedSkins.add(skin.id.name);
      _activeSkinId = skin.id.name;
    });

    AudioManager.instance.playUnlock();
    HapticFeedback.heavyImpact();

    await score_storage.saveTotalGems(_gems);
    await score_storage.saveUnlockedSkins(_unlockedSkins);
    await score_storage.saveActiveSkin(_activeSkinId);

    widget.onSkinChanged(_activeSkinId, _gems, _unlockedSkins);

    // Show celebratory unlock toast
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: BirdRarityData.of(skin.rarity).color, width: 2),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              MyBird(
                skinConfig: skin,
                width: 72,
                height: 72,
              ),
              const SizedBox(height: 16),
              Text(
                'UNLOCKED!',
                style: TextStyle(
                  color: BirdRarityData.of(skin.rarity).color,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                skin.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                skin.title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BirdRarityData.of(skin.rarity).color,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('EQUIP & FLY', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _selectSkin(String skinId) async {
    setState(() {
      _activeSkinId = skinId;
    });

    AudioManager.instance.playClick();
    HapticFeedback.selectionClick();

    await score_storage.saveActiveSkin(skinId);
    widget.onSkinChanged(_activeSkinId, _gems, _unlockedSkins);
  }

  @override
  Widget build(BuildContext context) {
    final filteredSkins = _filterRarity == null
        ? BirdSkinConfig.all
        : BirdSkinConfig.all.where((s) => s.rarity == _filterRarity).toList();

    final totalCount = BirdSkinConfig.all.length;
    final unlockedCount = _unlockedSkins.length;
    final completionPct = ((unlockedCount / totalCount) * 100).toInt();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFB300), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66FFB300),
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
                      color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.pets_rounded, color: Color(0xFFFFB300), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LEGENDARY AVIARY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '$unlockedCount / $totalCount Collected ($completionPct%)',
                          style: const TextStyle(
                            color: Color(0xFFFFB300),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Gem balance
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

            // Rarity filter tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildFilterChip('ALL', null),
                  for (final r in BirdRarity.values)
                    _buildFilterChip(BirdRarityData.of(r).label, r),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF1E293B), height: 1),

            // Flyer cards list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: filteredSkins.length,
                itemBuilder: (context, index) {
                  final skin = filteredSkins[index];
                  final isUnlocked = _unlockedSkins.contains(skin.id.name);
                  final isSelected = _activeSkinId == skin.id.name;
                  final rarityData = BirdRarityData.of(skin.rarity);

                  return AnimatedBuilder(
                    animation: _hoverController,
                    builder: (context, child) {
                      final hoverY = sin(_hoverController.value * pi * 2) * 3.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFFB300)
                                : (isUnlocked ? rarityData.color.withValues(alpha: 0.6) : const Color(0xFF1E293B)),
                            width: isSelected ? 2.2 : 1.2,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              rarityData.badgeBackground.withValues(alpha: isUnlocked ? 0.45 : 0.1),
                              const Color(0xFF1E293B).withValues(alpha: 0.7),
                            ],
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFFB300).withValues(alpha: 0.35),
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
                              // Animated Flyer sprite preview
                              Transform.translate(
                                offset: Offset(0, hoverY),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black26,
                                    border: Border.all(
                                      color: rarityData.color.withValues(alpha: 0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: MyBird(
                                    skinConfig: skin,
                                    width: 48,
                                    height: 48,
                                    wingCycle: _hoverController.value,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Bird Info & Rarity badge
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Rarity badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: rarityData.badgeBackground,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: rarityData.badgeBorder, width: 1),
                                          ),
                                          child: Text(
                                            rarityData.label,
                                            style: TextStyle(
                                              color: rarityData.color,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            skin.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 15,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      skin.title,
                                      style: TextStyle(
                                        color: rarityData.color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      skin.description,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 11,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Select / Unlock Button
                              if (isUnlocked)
                                ElevatedButton(
                                  onPressed: isSelected ? null : () => _selectSkin(skin.id.name),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFFFB300),
                                    foregroundColor: isSelected ? Colors.white70 : Colors.black,
                                    elevation: isSelected ? 0 : 4,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    isSelected ? 'EQUIPPED' : 'EQUIP',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: () => _unlockSkin(skin),
                                  icon: const Icon(Icons.diamond_rounded, size: 14, color: Color(0xFFFFD700)),
                                  label: Text(
                                    '${skin.gemCost}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _gems >= skin.gemCost
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, BirdRarity? rarity) {
    final isSelected = _filterRarity == rarity;
    final color = rarity != null ? BirdRarityData.of(rarity).color : const Color(0xFFFFB300);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _filterRarity = rarity;
          });
          AudioManager.instance.playClick();
        },
        selectedColor: color,
        backgroundColor: const Color(0xFF1E293B),
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white70,
          fontWeight: FontWeight.w900,
          fontSize: 11,
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
