import 'package:flutter/material.dart';
import 'package:guess_game/cricket/models.dart';
import 'package:guess_game/theme/game_theme.dart';

/// Relative positions on the oval (x, y) with center pitch at (0, 0).
/// y: -1 = striker/keeper end, +1 = bowling/non-striker end.
/// Spread toward the boundary so markers stay readable on phones.
const _slotAnchors = <int, Offset>{
  0: Offset(-0.22, -0.08), // opener 1
  1: Offset(0.24, 0.04), // opener 2
  2: Offset(-0.72, -0.28), // batter 3
  3: Offset(0.72, -0.22), // batter 4
  4: Offset(-0.68, 0.18), // middle 5
  5: Offset(0.68, 0.16), // all-round 6
  6: Offset(0.0, -0.90), // keeper — deep behind the striker's end (mirrors slot 11)
  7: Offset(-0.36, 0.58), // all-round 8
  8: Offset(-0.72, 0.78), // bowler 9
  9: Offset(0.72, 0.78), // bowler 10
  10: Offset(0.0, 0.90), // bowler 11
};

class CricketGround extends StatelessWidget {
  const CricketGround({
    super.key,
    required this.slots,
    required this.picks,
    this.selectedSlotIndex,
    this.highlightedSlotIndexes = const {},
    this.onSlotTap,
    this.height,
  });

  final List<SquadSlot> slots;
  final List<DraftPick> picks;
  final int? selectedSlotIndex;
  final Set<int> highlightedSlotIndexes;
  final ValueChanged<SquadSlot>? onSlotTap;
  final double? height;

