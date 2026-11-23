import 'package:guess_game/cricket/models.dart';

CricketPlayer _p(
  String id,
  String name,
  String teamId,
  List<PlayerRole> roles, {
  required int bat,
  required int bowl,
  required int field,
}) {
  return CricketPlayer(
    id: id,
    name: name,
    teamId: teamId,
    roles: roles,
    batRating: bat,
    bowlRating: bowl,
    fieldRating: field,
  );
}

List<CricketTeam>? _apiCricketTeams;

/// Built-in national packs (offline / FORCE_LOCAL fallback).
final seedCricketTeams = <CricketTeam>[
  CricketTeam(
    id: 'ind',
    name: 'India',
    shortName: 'IND',
    players: [
      _p('ind_1', 'Rohit Sharma', 'ind', [PlayerRole.opener, PlayerRole.batter], bat: 92, bowl: 18, field: 78),
      _p('ind_2', 'Virat Kohli', 'ind', [PlayerRole.batter, PlayerRole.middleOrder], bat: 95, bowl: 12, field: 88),
      _p('ind_3', 'Shubman Gill', 'ind', [PlayerRole.opener, PlayerRole.batter], bat: 88, bowl: 10, field: 82),
      _p('ind_4', 'Suryakumar Yadav', 'ind', [PlayerRole.middleOrder, PlayerRole.batter], bat: 91, bowl: 8, field: 80),
      _p('ind_5', 'Hardik Pandya', 'ind', [PlayerRole.allRounder, PlayerRole.middleOrder], bat: 84, bowl: 78, field: 85),
      _p('ind_6', 'Ravindra Jadeja', 'ind', [PlayerRole.allRounder, PlayerRole.bowler], bat: 76, bowl: 86, field: 94),
      _p('ind_7', 'Rishabh Pant', 'ind', [PlayerRole.wicketKeeper, PlayerRole.middleOrder], bat: 86, bowl: 5, field: 80),
      _p('ind_8', 'Axar Patel', 'ind', [PlayerRole.allRounder, PlayerRole.bowler], bat: 72, bowl: 82, field: 84),
      _p('ind_9', 'Jasprit Bumrah', 'ind', [PlayerRole.bowler], bat: 22, bowl: 97, field: 70),
      _p('ind_10', 'Mohammed Siraj', 'ind', [PlayerRole.bowler], bat: 18, bowl: 88, field: 72),
      _p('ind_11', 'Kuldeep Yadav', 'ind', [PlayerRole.bowler], bat: 28, bowl: 87, field: 68),
      _p('ind_12', 'Yashasvi Jaiswal', 'ind', [PlayerRole.opener, PlayerRole.batter], bat: 87, bowl: 14, field: 79),
      _p('ind_13', 'Shivam Dube', 'ind', [PlayerRole.middleOrder, PlayerRole.allRounder], bat: 80, bowl: 62, field: 74),
      _p('ind_14', 'Arshdeep Singh', 'ind', [PlayerRole.bowler], bat: 16, bowl: 85, field: 71),
    ],
  ),
  CricketTeam(
    id: 'aus',
    name: 'Australia',
    shortName: 'AUS',
    players: [
      _p('aus_1', 'David Warner', 'aus', [PlayerRole.opener], bat: 89, bowl: 12, field: 80),
      _p('aus_2', 'Travis Head', 'aus', [PlayerRole.opener, PlayerRole.batter], bat: 90, bowl: 35, field: 83),
      _p('aus_3', 'Steve Smith', 'aus', [PlayerRole.batter, PlayerRole.middleOrder], bat: 93, bowl: 28, field: 86),
      _p('aus_4', 'Mitchell Marsh', 'aus', [PlayerRole.allRounder, PlayerRole.middleOrder], bat: 85, bowl: 74, field: 82),
      _p('aus_5', 'Glenn Maxwell', 'aus', [PlayerRole.allRounder, PlayerRole.middleOrder], bat: 88, bowl: 70, field: 90),
      _p('aus_6', 'Marcus Stoinis', 'aus', [PlayerRole.allRounder, PlayerRole.middleOrder], bat: 81, bowl: 72, field: 78),
      _p('aus_7', 'Josh Inglis', 'aus', [PlayerRole.wicketKeeper, PlayerRole.batter], bat: 82, bowl: 5, field: 84),
      _p('aus_8', 'Pat Cummins', 'aus', [PlayerRole.bowler, PlayerRole.allRounder], bat: 48, bowl: 93, field: 80),
      _p('aus_9', 'Mitchell Starc', 'aus', [PlayerRole.bowler], bat: 35, bowl: 94, field: 72),
      _p('aus_10', 'Adam Zampa', 'aus', [PlayerRole.bowler], bat: 24, bowl: 90, field: 70),
      _p('aus_11', 'Josh Hazlewood', 'aus', [PlayerRole.bowler], bat: 20, bowl: 92, field: 74),
      _p('aus_12', 'Cameron Green', 'aus', [PlayerRole.allRounder, PlayerRole.batter], bat: 79, bowl: 76, field: 88),
      _p('aus_13', 'Tim David', 'aus', [PlayerRole.middleOrder], bat: 83, bowl: 18, field: 76),
      _p('aus_14', 'Spencer Johnson', 'aus', [PlayerRole.bowler], bat: 14, bowl: 84, field: 69),
    ],
  ),
  CricketTeam(
    id: 'eng',
    name: 'England',
    shortName: 'ENG',
    players: [
      _p('eng_1', 'Jos Buttler', 'eng', [PlayerRole.opener, PlayerRole.wicketKeeper], bat: 91, bowl: 5, field: 86),
      _p('eng_2', 'Phil Salt', 'eng', [PlayerRole.opener, PlayerRole.wicketKeeper], bat: 86, bowl: 5, field: 82),
      _p('eng_3', 'Harry Brook', 'eng', [PlayerRole.batter, PlayerRole.middleOrder], bat: 90, bowl: 12, field: 84),
      _p('eng_4', 'Ben Stokes', 'eng', [PlayerRole.allRounder, PlayerRole.middleOrder], bat: 87, bowl: 80, field: 88),
      _p('eng_5', 'Liam Livingstone', 'eng', [PlayerRole.middleOrder, PlayerRole.allRounder], bat: 84, bowl: 68, field: 80),
      _p('eng_6', 'Moeen Ali', 'eng', [PlayerRole.allRounder, PlayerRole.bowler], bat: 74, bowl: 78, field: 81),
      _p('eng_7', 'Sam Curran', 'eng', [PlayerRole.allRounder, PlayerRole.bowler], bat: 72, bowl: 82, field: 79),
      _p('eng_8', 'Jofra Archer', 'eng', [PlayerRole.bowler], bat: 30, bowl: 93, field: 76),
      _p('eng_9', 'Mark Wood', 'eng', [PlayerRole.bowler], bat: 22, bowl: 91, field: 70),
      _p('eng_10', 'Adil Rashid', 'eng', [PlayerRole.bowler], bat: 28, bowl: 89, field: 72),
      _p('eng_11', 'Reece Topley', 'eng', [PlayerRole.bowler], bat: 16, bowl: 85, field: 68),
      _p('eng_12', 'Will Jacks', 'eng', [PlayerRole.opener, PlayerRole.allRounder], bat: 80, bowl: 66, field: 78),
      _p('eng_13', 'Jonny Bairstow', 'eng', [PlayerRole.opener, PlayerRole.wicketKeeper, PlayerRole.batter], bat: 85, bowl: 5, field: 80),
      _p('eng_14', 'Chris Jordan', 'eng', [PlayerRole.bowler, PlayerRole.allRounder], bat: 40, bowl: 84, field: 90),
    ],
  ),
  CricketTeam(
    id: 'nz',
    name: 'New Zealand',
    shortName: 'NZ',
    players: [
      _p('nz_1', 'Devon Conway', 'nz', [PlayerRole.opener, PlayerRole.wicketKeeper], bat: 88, bowl: 5, field: 82),
      _p('nz_2', 'Kane Williamson', 'nz', [PlayerRole.batter, PlayerRole.middleOrder], bat: 92, bowl: 30, field: 85),
      _p('nz_3', 'Finn Allen', 'nz', [PlayerRole.opener], bat: 84, bowl: 8, field: 76),
      _p('nz_4', 'Daryl Mitchell', 'nz', [PlayerRole.middleOrder, PlayerRole.allRounder], bat: 86, bowl: 62, field: 84),
      _p('nz_5', 'Glenn Phillips', 'nz', [PlayerRole.middleOrder, PlayerRole.wicketKeeper], bat: 83, bowl: 40, field: 92),
      _p('nz_6', 'Mitchell Santner', 'nz', [PlayerRole.allRounder, PlayerRole.bowler], bat: 68, bowl: 86, field: 85),
      _p('nz_7', 'Rachin Ravindra', 'nz', [PlayerRole.allRounder, PlayerRole.batter], bat: 84, bowl: 74, field: 82),
      _p('nz_8', 'Tim Southee', 'nz', [PlayerRole.bowler], bat: 32, bowl: 88, field: 78),
      _p('nz_9', 'Trent Boult', 'nz', [PlayerRole.bowler], bat: 28, bowl: 93, field: 80),
      _p('nz_10', 'Lockie Ferguson', 'nz', [PlayerRole.bowler], bat: 18, bowl: 90, field: 74),
      _p('nz_11', 'Ish Sodhi', 'nz', [PlayerRole.bowler], bat: 22, bowl: 84, field: 70),
      _p('nz_12', 'Tom Latham', 'nz', [PlayerRole.opener, PlayerRole.wicketKeeper], bat: 82, bowl: 5, field: 86),
      _p('nz_13', 'James Neesham', 'nz', [PlayerRole.allRounder, PlayerRole.middleOrder], bat: 74, bowl: 76, field: 80),
      _p('nz_14', 'Matt Henry', 'nz', [PlayerRole.bowler], bat: 24, bowl: 87, field: 76),
    ],
  ),
  CricketTeam(
    id: 'sa',
    name: 'South Africa',
    shortName: 'SA',
    players: [
      _p('sa_1', 'Quinton de Kock', 'sa', [PlayerRole.opener, PlayerRole.wicketKeeper], bat: 90, bowl: 5, field: 84),
      _p('sa_2', 'Reeza Hendricks', 'sa', [PlayerRole.opener, PlayerRole.batter], bat: 84, bowl: 10, field: 78),
      _p('sa_3', 'Aiden Markram', 'sa', [PlayerRole.batter, PlayerRole.allRounder], bat: 86, bowl: 70, field: 85),
      _p('sa_4', 'Heinrich Klaasen', 'sa', [PlayerRole.middleOrder, PlayerRole.wicketKeeper], bat: 89, bowl: 5, field: 82),
      _p('sa_5', 'David Miller', 'sa', [PlayerRole.middleOrder], bat: 87, bowl: 8, field: 80),
      _p('sa_6', 'Marco Jansen', 'sa', [PlayerRole.allRounder, PlayerRole.bowler], bat: 70, bowl: 86, field: 84),
      _p('sa_7', 'Keshav Maharaj', 'sa', [PlayerRole.bowler, PlayerRole.allRounder], bat: 48, bowl: 85, field: 78),
      _p('sa_8', 'Kagiso Rabada', 'sa', [PlayerRole.bowler], bat: 28, bowl: 95, field: 76),
      _p('sa_9', 'Anrich Nortje', 'sa', [PlayerRole.bowler], bat: 18, bowl: 92, field: 72),
      _p('sa_10', 'Tabraiz Shamsi', 'sa', [PlayerRole.bowler], bat: 16, bowl: 88, field: 68),
      _p('sa_11', 'Lungi Ngidi', 'sa', [PlayerRole.bowler], bat: 20, bowl: 86, field: 70),
      _p('sa_12', 'Tristan Stubbs', 'sa', [PlayerRole.middleOrder, PlayerRole.batter], bat: 82, bowl: 22, field: 86),
      _p('sa_13', 'Gerald Coetzee', 'sa', [PlayerRole.bowler], bat: 26, bowl: 85, field: 74),
      _p('sa_14', 'Rassie van der Dussen', 'sa', [PlayerRole.batter, PlayerRole.middleOrder], bat: 85, bowl: 12, field: 80),
    ],
  ),
  CricketTeam(
    id: 'pak',
    name: 'Pakistan',
    shortName: 'PAK',
    players: [
      _p('pak_1', 'Babar Azam', 'pak', [PlayerRole.batter, PlayerRole.opener], bat: 94, bowl: 10, field: 84),
      _p('pak_2', 'Mohammad Rizwan', 'pak', [PlayerRole.opener, PlayerRole.wicketKeeper], bat: 90, bowl: 5, field: 86),
      _p('pak_3', 'Fakhar Zaman', 'pak', [PlayerRole.opener], bat: 85, bowl: 12, field: 78),
      _p('pak_4', 'Saim Ayub', 'pak', [PlayerRole.opener, PlayerRole.allRounder], bat: 82, bowl: 60, field: 80),
      _p('pak_5', 'Shadab Khan', 'pak', [PlayerRole.allRounder, PlayerRole.bowler], bat: 74, bowl: 86, field: 88),
      _p('pak_6', 'Iftikhar Ahmed', 'pak', [PlayerRole.middleOrder, PlayerRole.allRounder], bat: 78, bowl: 64, field: 76),
      _p('pak_7', 'Imad Wasim', 'pak', [PlayerRole.allRounder, PlayerRole.bowler], bat: 70, bowl: 82, field: 80),
      _p('pak_8', 'Shaheen Afridi', 'pak', [PlayerRole.bowler], bat: 30, bowl: 95, field: 74),
      _p('pak_9', 'Haris Rauf', 'pak', [PlayerRole.bowler], bat: 18, bowl: 91, field: 72),
      _p('pak_10', 'Naseem Shah', 'pak', [PlayerRole.bowler], bat: 24, bowl: 89, field: 74),
      _p('pak_11', 'Abrar Ahmed', 'pak', [PlayerRole.bowler], bat: 16, bowl: 86, field: 68),
      _p('pak_12', 'Usmar Khan', 'pak', [PlayerRole.middleOrder], bat: 81, bowl: 10, field: 76),
      _p('pak_13', 'Mohammad Nawaz', 'pak', [PlayerRole.allRounder, PlayerRole.bowler], bat: 68, bowl: 80, field: 82),
      _p('pak_14', 'Abbas Afridi', 'pak', [PlayerRole.bowler], bat: 22, bowl: 84, field: 70),
    ],
  ),
];

List<CricketTeam> get cricketTeams => _apiCricketTeams ?? seedCricketTeams;

void applyNationalTeams(List<CricketTeam> teams) {
  _apiCricketTeams = List<CricketTeam>.unmodifiable(teams);
}

CricketTeam teamById(String id) =>
    cricketTeams.firstWhere((team) => team.id == id);

CricketPlayer? playerById(String id) {
  for (final team in cricketTeams) {
    for (final player in team.players) {
      if (player.id == id) return player;
    }
  }
  return null;
}
