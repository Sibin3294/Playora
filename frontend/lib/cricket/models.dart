enum CricketFormat {
  t20(id: 't20', label: 'T20', overs: 20, locked: false),
  odi(id: 'odi', label: 'ODI', overs: 50, locked: true),
  test(id: 'test', label: 'TEST', overs: 90, locked: true);

  const CricketFormat({
    required this.id,
    required this.label,
    required this.overs,
    required this.locked,
  });

  final String id;
  final String label;
  final int overs;
  final bool locked;
}

enum PlayerRole {
  opener('OPENER'),
  batter('BATTER'),
  middleOrder('MIDDLE'),
  wicketKeeper('KEEPER'),
  allRounder('ALL-ROUNDER'),
  bowler('BOWLER');

  const PlayerRole(this.label);
  final String label;
}

class CricketPlayer {
  const CricketPlayer({
    required this.id,
    required this.name,
    required this.teamId,
    required this.roles,
    required this.batRating,
    required this.bowlRating,
    required this.fieldRating,
    this.isOverseas = false,
  });

  final String id;
  final String name;
  final String teamId;
  final List<PlayerRole> roles;
  final int batRating;
  final int bowlRating;
  final int fieldRating;

  /// IPL overseas / foreign player flag. Unused for national exhibition sides.
  final bool isOverseas;

  int get overall =>
      ((batRating * 0.45) + (bowlRating * 0.35) + (fieldRating * 0.2)).round();

  bool canPlay(PlayerRole role) => roles.contains(role);

  /// Slot fit rules for draft: natural role match, plus wicket-keepers may
  /// occupy any of positions 1–7. Position 7 can also take a batting player
  /// when the keeper is placed higher in the order.
  bool fitsSlot(SquadSlot slot) {
    if (canPlay(slot.role)) return true;
    if (roles.contains(PlayerRole.wicketKeeper) && slot.index <= 6) {
      return true;
    }
    if (slot.index == 6) {
      return roles.contains(PlayerRole.opener) ||
          roles.contains(PlayerRole.batter) ||
          roles.contains(PlayerRole.middleOrder) ||
          roles.contains(PlayerRole.allRounder);
    }
    return false;
  }

  bool get isBowlerType =>
      roles.contains(PlayerRole.bowler) ||
      roles.contains(PlayerRole.allRounder);
}

class CricketTeam {
  const CricketTeam({
    required this.id,
    required this.name,
    required this.shortName,
    required this.players,
  });

  final String id;
  final String name;
  final String shortName;
  final List<CricketPlayer> players;
}

class SquadSlot {
  const SquadSlot({
    required this.index,
    required this.role,
    required this.label,
  });

  final int index;
  final PlayerRole role;
  final String label;
}

class DraftPick {
  const DraftPick({
    required this.slot,
    required this.player,
    required this.fromTeamId,
  });

  final SquadSlot slot;
  final CricketPlayer player;
  final String fromTeamId;
}

class Squad {
  Squad({required this.picks});

  final List<DraftPick> picks;

  List<CricketPlayer> get players =>
      picks.map((pick) => pick.player).toList(growable: false);

  CricketPlayer playerInSlot(int index) =>
      picks.firstWhere((pick) => pick.slot.index == index).player;
}

/// Fixed XI template for T20 draft competitions.
const t20Slots = <SquadSlot>[
  SquadSlot(index: 0, role: PlayerRole.opener, label: 'OPENER 1'),
  SquadSlot(index: 1, role: PlayerRole.opener, label: 'OPENER 2'),
  SquadSlot(index: 2, role: PlayerRole.batter, label: 'BATTER 3'),
  SquadSlot(index: 3, role: PlayerRole.batter, label: 'BATTER 4'),
  SquadSlot(index: 4, role: PlayerRole.middleOrder, label: 'MIDDLE 5'),
  SquadSlot(index: 5, role: PlayerRole.allRounder, label: 'ALL-ROUND 6'),
  SquadSlot(index: 6, role: PlayerRole.wicketKeeper, label: 'KEEPER 7'),
  SquadSlot(index: 7, role: PlayerRole.allRounder, label: 'ALL-ROUND 8'),
  SquadSlot(index: 8, role: PlayerRole.bowler, label: 'BOWLER 9'),
  SquadSlot(index: 9, role: PlayerRole.bowler, label: 'BOWLER 10'),
  SquadSlot(index: 10, role: PlayerRole.bowler, label: 'BOWLER 11'),
];
