import 'package:flutter/material.dart';
import 'package:guess_game/cards/trump_models.dart';
import 'package:guess_game/cards/trump_progression.dart';
import 'package:guess_game/catalog/game_catalog.dart';
import 'package:guess_game/cricket/ipl_roster.dart';
import 'package:guess_game/cricket/models.dart';
import 'package:guess_game/cricket/roster.dart';
import 'package:guess_game/cricket/venues.dart';
import 'package:guess_game/game/hunt_level.dart';
import 'package:guess_game/puzzle/sports_face_puzzles.dart';
import 'package:guess_game/theme/game_theme.dart';

/// Applies `/api/catalog` payloads onto local seed modules.
class CatalogCache {
  CatalogCache._();

  static final CatalogCache instance = CatalogCache._();

  bool loadedFromApi = false;

  void applyApiCatalog(Map<String, dynamic> catalog) {
    final levelsJson = catalog['huntLevels'] as List<dynamic>?;
    if (levelsJson != null && levelsJson.isNotEmpty) {
      HuntLevel.applyLevels([
        for (final item in levelsJson)
          _huntLevel(item as Map<String, dynamic>),
      ]);
    }

    final nationalJson = catalog['nationalTeams'] as List<dynamic>?;
    if (nationalJson != null && nationalJson.isNotEmpty) {
      applyNationalTeams([
        for (final item in nationalJson) _team(item as Map<String, dynamic>),
      ]);
    }

    final ipl = catalog['ipl'] as Map<String, dynamic>?;
    if (ipl != null) {
      final teamsJson = ipl['teams'] as List<dynamic>?;
      List<CricketTeam>? iplTeamList;
      if (teamsJson != null && teamsJson.isNotEmpty) {
        iplTeamList = [
          for (final item in teamsJson) _team(item as Map<String, dynamic>),
        ];
        applyIplTeams(iplTeamList);
      }
      final competition = ipl['competition'] as Map<String, dynamic>?;
      if (competition != null) {
        applyIplCompetition(
          LeagueCompetition(
            id: competition['id'] as String? ?? iplCompetitionId,
            name: competition['name'] as String? ?? 'Indian Premier League',
            tagline: competition['tagline'] as String? ?? '',
            teams: iplTeamList ?? iplTeams,
            maxOverseasPlayers: competition['maxOverseasPlayers'] as int?,
          ),
        );
      }
    }

    final venuesJson = catalog['venues'] as List<dynamic>?;
    if (venuesJson != null && venuesJson.isNotEmpty) {
      applyVenues([
        for (final item in venuesJson) _venue(item as Map<String, dynamic>),
      ]);
    }

    final puzzlesJson = catalog['sportsFacePuzzles'] as List<dynamic>?;
    if (puzzlesJson != null && puzzlesJson.isNotEmpty) {
      applySportsFacePuzzles([
        for (final item in puzzlesJson)
          _puzzle(item as Map<String, dynamic>),
      ]);
    }

    final hubJson = catalog['hubCategories'] as List<dynamic>?;
    if (hubJson != null && hubJson.isNotEmpty) {
      GameCatalog.applyCategories([
        for (final item in hubJson) _category(item as Map<String, dynamic>),
      ]);
    }

    final trump = catalog['trumpConfig'] as Map<String, dynamic>?;
    if (trump != null) {
      final starterNames = trump['starterStats'] as List<dynamic>?;
      final starters = starterNames == null
          ? null
          : [
              for (final name in starterNames)
                if (TrumpStat.tryParse(name as String) != null)
                  TrumpStat.tryParse(name as String)!,
            ];
      final deckSizes = (trump['deckSizes'] as List<dynamic>?)
          ?.map((value) => value as int)
          .toList();
      TrumpLevels.applyConfig(
        maxLevel: trump['maxLevel'] as int?,
        maxStats: trump['maxStats'] as int?,
        maxCards: trump['maxCards'] as int?,
        picksPerAdvance: trump['picksPerAdvance'] as int?,
        deckSizes: deckSizes,
        starterStats: starters,
      );
    }

    loadedFromApi = true;
  }

  HuntLevel _huntLevel(Map<String, dynamic> json) {
    return HuntLevel(
      id: json['id'] as int,
      name: json['name'] as String,
      blurb: json['blurb'] as String? ?? '',
      minValue: json['minValue'] as int,
      maxValue: json['maxValue'] as int,
      maxAttempts: json['maxAttempts'] as int,
      pointsToUnlock: json['pointsToUnlock'] as int? ?? 0,
      multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1,
      accent: Color(json['accent'] as int? ?? GameColors.cyan.value),
    );
  }

  CricketTeam _team(Map<String, dynamic> json) {
    final players = (json['players'] as List<dynamic>? ?? [])
        .map((item) => _player(item as Map<String, dynamic>))
        .toList();
    return CricketTeam(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['shortName'] as String,
      players: players,
    );
  }

  CricketPlayer _player(Map<String, dynamic> json) {
    final roles = (json['roles'] as List<dynamic>? ?? [])
        .map((name) => PlayerRole.values.firstWhere(
              (role) => role.name == name,
              orElse: () => PlayerRole.batter,
            ))
        .toList();
    return CricketPlayer(
      id: json['id'] as String,
      name: json['name'] as String,
      teamId: json['teamId'] as String,
      roles: roles,
      batRating: json['batRating'] as int? ?? 70,
      bowlRating: json['bowlRating'] as int? ?? 70,
      fieldRating: json['fieldRating'] as int? ?? 70,
      isOverseas: json['isOverseas'] as bool? ?? false,
    );
  }

  CricketVenue _venue(Map<String, dynamic> json) {
    return CricketVenue(
      name: json['name'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      capacity: json['capacity'] as int? ?? 0,
      pitchReport: json['pitchReport'] as String? ?? '',
      outfieldNote: json['outfieldNote'] as String? ?? '',
      weather: json['weather'] as String? ?? '',
    );
  }

  SportsFacePuzzle _puzzle(Map<String, dynamic> json) {
    return sportsFacePuzzleFromJson(json);
  }

  GameCategory _category(Map<String, dynamic> json) {
    final games = (json['games'] as List<dynamic>? ?? []).map((item) {
      final game = item as Map<String, dynamic>;
      final availability = game['availability'] == 'playable'
          ? GameAvailability.playable
          : GameAvailability.comingSoon;
      return CatalogGame(
        id: game['id'] as String,
        title: game['title'] as String,
        tagline: game['tagline'] as String? ?? '',
        availability: availability,
      );
    }).toList();
    return GameCategory(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      accent: Color(json['accent'] as int? ?? GameColors.cyan.value),
      icon: _iconFor(json['icon'] as String?),
      games: games,
    );
  }

  IconData _iconFor(String? name) {
    switch (name) {
      case 'cricket':
        return Icons.sports_cricket_rounded;
      case 'puzzle':
        return Icons.extension_rounded;
      case 'cards':
        return Icons.style_rounded;
      case 'tag':
      default:
        return Icons.tag_rounded;
    }
  }
}
