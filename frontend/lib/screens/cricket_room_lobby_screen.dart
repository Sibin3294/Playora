import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guess_game/api/game_api.dart';
import 'package:guess_game/api/game_session.dart';
import 'package:guess_game/cricket/match_codec.dart';
import 'package:guess_game/cricket/match_engine.dart';
import 'package:guess_game/cricket/models.dart';
import 'package:guess_game/screens/cricket_draft_screen.dart';
import 'package:guess_game/screens/cricket_match_screen.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

class CricketRoomLobbyScreen extends StatefulWidget {
  const CricketRoomLobbyScreen({super.key, required this.code});

  final String code;

  static Route<void> route({required String code}) {
    return FadeScaleRoute(page: CricketRoomLobbyScreen(code: code));
  }

  @override
  State<CricketRoomLobbyScreen> createState() => _CricketRoomLobbyScreenState();
}

class _CricketRoomLobbyScreenState extends State<CricketRoomLobbyScreen> {
  Timer? _poll;
  Map<String, dynamic>? _room;
  String? _error;
  bool _busy = false;
  bool _openingMatch = false;
  bool _simulating = false;

  String get _playerId => GameSession.instance.playerId ?? '';

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_playerId.isEmpty || _busy || _openingMatch) return;
    try {
      final room = await GameSession.instance.api.getRoom(
        code: widget.code,
        playerId: _playerId,
      );
      if (!mounted) return;
      setState(() {
        _room = room;
        _error = null;
      });
      await _maybeSimulate(room);
      await _maybeOpenMatch(room);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Lost connection to the room server.');
    }
  }

  Future<void> _maybeSimulate(Map<String, dynamic> room) async {
    if (_simulating || _openingMatch) return;
    if (room['youAreHost'] != true) return;
    if (room['status'] != 'ready') return;
    if (room['matchResult'] != null) return;

    final hostSquadJson = room['hostSquad'] as Map<String, dynamic>?;
    final guestSquadJson = room['guestSquad'] as Map<String, dynamic>?;
    if (hostSquadJson == null || guestSquadJson == null) return;

    _simulating = true;
    try {
      final host = room['host'] as Map<String, dynamic>;
      final guest = room['guest'] as Map<String, dynamic>;
      final result = MatchEngine().play(
        format: CricketFormat.t20,
        userSquad: squadFromJson(hostSquadJson),
        cpuSquad: squadFromJson(guestSquadJson),
        userTeamName: (host['name'] as String?) ?? 'HOST',
        cpuTeamName: (guest['name'] as String?) ?? 'GUEST',
      );
      final updated = await GameSession.instance.api.submitRoomMatch(
        code: widget.code,
        playerId: _playerId,
        matchResult: matchResultToJson(result),
      );
      if (!mounted) return;
      setState(() => _room = updated);
      await _maybeOpenMatch(updated);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not simulate the match.');
    } finally {
      _simulating = false;
    }
  }

  Future<void> _maybeOpenMatch(Map<String, dynamic> room) async {
    if (_openingMatch) return;
    final raw = room['matchResult'];
    if (raw is! Map<String, dynamic>) return;

    _openingMatch = true;
    _poll?.cancel();
    try {
      final hostView = matchResultFromJson(raw);
      final isHost = room['youAreHost'] == true;
      final perspective = isHost ? hostView : matchResultForGuest(hostView);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        CricketMatchScreen.route(perspective, skipToss: true),
      );
    } catch (_) {
      _openingMatch = false;
      if (!mounted) return;
      setState(() => _error = 'Match data could not be opened.');
      _poll = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
    }
  }

  Future<void> _draft() async {
    setState(() => _busy = true);
    await Navigator.of(context).push(
      CricketDraftScreen.route(
        CricketFormat.t20,
        headline: 'ROOM DRAFT • ${widget.code}',
        onDraftComplete: (context, squad) async {
          try {
            final room = await GameSession.instance.api.submitRoomSquad(
              code: widget.code,
              playerId: _playerId,
              squad: squadToJson(squad),
            );
            if (context.mounted) {
              Navigator.of(context).pop();
            }
            if (!mounted) return;
            setState(() {
              _room = room;
              _busy = false;
              _error = null;
            });
          } on ApiException catch (error) {
            if (!mounted) return;
            setState(() {
              _busy = false;
              _error = error.message;
            });
          }
        },
      ),
    );
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _ready() async {
    setState(() => _busy = true);
    try {
      final room = await GameSession.instance.api.setRoomReady(
        code: widget.code,
        playerId: _playerId,
      );
      if (!mounted) return;
      setState(() {
        _room = room;
        _busy = false;
      });
      await _maybeSimulate(room);
      await _maybeOpenMatch(room);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not ready up.';
      });
    }
  }

  bool _iHaveSquad(Map<String, dynamic> room) {
    final host = room['host'] as Map<String, dynamic>;
    final guest = room['guest'] as Map<String, dynamic>?;
    if (room['youAreHost'] == true) return host['hasSquad'] == true;
    return guest?['hasSquad'] == true;
  }

  bool _iAmReady(Map<String, dynamic> room) {
    final host = room['host'] as Map<String, dynamic>;
    final guest = room['guest'] as Map<String, dynamic>?;
    if (room['youAreHost'] == true) return host['ready'] == true;
    return guest?['ready'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;
    final host = room?['host'] as Map<String, dynamic>?;
    final guest = room?['guest'] as Map<String, dynamic>?;
    final status = room?['status'] as String? ?? 'waiting';

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
                      tooltip: 'Leave',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: GameColors.mute,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'ROOM LOBBY',
                        style: hudLabelStyle(color: GameColors.gold, size: 12),
                      ),
                    ),
                    if (_simulating)
                      Text(
                        'SIMULATING…',
                        style: hudLabelStyle(color: GameColors.cyan, size: 10),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'PRIVATE\nFIXTURE',
                  style: TextStyle(
                    color: GameColors.text,
                    fontSize: 32,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: panelDecoration(glow: GameColors.gold),
                  child: Column(
                    children: [
                      Text(
                        'SHARE CODE',
                        style: hudLabelStyle(color: GameColors.gold, size: 10),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.code,
                        style: const TextStyle(
                          color: GameColors.text,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: widget.code),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: GameColors.panelSolid,
                              content: Text(
                                'Room code copied.',
                                style: TextStyle(color: GameColors.text),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.copy_rounded,
                          color: GameColors.gold,
                          size: 18,
                        ),
                        label: Text(
                          'COPY CODE',
                          style: hudLabelStyle(color: GameColors.gold, size: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    children: [
                      _SeatCard(
                        title: 'HOST',
                        name: host?['name'] as String? ?? '…',
                        hasSquad: host?['hasSquad'] == true,
                        ready: host?['ready'] == true,
                        accent: GameColors.gold,
                        isYou: room?['youAreHost'] == true,
                      ),
                      const SizedBox(height: 10),
                      _SeatCard(
                        title: 'GUEST',
                        name: guest != null
                            ? (guest['name'] as String? ?? 'Guest')
                            : 'Waiting for code join…',
                        hasSquad: guest?['hasSquad'] == true,
                        ready: guest?['ready'] == true,
                        accent: GameColors.cyan,
                        isYou: room?['youAreGuest'] == true,
                        empty: guest == null,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _statusLabel(status),
                        textAlign: TextAlign.center,
                        style: hudLabelStyle(color: GameColors.mute, size: 10),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
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
                if (room != null && guest != null) ...[
                  if (!_iHaveSquad(room))
                    NeonButton(
                      label: _busy ? 'OPENING DRAFT…' : 'DRAFT YOUR XI',
                      color: GameColors.lime,
                      onPressed: _busy ? null : _draft,
                    )
                  else if (!_iAmReady(room))
                    NeonButton(
                      label: _busy ? 'READYING…' : 'READY UP',
                      color: GameColors.cyan,
                      onPressed: _busy ? null : _ready,
                    )
                  else
                    Text(
                      status == 'finished' || room['matchResult'] != null
                          ? 'OPENING MATCH…'
                          : 'WAITING FOR BOTH PLAYERS…',
                      textAlign: TextAlign.center,
                      style: hudLabelStyle(color: GameColors.gold, size: 10),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'waiting':
        return 'WAITING FOR OPPONENT';
      case 'open':
        return 'DRAFT AND READY UP';
      case 'ready':
        return 'BOTH READY • HOST SIMULATING';
      case 'finished':
        return 'MATCH READY';
      default:
        return status.toUpperCase();
    }
  }
}

class _SeatCard extends StatelessWidget {
  const _SeatCard({
    required this.title,
    required this.name,
    required this.hasSquad,
    required this.ready,
    required this.accent,
    required this.isYou,
    this.empty = false,
  });

  final String title;
  final String name;
  final bool hasSquad;
  final bool ready;
  final Color accent;
  final bool isYou;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: panelDecoration(glow: accent),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isYou ? '$title • YOU' : title,
                  style: hudLabelStyle(color: accent, size: 10),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: TextStyle(
                    color: empty ? GameColors.mute : GameColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hasSquad ? 'XI SET' : 'NO XI',
                style: hudLabelStyle(
                  color: hasSquad ? GameColors.lime : GameColors.mute,
                  size: 9,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ready ? 'READY' : 'NOT READY',
                style: hudLabelStyle(
                  color: ready ? GameColors.cyan : GameColors.mute,
                  size: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
