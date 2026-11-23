import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guess_game/api/game_api.dart';
import 'package:guess_game/api/game_session.dart';
import 'package:guess_game/game/guess_engine.dart';
import 'package:guess_game/game/hunt_level.dart';
import 'package:guess_game/game/player_progress.dart';
import 'package:guess_game/screens/result_screen.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/attempt_pips.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/game_keypad.dart';
import 'package:guess_game/widgets/neon_button.dart';
import 'package:guess_game/widgets/range_track.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, this.engine, this.level});

  final GuessEngine? engine;
  final HuntLevel? level;

  static Route<void> route({GuessEngine? engine, HuntLevel? level}) {
    return FadeScaleRoute(page: PlayScreen(engine: engine, level: level));
  }

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen>
    with SingleTickerProviderStateMixin {
  GuessEngine? _engine;
  String? _gameId;
  late final AnimationController _shake;
  String _input = '';
  String? _error;
  String? _startError;
  GuessAttempt? _lastAttempt;
  bool _busy = false;

  HuntLevel get _level => widget.level ?? PlayerProgress.instance.selectedLevel;

  @override
  void initState() {
    super.initState();
    if (widget.engine != null || GameSession.forceLocal) {
      _engine = widget.engine ?? GuessEngine.fromLevel(_level);
    } else {
      _openRemoteHunt();
    }
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _openRemoteHunt() async {
    setState(() {
      _startError = null;
      _engine = null;
      _gameId = null;
    });
    try {
      if (!GameSession.instance.ready) {
        await GameSession.instance.bootstrap();
      }

      final online = await GameSession.instance.ensureServerSession();
      if (!mounted) return;

      if (!online) {
        // API truly unreachable — keep local play so the hunt still works.
        setState(() {
          _gameId = null;
          _engine = GuessEngine.fromLevel(_level);
        });
        return;
      }

      final playerId = GameSession.instance.playerId;
      if (playerId == null) {
        throw ApiException('No hunter profile on the server yet.');
      }

      final started = await GameSession.instance.api.startGame(
        playerId: playerId,
        levelId: _level.id,
      );
      if (!mounted) return;
      GameSession.instance.applyPlayer(started.player);
      setState(() {
        _gameId = started.gameId;
        _engine = started.engine;
        _startError = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _gameId = null;
        _engine = null;
        _startError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _gameId = null;
        _engine = null;
        _startError =
            'Cannot reach the hunt server. Keep the API running on port 3100, then try again.';
      });
    }
  }

  void _type(String digit) {
    final engine = _engine;
    if (engine == null || _input.length >= engine.maxDigits) return;
    setState(() {
      _error = null;
      _input = '$_input$digit';
    });
  }

  void _backspace() {
    if (_input.isEmpty) return;
    setState(() {
      _error = null;
      _input = _input.substring(0, _input.length - 1);
    });
  }

  void _clear() {
    setState(() {
      _error = null;
      _input = '';
    });
  }

  Future<void> _submit() async {
    if (_input.isEmpty) {
      setState(() => _error = 'Enter a number first.');
      _shake.forward(from: 0);
      return;
    }
    final value = int.tryParse(_input);
    if (value == null) {
      setState(() => _error = 'That is not a number.');
      _shake.forward(from: 0);
      return;
    }

    if (_gameId != null) {
      await _submitRemote(value);
      return;
    }
    final engine = _engine;
    if (engine == null) return;

    final result = engine.submit(value);
    if (result.isError) {
      setState(() => _error = result.error);
      _shake.forward(from: 0);
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _lastAttempt = result.attempt;
      _error = null;
      _input = '';
    });

    if (engine.isOver && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 420));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        ResultScreen.route(engine: engine),
      );
    }
  }

  Future<void> _submitRemote(int value) async {
    setState(() => _busy = true);
    try {
      final result = await GameSession.instance.api.submitGuess(
        gameId: _gameId!,
        value: value,
      );
      if (!mounted) return;
      GameSession.instance.applyPlayer(result.player);
      setState(() {
        _engine = result.engine;
        _lastAttempt = result.engine.guesses.last;
        _error = null;
        _input = '';
        _busy = false;
      });
      if (result.engine.isOver) {
        await Future<void>.delayed(const Duration(milliseconds: 420));
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          ResultScreen.route(
            engine: result.engine,
            settledOnServer: true,
            awardedPoints: result.pointsEarned,
            awardedBonus: result.campaignBonus,
            unlockedLevels: result.unlockedLevels,
          ),
        );
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _busy = false;
      });
      _shake.forward(from: 0);
      HapticFeedback.heavyImpact();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'The hunt server did not answer.';
        _busy = false;
      });
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final label = event.logicalKey.keyLabel;
    if (label.length == 1 && label.contains(RegExp(r'[0-9]'))) {
      _type(label);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _backspace();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _submit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final engine = _engine;
    if (engine == null) {
      return GameBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: _startError == null
                    ? const CircularProgressIndicator(color: GameColors.cyan)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _startError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: GameColors.coral),
                          ),
                          const SizedBox(height: 16),
                          NeonButton(
                            label: 'TRY AGAIN',
                            onPressed: _openRemoteHunt,
                          ),
                          const SizedBox(height: 10),
                          NeonButton(
                            label: 'PLAY OFFLINE',
                            outlined: true,
                            color: GameColors.gold,
                            onPressed: () {
                              setState(() {
                                _startError = null;
                                _gameId = null;
                                _engine = GuessEngine.fromLevel(_level);
                              });
                            },
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
    }
    final hints = engine.unlockedHints;
    final last = _lastAttempt;

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Focus(
          autofocus: true,
          onKeyEvent: _onKey,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: GameColors.mute),
                      ),
                      Expanded(
                        child: Text(
                          engine.level?.name ?? 'HUNT IN PROGRESS',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: GameColors.text,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ),
                      Text(
                        '${engine.attemptsLeft}',
                        style: TextStyle(
                          color: engine.attemptsLeft <= 3
                              ? GameColors.coral
                              : GameColors.cyan,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  AttemptPips(
                    total: engine.maxAttempts,
                    remaining: engine.attemptsLeft,
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    flex: 5,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                            decoration: panelDecoration(
                              glow: last == null
                                  ? GameColors.violet
                                  : last.direction == GuessDirection.tooHigh
                                      ? GameColors.coral
                                      : GameColors.cyan,
                            ),
                            child: Column(
                              children: [
                                RangeTrack(engine: engine),
                                const SizedBox(height: 14),
                                Text(
                                  last == null
                                      ? 'MAKE YOUR FIRST SHOT'
                                      : last.direction.hudLabel,
                                  style: TextStyle(
                                    color: last == null
                                        ? GameColors.mute
                                        : last.direction ==
                                                GuessDirection.tooHigh
                                            ? GameColors.coral
                                            : GameColors.lime,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.2,
                                    fontSize: 18,
                                  ),
                                ),
                                if (last != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${last.heat.label}  •  last shot ${last.value}',
                                    style: const TextStyle(
                                      color: GameColors.gold,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (hints.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _HintCard(
                              hints: hints,
                              fresh: engine.justUnlockedHint,
                            ),
                          ],
                          if (engine.guesses.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 34,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  for (final guess in engine.guesses.reversed)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(99),
                                        color: const Color(0xFF1A2142),
                                        border: Border.all(
                                            color: GameColors.panelBorder),
                                      ),
                                      child: Text(
                                        '${guess.value} ${guess.direction.arrow}',
                                        style: const TextStyle(
                                          color: GameColors.text,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          AnimatedBuilder(
                            animation: _shake,
                            builder: (context, child) {
                              final dx = math.sin(_shake.value * math.pi * 6) *
                                  10 *
                                  (1 - _shake.value);
                              return Transform.translate(
                                offset: Offset(dx, 0),
                                child: child,
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF070B1A),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: _error == null
                                      ? GameColors.cyan
                                      : GameColors.coral,
                                  width: 1.6,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _input.isEmpty ? '•••' : _input,
                                    style: TextStyle(
                                      color: _input.isEmpty
                                          ? GameColors.mute
                                          : GameColors.text,
                                      fontSize: 40,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 8,
                                    ),
                                  ),
                                  Text(
                                    _error ??
                                        'ENTER ${engine.minValue} – ${engine.maxValue}',
                                    style: hudLabelStyle(
                                      color: _error == null
                                          ? GameColors.mute
                                          : GameColors.coral,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 5,
                    child: GameKeypad(
                      onDigit: _type,
                      onBackspace: _backspace,
                      onClear: _clear,
                    ),
                  ),
                  NeonButton(
                    label: 'LOCK IN',
                    onPressed: _busy || engine.isOver ? null : _submit,
                    color: GameColors.lime,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.hints, required this.fresh});

  final List<String> hints;
  final bool fresh;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: panelDecoration(
        border: GameColors.gold,
        glow: GameColors.gold,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fresh ? 'NEW INTEL UNLOCKED' : 'INTEL',
            style: hudLabelStyle(color: GameColors.gold, size: 10),
          ),
          const SizedBox(height: 4),
          for (final hint in hints)
            Text(
              '• $hint',
              style: const TextStyle(
                color: GameColors.text,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
        ],
      ),
    );
  }
}
