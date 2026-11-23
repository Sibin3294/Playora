import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guess_game/theme/game_theme.dart';

class NeonButton extends StatefulWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = GameColors.cyan,
    this.expanded = true,
    this.outlined = false,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool expanded;
  final bool outlined;
  final double height;

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final button = Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.mediumImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 90),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: enabled ? 1 : 0.45,
            child: Container(
              height: widget.height,
              alignment: Alignment.center,
              decoration: widget.outlined
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: widget.color.withOpacity(0.08),
                      border: Border.all(color: widget.color, width: 1.6),
                    )
                  : BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          widget.color.withOpacity(0.95),
                          Color.lerp(widget.color, GameColors.violet, 0.45)!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withOpacity(0.45),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
              child: Text(
                widget.label,
                style: TextStyle(
                  color:
                      widget.outlined ? widget.color : const Color(0xFF071018),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 2.6,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
