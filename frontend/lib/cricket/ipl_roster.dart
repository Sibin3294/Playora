import 'package:guess_game/cricket/models.dart';

CricketPlayer _p(
  String id,
  String name,
  String teamId,
  List<PlayerRole> roles, {
  required int bat,
  required int bowl,
  required int field,
  bool overseas = false,
}) {
  return CricketPlayer(
    id: id,
    name: name,
    teamId: teamId,
    roles: roles,
    batRating: bat,
    bowlRating: bowl,
    fieldRating: field,
    isOverseas: overseas,
  );
}

List<CricketTeam>? _apiIplTeams;
LeagueCompetition? _apiIplCompetition;

/// Built-in IPL franchises (offline / FORCE_LOCAL fallback).
final seedIplTeams = <CricketTeam>[
  CricketTeam(
    id: 'mi',
    name: 'Mumbai Indians',
    shortName: 'MI',
    players: [
      _p('mi_1', 'Rohit Sharma', 'mi', [PlayerRole.opener, PlayerRole.batter], bat: 90, bowl: 16, field: 78),
      _p('mi_2', 'Ishan Kishan', 'mi', [PlayerRole.opener, PlayerRole.wicketKeeper], bat: 84, bowl: 5, field: 82),
      _p('mi_3', 'Suryakumar Yadav', 'mi', [PlayerRole.middleOrder, PlayerRole.batter], bat: 92, bowl: 8, field: 84),
      _p('mi_4', 'Tilak Varma', 'mi', [PlayerRole.batter, PlayerRole.middleOrder], bat: 86, bowl: 28, field: 80),
      _p('mi_5', 'Hardik Pandya', 'mi', [PlayerRole.allRounder, PlayerRole.middleOrder], bat: 85, bowl: 78, field: 86),
      _p('mi_6', 'Tim David', 'mi', [PlayerRole.middleOrder], bat: 83, bowl: 12, field: 74, overseas: true),
      _p('mi_7', 'Naman Dhir', 'mi', [PlayerRole.allRounder, PlayerRole.batter], bat: 78, bowl: 62, field: 80),
      _p('mi_8', 'Jasprit Bumrah', 'mi', [PlayerRole.bowler], bat: 22, bowl: 97, field: 72),
      _p('mi_9', 'Gerald Coetzee', 'mi', [PlayerRole.bowler], bat: 28, bowl: 86, field: 70, overseas: true),
      _p('mi_10', 'Piyush Chawla', 'mi', [PlayerRole.bowler], bat: 30, bowl: 84, field: 68),
      _p('mi_11', 'Luke Wood', 'mi', [PlayerRole.bowler], bat: 18, bowl: 83, field: 71, overseas: true),
      _p('mi_12', 'Nehal Wadhera', 'mi', [PlayerRole.middleOrder, PlayerRole.batter], bat: 79, bowl: 20, field: 76),
      _p('mi_13', 'Shreyas Gopal', 'mi', [PlayerRole.bowler, PlayerRole.allRounder], bat: 42, bowl: 80, field: 74),
      _p('mi_14', 'Dewald Brevis', 'mi', [PlayerRole.batter, PlayerRole.opener], bat: 82, bowl: 24, field: 78, overseas: true),
    ],
  ),
  CricketTeam(
    id: 'csk',
    name: 'Chennai Super Kings',
    shortName: 'CSK',
    players: [
      _p('csk_1', 'Ruturaj Gaikwad', 'csk', [PlayerRole.opener, PlayerRole.batter], bat: 88, bowl: 10, field: 82),
      _p('csk_2', 'Rachin Ravindra', 'csk', [PlayerRole.opener, PlayerRole.allRounder], bat: 84, bowl: 74, field: 80, overseas: true),
      _p('csk_3', 'Ajinkya Rahane', 'csk', [PlayerRole.batter, PlayerRole.middleOrder], bat: 82, bowl: 8, field: 84),
      _p('csk_4', 'Shivam Dube', 'csk', [PlayerRole.middleOrder, PlayerRole.allRounder], bat: 84, bowl: 64, field: 76),
      _p('csk_5', 'MS Dhoni', 'csk', [PlayerRole.wicketKeeper, PlayerRole.middleOrder], bat: 80, bowl: 5, field: 88),
      _p('csk_6', 'Ravindra Jadeja', 'csk', [PlayerRole.allRounder, PlayerRole.bowler], bat: 76, bowl: 88, field: 95),
      _p('csk_7', 'Sameer Rizvi', 'csk', [PlayerRole.middleOrder], bat: 78, bowl: 14, field: 74),
      _p('csk_8', 'Deepak Chahar', 'csk', [PlayerRole.bowler], bat: 32, bowl: 87, field: 72),
      _p('csk_9', 'Matheesha Pathirana', 'csk', [PlayerRole.bowler], bat: 16, bowl: 91, field: 68, overseas: true),
      _p('csk_10', 'Mustafizur Rahman', 'csk', [PlayerRole.bowler], bat: 18, bowl: 88, field: 70, overseas: true),
      _p('csk_11', 'Maheesh Theekshana', 'csk', [PlayerRole.bowler], bat: 22, bowl: 85, field: 74, overseas: true),
      _p('csk_12', 'Daryl Mitchell', 'csk', [PlayerRole.allRounder, PlayerRole.middleOrder], bat: 81, bowl: 72, field: 82, overseas: true),
      _p('csk_13', 'Shardul Thakur', 'csk', [PlayerRole.bowler, PlayerRole.allRounder], bat: 48, bowl: 82, field: 76),
      _p('csk_14', 'Devon Conway', 'csk', [PlayerRole.opener, PlayerRole.wicketKeeper], bat: 86, bowl: 5, field: 80, overseas: true),
    ],
  ),
  CricketTeam(
    id: 'rcb',
    name: 'Royal Challengers Bengaluru',
    shortName: 'RCB',
    players: [
      _p('rcb_1', 'Virat Kohli', 'rcb', [PlayerRole.opener, PlayerRole.batter], bat: 95, bowl: 12, field: 88),
      _p('rcb_2', 'Faf du Plessis', 'rcb', [PlayerRole.opener, PlayerRole.batter], bat: 87, bowl: 14, field: 84, overseas: true),
      _p('rcb_3', 'Will Jacks', 'rcb', [PlayerRole.batter, PlayerRole.allRounder], bat: 84, bowl: 70, field: 80, overseas: true),
      _p('rcb_4', 'Rajat Patidar', 'rcb', [PlayerRole.middleOrder, PlayerRole.batter], bat: 85, bowl: 18, field: 78),
      _p('rcb_5', 'Cameron Green', 'rcb', [PlayerRole.allRounder, PlayerRole.middleOrder], bat: 82, bowl: 78, field: 88, overseas: true),
      _p('rcb_6', 'Dinesh Karthik', 'rcb', [PlayerRole.wicketKeeper, PlayerRole.middleOrder], bat: 80, bowl: 5, field: 86),
      _p('rcb_7', 'Glenn Maxwell', 'rcb', [PlayerRole.allRounder, PlayerRole.middleOrder], bat: 86, bowl: 72, field: 90, overseas: true),
      _p('rcb_8', 'Mohammed Siraj', 'rcb', [PlayerRole.bowler], bat: 18, bowl: 89, field: 74),
      _p('rcb_9', 'Josh Hazlewood', 'rcb', [PlayerRole.bowler], bat: 16, bowl: 92, field: 72, overseas: true),
      _p('rcb_10', 'Yash Dayal', 'rcb', [PlayerRole.bowler], bat: 14, bowl: 84, field: 70),
      _p('rcb_11', 'Karn Sharma', 'rcb', [PlayerRole.bowler], bat: 28, bowl: 82, field: 68),
      _p('rcb_12', 'Mahipal Lomror', 'rcb', [PlayerRole.middleOrder, PlayerRole.allRounder], bat: 78, bowl: 60, field: 76),
      _p('rcb_13', 'Swapnil Singh', 'rcb', [PlayerRole.allRounder, PlayerRole.bowler], bat: 62, bowl: 80, field: 74),
      _p('rcb_14', 'Anuj Rawat', 'rcb', [PlayerRole.wicketKeeper, PlayerRole.opener], bat: 76, bowl: 5, field: 80),
    ],
  ),
  CricketTeam(
    id: 'kkr',
    name: 'Kolkata Knight Riders',
    shortName: 'KKR',
    players: [
      _p('kkr_1', 'Phil Salt', 'kkr', [PlayerRole.opener, PlayerRole.wicketKeeper], bat: 86, bowl: 5, field: 84, overseas: true),
      _p('kkr_2', 'Sunil Narine', 'kkr', [PlayerRole.opener, PlayerRole.allRounder], bat: 78, bowl: 90, field: 80, overseas: true),
      _p('kkr_3', 'Shreyas Iyer', 'kkr', [PlayerRole.batter, PlayerRole.middleOrder], bat: 87, bowl: 12, field: 82),
      _p('kkr_4', 'Venkatesh Iyer', 'kkr', [PlayerRole.middleOrder, PlayerRole.allRounder], bat: 82, bowl: 68, field: 80),
      _p('kkr_5', 'Rinku Singh', 'kkr', [PlayerRole.middleOrder], bat: 85, bowl: 16, field: 84),
      _p('kkr_6', 'Andre Russell', 'kkr', [PlayerRole.allRounder, PlayerRole.middleOrder], bat: 88, bowl: 80, field: 82, overseas: true),
      _p('kkr_7', 'Ramandeep Singh', 'kkr', [PlayerRole.allRounder, PlayerRole.middleOrder], bat: 76, bowl: 66, field: 78),
      _p('kkr_8', 'Mitchell Starc', 'kkr', [PlayerRole.bowler], bat: 30, bowl: 94, field: 72, overseas: true),
      _p('kkr_9', 'Harshit Rana', 'kkr', [PlayerRole.bowler], bat: 22, bowl: 85, field: 70),
      _p('kkr_10', 'Varun Chakaravarthy', 'kkr', [PlayerRole.bowler], bat: 18, bowl: 89, field: 74),
      _p('kkr_11', 'Vaibhav Arora', 'kkr', [PlayerRole.bowler], bat: 16, bowl: 82, field: 68),
      _p('kkr_12', 'Nitish Rana', 'kkr', [PlayerRole.batter, PlayerRole.middleOrder], bat: 81, bowl: 48, field: 76),
      _p('kkr_13', 'Angkrish Raghuvanshi', 'kkr', [PlayerRole.batter, PlayerRole.opener], bat: 79, bowl: 20, field: 78),
      _p('kkr_14', 'Suyash Sharma', 'kkr', [PlayerRole.bowler], bat: 14, bowl: 83, field: 66),
    ],
  ),
  CricketTeam(
    id: 'dc',
    name: 'Delhi Capitals',
    shortName: 'DC',
    players: [
      _p('dc_1', 'David Warner', 'dc', [PlayerRole.opener], bat: 88, bowl: 12, field: 80, overseas: true),
      _p('dc_2', 'Prithvi Shaw', 'dc', [PlayerRole.opener, PlayerRole.batter], bat: 82, bowl: 10, field: 74),
      _p('dc_3', 'Jake Fraser-McGurk', 'dc', [PlayerRole.batter, PlayerRole.middleOrder], bat: 84, bowl: 14, field: 78, overseas: true),
      _p('dc_4', 'Rishabh Pant', 'dc', [PlayerRole.wicketKeeper, PlayerRole.middleOrder], bat: 87, bowl: 5, field: 82),
      _p('dc_5', 'Tristan Stubbs', 'dc', [PlayerRole.middleOrder], bat: 83, bowl: 18, field: 80, overseas: true),
      _p('dc_6', 'Axar Patel', 'dc', [PlayerRole.allRounder, PlayerRole.bowler], bat: 74, bowl: 86, field: 86),
      _p('dc_7', 'Abishek Porel', 'dc', [PlayerRole.wicketKeeper, PlayerRole.opener], bat: 78, bowl: 5, field: 80),
      _p('dc_8', 'Kuldeep Yadav', 'dc', [PlayerRole.bowler], bat: 26, bowl: 90, field: 70),
      _p('dc_9', 'Mukesh Kumar', 'dc', [PlayerRole.bowler], bat: 16, bowl: 84, field: 72),
      _p('dc_10', 'Khaleel Ahmed', 'dc', [PlayerRole.bowler], bat: 14, bowl: 85, field: 70),
      _p('dc_11', 'Anrich Nortje', 'dc', [PlayerRole.bowler], bat: 18, bowl: 91, field: 68, overseas: true),
      _p('dc_12', 'Lalit Yadav', 'dc', [PlayerRole.allRounder, PlayerRole.middleOrder], bat: 72, bowl: 74, field: 78),
      _p('dc_13', 'Harry Brook', 'dc', [PlayerRole.batter, PlayerRole.middleOrder], bat: 86, bowl: 16, field: 82, overseas: true),
      _p('dc_14', 'Ishant Sharma', 'dc', [PlayerRole.bowler], bat: 20, bowl: 82, field: 70),
    ],
  ),
  CricketTeam(
    id: 'rr',
    name: 'Rajasthan Royals',
    shortName: 'RR',
    players: [
      _p('rr_1', 'Yashasvi Jaiswal', 'rr', [PlayerRole.opener, PlayerRole.batter], bat: 89, bowl: 18, field: 80),
      _p('rr_2', 'Jos Buttler', 'rr', [PlayerRole.opener, PlayerRole.wicketKeeper], bat: 91, bowl: 5, field: 86, overseas: true),
      _p('rr_3', 'Sanju Samson', 'rr', [PlayerRole.wicketKeeper, PlayerRole.middleOrder], bat: 86, bowl: 5, field: 84),
      _p('rr_4', 'Riyan Parag', 'rr', [PlayerRole.middleOrder, PlayerRole.allRounder], bat: 84, bowl: 68, field: 80),
      _p('rr_5', 'Shimron Hetmyer', 'rr', [PlayerRole.middleOrder], bat: 83, bowl: 10, field: 76, overseas: true),
      _p('rr_6', 'Ravichandran Ashwin', 'rr', [PlayerRole.allRounder, PlayerRole.bowler], bat: 62, bowl: 88, field: 82),
      _p('rr_7', 'Rovman Powell', 'rr', [PlayerRole.middleOrder, PlayerRole.allRounder], bat: 82, bowl: 58, field: 78, overseas: true),
      _p('rr_8', 'Trent Boult', 'rr', [PlayerRole.bowler], bat: 28, bowl: 92, field: 74, overseas: true),
      _p('rr_9', 'Avesh Khan', 'rr', [PlayerRole.bowler], bat: 18, bowl: 86, field: 72),
      _p('rr_10', 'Yuzvendra Chahal', 'rr', [PlayerRole.bowler], bat: 20, bowl: 90, field: 70),
      _p('rr_11', 'Sandeep Sharma', 'rr', [PlayerRole.bowler], bat: 16, bowl: 84, field: 70),
      _p('rr_12', 'Dhruv Jurel', 'rr', [PlayerRole.wicketKeeper, PlayerRole.middleOrder], bat: 80, bowl: 5, field: 82),
      _p('rr_13', 'Donovan Ferreira', 'rr', [PlayerRole.middleOrder, PlayerRole.allRounder], bat: 78, bowl: 60, field: 76, overseas: true),
      _p('rr_14', 'Kuldeep Sen', 'rr', [PlayerRole.bowler], bat: 14, bowl: 82, field: 68),
    ],
  ),
  CricketTeam(
    id: 'pbks',
    name: 'Punjab Kings',
    shortName: 'PBKS',
    players: [
      _p('pbks_1', 'Shikhar Dhawan', 'pbks', [PlayerRole.opener], bat: 84, bowl: 10, field: 76),
      _p('pbks_2', 'Jonny Bairstow', 'pbks', [PlayerRole.opener, PlayerRole.wicketKeeper], bat: 85, bowl: 5, field: 82, overseas: true),
      _p('pbks_3', 'Prabhsimran Singh', 'pbks', [PlayerRole.opener, PlayerRole.wicketKeeper], bat: 82, bowl: 5, field: 78),
      _p('pbks_4', 'Liam Livingstone', 'pbks', [PlayerRole.middleOrder, PlayerRole.allRounder], bat: 86, bowl: 72, field: 80, overseas: true),
      _p('pbks_5', 'Jitesh Sharma', 'pbks', [PlayerRole.wicketKeeper, PlayerRole.middleOrder], bat: 81, bowl: 5, field: 82),
      _p('pbks_6', 'Sam Curran', 'pbks', [PlayerRole.allRounder, PlayerRole.bowler], bat: 76, bowl: 84, field: 80, overseas: true),
      _p('pbks_7', 'Shashank Singh', 'pbks', [PlayerRole.middleOrder, PlayerRole.allRounder], bat: 80, bowl: 58, field: 76),
      _p('pbks_8', 'Kagiso Rabada', 'pbks', [PlayerRole.bowler], bat: 24, bowl: 93, field: 74, overseas: true),
      _p('pbks_9', 'Arshdeep Singh', 'pbks', [PlayerRole.bowler], bat: 18, bowl: 88, field: 72),
      _p('pbks_10', 'Harpreet Brar', 'pbks', [PlayerRole.bowler, PlayerRole.allRounder], bat: 48, bowl: 80, field: 78),
      _p('pbks_11', 'Rahul Chahar', 'pbks', [PlayerRole.bowler], bat: 22, bowl: 84, field: 70),
      _p('pbks_12', 'Ashutosh Sharma', 'pbks', [PlayerRole.middleOrder], bat: 79, bowl: 20, field: 74),
      _p('pbks_13', 'Harshal Patel', 'pbks', [PlayerRole.bowler], bat: 28, bowl: 86, field: 72),
      _p('pbks_14', 'Sikandar Raza', 'pbks', [PlayerRole.allRounder, PlayerRole.middleOrder], bat: 78, bowl: 76, field: 82, overseas: true),
    ],
  ),
  CricketTeam(
    id: 'srh',
    name: 'Sunrisers Hyderabad',
    shortName: 'SRH',
    players: [
      _p('srh_1', 'Travis Head', 'srh', [PlayerRole.opener, PlayerRole.batter], bat: 90, bowl: 30, field: 82, overseas: true),
      _p('srh_2', 'Abhishek Sharma', 'srh', [PlayerRole.opener, PlayerRole.allRounder], bat: 86, bowl: 68, field: 80),
      _p('srh_3', 'Heinrich Klaasen', 'srh', [PlayerRole.wicketKeeper, PlayerRole.middleOrder], bat: 90, bowl: 5, field: 84, overseas: true),
      _p('srh_4', 'Aiden Markram', 'srh', [PlayerRole.batter, PlayerRole.allRounder], bat: 84, bowl: 70, field: 86, overseas: true),
      _p('srh_5', 'Nitish Kumar Reddy', 'srh', [PlayerRole.allRounder, PlayerRole.middleOrder], bat: 80, bowl: 76, field: 82),
      _p('srh_6', 'Abdul Samad', 'srh', [PlayerRole.middleOrder], bat: 78, bowl: 24, field: 76),
      _p('srh_7', 'Shahbaz Ahmed', 'srh', [PlayerRole.allRounder, PlayerRole.bowler], bat: 68, bowl: 78, field: 80),
      _p('srh_8', 'Pat Cummins', 'srh', [PlayerRole.bowler, PlayerRole.allRounder], bat: 48, bowl: 94, field: 82, overseas: true),
      _p('srh_9', 'Bhuvneshwar Kumar', 'srh', [PlayerRole.bowler], bat: 28, bowl: 88, field: 74),
      _p('srh_10', 'T Natarajan', 'srh', [PlayerRole.bowler], bat: 14, bowl: 87, field: 70),
      _p('srh_11', 'Mayank Markande', 'srh', [PlayerRole.bowler], bat: 20, bowl: 82, field: 68),
      _p('srh_12', 'Jaydev Unadkat', 'srh', [PlayerRole.bowler], bat: 24, bowl: 83, field: 72),
      _p('srh_13', 'Rahul Tripathi', 'srh', [PlayerRole.batter, PlayerRole.middleOrder], bat: 81, bowl: 16, field: 80),
      _p('srh_14', 'Washington Sundar', 'srh', [PlayerRole.allRounder, PlayerRole.bowler], bat: 70, bowl: 82, field: 84),
    ],
  ),
  CricketTeam(
    id: 'lsg',
    name: 'Lucknow Super Giants',
    shortName: 'LSG',
    players: [
      _p('lsg_1', 'KL Rahul', 'lsg', [PlayerRole.opener, PlayerRole.wicketKeeper], bat: 88, bowl: 5, field: 84),
      _p('lsg_2', 'Quinton de Kock', 'lsg', [PlayerRole.opener, PlayerRole.wicketKeeper], bat: 87, bowl: 5, field: 82, overseas: true),
      _p('lsg_3', 'Marcus Stoinis', 'lsg', [PlayerRole.allRounder, PlayerRole.middleOrder], bat: 84, bowl: 74, field: 80, overseas: true),
      _p('lsg_4', 'Nicholas Pooran', 'lsg', [PlayerRole.middleOrder, PlayerRole.wicketKeeper], bat: 88, bowl: 8, field: 78, overseas: true),
      _p('lsg_5', 'Deepak Hooda', 'lsg', [PlayerRole.middleOrder, PlayerRole.allRounder], bat: 78, bowl: 62, field: 82),
      _p('lsg_6', 'Ayush Badoni', 'lsg', [PlayerRole.middleOrder, PlayerRole.allRounder], bat: 80, bowl: 58, field: 80),
      _p('lsg_7', 'Krunal Pandya', 'lsg', [PlayerRole.allRounder, PlayerRole.bowler], bat: 72, bowl: 80, field: 82),
      _p('lsg_8', 'Mohsin Khan', 'lsg', [PlayerRole.bowler], bat: 18, bowl: 85, field: 72),
      _p('lsg_9', 'Naveen-ul-Haq', 'lsg', [PlayerRole.bowler], bat: 16, bowl: 86, field: 70, overseas: true),
      _p('lsg_10', 'Ravi Bishnoi', 'lsg', [PlayerRole.bowler], bat: 20, bowl: 88, field: 74),
      _p('lsg_11', 'Yash Thakur', 'lsg', [PlayerRole.bowler], bat: 14, bowl: 83, field: 68),
      _p('lsg_12', 'Devdutt Padikkal', 'lsg', [PlayerRole.opener, PlayerRole.batter], bat: 82, bowl: 12, field: 78),
      _p('lsg_13', 'Ashton Turner', 'lsg', [PlayerRole.middleOrder], bat: 79, bowl: 28, field: 76, overseas: true),
      _p('lsg_14', 'Matt Henry', 'lsg', [PlayerRole.bowler], bat: 26, bowl: 87, field: 74, overseas: true),
    ],
  ),
  CricketTeam(
    id: 'gt',
    name: 'Gujarat Titans',
    shortName: 'GT',
    players: [
      _p('gt_1', 'Shubman Gill', 'gt', [PlayerRole.opener, PlayerRole.batter], bat: 90, bowl: 12, field: 84),
      _p('gt_2', 'Wriddhiman Saha', 'gt', [PlayerRole.opener, PlayerRole.wicketKeeper], bat: 78, bowl: 5, field: 86),
      _p('gt_3', 'Sai Sudharsan', 'gt', [PlayerRole.batter, PlayerRole.middleOrder], bat: 85, bowl: 16, field: 80),
      _p('gt_4', 'David Miller', 'gt', [PlayerRole.middleOrder], bat: 84, bowl: 10, field: 78, overseas: true),
      _p('gt_5', 'Rahul Tewatia', 'gt', [PlayerRole.allRounder, PlayerRole.middleOrder], bat: 76, bowl: 74, field: 80),
      _p('gt_6', 'Vijay Shankar', 'gt', [PlayerRole.allRounder, PlayerRole.middleOrder], bat: 74, bowl: 70, field: 82),
      _p('gt_7', 'Azmatullah Omarzai', 'gt', [PlayerRole.allRounder, PlayerRole.bowler], bat: 72, bowl: 82, field: 78, overseas: true),
      _p('gt_8', 'Mohammed Shami', 'gt', [PlayerRole.bowler], bat: 24, bowl: 92, field: 74),
      _p('gt_9', 'Rashid Khan', 'gt', [PlayerRole.bowler, PlayerRole.allRounder], bat: 58, bowl: 95, field: 86, overseas: true),
      _p('gt_10', 'Mohit Sharma', 'gt', [PlayerRole.bowler], bat: 18, bowl: 86, field: 72),
      _p('gt_11', 'Noor Ahmad', 'gt', [PlayerRole.bowler], bat: 16, bowl: 87, field: 70, overseas: true),
      _p('gt_12', 'Kane Williamson', 'gt', [PlayerRole.batter, PlayerRole.middleOrder], bat: 86, bowl: 28, field: 84, overseas: true),
      _p('gt_13', 'Spencer Johnson', 'gt', [PlayerRole.bowler], bat: 14, bowl: 84, field: 68, overseas: true),
      _p('gt_14', 'Shahrukh Khan', 'gt', [PlayerRole.middleOrder], bat: 80, bowl: 22, field: 76),
    ],
  ),
];

