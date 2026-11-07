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
  late String _inspectedSkinId;
  late int _gems;
  BirdRarity? _filterRarity;

  late final AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    _unlockedSkins = List.from(widget.unlockedSkins);
    _activeSkinId = widget.activeSkinId;
    _inspectedSkinId = widget.activeSkinId;
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

  BirdSkinConfig get _inspectedSkin => BirdSkinConfig.fromStringId(_inspectedSkinId);

  void _showInsufficientGemsDialog(BirdSkinConfig skin) {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.vibrate();
    final int missing = skin.gemCost - _gems;
    final rarityData = BirdRarityData.of(skin.rarity);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 390),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFF5252), width: 2.2),
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
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                      border: Border.all(color: const Color(0xFFFF5252), width: 2),
                    ),
                    child: Center(
                      child: MyBird(
                        skinConfig: skin,
                        width: 52,
                        height: 52,
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

              // Subtitle with bird name
              Text(
                'Cannot unlock "${skin.name}" (${rarityData.label})',
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Unlock Cost:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Row(
                          children: [
                            const Icon(Icons.diamond_rounded, color: Color(0xFFFFD700), size: 15),
                            const SizedBox(width: 4),
                            Text('${skin.gemCost}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Your Current Balance:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Row(
                          children: [
                            const Icon(Icons.diamond_rounded, color: Color(0xFFFFD700), size: 15),
                            const SizedBox(width: 4),
                            Text('$_gems', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Gems Still Needed:', style: TextStyle(color: Color(0xFFFF8A80), fontSize: 13, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            const Icon(Icons.diamond_rounded, color: Color(0xFFFF5252), size: 15),
                            const SizedBox(width: 4),
                            Text('+$missing GEMS', style: const TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w900, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Pro-tip card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF132F23),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Collect floating Sky Gems in flight (+2 each) or complete Daily Quests to earn gems quickly!',
                        style: TextStyle(
                          color: const Color(0xFF10B981).withValues(alpha: 0.95),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5252),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'GOT IT, LET\'S EARN GEMS!',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _unlockSkin(BirdSkinConfig skin) async {
    if (_gems < skin.gemCost) {
      _showInsufficientGemsDialog(skin);
      return;
    }

    setState(() {
      _gems -= skin.gemCost;
      _unlockedSkins.add(skin.id.name);
      _activeSkinId = skin.id.name;
      _inspectedSkinId = skin.id.name;
    });

    AudioManager.instance.playUnlock();
    HapticFeedback.heavyImpact();

    await score_storage.saveTotalGems(_gems);
    await score_storage.saveUnlockedSkins(_unlockedSkins);
    await score_storage.saveActiveSkin(_activeSkinId);

    widget.onSkinChanged(_activeSkinId, _gems, _unlockedSkins);

    // Show celebratory unlock modal
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
      _inspectedSkinId = skinId;
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

    final inspected = _inspectedSkin;
    final inspectedUnlocked = _unlockedSkins.contains(inspected.id.name);
    final inspectedEquipped = _activeSkinId == inspected.id.name;
    final inspectedRarity = BirdRarityData.of(inspected.rarity);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 760),
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
            // Top Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 10),
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
                  // Current Gem balance
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond_rounded, color: Color(0xFFFFD700), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '$_gems',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
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

            // Hero Spotlight Preview of currently inspected bird
            AnimatedBuilder(
              animation: _hoverController,
              builder: (context, _) {
                final hoverY = sin(_hoverController.value * pi * 2) * 4.0;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        inspectedRarity.badgeBackground.withValues(alpha: 0.6),
                        const Color(0xFF1E293B),
                      ],
                    ),
                    border: Border.all(
                      color: inspectedEquipped
                          ? const Color(0xFFFFB300)
                          : inspectedRarity.color.withValues(alpha: 0.8),
                      width: inspectedEquipped ? 2.0 : 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: inspectedRarity.color.withValues(alpha: 0.25),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Animated Spotlight Avatar
                      Transform.translate(
                        offset: Offset(0, hoverY),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black38,
                            border: Border.all(
                              color: inspectedRarity.color,
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: inspectedRarity.color.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: MyBird(
                              skinConfig: inspected,
                              width: 54,
                              height: 54,
                              wingCycle: _hoverController.value,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Bird Lore & Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: inspectedRarity.badgeBackground,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: inspectedRarity.badgeBorder, width: 1),
                                  ),
                                  child: Text(
                                    inspectedRarity.label,
                                    style: TextStyle(
                                      color: inspectedRarity.color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    inspected.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              inspected.title,
                              style: TextStyle(
                                color: inspectedRarity.color,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              inspected.description,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Action Button on Spotlight
                      if (inspectedEquipped)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF10B981)),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                              SizedBox(height: 2),
                              Text('EQUIPPED', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        )
                      else if (inspectedUnlocked)
                        ElevatedButton(
                          onPressed: () => _selectSkin(inspected.id.name),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB300),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('EQUIP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => _unlockSkin(inspected),
                          icon: Icon(
                            _gems >= inspected.gemCost ? Icons.lock_open_rounded : Icons.lock_rounded,
                            size: 14,
                            color: _gems >= inspected.gemCost ? Colors.black : Colors.white70,
                          ),
                          label: Text(
                            '${inspected.gemCost}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              color: _gems >= inspected.gemCost ? Colors.black : Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _gems >= inspected.gemCost
                                ? const Color(0xFFFFD700)
                                : const Color(0xFF475569),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            // Rarity filter chips bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  _buildFilterChip('ALL', null),
                  for (final r in BirdRarity.values)
                    _buildFilterChip(BirdRarityData.of(r).label, r),
                ],
              ),
            ),
            const Divider(color: Color(0xFF1E293B), height: 1),

            // Scrollable Aviary Collection List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: filteredSkins.length,
                itemBuilder: (context, index) {
                  final skin = filteredSkins[index];
                  final isUnlocked = _unlockedSkins.contains(skin.id.name);
                  final isEquipped = _activeSkinId == skin.id.name;
                  final isInspected = _inspectedSkinId == skin.id.name;
                  final rarityData = BirdRarityData.of(skin.rarity);
                  final canAfford = _gems >= skin.gemCost;
                  final missingGems = max(0, skin.gemCost - _gems);

                  return AnimatedBuilder(
                    animation: _hoverController,
                    builder: (context, child) {
                      final hoverY = sin(_hoverController.value * pi * 2 + index * 0.4) * 2.5;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isEquipped
                                ? const Color(0xFFFFB300)
                                : isInspected
                                    ? rarityData.color
                                    : (isUnlocked ? rarityData.color.withValues(alpha: 0.45) : const Color(0xFF1E293B)),
                            width: isEquipped ? 2.2 : (isInspected ? 1.8 : 1.0),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              rarityData.badgeBackground.withValues(alpha: isUnlocked ? 0.40 : 0.12),
                              const Color(0xFF1E293B).withValues(alpha: 0.75),
                            ],
                          ),
                          boxShadow: isEquipped
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFFB300).withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              setState(() {
                                _inspectedSkinId = skin.id.name;
                              });
                              AudioManager.instance.playClick();
                              HapticFeedback.selectionClick();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Flyer sprite preview circle
                                  Transform.translate(
                                    offset: Offset(0, hoverY),
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black26,
                                        border: Border.all(
                                          color: rarityData.color.withValues(alpha: isUnlocked ? 0.6 : 0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: MyBird(
                                        skinConfig: skin,
                                        width: 44,
                                        height: 44,
                                        wingCycle: _hoverController.value,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Bird Information
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
                                                  fontSize: 14,
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
                                        const SizedBox(height: 2),
                                        Text(
                                          skin.description,
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (!isUnlocked && !canAfford) ...[
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              const Icon(Icons.info_outline_rounded, color: Color(0xFFFF5252), size: 12),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Need $missingGems more gems to unlock',
                                                style: const TextStyle(
                                                  color: Color(0xFFFF8A80),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Select / Unlock action button
                                  if (isUnlocked)
                                    ElevatedButton(
                                      onPressed: isEquipped ? null : () => _selectSkin(skin.id.name),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isEquipped
                                            ? const Color(0xFF1E293B)
                                            : const Color(0xFFFFB300),
                                        foregroundColor: isEquipped ? Colors.white60 : Colors.black,
                                        elevation: isEquipped ? 0 : 3,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        isEquipped ? 'EQUIPPED' : 'EQUIP',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                        ),
                                      ),
                                    )
                                  else
                                    ElevatedButton.icon(
                                      onPressed: () => _unlockSkin(skin),
                                      icon: Icon(
                                        canAfford ? Icons.diamond_rounded : Icons.lock_rounded,
                                        size: 13,
                                        color: canAfford ? const Color(0xFFFFD700) : Colors.white70,
                                      ),
                                      label: Text(
                                        '${skin.gemCost}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                          color: canAfford ? Colors.white : Colors.white70,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: canAfford
                                            ? const Color(0xFFE11D48)
                                            : const Color(0xFF334155),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          side: BorderSide(
                                            color: canAfford ? const Color(0xFFFF4081) : Colors.transparent,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
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
