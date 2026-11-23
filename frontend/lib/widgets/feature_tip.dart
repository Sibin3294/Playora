import 'package:flutter/material.dart';
import 'package:guess_game/intro/first_run_store.dart';
import 'package:guess_game/theme/game_theme.dart';

/// Coach-mark style feature tip — a short one-time tooltip callout.
/// Common names: coach mark, feature discovery, feature highlight.
class FeatureTip extends StatefulWidget {
  const FeatureTip({
    super.key,
    required this.id,
    required this.title,
    required this.message,
    required this.child,
    this.accent = GameColors.gold,
    this.preferBelow = true,
  });

  final String id;
  final String title;
  final String message;
  final Widget child;
  final Color accent;
  final bool preferBelow;

  @override
  State<FeatureTip> createState() => _FeatureTipState();
}

class _FeatureTipState extends State<FeatureTip> {
  bool _visible = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final show = await FirstRunStore.instance.shouldShow(widget.id);
    if (!mounted) return;
    setState(() {
      _checked = true;
      _visible = show;
    });
  }

  Future<void> _dismiss() async {
    await FirstRunStore.instance.markSeen(widget.id);
    if (!mounted) return;
    setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || !_visible) return widget.child;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.preferBelow) ...[
          _TipBubble(
            title: widget.title,
            message: widget.message,
            accent: widget.accent,
            onDismiss: _dismiss,
            arrowDown: false,
          ),
          const SizedBox(height: 8),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: widget.accent, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withOpacity(0.28),
                blurRadius: 16,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: widget.child,
        ),
        if (widget.preferBelow) ...[
          const SizedBox(height: 8),
          _TipBubble(
            title: widget.title,
            message: widget.message,
            accent: widget.accent,
            onDismiss: _dismiss,
            arrowDown: true,
          ),
        ],
      ],
    );
  }
}

class _TipBubble extends StatelessWidget {
  const _TipBubble({
    required this.title,
    required this.message,
    required this.accent,
    required this.onDismiss,
    required this.arrowDown,
  });

  final String title;
  final String message;
  final Color accent;
  final VoidCallback onDismiss;
  final bool arrowDown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (arrowDown)
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: CustomPaint(
              size: const Size(14, 8),
              painter: _ArrowPainter(color: accent, pointUp: true),
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: const Color(0xF2141A33),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withOpacity(0.85)),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.18),
                blurRadius: 14,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: accent, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: hudLabelStyle(color: accent, size: 10),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        color: GameColors.text,
                        height: 1.35,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'GOT IT',
                  style: hudLabelStyle(color: accent, size: 10),
                ),
              ),
            ],
          ),
        ),
        if (!arrowDown)
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: CustomPaint(
              size: const Size(14, 8),
              painter: _ArrowPainter(color: accent, pointUp: false),
            ),
          ),
      ],
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.color, required this.pointUp});

  final Color color;
  final bool pointUp;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointUp) {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withOpacity(0.85));
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pointUp != pointUp;
}
