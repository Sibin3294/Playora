import 'package:flutter/material.dart';
import 'package:guess_game/theme/game_theme.dart';

class AttemptPips extends StatelessWidget {
  const AttemptPips({
    super.key,
    required this.total,
    required this.remaining,
  });

  final int total;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (index) {
        final alive = index < remaining;
        final critical = remaining <= 3;
        final color = !alive
            ? const Color(0xFF2A3154)
            : critical
                ? GameColors.coral
                : GameColors.cyan;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
              boxShadow: alive
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.7),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
