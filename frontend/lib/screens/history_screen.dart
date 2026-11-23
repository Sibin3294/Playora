import 'package:flutter/material.dart';
import 'package:guess_game/catalog/game_catalog.dart';
import 'package:guess_game/cricket/match_history.dart';
import 'package:guess_game/game/hunt_archive.dart';
import 'package:guess_game/history/play_history.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/game_background.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.archive});

  /// Kept for call-site compatibility; history now reads [PlayHistoryStore].
  final Object? archive;

  static Route<void> route({Object? archive}) {
    return FadeScaleRoute(page: HistoryScreen(archive: archive));
  }

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _filterGameId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final store = PlayHistoryStore.instance;
    await store.ensureLoaded();
    if (await store.needsLegacyMigration()) {
      final legacy = <PlayHistoryEntry>[
        for (final hunt in HuntArchive.instance.records)
          PlayHistoryEntry(
            id:
                'legacy_hunt_${hunt.playedAt.toIso8601String()}_${hunt.secretNumber}',
            gameId: GameCatalog.numberHunterId,
            resultLabel: hunt.resultLabel,
            headline: '${hunt.secretNumber}',
            summary: hunt.summary,
            playedAt: hunt.playedAt,
            won: hunt.won,
            detail: hunt.levelName,
          ),
        for (final match in await MatchHistoryStore.all())
          PlayHistoryEntry(
            id:
                'legacy_match_${match.playedAt.toIso8601String()}_${match.scoreline}',
            gameId: GameCatalog.cricketId,
            resultLabel: match.resultLabel,
            headline: match.scoreline,
            summary: match.summary.isEmpty ? match.venueName : match.summary,
            playedAt: match.playedAt,
            won: match.tied ? null : match.userWon,
            detail: match.venueName,
          ),
      ];
      await store.importLegacy(legacy);
      await store.markLegacyMigrated();
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
            child: ListenableBuilder(
              listenable: PlayHistoryStore.instance,
              builder: (context, _) {
                final store = PlayHistoryStore.instance;
                final entries = store.filtered(gameId: _filterGameId);
                final wins = entries.where((e) => e.won == true).length;
                final games = GameCatalog.playableGames;

                return Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: GameColors.mute,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'PLAY HISTORY',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: GameColors.text,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Clear history',
                          onPressed: entries.isEmpty
                              ? null
                              : () => _confirmClear(context),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: entries.isEmpty
                                ? GameColors.mute.withOpacity(0.35)
                                : GameColors.coral,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _FilterBar(
                      games: games,
                      selectedGameId: _filterGameId,
                      onChanged: (id) => setState(() => _filterGameId = id),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            title: 'PLAYED',
                            value: '${entries.length}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatTile(
                            title: 'WINS',
                            value: '$wins',
                            color: GameColors.lime,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatTile(
                            title: 'FILTER',
                            value: _filterGameId == null
                                ? 'ALL'
                                : (GameCatalog.gameById(_filterGameId!)
                                        ?.title
                                        .split(' ')
                                        .first ??
                                    'GAME'),
                            color: GameColors.cyan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: GameColors.cyan,
                              ),
                            )
                          : entries.isEmpty
                              ? _EmptyLog(
                                  filtered: _filterGameId != null,
                                )
                              : ListView.separated(
                                  itemCount: entries.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    return _HistoryCard(
                                      entry: entries[index],
                                      showGame: _filterGameId == null,
                                    );
                                  },
                                ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final filterLabel = _filterGameId == null
        ? 'all games'
        : (GameCatalog.gameById(_filterGameId!)?.title ?? 'this game');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: GameColors.panelSolid,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: GameColors.panelBorder),
          ),
          title: Text(
            'CLEAR HISTORY?',
            style: hudLabelStyle(color: GameColors.coral, size: 14),
          ),
          content: Text(
            'This removes recorded plays for $filterLabel on this device.',
            style: const TextStyle(color: GameColors.mute, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('KEEP', style: hudLabelStyle(color: GameColors.mute)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  Text('CLEAR', style: hudLabelStyle(color: GameColors.coral)),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await PlayHistoryStore.instance.clear(gameId: _filterGameId);
    }
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.games,
    required this.selectedGameId,
    required this.onChanged,
  });

  final List<CatalogGame> games;
  final String? selectedGameId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openFilterSheet(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: panelDecoration(),
          child: Row(
            children: [
              const Icon(Icons.filter_list_rounded, color: GameColors.cyan),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FILTER BY GAME', style: hudLabelStyle(size: 9)),
                    const SizedBox(height: 4),
                    Text(
                      selectedGameId == null
                          ? 'All games'
                          : (GameCatalog.gameById(selectedGameId!)?.title ??
                              'Selected game'),
                      style: const TextStyle(
                        color: GameColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: GameColors.mute,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    final chosen = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: GameColors.panelSolid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'FILTER BY GAME',
                  style: hudLabelStyle(color: GameColors.cyan, size: 11),
                ),
                const SizedBox(height: 12),
                _FilterOption(
                  label: 'All games',
                  selected: selectedGameId == null,
                  onTap: () => Navigator.pop(context, ''),
                ),
                for (final game in games) ...[
                  const SizedBox(height: 8),
                  _FilterOption(
                    label: game.title,
                    selected: selectedGameId == game.id,
                    onTap: () => Navigator.pop(context, game.id),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
    if (chosen == null) return;
    onChanged(chosen.isEmpty ? null : chosen);
  }
}

class _FilterOption extends StatelessWidget {
  const _FilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? GameColors.cyan : GameColors.mute;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? GameColors.cyan.withOpacity(0.12)
              : const Color(0xFF10162C),
          border: Border.all(color: accent.withOpacity(selected ? 1 : 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? GameColors.text : GameColors.mute,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, color: GameColors.cyan, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    this.color = GameColors.text,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: panelDecoration(),
      child: Column(
        children: [
          Text(title, style: hudLabelStyle(size: 9)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLog extends StatelessWidget {
  const _EmptyLog({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              filtered ? 'NO MATCHES' : 'NO PLAYS YET',
              style: const TextStyle(
                color: GameColors.gold,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              filtered
                  ? 'Nothing recorded for this game yet. Play a round and it will show up here.'
                  : 'Finish any game — Number Hunter, Cricket, Face Reveal, or Stat Battle — and it lands here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GameColors.mute,
                height: 1.45,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.entry,
    required this.showGame,
  });

  final PlayHistoryEntry entry;
  final bool showGame;

  @override
  Widget build(BuildContext context) {
    final accent = entry.won == true
        ? GameColors.lime
        : entry.won == false
            ? GameColors.coral
            : GameColors.gold;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: panelDecoration(border: accent, glow: accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: accent.withOpacity(0.16),
                  border: Border.all(color: accent),
                ),
                child: Text(
                  entry.resultLabel,
                  style: hudLabelStyle(color: accent, size: 10),
                ),
              ),
              const SizedBox(width: 10),
              Text(entry.ageLabel(), style: hudLabelStyle(size: 10)),
              if (showGame) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    entry.gameTitle,
                    overflow: TextOverflow.ellipsis,
                    style: hudLabelStyle(color: GameColors.cyan, size: 10),
                  ),
                ),
              ],
              if (entry.detail != null && entry.detail!.isNotEmpty) ...[
                const Spacer(),
                Flexible(
                  child: Text(
                    entry.detail!,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: hudLabelStyle(color: GameColors.mute, size: 10),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            entry.headline,
            style: const TextStyle(
              color: GameColors.text,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              height: 1.25,
            ),
          ),
          if (entry.summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry.summary,
              style: const TextStyle(
                color: GameColors.mute,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