  DraftPick? _pickFor(int index) {
    for (final pick in picks) {
      if (pick.slot.index == index) return pick;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final groundH = height ?? (screenW < 420 ? screenW * 0.88 : 280.0).clamp(240.0, 320.0);

    return SizedBox(
      height: groundH,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final markerW = (w * 0.16).clamp(42.0, 56.0);
          final markerH = markerW * 1.35;
          final halfW = markerW / 2;
          final halfH = markerH / 2;
          // Keep markers inside the grass oval, not the card corners.
          final spreadX = w * 0.38;
          final spreadY = h * 0.36;

          return ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: _GroundPainter()),
                ...slots.map((slot) {
                  final anchor = _slotAnchors[slot.index] ?? Offset.zero;
                  final pick = _pickFor(slot.index);
                  final selected = selectedSlotIndex == slot.index;
                  final highlighted =
                      highlightedSlotIndexes.contains(slot.index);
                  final cx = (w / 2) + (anchor.dx * spreadX);
                  final cy = (h / 2) + (anchor.dy * spreadY);
                  return Positioned(
                    left: (cx - halfW).clamp(6.0, w - markerW - 6),
                    top: (cy - halfH).clamp(28.0, h - markerH - 6),
                    child: _PlayerMarker(
                      width: markerW,
                      slot: slot,
                      pick: pick,
                      selected: selected,
                      highlighted: highlighted,
                      onTap:
                          onSlotTap == null ? null : () => onSlotTap!(slot),
                    ),
                  );
                }),
                Positioned(
                  left: 12,
                  top: 10,
                  child: Text(
                    'YOUR XI',
                    style: hudLabelStyle(color: GameColors.lime, size: 9),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 10,
                  child: Text(
                    '${picks.length}/11',
                    style: hudLabelStyle(color: GameColors.gold, size: 9),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TeamKit {
  const _TeamKit(this.primary, this.secondary, this.number);

  final Color primary;
  final Color secondary;
  final Color number;
}

const _teamKits = <String, _TeamKit>{
  // National sides
  'ind': _TeamKit(Color(0xFF0033A0), Color(0xFFFF6B00), Color(0xFFFFFFFF)),
  'aus': _TeamKit(Color(0xFFFFD100), Color(0xFF00843D), Color(0xFF1A1A1A)),
  'eng': _TeamKit(Color(0xFF1A2B5C), Color(0xFFC8102E), Color(0xFFFFFFFF)),
  'nz': _TeamKit(Color(0xFF111111), Color(0xFFFFFFFF), Color(0xFFFFFFFF)),
  'sa': _TeamKit(Color(0xFF007A4D), Color(0xFFFFB81C), Color(0xFFFFFFFF)),
  'pak': _TeamKit(Color(0xFF01411C), Color(0xFFFFFFFF), Color(0xFFFFFFFF)),
  // IPL franchises
  'mi': _TeamKit(Color(0xFF004BA0), Color(0xFFD1AB3E), Color(0xFFFFFFFF)),
  'csk': _TeamKit(Color(0xFFF9CD05), Color(0xFF0081E9), Color(0xFF1A1A1A)),
  'rcb': _TeamKit(Color(0xFFEC1C24), Color(0xFF000000), Color(0xFFFFFFFF)),
  'kkr': _TeamKit(Color(0xFF3A225D), Color(0xFFC6A664), Color(0xFFFFFFFF)),
  'dc': _TeamKit(Color(0xFF0078BC), Color(0xFFEF1B23), Color(0xFFFFFFFF)),
  'rr': _TeamKit(Color(0xFFEA1A85), Color(0xFF254AA5), Color(0xFFFFFFFF)),
  'pbks': _TeamKit(Color(0xFFED1B24), Color(0xFFA7A9AC), Color(0xFFFFFFFF)),
  'srh': _TeamKit(Color(0xFFFF822A), Color(0xFF000000), Color(0xFFFFFFFF)),
  'lsg': _TeamKit(Color(0xFFA720FF), Color(0xFFFFF200), Color(0xFFFFFFFF)),
  'gt': _TeamKit(Color(0xFF1C2C5B), Color(0xFFB5975A), Color(0xFFFFFFFF)),
};

_TeamKit _kitForTeamId(String? teamId) {
  if (teamId == null) {
    return const _TeamKit(
      Color(0xFF1A2438),
      Color(0xFF33407A),
      Color(0xFF9AA3C7),
    );
  }
  return _teamKits[teamId] ??
      const _TeamKit(
        Color(0xFF2A3A55),
        Color(0xFF7CFF6B),
        Color(0xFFFFFFFF),
      );
}

class _PlayerMarker extends StatelessWidget {
  const _PlayerMarker({
    required this.width,
    required this.slot,
    required this.pick,
    required this.selected,
    required this.highlighted,
    required this.onTap,
  });

  final double width;
  final SquadSlot slot;
  final DraftPick? pick;
  final bool selected;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final filled = pick != null;
    final teamId = pick?.fromTeamId ?? pick?.player.teamId;
    final kit = _kitForTeamId(filled ? teamId : null);
    final border = selected
        ? GameColors.lime
        : (highlighted
            ? GameColors.cyan
            : (filled ? kit.secondary : const Color(0x66A8FFC4)));
    final label = filled
        ? pick!.player.name.split(' ').last
        : slot.label.split(' ').first;
    final jerseyW = width * 0.72;
    final jerseyH = jerseyW * 1.15;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: jerseyW,
                height: jerseyH,
                child: CustomPaint(
                  painter: _JerseyPainter(
                    primary: kit.primary,
                    secondary: kit.secondary,
                    border: border,
                    filled: filled,
                    selected: selected || highlighted,
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: jerseyH * 0.08),
                      child: Text(
                        '${slot.index + 1}',
                        style: TextStyle(
                          color: filled ? kit.number : GameColors.mute,
                          fontSize: (jerseyW * 0.34).clamp(11.0, 16.0),
                          fontWeight: FontWeight.w900,
                          height: 1,
                          shadows: filled
                              ? const [
                                  Shadow(
                                    color: Color(0x66000000),
                                    blurRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: filled ? GameColors.text : GameColors.mute,
                  fontSize: (width * 0.17).clamp(8.0, 10.0),
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  shadows: const [
                    Shadow(
                      color: Color(0xCC000000),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              if (filled && pick!.player.isOverseas) ...[
                const SizedBox(height: 1),
                Icon(
                  Icons.flight_rounded,
                  size: (width * 0.22).clamp(9.0, 12.0),
                  color: GameColors.magenta,
                  shadows: const [
                    Shadow(color: Color(0xCC000000), blurRadius: 3),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _JerseyPainter extends CustomPainter {
  const _JerseyPainter({
    required this.primary,
    required this.secondary,
    required this.border,
    required this.filled,
    required this.selected,
  });

  final Color primary;
  final Color secondary;
  final Color border;
  final bool filled;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    // Jersey silhouette: collar, sleeves, torso, hem.
    path.moveTo(w * 0.32, h * 0.08);
    path.lineTo(w * 0.38, h * 0.02);
    path.quadraticBezierTo(w * 0.50, h * 0.10, w * 0.62, h * 0.02);
    path.lineTo(w * 0.68, h * 0.08);
    // Right sleeve
    path.lineTo(w * 0.96, h * 0.22);
    path.lineTo(w * 0.82, h * 0.36);
    path.lineTo(w * 0.78, h * 0.30);
    // Right side down to hem
    path.lineTo(w * 0.78, h * 0.92);
    path.quadraticBezierTo(w * 0.50, h * 0.98, w * 0.22, h * 0.92);
    // Left side up
    path.lineTo(w * 0.22, h * 0.30);
    path.lineTo(w * 0.18, h * 0.36);
    path.lineTo(w * 0.04, h * 0.22);
    path.close();

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = filled ? primary : const Color(0xCC0A1810);
    canvas.drawPath(path, fill);

    // Sleeve / side accent stripes
    if (filled) {
      final accent = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * 0.07).clamp(2.0, 3.5)
        ..color = secondary.withOpacity(0.9)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(w * 0.18, h * 0.24),
        Offset(w * 0.30, h * 0.18),
        accent,
      );
      canvas.drawLine(
        Offset(w * 0.82, h * 0.24),
        Offset(w * 0.70, h * 0.18),
        accent,
      );
      canvas.drawLine(
        Offset(w * 0.28, h * 0.88),
        Offset(w * 0.72, h * 0.88),
        accent..strokeWidth = (w * 0.05).clamp(1.5, 2.5),
      );
    }

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2.2 : 1.3
      ..color = border;
    canvas.drawPath(path, outline);

    if (selected || filled) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 4 : 2.5
          ..color = border.withOpacity(0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _JerseyPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.border != border ||
        oldDelegate.filled != filled ||
        oldDelegate.selected != selected;
  }
}

class _GroundPainter extends CustomPainter {
  const _GroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Dark apron around the ground
    canvas.drawRect(
      rect,
      Paint()..color = const Color(0xFF06100A),
    );

    final oval = Rect.fromCenter(
      center: rect.center,
      width: size.width * 0.94,
      height: size.height * 0.90,
    );

    final grass = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.15),
        radius: 0.95,
        colors: [
          Color(0xFF2A8A4A),
          Color(0xFF176338),
          Color(0xFF0C3D24),
          Color(0xFF071A12),
        ],
        stops: [0.0, 0.35, 0.7, 1],
      ).createShader(oval);
    canvas.drawOval(oval, grass);

    // Subtle stripe bands
    final stripePaint = Paint()
      ..color = const Color(0x14000000)
      ..style = PaintingStyle.fill;
    for (var i = -5; i <= 5; i++) {
      final band = Rect.fromCenter(
        center: oval.center.translate(0, i * oval.height * 0.07),
        width: oval.width * 0.92,
        height: oval.height * 0.035,
      );
      canvas.drawOval(band, stripePaint);
    }

    final ring = Paint()
      ..color = const Color(0x66C8FFD8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawOval(oval.deflate(3), ring);

    final circle = Rect.fromCenter(
      center: oval.center,
      width: size.width * 0.42,
      height: size.height * 0.42,
    );
    canvas.drawOval(
      circle,
      Paint()
        ..color = const Color(0x33A8FFC4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    // Pitch
    final pitch = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: oval.center.translate(0, -size.height * 0.02),
        width: size.width * 0.09,
        height: size.height * 0.28,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      pitch,
      Paint()..color = const Color(0xFFD2B07A),
    );
    canvas.drawRRect(
      pitch,
      Paint()
        ..color = const Color(0xAAFFD166)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    final creasePaint = Paint()
      ..color = const Color(0xEEFFFFFF)
      ..strokeWidth = 1.1;
    final pitchRect = pitch.outerRect;
    canvas.drawLine(
      Offset(pitchRect.left - 5, pitchRect.top + 8),
      Offset(pitchRect.right + 5, pitchRect.top + 8),
      creasePaint,
    );
    canvas.drawLine(
      Offset(pitchRect.left - 5, pitchRect.bottom - 8),
      Offset(pitchRect.right + 5, pitchRect.bottom - 8),
      creasePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
