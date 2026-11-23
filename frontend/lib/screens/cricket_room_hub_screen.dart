import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guess_game/api/game_api.dart';
import 'package:guess_game/api/game_session.dart';
import 'package:guess_game/intro/first_run_store.dart';
import 'package:guess_game/screens/cricket_room_lobby_screen.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/first_run_intro.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

class CricketRoomHubScreen extends StatefulWidget {
  const CricketRoomHubScreen({super.key});

  static Route<void> route() =>
      FadeScaleRoute(page: const CricketRoomHubScreen());

  @override
  State<CricketRoomHubScreen> createState() => _CricketRoomHubScreenState();
}

class _CricketRoomHubScreenState extends State<CricketRoomHubScreen> {
  final _codeController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      maybeShowFirstRunIntro(
        context,
        id: FirstRunStore.privateRoomId,
        pages: const [
          FirstRunPage(
            title: 'PRIVATE ROOM',
            body:
                'Create a code and share it, or join a friend’s code. Both draft an XI, ready up, then play the same T20 match.',
            accent: GameColors.gold,
            icon: Icons.meeting_room_rounded,
          ),
          FirstRunPage(
            title: 'NEEDS THE API',
            body:
                'Rooms use the server on your Wi‑Fi. Keep the backend running so both players can connect.',
            accent: GameColors.cyan,
            icon: Icons.wifi_rounded,
          ),
        ],
      );
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<String> _ensurePlayerId() async {
    final online = await GameSession.instance.ensureServerSession();
    if (!online || GameSession.instance.playerId == null) {
      throw ApiException(
        'Private rooms need the hunt server on the same Wi‑Fi.',
      );
    }
    return GameSession.instance.playerId!;
  }

  String? get _displayName {
    final name = GameSession.instance.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    return GameSession.instance.isLoggedIn ? 'Hunter' : 'Guest';
  }

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final playerId = await _ensurePlayerId();
      final room = await GameSession.instance.api.createRoom(
        playerId: playerId,
        name: _displayName,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        CricketRoomLobbyScreen.route(code: room['code'] as String),
      );
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
        _error = 'Could not create a room. Is the API running?';
      });
    }
  }

  Future<void> _join() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length < 4) {
      setState(() => _error = 'Enter the room code from your friend.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final playerId = await _ensurePlayerId();
      final room = await GameSession.instance.api.joinRoom(
        code: code,
        playerId: playerId,
        name: _displayName,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        CricketRoomLobbyScreen.route(code: room['code'] as String),
      );
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
        _error = 'Could not join that room.';
      });
    }
  }

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
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: GameColors.mute,
                      ),
                    ),
                    Text(
                      'PRIVATE ROOM',
                      style: hudLabelStyle(color: GameColors.gold, size: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'INVITE &\nPLAY',
                  style: TextStyle(
                    color: GameColors.text,
                    fontSize: 36,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Create a room code, share it, and play a T20 with the same draft and match rules.',
                  style: TextStyle(
                    color: GameColors.mute,
                    height: 1.4,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: panelDecoration(glow: GameColors.gold),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'CREATE ROOM',
                        style: hudLabelStyle(color: GameColors.gold, size: 10),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You become the host. Share the code when it appears.',
                        style: TextStyle(color: GameColors.mute, height: 1.35),
                      ),
                      const SizedBox(height: 14),
                      NeonButton(
                        label: _busy ? 'WORKING…' : 'CREATE ROOM',
                        color: GameColors.gold,
                        height: 48,
                        onPressed: _busy ? null : _create,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: panelDecoration(glow: GameColors.cyan),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'JOIN ROOM',
                        style: hudLabelStyle(color: GameColors.cyan, size: 10),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _codeController,
                        enabled: !_busy,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9]'),
                          ),
                          LengthLimitingTextInputFormatter(6),
                        ],
                        style: const TextStyle(
                          color: GameColors.text,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                        decoration: InputDecoration(
                          hintText: 'ROOM CODE',
                          hintStyle: const TextStyle(
                            color: GameColors.mute,
                            letterSpacing: 2,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF070B1A),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: GameColors.panelBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: GameColors.cyan,
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      NeonButton(
                        label: _busy ? 'WORKING…' : 'JOIN ROOM',
                        color: GameColors.cyan,
                        height: 48,
                        onPressed: _busy ? null : _join,
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
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
