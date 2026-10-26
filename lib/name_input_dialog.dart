import 'package:flutter/material.dart';

class NameInputDialog extends StatefulWidget {
  final int score;
  final String initialName;
  final ValueChanged<String> onSubmit;

  const NameInputDialog({
    super.key,
    required this.score,
    required this.initialName,
    required this.onSubmit,
  });

  @override
  State<NameInputDialog> createState() => _NameInputDialogState();
}

class _NameInputDialogState extends State<NameInputDialog> {
  late final TextEditingController _controller;
  final List<String> _presets = const ['ACE', 'VIPER', 'EAGLE', 'PHOENIX', 'SKY'];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    widget.onSubmit(name.isEmpty ? 'PILOT' : name);
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFDED895),
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
              const Icon(
                Icons.military_tech_rounded,
                color: Color(0xFFF09030),
                size: 42,
              ),
              const SizedBox(height: 8),
              const Text(
                'RECORD FLIGHT!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Color(0xFFD32F2F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You scored ${widget.score} points!',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF554A18),
                ),
              ),
              const SizedBox(height: 16),

              // Pilot name textfield
              TextField(
                controller: _controller,
                autofocus: true,
                maxLength: 12,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  counterText: '',
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
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),

              // Quick call-sign chips
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

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
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
                      child: const Text(
                        'SAVE RECORD',
                        style: TextStyle(
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
    );
  }
}
