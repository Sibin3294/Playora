import 'package:flutter/material.dart';
import 'package:guess_game/theme/game_theme.dart';

enum GameAvailability { playable, comingSoon }

class CatalogGame {
  const CatalogGame({
    required this.id,
    required this.title,
    required this.tagline,
    required this.availability,
  });

  final String id;
  final String title;
  final String tagline;
  final GameAvailability availability;

  bool get isPlayable => availability == GameAvailability.playable;
}

class GameCategory {
  const GameCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.games,
  });

  final String id;
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final List<CatalogGame> games;

  int get playableCount =>
      games.where((game) => game.isPlayable).length;
}

class GameCatalog {
  static const numberHunterId = 'number_hunter';
  static const cricketId = 'cricket';
  static const sportsFacePuzzleId = 'sports_face_puzzle';
  static const cricketTrumpId = 'cricket_trump';

  static List<GameCategory>? _apiCategories;

  static const seedCategories = <GameCategory>[
    GameCategory(
      id: 'number',
      title: 'NUMBER GAMES',
      subtitle: 'Logic, range, and sharp guesses.',
      accent: GameColors.cyan,
      icon: Icons.tag_rounded,
      games: [
        CatalogGame(
          id: numberHunterId,
          title: 'NUMBER HUNTER',
          tagline: 'Track the secret number before shots run out.',
          availability: GameAvailability.playable,
        ),
      ],
    ),
    GameCategory(
      id: 'sports',
      title: 'SPORTS',
      subtitle: 'Match-day calls and live plays.',
      accent: GameColors.lime,
      icon: Icons.sports_cricket_rounded,
      games: [
        CatalogGame(
          id: cricketId,
          title: 'CRICKET',
          tagline: 'Draft an XI from world teams and autoplay T20.',
          availability: GameAvailability.playable,
        ),
      ],
    ),
    GameCategory(
      id: 'puzzles',
      title: 'PUZZLES',
      subtitle: 'Reveal, guess, and sharp eyes.',
      accent: GameColors.violet,
      icon: Icons.extension_rounded,
      games: [
        CatalogGame(
          id: sportsFacePuzzleId,
          title: 'FACE REVEAL',
          tagline: 'Peel numbered tiles and name the sports star in 5 chances.',
          availability: GameAvailability.playable,
        ),
      ],
    ),
    GameCategory(
      id: 'cards',
      title: 'CARD GAMES',
      subtitle: 'Stats, calls, and deck battles.',
      accent: GameColors.magenta,
      icon: Icons.style_rounded,
      games: [
        CatalogGame(
          id: cricketTrumpId,
          title: 'STAT BATTLE',
          tagline: 'Cricket Top Trumps — pick a stat and empty the CPU deck.',
          availability: GameAvailability.playable,
        ),
      ],
    ),
  ];

  static List<GameCategory> get categories =>
      _apiCategories ?? seedCategories;

  static void applyCategories(List<GameCategory> categories) {
    _apiCategories = List<GameCategory>.unmodifiable(categories);
  }

  static GameCategory? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  static CatalogGame? gameById(String id) {
    for (final category in categories) {
      for (final game in category.games) {
        if (game.id == id) return game;
      }
    }
    return null;
  }

  static List<CatalogGame> get playableGames {
    return [
      for (final category in categories)
        for (final game in category.games)
          if (game.isPlayable) game,
    ];
  }
}