List<CricketTeam> get iplTeams => _apiIplTeams ?? seedIplTeams;

void applyIplTeams(List<CricketTeam> teams) {
  _apiIplTeams = List<CricketTeam>.unmodifiable(teams);
}

CricketTeam iplTeamById(String id) =>
    iplTeams.firstWhere((team) => team.id == id);

/// Catalog of playable league competitions under T20.
class LeagueCompetition {
  const LeagueCompetition({
    required this.id,
    required this.name,
    required this.tagline,
    required this.teams,
    this.maxOverseasPlayers,
  });

  final String id;
  final String name;
  final String tagline;
  final List<CricketTeam> teams;

  /// Playing XI overseas cap for this competition (IPL: 4). Null = no cap.
  final int? maxOverseasPlayers;
}

const iplCompetitionId = 'ipl';

LeagueCompetition get seedIplCompetition => LeagueCompetition(
      id: iplCompetitionId,
      name: 'Indian Premier League',
      tagline:
          'Enter as a new side against all 10 franchises. League, playoffs, cup.',
      teams: iplTeams,
      maxOverseasPlayers: 4,
    );

LeagueCompetition get iplCompetition =>
    _apiIplCompetition ?? seedIplCompetition;

void applyIplCompetition(LeagueCompetition competition) {
  _apiIplCompetition = competition;
}

List<LeagueCompetition> get t20Leagues => [iplCompetition];
