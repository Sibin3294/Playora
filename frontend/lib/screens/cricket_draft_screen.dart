import 'dart:math';

import 'package:flutter/material.dart';
import 'package:guess_game/cricket/draft_engine.dart';
import 'package:guess_game/cricket/models.dart';
import 'package:guess_game/cricket/roster.dart';
import 'package:guess_game/screens/cricket_prematch_screen.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/cricket_ground.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

class CricketDraftScreen extends StatefulWidget {
  const CricketDraftScreen({
    super.key,
    required this.format,
    this.teamPool,
    this.headline,
    this.maxOverseas,
    this.onDraftComplete,
  });

  final CricketFormat format;
  final List<CricketTeam>? teamPool;
  final String? headline;

  /// League-specific overseas cap (IPL: 4). Null = no cap.
  final int? maxOverseas;

  /// When set, called instead of the exhibition prematch flow.
  final Future<void> Function(BuildContext context, Squad squad)? onDraftComplete;

  static Route<void> route(
    CricketFormat format, {
    List<CricketTeam>? teamPool,
    String? headline,
    int? maxOverseas,
    Future<void> Function(BuildContext context, Squad squad)? onDraftComplete,
  }) {
    return FadeScaleRoute(
      page: CricketDraftScreen(
        format: format,
        teamPool: teamPool,
        headline: headline,
        maxOverseas: maxOverseas,
        onDraftComplete: onDraftComplete,
      ),
    );
  }

  @override
  State<CricketDraftScreen> createState() => _CricketDraftScreenState();
}

