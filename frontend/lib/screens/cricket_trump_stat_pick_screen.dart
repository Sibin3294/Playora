import 'package:flutter/material.dart';
import 'package:guess_game/cards/trump_models.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

class CricketTrumpStatPickScreen extends StatefulWidget {
  const CricketTrumpStatPickScreen({
    super.key,
    required this.level,
    required this.pickCount,
    required this.available,
  });

  final int level;
  final int pickCount;
  final List<TrumpStat> available;

  static Route<List<TrumpStat>> route({
    required int level,
    required int pickCount,
    required List<TrumpStat> available,
  }) {
    return FadeScaleRoute(
      page: CricketTrumpStatPickScreen(
        level: level,
        pickCount: pickCount,
        available: available,
      ),
    );
  }

  @override
  State<CricketTrumpStatPickScreen> createState() =>
      _CricketTrumpStatPickScreenState();
}

class _CricketTrumpStatPickScreenState
    extends State<CricketTrumpStatPickScreen> {
  final Set<TrumpStat> _selected = {};

  void _toggle(TrumpStat stat) {
    setState(() {
      if (_selected.contains(stat)) {
        _selected.remove(stat);
        return;
      }
      if (_selected.length >= widget.pickCount) return;
      _selected.add(stat);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ready = _selected.length == widget.pickCount;

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: GameColors.mute,
                      ),
                    ),
                    Text(
                      'LEVEL ${widget.level} UNLOCK',
                      style: hudLabelStyle(color: GameColors.gold, size: 12),
                    ),
                    const Spacer(),
                    Text(
                      '${_selected.length}/${widget.pickCount}',
                      style: hudLabelStyle(color: GameColors.magenta, size: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Pick ${widget.pickCount} new stats',
                  style: const TextStyle(
                    color: GameColors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'These join your carried stats for this level and beyond.',
                  style: TextStyle(color: GameColors.mute, height: 1.35),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final stat in widget.available)
                            _StatChip(
                              stat: stat,
                              selected: _selected.contains(stat),
                              enabled: _selected.contains(stat) ||
                                  _selected.length < widget.pickCount,
                              onTap: () => _toggle(stat),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                NeonButton(
                  label: ready ? 'LOCK STATS & PLAY' : 'PICK ${widget.pickCount}',
                  color: GameColors.magenta,
                  onPressed: ready
                      ? () => Navigator.of(context)
                          .pop(_selected.toList(growable: false))
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.stat,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final TrumpStat stat;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? GameColors.lime : GameColors.cyan;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: (MediaQuery.sizeOf(context).width - 56) / 2,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(selected ? 0.18 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : GameColors.panelBorder,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.shortLabel,
                style: hudLabelStyle(color: color, size: 10),
              ),
              const SizedBox(height: 4),
              Text(
                stat.label,
                style: TextStyle(
                  color: selected ? GameColors.text : GameColors.mute,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              if (!stat.higherWins) ...[
                const SizedBox(height: 4),
                Text(
                  'LOWER WINS',
                  style: hudLabelStyle(color: GameColors.gold, size: 8),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
