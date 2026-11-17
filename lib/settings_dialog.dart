// Core Flutter framework for UI layout and sliders
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Audio manager for real-time volume preview
import 'audio_manager.dart';

// Game models for settings
import 'game_models.dart';

// Pilot callsign dialog
import 'name_input_dialog.dart';

// Score storage for persistence
import 'score_storage.dart' as score_storage;

/// Dialog allowing players to tune audio volumes, haptics, motion settings, and pilot callsign.
class SettingsDialog extends StatefulWidget {
  final GameSettings settings;
  final String pilotName;
  final Function(GameSettings newSettings, String newPilotName) onSettingsSaved;

  const SettingsDialog({
    super.key,
    required this.settings,
    required this.pilotName,
    required this.onSettingsSaved,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late GameSettings _settings;
  late String _pilotName;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _pilotName = widget.pilotName;
  }

  Future<void> _updateSettings(GameSettings updated) async {
    setState(() {
      _settings = updated;
    });

    AudioManager.instance.setVolumes(
      musicVolume: updated.isMusicEnabled ? updated.musicVolume : 0.0,
      sfxVolume: updated.isSfxEnabled ? updated.sfxVolume : 0.0,
    );

    await score_storage.saveGameSettings(updated);
    widget.onSettingsSaved(_settings, _pilotName);
  }

  Future<void> _changePilotName() async {
    showDialog(
      context: context,
      builder: (ctx) => NameInputDialog(
        score: 0,
        initialName: _pilotName,
        onSubmit: (newName) async {
          if (newName.trim().isNotEmpty) {
            setState(() {
              _pilotName = newName.trim();
            });
            await score_storage.saveLastPlayerName(_pilotName);
            widget.onSettingsSaved(_settings, _pilotName);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF64748B), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66334155),
              blurRadius: 28,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.settings_rounded, color: Color(0xFF38BDF8), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'FLIGHT SETTINGS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF1E293B), height: 1),
              const SizedBox(height: 16),

              // Pilot Callsign
              Row(
                children: [
                  const Icon(Icons.badge_rounded, color: Color(0xFFFFD700), size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PILOT CALLSIGN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                        Text('Shown on Hall of Fame records', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _changePilotName,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFFD700)),
                      foregroundColor: const Color(0xFFFFD700),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(_pilotName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Music Volume
              Row(
                children: [
                  Icon(
                    _settings.isMusicEnabled ? Icons.music_note_rounded : Icons.music_off_rounded,
                    color: _settings.isMusicEnabled ? const Color(0xFF38BDF8) : Colors.white38,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Text('MUSIC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                  Expanded(
                    child: Slider(
                      value: _settings.musicVolume,
                      activeColor: const Color(0xFF38BDF8),
                      inactiveColor: const Color(0xFF1E293B),
                      onChanged: _settings.isMusicEnabled
                          ? (v) => _updateSettings(_settings.copyWith(musicVolume: v))
                          : null,
                    ),
                  ),
                  Switch(
                    value: _settings.isMusicEnabled,
                    activeThumbColor: const Color(0xFF38BDF8),
                    onChanged: (v) => _updateSettings(_settings.copyWith(isMusicEnabled: v)),
                  ),
                ],
              ),

              // Sound FX Volume
              Row(
                children: [
                  Icon(
                    _settings.isSfxEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    color: _settings.isSfxEnabled ? const Color(0xFF10B981) : Colors.white38,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Text('SFX', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                  Expanded(
                    child: Slider(
                      value: _settings.sfxVolume,
                      activeColor: const Color(0xFF10B981),
                      inactiveColor: const Color(0xFF1E293B),
                      onChanged: _settings.isSfxEnabled
                          ? (v) => _updateSettings(_settings.copyWith(sfxVolume: v))
                          : null,
                    ),
                  ),
                  Switch(
                    value: _settings.isSfxEnabled,
                    activeThumbColor: const Color(0xFF10B981),
                    onChanged: (v) => _updateSettings(_settings.copyWith(isSfxEnabled: v)),
                  ),
                ],
              ),

              // Haptics Toggle
              Row(
                children: [
                  Icon(
                    _settings.isHapticsEnabled ? Icons.vibration_rounded : Icons.smartphone_rounded,
                    color: _settings.isHapticsEnabled ? const Color(0xFFF59E0B) : Colors.white38,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HAPTIC FEEDBACK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                        Text('Tactile vibration on flap & impact', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _settings.isHapticsEnabled,
                    activeThumbColor: const Color(0xFFF59E0B),
                    onChanged: (v) {
                      if (v) HapticFeedback.mediumImpact();
                      _updateSettings(_settings.copyWith(isHapticsEnabled: v));
                    },
                  ),
                ],
              ),

              // Reduced Motion Toggle
              Row(
                children: [
                  Icon(
                    Icons.motion_photos_off_rounded,
                    color: _settings.reducedMotion ? const Color(0xFFA855F7) : Colors.white38,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('REDUCED MOTION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                        Text('Subtle particles for accessibility', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _settings.reducedMotion,
                    activeThumbColor: const Color(0xFFA855F7),
                    onChanged: (v) => _updateSettings(_settings.copyWith(reducedMotion: v)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