class _CricketDraftScreenState extends State<CricketDraftScreen> {
  late final DraftEngine _draft;
  late final List<CricketTeam> _pool;
  DraftOffer? _offer;
  CricketPlayer? _selectedPlayer;
  SquadSlot? _selectedSlot;
  String? _error;
  bool _busy = false;
  bool _spinning = false;
  bool _spinLanded = false;
  CricketTeam? _spinDisplayTeam;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _pool = widget.teamPool ?? cricketTeams;
    _draft = DraftEngine(teamPool: _pool, maxOverseas: widget.maxOverseas);
  }

  Future<void> _spin() async {
    if (_spinning || _busy || _draft.isComplete) return;

    setState(() {
      _error = null;
      _selectedPlayer = null;
      _selectedSlot = null;
      _offer = null;
      _spinning = true;
      _spinLanded = false;
      _spinDisplayTeam = _pool[_random.nextInt(_pool.length)];
    });

    late final DraftOffer offer;
    try {
      offer = _draft.spin();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _spinning = false;
        _spinDisplayTeam = null;
        _error = error.toString();
      });
      return;
    }

    final pool = _pool.where((team) => team.id != offer.team.id).toList()
      ..shuffle(_random);
    if (pool.isEmpty) {
      pool.add(offer.team);
    }

    // Build a decelerating reel that ends on the real spun team.
    final frames = <CricketTeam>[];
    for (var i = 0; i < 16; i++) {
      frames.add(pool[i % pool.length]);
    }
    frames.add(offer.team);

    for (var i = 0; i < frames.length; i++) {
      if (!mounted) return;
      setState(() {
        _spinDisplayTeam = frames[i];
        _spinLanded = i == frames.length - 1;
      });
      final t = i / (frames.length - 1);
      final delayMs = (55 + (t * t * 220)).round();
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }

    // Hold the winning team so the user can read it.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _spinning = false;
      _spinLanded = false;
      _spinDisplayTeam = null;
      _offer = offer;
    });
  }

  void _showOverseasCapAlert() {
    final cap = widget.maxOverseas ?? _draft.maxOverseas ?? 4;
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: GameColors.panelSolid,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: GameColors.panelBorder),
          ),
          title: Text(
            'OVERSEAS LIMIT',
            style: hudLabelStyle(color: GameColors.magenta, size: 12),
          ),
          content: Text(
            'Only $cap overseas players are allowed in your XI. '
            'You already have $cap. Pick a domestic player instead.',
            style: const TextStyle(
              color: GameColors.text,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'OK',
                style: hudLabelStyle(color: GameColors.lime, size: 11),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmPick() {
    final offer = _offer;
    final player = _selectedPlayer;
    final slot = _selectedSlot;
    if (offer == null || player == null || slot == null) {
      setState(() => _error = 'Pick a player and a free role slot.');
      return;
    }
    if (_draft.isBlockedByOverseas(player)) {
      _showOverseasCapAlert();
      return;
    }
    try {
      _draft.pick(team: offer.team, player: player, slot: slot);
      setState(() {
        _offer = null;
        _selectedPlayer = null;
        _selectedSlot = null;
        _error = null;
      });
      if (_draft.isComplete) {
        _startMatch();
      }
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }

  Future<void> _startMatch() async {
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    try {
      final userSquad = _draft.toSquad();
      if (widget.onDraftComplete != null) {
        await widget.onDraftComplete!(context, userSquad);
        return;
      }
      final cpuSquad = DraftEngine(
        teamPool: _pool,
        maxOverseas: widget.maxOverseas,
      ).buildCpuSquad(
        excludePlayerIds: userSquad.players.map((p) => p.id).toSet(),
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        CricketPrematchScreen.route(
          format: widget.format,
          userSquad: userSquad,
          cpuSquad: cpuSquad,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer = _offer;
    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: _busy || _spinning
                          ? null
                          : () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: GameColors.mute,
                      ),
                    ),
                    Text(
                      widget.headline ?? '${widget.format.label} DRAFT',
                      style: hudLabelStyle(color: GameColors.lime, size: 12),
                    ),
                    const Spacer(),
                    if (widget.maxOverseas != null) ...[
                      Text(
                        'OS ${_draft.overseasCount}/${widget.maxOverseas}',
                        style: hudLabelStyle(
                          color: _draft.overseasCapReached
                              ? GameColors.coral
                              : GameColors.mute,
                          size: 10,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      _draft.isComplete
                          ? 'XI READY'
                          : 'SPIN ${_draft.spinNumber}/11',
                      style: hudLabelStyle(color: GameColors.gold, size: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                CricketGround(
                  slots: t20Slots,
                  picks: _draft.picks,
                  selectedSlotIndex: _selectedSlot?.index,
                  highlightedSlotIndexes: _selectedPlayer == null
                      ? const <int>{}
                      : _draft
                          .slotsForPlayer(_selectedPlayer!)
                          .map((slot) => slot.index)
                          .toSet(),
                  onSlotTap: (_spinning || _busy)
                      ? null
                      : (slot) {
                          if (_selectedPlayer == null) return;
                          if (!_draft.slotsForPlayer(_selectedPlayer!).any(
                                (open) => open.index == slot.index,
                              )) {
                            setState(() {
                              _error =
                                  '${_selectedPlayer!.name} cannot take the ${slot.label} mark.';
                            });
                            return;
                          }
                          setState(() {
                            _selectedSlot = slot;
                            _error = null;
                          });
                        },
                ),
                const SizedBox(height: 10),
                if (_busy)
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: GameColors.lime),
                          SizedBox(height: 16),
                          Text(
                            'RIVAL XI LOCKING IN… TOSS COMING UP',
                            style: TextStyle(
                              color: GameColors.mute,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_spinning) ...[
                  Expanded(
                    child: _TeamSpinView(
                      team: _spinDisplayTeam,
                      landed: _spinLanded,
                      spinNumber: _draft.spinNumber,
                    ),
                  ),
                ] else if (offer == null) ...[
                  Expanded(
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: panelDecoration(glow: GameColors.lime),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'SPIN ${_draft.spinNumber}',
                              style: hudLabelStyle(
                                color: GameColors.lime,
                                size: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Spin the national packs. Watch the reel, then claim one player for an open role.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: GameColors.mute,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 18),
                            NeonButton(
                              label: 'SPIN TEAM',
                              color: GameColors.lime,
                              onPressed: _spin,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    '${offer.team.name.toUpperCase()} PACK',
                    style: const TextStyle(
                      color: GameColors.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You landed ${offer.team.shortName}. Pick one player for a free role.',
                    style: hudLabelStyle(size: 9),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      children: [
                        ...offer.eligiblePlayers.map((player) {
                          final selected = _selectedPlayer?.id == player.id;
                          final blocked =
                              _draft.isBlockedByOverseas(player);
                          final fits = _draft.slotsForPlayer(player);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Opacity(
                              opacity: blocked ? 0.48 : 1,
                              child: InkWell(
                                onTap: () {
                                  if (blocked) {
                                    _showOverseasCapAlert();
                                    return;
                                  }
                                  setState(() {
                                    _selectedPlayer = player;
                                    _selectedSlot =
                                        fits.length == 1 ? fits.first : null;
                                    _error = null;
                                  });
                                },
                                borderRadius: BorderRadius.circular(18),
                                child: Ink(
                                  padding: const EdgeInsets.all(14),
                                  decoration: panelDecoration(
                                    glow: blocked
                                        ? GameColors.mute
                                        : (selected
                                            ? GameColors.lime
                                            : GameColors.cyan),
                                    border: selected && !blocked
                                        ? GameColors.lime
                                        : (blocked
                                            ? GameColors.panelBorder
                                            : null),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              player.name,
                                              style: TextStyle(
                                                color: blocked
                                                    ? GameColors.mute
                                                    : GameColors.text,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'OVR ${player.overall}',
                                            style: hudLabelStyle(
                                              color: GameColors.gold,
                                              size: 9,
                                            ),
                                          ),
                                          if (player.isOverseas) ...[
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.flight_rounded,
                                              size: 16,
                                              color: GameColors.magenta
                                                  .withOpacity(
                                                blocked ? 0.55 : 1,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'BAT ${player.batRating}  •  BOWL ${player.bowlRating}  •  FIELD ${player.fieldRating}',
                                        style: const TextStyle(
                                          color: GameColors.mute,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        blocked
                                            ? 'OVERSEAS CAP FULL • NOT AVAILABLE'
                                            : player.roles
                                                .map((role) => role.label)
                                                .join(' / '),
                                        style: hudLabelStyle(
                                          color: blocked
                                              ? GameColors.coral
                                              : GameColors.cyan,
                                          size: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        if (_selectedPlayer != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'ASSIGN ROLE • TAP A HIGHLIGHTED MARK ON THE GROUND',
                            style: hudLabelStyle(size: 9),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _draft
                                .slotsForPlayer(_selectedPlayer!)
                                .map((slot) {
                              final selected =
                                  _selectedSlot?.index == slot.index;
                              return ChoiceChip(
                                label: Text(slot.label),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() => _selectedSlot = slot);
                                },
                                selectedColor: GameColors.lime.withOpacity(0.25),
                                backgroundColor: GameColors.panelSolid,
                                labelStyle: TextStyle(
                                  color: selected
                                      ? GameColors.lime
                                      : GameColors.text,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                                side: BorderSide(
                                  color: selected
                                      ? GameColors.lime
                                      : GameColors.panelBorder,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  NeonButton(
                    label: 'LOCK PICK',
                    color: GameColors.lime,
                    onPressed: _confirmPick,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GameColors.coral,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamSpinView extends StatelessWidget {
  const _TeamSpinView({
    required this.team,
    required this.landed,
    required this.spinNumber,
  });

  final CricketTeam? team;
  final bool landed;
  final int spinNumber;

  @override
  Widget build(BuildContext context) {
    final short = team?.shortName ?? '…';
    final name = team?.name.toUpperCase() ?? 'DRAWING PACK';
    final accent = landed ? GameColors.gold : GameColors.cyan;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: panelDecoration(glow: accent),
      child: Column(
        children: [
          Text(
            landed ? 'TEAM LOCKED' : 'SPINNING PACKS',
            style: hudLabelStyle(color: accent, size: 11),
          ),
          const SizedBox(height: 6),
          Text(
            'Spin $spinNumber of 11',
            style: const TextStyle(color: GameColors.mute, fontSize: 12),
          ),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 120),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.86, end: 1).animate(animation),
                  child: child,
                ),
              );
            },
            child: Column(
              key: ValueKey<String>('${team?.id}-$landed'),
              children: [
                Container(
                  width: 120,
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF10182E),
                    border: Border.all(color: accent, width: 2.4),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.35),
                        blurRadius: landed ? 24 : 14,
                        spreadRadius: landed ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Text(
                    short,
                    style: TextStyle(
                      color: accent,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: GameColors.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            landed
                ? 'Opening the ${team?.shortName ?? ''} pack…'
                : 'Watch the reel — one nation will land for this pick.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GameColors.mute,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
