import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_game/cricket/draft_engine.dart';
import 'package:guess_game/cricket/match_engine.dart';
import 'package:guess_game/cricket/models.dart';
import 'package:guess_game/cricket/roster.dart';

void main() {
  test('draft fills exactly 11 role slots without duplicate openers beyond capacity', () {
    final draft = DraftEngine(random: Random(7));
    while (!draft.isComplete) {
      final offer = draft.spin();
      expect(offer.eligiblePlayers, isNotEmpty);
      final player = offer.eligiblePlayers.first;
      final slot = draft.slotsForPlayer(player).first;
      draft.pick(team: offer.team, player: player, slot: slot);
    }

    final openers = draft.picks.where((pick) => pick.slot.role == PlayerRole.opener);
    expect(openers.length, 2);
    expect(draft.picks.map((pick) => pick.player.id).toSet().length, 11);
  });

  test('wicket-keeper can be placed in any position from 1 to 7', () {
    final keeper = cricketTeams
        .expand((team) => team.players)
        .firstWhere((player) => player.roles.contains(PlayerRole.wicketKeeper));

    for (final slot in t20Slots.where((slot) => slot.index <= 6)) {
      expect(keeper.fitsSlot(slot), isTrue, reason: slot.label);
    }
    for (final slot in t20Slots.where((slot) => slot.index > 6)) {
      expect(
        keeper.fitsSlot(slot),
        keeper.canPlay(slot.role),
        reason: slot.label,
      );
    }
  });

  test('match engine returns dual innings scorecards and fantasy points', () {
    final user = DraftEngine(random: Random(11)).buildCpuSquad();
    final cpu = DraftEngine(random: Random(22)).buildCpuSquad(
      excludePlayerIds: user.players.map((player) => player.id).toSet(),
    );
    final result = MatchEngine(random: Random(33)).play(
      format: CricketFormat.t20,
      userSquad: user,
      cpuSquad: cpu,
      userWantsToBat: true,
    );

    expect(result.firstInnings.balls, greaterThan(0));
    expect(result.secondInnings.balls, greaterThan(0));
    expect(result.firstInningsOvers, isNotEmpty);
    expect(result.secondInningsOvers, isNotEmpty);
    expect(result.tossSummary, contains('toss'));
    expect(result.userPoints + result.cpuPoints, greaterThan(0));
    expect(result.matchSummary, isNotEmpty);
  });
}
