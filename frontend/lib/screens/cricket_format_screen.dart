import 'package:flutter/material.dart';
import 'package:guess_game/cricket/models.dart';
import 'package:guess_game/screens/cricket_t20_hub_screen.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

class CricketFormatScreen extends StatelessWidget {
  const CricketFormatScreen({super.key});

  static Route<void> route() =>
      FadeScaleRoute(page: const CricketFormatScreen());

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
                      'CRICKET DRAFT',
                      style: hudLabelStyle(color: GameColors.lime, size: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'PICK YOUR\nFORMAT',
                  style: TextStyle(
                    color: GameColors.text,
                    fontSize: 38,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pick a format, then choose a one-off system match or a full league season.',
                  style: TextStyle(
                    color: GameColors.mute,
                    height: 1.4,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: ListView.separated(
                    itemCount: CricketFormat.values.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final format = CricketFormat.values[index];
                      return _FormatTile(
                        format: format,
                        onPlay: format.locked
                            ? null
                            : () {
                                if (format == CricketFormat.t20) {
                                  Navigator.of(context).push(
                                    CricketT20HubScreen.route(),
                                  );
                                }
                              },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormatTile extends StatelessWidget {
  const _FormatTile({required this.format, required this.onPlay});

  final CricketFormat format;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final live = !format.locked;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: panelDecoration(
        glow: live ? GameColors.lime : GameColors.panelBorder,
        border: live ? null : GameColors.panelBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  format.label,
                  style: const TextStyle(
                    color: GameColors.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Text(
                live ? 'OPEN' : 'LOCKED',
                style: hudLabelStyle(
                  color: live ? GameColors.lime : GameColors.gold,
                  size: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            live
                ? '${format.overs} overs a side. Exhibition fixtures or league cups.'
                : 'Coming in a later competition drop.',
            style: const TextStyle(color: GameColors.mute, height: 1.4),
          ),
          const SizedBox(height: 16),
          NeonButton(
            label: live ? 'ENTER T20' : 'LOCKED',
            color: live ? GameColors.lime : GameColors.mute,
            height: 48,
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}
