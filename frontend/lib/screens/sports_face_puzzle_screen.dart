import 'dart:math';

import 'package:flutter/material.dart';
import 'package:guess_game/catalog/game_catalog.dart';
import 'package:guess_game/history/play_history.dart';
import 'package:guess_game/puzzle/sports_face_puzzles.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/category_rating_prompt.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

class SportsFacePuzzleScreen extends StatefulWidget {
  const SportsFacePuzzleScreen({super.key});

  static Route<void> route() =>
      FadeScaleRoute(page: const SportsFacePuzzleScreen());

  @override
  State<SportsFacePuzzleScreen> createState() => _SportsFacePuzzleScreenState();
}

class _SportsFacePuzzleScreenState extends State<SportsFacePuzzleScreen>
    with TickerProviderStateMixin {
  static const _gridSize = 3;
  static const _maxChances = 5;

  late SportsFacePuzzle _puzzle;
  late Set<int> _removed;
  late List<String> _shuffledOptions;
  late List<SportsFacePuzzle> _deck;
  int _deckIndex = 0;
  int _chancesLeft = _maxChances;
  int _cleared = 0;
  bool? _won;
  String? _feedback;
  String? _wrongPick;

  late final AnimationController _boardPulse;
  late final AnimationController _resultPop;

  int get _tileCount => _gridSize * _gridSize;
  int get _revealedCount => _removed.length;

  @override
  void initState() {
    super.initState();
    _boardPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _resultPop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _reshuffleDeck();
    _startRound(fromDeck: true);
  }

  @override
  void dispose() {
    _boardPulse.dispose();
    _resultPop.dispose();
    super.dispose();
  }

  void _reshuffleDeck() {
    _deck = List<SportsFacePuzzle>.from(sportsFacePuzzles)..shuffle(Random());
    _deckIndex = 0;
  }

  void _startRound({SportsFacePuzzle? next, bool fromDeck = false}) {
    if (next != null) {
      _puzzle = next;
    } else if (fromDeck) {
      if (_deckIndex >= _deck.length) _reshuffleDeck();
      _puzzle = _deck[_deckIndex++];
    } else {
      final others = sportsFacePuzzles
          .where((p) => p.id != _puzzle.id)
          .toList()
        ..shuffle(Random());
      _puzzle = others.isEmpty ? _puzzle : others.first;
    }
    _removed = {};
    _shuffledOptions = List<String>.from(_puzzle.options)..shuffle(Random());
    _chancesLeft = _maxChances;
    _won = null;
    _feedback = null;
    _wrongPick = null;
    _resultPop.reset();
    setState(() {});
  }

  void _removeTile(int index) {
    if (_won != null || _removed.contains(index)) return;
    setState(() {
      _removed.add(index);
      _feedback = null;
      _wrongPick = null;
    });
  }

  void _guess(String option) {
    if (_won != null || _chancesLeft <= 0) return;
    if (option == _puzzle.answer) {
      setState(() {
        _won = true;
        _cleared += 1;
        _removed = {for (var i = 0; i < _tileCount; i++) i};
        _feedback = 'Identified';
        _wrongPick = null;
      });
      _resultPop.forward(from: 0);
      _recordRound(won: true);
      return;
    }
    setState(() {
      _chancesLeft -= 1;
      _wrongPick = option;
      if (_chancesLeft <= 0) {
        _won = false;
        _removed = {for (var i = 0; i < _tileCount; i++) i};
        _feedback = 'Out of chances';
        _recordRound(won: false);
        _resultPop.forward(from: 0);
      } else {
        _feedback =
            'Not ${_shortName(option)} · $_chancesLeft left';
      }
    });
  }

  String _shortName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return name;
    return parts.last;
  }

  void _recordRound({required bool won}) {
    final used = _maxChances - _chancesLeft + (won ? 1 : 0);
    PlayHistoryStore.instance.record(
      gameId: GameCatalog.sportsFacePuzzleId,
      resultLabel: won ? 'WIN' : 'LOSS',
      headline: _puzzle.answer,
      summary: won
          ? 'Named in $used/$_maxChances · ${_revealedCount} tiles open'
          : 'Missed — answer was ${_puzzle.answer}',
      won: won,
      detail: '${_puzzle.country} · ${_puzzle.role}',
    );
  }

  Future<void> _afterWinContinue(VoidCallback next) async {
    if (_won == true && mounted) {
      await maybePromptCategoryRating(context, 'puzzles');
    }
    if (!mounted) return;
    next();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _puzzle.accent;
    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
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
                      'FACE REVEAL',
                      style: hudLabelStyle(color: accent, size: 12),
                    ),
                    const Spacer(),
                    _MetaChip(
                      label: 'CLEARED $_cleared',
                      color: GameColors.gold,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _won == true
                      ? _puzzle.answer.toUpperCase()
                      : (_won == false
                          ? 'REVEALED'
                          : 'IDENTIFY THE PLAYER'),
                  style: const TextStyle(
                    color: GameColors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _won == null
                      ? 'Peel tiles for clues, then pick the correct name. Five chances.'
                      : (_won == true
                          ? '${_puzzle.role} · ${_puzzle.country} · ${_puzzle.sport}'
                          : 'It was ${_puzzle.answer} · ${_puzzle.country}'),
                  style: const TextStyle(
                    color: GameColors.mute,
                    height: 1.35,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                _ChanceRow(
                  chancesLeft: _chancesLeft,
                  maxChances: _maxChances,
                  accent: accent,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      AnimatedBuilder(
                        animation: _boardPulse,
                        builder: (context, child) {
                          final glow = 0.12 + (_boardPulse.value * 0.1);
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: accent.withOpacity(0.55),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(glow),
                                  blurRadius: 28,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                        child: AspectRatio(
                          aspectRatio: 0.92,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(21),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final tileW =
                                    constraints.maxWidth / _gridSize;
                                final tileH =
                                    constraints.maxHeight / _gridSize;
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _PlayerPortrait(puzzle: _puzzle),
                                    for (var i = 0; i < _tileCount; i++)
                                      if (!_removed.contains(i))
                                        Positioned(
                                          left: (i % _gridSize) * tileW,
                                          top: (i ~/ _gridSize) * tileH,
                                          width: tileW,
                                          height: tileH,
                                          child: _PuzzleTile(
                                            number: i + 1,
                                            accent: accent,
                                            onTap: () => _removeTile(i),
                                          ),
                                        ),
                                    if (_won != null)
                                      Positioned(
                                        left: 12,
                                        right: 12,
                                        bottom: 12,
                                        child: ScaleTransition(
                                          scale: CurvedAnimation(
                                            parent: _resultPop,
                                            curve: Curves.easeOutBack,
                                          ),
                                          child: _ResultPlate(
                                            won: _won == true,
                                            name: _puzzle.answer,
                                            meta:
                                                '${_puzzle.role}  ·  ${_puzzle.country}',
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'TILES ${_revealedCount}/$_tileCount',
                            style: hudLabelStyle(size: 9),
                          ),
                          const Spacer(),
                          Text(
                            '${sportsFacePuzzles.length} PLAYERS IN ROTATION',
                            style: hudLabelStyle(
                              color: GameColors.cyan,
                              size: 9,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_feedback != null && _won == null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            _feedback!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: GameColors.gold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      if (_won == null)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _shuffledOptions.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 2.55,
                          ),
                          itemBuilder: (context, index) {
                            final option = _shuffledOptions[index];
                            final missed = option == _wrongPick;
                            return _OptionChip(
                              label: option,
                              accent: accent,
                              missed: missed,
                              onTap: missed ? null : () => _guess(option),
                            );
                          },
                        )
                      else ...[
                        NeonButton(
                          label: 'NEXT PLAYER',
                          color: accent,
                          onPressed: () => _afterWinContinue(() {
                            _startRound(fromDeck: true);
                          }),
                        ),
                        const SizedBox(height: 8),
                        NeonButton(
                          label: 'LEAVE',
                          outlined: true,
                          color: GameColors.mute,
                          onPressed: () => _afterWinContinue(
                            () => Navigator.of(context).maybePop(),
                          ),
                        ),
                      ],
                    ],
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

class _ChanceRow extends StatelessWidget {
  const _ChanceRow({
    required this.chancesLeft,
    required this.maxChances,
    required this.accent,
  });

  final int chancesLeft;
  final int maxChances;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('CHANCES', style: hudLabelStyle(size: 9)),
        const SizedBox(width: 10),
        for (var i = 0; i < maxChances; i++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 18,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: i < chancesLeft
                  ? (chancesLeft <= 2 ? GameColors.coral : accent)
                  : const Color(0xFF1A2142),
              border: Border.all(
                color: i < chancesLeft
                    ? (chancesLeft <= 2 ? GameColors.coral : accent)
                    : GameColors.panelBorder,
              ),
            ),
          ),
          if (i < maxChances - 1) const SizedBox(width: 6),
        ],
        const Spacer(),
        Text(
          '$chancesLeft LEFT',
          style: hudLabelStyle(
            color: chancesLeft <= 2 ? GameColors.coral : GameColors.mute,
            size: 9,
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.7)),
        color: color.withOpacity(0.12),
      ),
      child: Text(label, style: hudLabelStyle(color: color, size: 9)),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.accent,
    required this.onTap,
    this.missed = false,
  });

  final String label;
  final Color accent;
  final VoidCallback? onTap;
  final bool missed;

  @override
  Widget build(BuildContext context) {
    final color = missed ? GameColors.coral : accent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: missed
                ? GameColors.coral.withOpacity(0.12)
                : const Color(0xFF10162C),
            border: Border.all(color: color.withOpacity(missed ? 0.8 : 0.45)),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: missed ? GameColors.coral : GameColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  height: 1.2,
                  decoration: missed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultPlate extends StatelessWidget {
  const _ResultPlate({
    required this.won,
    required this.name,
    required this.meta,
  });

  final bool won;
  final String name;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final accent = won ? GameColors.lime : GameColors.coral;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xF00A1024),
        border: Border.all(color: accent),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.28), blurRadius: 18),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            won ? 'CORRECT' : 'ANSWER',
            style: hudLabelStyle(color: accent, size: 10),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GameColors.text,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            meta,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GameColors.mute,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PuzzleTile extends StatelessWidget {
  const _PuzzleTile({
    required this.number,
    required this.accent,
    required this.onTap,
  });

  final int number;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF2141A33),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: GameColors.panelBorder.withOpacity(0.85),
              width: 0.8,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xF2182040),
                Color.lerp(const Color(0xF2121830), accent, 0.18)!,
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$number',
                style: TextStyle(
                  color: GameColors.text.withOpacity(0.92),
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'REVEAL',
                style: hudLabelStyle(
                  color: accent.withOpacity(0.85),
                  size: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerPortrait extends StatelessWidget {
  const _PlayerPortrait({required this.puzzle});

  final SportsFacePuzzle puzzle;

  @override
  Widget build(BuildContext context) {
    if (puzzle.hasNetworkImage) {
      return Image.network(
        puzzle.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _CardPortrait(puzzle: puzzle),
      );
    }
    if (puzzle.hasLocalImage) {
      return Image.asset(
        puzzle.imageAsset,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _CardPortrait(puzzle: puzzle),
      );
    }
    return _CardPortrait(puzzle: puzzle);
  }
}

class _CardPortrait extends StatelessWidget {
  const _CardPortrait({required this.puzzle});

  final SportsFacePuzzle puzzle;

  int get _jerseyNo => 7 + (puzzle.id.hashCode.abs() % 90);

  @override
  Widget build(BuildContext context) {
    final accent = puzzle.accent;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(accent, const Color(0xFF071018), 0.35)!,
            const Color(0xFF071018),
            Color.lerp(accent, const Color(0xFF050713), 0.55)!,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.18),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _Tag(text: puzzle.sport.toUpperCase(), color: accent),
                    const Spacer(),
                    _Tag(
                      text: puzzle.country.toUpperCase(),
                      color: GameColors.gold,
                    ),
                  ],
                ),
                const Spacer(),
                Center(
                  child: Container(
                    width: 148,
                    height: 148,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withOpacity(0.55),
                          accent.withOpacity(0.12),
                        ],
                      ),
                      border: Border.all(color: accent, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.35),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_cricket_rounded,
                          color: GameColors.text.withOpacity(0.9),
                          size: 34,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$_jerseyNo',
                          style: const TextStyle(
                            color: GameColors.text,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  puzzle.role.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: hudLabelStyle(color: accent, size: 11),
                ),
                const SizedBox(height: 8),
                Text(
                  'CLASSIFIED PLAYER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GameColors.text.withOpacity(0.28),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.7)),
        color: color.withOpacity(0.14),
      ),
      child: Text(text, style: hudLabelStyle(color: color, size: 9)),
    );
  }
}
