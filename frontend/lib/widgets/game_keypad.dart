import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guess_game/theme/game_theme.dart';

class GameKeypad extends StatelessWidget {
  const GameKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', 'DEL'],
    ];

    return Column(
      children: [
        for (final row in keys)
          Expanded(
            child: Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: _KeyCap(
                        key: ValueKey('key-$key'),
                        label: key,
                        accent: key == 'C' || key == 'DEL',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          if (key == 'C') {
                            onClear();
                          } else if (key == 'DEL') {
                            onBackspace();
                          } else {
                            onDigit(key);
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _KeyCap extends StatelessWidget {
  const _KeyCap({
    super.key,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label == 'DEL'
          ? 'Backspace'
          : label == 'C'
              ? 'Clear'
              : 'Digit $label',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: accent
                ? GameColors.magenta.withOpacity(0.16)
                : const Color(0xFF1A2142),
            border: Border.all(
              color: accent ? GameColors.magenta : GameColors.panelBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: (accent ? GameColors.magenta : GameColors.cyan)
                    .withOpacity(0.12),
                blurRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: accent ? GameColors.magenta : GameColors.text,
                fontSize: label == 'DEL' ? 16 : 22,
                fontWeight: FontWeight.w800,
                letterSpacing: label == 'DEL' ? 1.4 : 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
