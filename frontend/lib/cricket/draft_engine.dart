import 'dart:math';

import 'package:guess_game/cricket/models.dart';
import 'package:guess_game/cricket/roster.dart';

class DraftOffer {
  const DraftOffer({
    required this.team,
    required this.eligiblePlayers,
    required this.openSlots,
  });

  final CricketTeam team;
  final List<CricketPlayer> eligiblePlayers;
  final List<SquadSlot> openSlots;
}

class DraftEngine {
  DraftEngine({
    List<SquadSlot>? slots,
    List<CricketTeam>? teamPool,
    this.maxOverseas,
    Random? random,
  })  : slots = slots ?? t20Slots,
        teamPool = teamPool ?? cricketTeams,
        _random = random ?? Random();

  final List<SquadSlot> slots;
  final List<CricketTeam> teamPool;

  /// When set (e.g. 4 for IPL), the XI may include at most this many overseas players.
  final int? maxOverseas;
  final Random _random;
  final List<DraftPick> picks = [];
  final List<String> usedTeamIds = [];
  final Set<String> draftedPlayerIds = {};

  bool get isComplete => picks.length >= slots.length;

  int get spinNumber => picks.length + 1;

  int get overseasCount =>
      picks.where((pick) => pick.player.isOverseas).length;

  bool get overseasCapReached =>
      maxOverseas != null && overseasCount >= maxOverseas!;

  List<SquadSlot> get openSlots {
    final filled = picks.map((pick) => pick.slot.index).toSet();
    return slots.where((slot) => !filled.contains(slot.index)).toList();
  }

  bool isBlockedByOverseas(CricketPlayer player) =>
      overseasCapReached && player.isOverseas;

  /// Role-fit players for [team] (includes overseas even when the cap is full).
  List<CricketPlayer> roleEligibleFromTeam(CricketTeam team) {
    final open = openSlots;
    if (open.isEmpty) return const [];
    return team.players.where((player) {
      if (draftedPlayerIds.contains(player.id)) return false;
      return open.any((slot) => player.fitsSlot(slot));
    }).toList();
  }

  /// Players from [team] who can still be picked into an open slot.
  List<CricketPlayer> eligibleFromTeam(CricketTeam team) {
    return roleEligibleFromTeam(team)
        .where((player) => !isBlockedByOverseas(player))
        .toList();
  }

  List<SquadSlot> slotsForPlayer(CricketPlayer player) {
    return openSlots.where((slot) => player.fitsSlot(slot)).toList();
  }

  DraftOffer spin() {
    if (isComplete) {
      throw StateError('Draft is already complete.');
    }

    final remainingTeams = teamPool
        .where((team) => !usedTeamIds.contains(team.id))
        .where((team) => eligibleFromTeam(team).isNotEmpty)
        .toList();

    final pool = remainingTeams.isNotEmpty
        ? remainingTeams
        : teamPool.where((team) => eligibleFromTeam(team).isNotEmpty).toList();

    if (pool.isEmpty) {
      throw StateError('No teams left with eligible players.');
    }

    final team = pool[_random.nextInt(pool.length)];
    return DraftOffer(
      team: team,
      // Show role-fit players including overseas blocked by the cap.
      eligiblePlayers: roleEligibleFromTeam(team),
      openSlots: openSlots,
    );
  }

  void pick({
    required CricketTeam team,
    required CricketPlayer player,
    required SquadSlot slot,
  }) {
    if (isComplete) {
      throw StateError('Draft is already complete.');
    }
    if (!openSlots.any((open) => open.index == slot.index)) {
      throw StateError('That squad slot is already filled.');
    }
    if (!player.fitsSlot(slot)) {
      throw StateError('${player.name} cannot play as ${slot.label}.');
    }
    if (draftedPlayerIds.contains(player.id)) {
      throw StateError('${player.name} is already in your XI.');
    }
    if (overseasCapReached && player.isOverseas) {
      throw StateError(
        'Overseas cap reached ($maxOverseas). Pick a domestic player.',
      );
    }
    if (!eligibleFromTeam(team).any((item) => item.id == player.id)) {
      throw StateError('${player.name} is not available from ${team.shortName}.');
    }

    picks.add(DraftPick(slot: slot, player: player, fromTeamId: team.id));
    draftedPlayerIds.add(player.id);
    usedTeamIds.add(team.id);
    picks.sort((a, b) => a.slot.index.compareTo(b.slot.index));
  }

  Squad toSquad() {
    if (!isComplete) {
      throw StateError('Finish all 11 picks first.');
    }
    return Squad(picks: List<DraftPick>.from(picks));
  }

  /// Builds a full opposing XI using the same draft rules.
  Squad buildCpuSquad({Set<String> excludePlayerIds = const {}}) {
    final cpu = DraftEngine(
      slots: slots,
      teamPool: teamPool,
      maxOverseas: maxOverseas,
      random: _random,
    );
    cpu.draftedPlayerIds.addAll(excludePlayerIds);

    while (!cpu.isComplete) {
      final offer = cpu.spin();
      final candidates = offer.eligiblePlayers
          .where((player) => !cpu.isBlockedByOverseas(player))
          .toList()
        ..sort((a, b) => b.overall.compareTo(a.overall));

      DraftPick? chosen;
      for (final player in candidates) {
        final fits = cpu.slotsForPlayer(player);
        if (fits.isEmpty) continue;
        fits.sort((a, b) {
          final aScore = player.roles.contains(a.role) ? 1 : 0;
          final bScore = player.roles.contains(b.role) ? 1 : 0;
          return bScore.compareTo(aScore);
        });
        chosen = DraftPick(
          slot: fits.first,
          player: player,
          fromTeamId: offer.team.id,
        );
        break;
      }

      if (chosen == null) {
        throw StateError('CPU could not complete the draft.');
      }
      cpu.pick(
        team: offer.team,
        player: chosen.player,
        slot: chosen.slot,
      );
    }
    return cpu.toSquad();
  }

  /// Best available XI from a single franchise roster.
  static Squad buildFranchiseXi(
    CricketTeam franchise, {
    Set<String> excludePlayerIds = const {},
    List<SquadSlot>? slots,
    int? maxOverseas,
  }) {
    final roleSlots = slots ?? t20Slots;
    final used = <String>{...excludePlayerIds};
    final picks = <DraftPick>[];
    var overseasPicked = 0;

    bool underOverseasCap(CricketPlayer player) {
      if (maxOverseas == null) return true;
      if (!player.isOverseas) return true;
      return overseasPicked < maxOverseas;
    }

    for (final slot in roleSlots) {
      final candidates = franchise.players
          .where(
            (player) =>
                !used.contains(player.id) &&
                player.fitsSlot(slot) &&
                underOverseasCap(player),
          )
          .toList()
        ..sort((a, b) => b.overall.compareTo(a.overall));

      CricketPlayer? chosen =
          candidates.isNotEmpty ? candidates.first : null;
      if (chosen == null) {
        final fallback = franchise.players
            .where(
              (player) =>
                  !used.contains(player.id) && underOverseasCap(player),
            )
            .toList()
          ..sort((a, b) => b.overall.compareTo(a.overall));
        if (fallback.isEmpty) {
          throw StateError('${franchise.shortName} cannot fill ${slot.label}.');
        }
        chosen = fallback.first;
      }

      picks.add(
        DraftPick(slot: slot, player: chosen, fromTeamId: franchise.id),
      );
      used.add(chosen.id);
      if (chosen.isOverseas) overseasPicked++;
    }

    return Squad(picks: picks);
  }
}
