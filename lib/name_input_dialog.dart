// Flutter Material Design library for interactive dialogs, textfields, and buttons
import 'package:flutter/material.dart';

/// Modal dialog prompting the player for their pilot callsign when setting a record flight.
class NameInputDialog extends StatefulWidget {
  // Score achieved in the round
  final int score;

  // Initial callsign pre-filled in the text box (e.g. from previous games)
  final String initialName;

  // Callback function invoked with the confirmed player name
  final ValueChanged<String> onSubmit;

  // Optional custom title header
  final String? title;

  // Optional custom subtitle text
  final String? subtitle;

  // Optional confirm button label
  final String? confirmButtonText;

  // Optional callback invoked when the user skips
  final VoidCallback? onSkip;

  const NameInputDialog({
    super.key,
    required this.score,
    required this.initialName,
    required this.onSubmit,
    this.title,
    this.subtitle,
    this.confirmButtonText,
    this.onSkip,
  });

  @override
  State<NameInputDialog> createState() => _NameInputDialogState();
}

class _NameInputDialogState extends State<NameInputDialog> {
  // Controller managing the text input state
  late final TextEditingController _controller;

  // Preset callsign suggestions allowing one-tap selection on mobile devices
  final List<String> _presets = const ['ACE', 'VIPER', 'EAGLE', 'PHOENIX', 'SKY'];

  @override
  void initState() {
    super.initState();
    // Initialize controller with initial name passed from parent
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    // Clean up controller to prevent memory leaks when dialog closes
    _controller.dispose();
    super.dispose();
  }

  /// Validates input, passes confirmed name to callback, and closes dialog.
  void _submit() {
    final name = _controller.text.trim();
    // Fall back to 'PILOT' if left blank
    widget.onSubmit(name.isEmpty ? 'PILOT' : name);
    // Dismiss the modal dialog
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent, // Transparent backdrop for custom container styling
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380), // Caps width on desktop & tablets
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFDED895), // Warm parchment arcade background
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF558022), width: 4), // Chunky retro border
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Shrink-wraps vertically to content
            children: [
              // Achievement medal icon / Pilot badge
              Icon(
                widget.score > 0 ? Icons.military_tech_rounded : Icons.flight_takeoff_rounded,
                color: const Color(0xFFF09030),
                size: 42,
              ),
              const SizedBox(height: 8),

              // Title Header
              Text(
                widget.title ?? (widget.score > 0 ? 'RECORD FLIGHT!' : 'PILOT REGISTRATION'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Color(0xFFD32F2F),
                ),
              ),
              const SizedBox(height: 6),

              // Score announcement / callsign prompt subtitle
              Text(
                widget.subtitle ??
                    (widget.score > 0
                        ? 'You scored ${widget.score} points!'
                        : 'Choose your call-sign for the Hall of Fame!'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF554A18),
                ),
              ),
              const SizedBox(height: 16),

              // Pilot callsign text entry field
              TextField(
                controller: _controller,
                autofocus: true, // Immediately opens on-screen keyboard on mobile
                maxLength: 12,    // Constrains callsign length
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  counterText: '', // Hides default character counter
                  hintText: 'ENTER PILOT CALL-SIGN',
                  filled: true,
                  fillColor: const Color(0xFFF7F3D0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFB8AE67), width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 3),
                  ),
                ),
                // Submitting via software keyboard 'Enter' key
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),

              // Quick-pick preset callsign chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _presets.map((preset) {
                  return InkWell(
                    onTap: () {
                      _controller.text = preset;
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F3D0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFB8AE67)),
                      ),
                      child: Text(
                        preset,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF706733),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Action buttons: Skip vs Save
              Row(
                children: [
                  // Skip button
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        widget.onSkip?.call();
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF554A18),
                      ),
                      child: const Text(
                        'SKIP',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Save button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        widget.confirmButtonText ??
                            (widget.score > 0 ? 'SAVE RECORD' : 'CONFIRM CALL-SIGN'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
