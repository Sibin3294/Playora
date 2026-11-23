import 'package:flutter/material.dart';
import 'package:guess_game/theme/game_theme.dart';

class SportsFacePuzzle {
  const SportsFacePuzzle({
    required this.id,
    required this.answer,
    required this.options,
    this.imageAsset = '',
    this.imageUrl = '',
    this.sport = 'Cricket',
    this.country = '',
    this.role = '',
    this.accent = GameColors.violet,
  });

  final String id;
  final String answer;
  final String imageAsset;
  final String imageUrl;
  final List<String> options;
  final String sport;
  final String country;
  final String role;
  final Color accent;

  bool get hasLocalImage => imageAsset.trim().isNotEmpty;
  bool get hasNetworkImage => imageUrl.trim().isNotEmpty;
}

List<SportsFacePuzzle>? _apiPuzzles;

/// Offline / FORCE_LOCAL starter pack — cricket faces.
const seedSportsFacePuzzles = <SportsFacePuzzle>[
  SportsFacePuzzle(
    id: 'virat_kohli',
    answer: 'Virat Kohli',
    imageAsset: 'assets/puzzles/puzzle_batter_blue.jpg',
    sport: 'Cricket',
    country: 'India',
    role: 'Batter',
    accent: Color(0xFF1B4F9C),
    options: ['Virat Kohli', 'Rohit Sharma', 'Kane Williamson', 'Joe Root'],
  ),
  SportsFacePuzzle(
    id: 'ms_dhoni',
    answer: 'MS Dhoni',
    imageAsset: 'assets/puzzles/puzzle_keeper_yellow.jpg',
    sport: 'Cricket',
    country: 'India',
    role: 'Wicketkeeper',
    accent: Color(0xFFD4A017),
    options: ['MS Dhoni', 'Rishabh Pant', 'Jos Buttler', 'AB de Villiers'],
  ),
  SportsFacePuzzle(
    id: 'rohit_sharma',
    answer: 'Rohit Sharma',
    sport: 'Cricket',
    country: 'India',
    role: 'Opener',
    accent: Color(0xFF0B3D91),
    options: ['Rohit Sharma', 'Shubman Gill', 'David Warner', 'Quinton de Kock'],
  ),
  SportsFacePuzzle(
    id: 'jasprit_bumrah',
    answer: 'Jasprit Bumrah',
    sport: 'Cricket',
    country: 'India',
    role: 'Fast bowler',
    accent: Color(0xFF163A6B),
    options: ['Jasprit Bumrah', 'Mohammed Shami', 'Pat Cummins', 'Kagiso Rabada'],
  ),
  SportsFacePuzzle(
    id: 'hardik_pandya',
    answer: 'Hardik Pandya',
    sport: 'Cricket',
    country: 'India',
    role: 'All-rounder',
    accent: Color(0xFF0E4D64),
    options: ['Hardik Pandya', 'Ravindra Jadeja', 'Ben Stokes', 'Glenn Maxwell'],
  ),
  SportsFacePuzzle(
    id: 'ravindra_jadeja',
    answer: 'Ravindra Jadeja',
    sport: 'Cricket',
    country: 'India',
    role: 'All-rounder',
    accent: Color(0xFF1F6B4A),
    options: ['Ravindra Jadeja', 'Axar Patel', 'Mitchell Santner', 'Shakib Al Hasan'],
  ),
  SportsFacePuzzle(
    id: 'pat_cummins',
    answer: 'Pat Cummins',
    sport: 'Cricket',
    country: 'Australia',
    role: 'Fast bowler',
    accent: Color(0xFF0A3A6B),
    options: ['Pat Cummins', 'Mitchell Starc', 'Josh Hazlewood', 'Jasprit Bumrah'],
  ),
  SportsFacePuzzle(
    id: 'steve_smith',
    answer: 'Steve Smith',
    sport: 'Cricket',
    country: 'Australia',
    role: 'Batter',
    accent: Color(0xFF1C4B82),
    options: ['Steve Smith', 'Marnus Labuschagne', 'Joe Root', 'Kane Williamson'],
  ),
  SportsFacePuzzle(
    id: 'david_warner',
    answer: 'David Warner',
    sport: 'Cricket',
    country: 'Australia',
    role: 'Opener',
    accent: Color(0xFF174A7C),
    options: ['David Warner', 'Travis Head', 'Rohit Sharma', 'Jonny Bairstow'],
  ),
  SportsFacePuzzle(
    id: 'kane_williamson',
    answer: 'Kane Williamson',
    sport: 'Cricket',
    country: 'New Zealand',
    role: 'Batter',
    accent: Color(0xFF1A3C2E),
    options: ['Kane Williamson', 'Devon Conway', 'Joe Root', 'Babar Azam'],
  ),
  SportsFacePuzzle(
    id: 'trent_boult',
    answer: 'Trent Boult',
    sport: 'Cricket',
    country: 'New Zealand',
    role: 'Fast bowler',
    accent: Color(0xFF145A3A),
    options: ['Trent Boult', 'Tim Southee', 'Mitchell Starc', 'Shaheen Afridi'],
  ),
  SportsFacePuzzle(
    id: 'joe_root',
    answer: 'Joe Root',
    sport: 'Cricket',
    country: 'England',
    role: 'Batter',
    accent: Color(0xFF1E3A5F),
    options: ['Joe Root', 'Harry Brook', 'Steve Smith', 'Virat Kohli'],
  ),
  SportsFacePuzzle(
    id: 'jos_buttler',
    answer: 'Jos Buttler',
    sport: 'Cricket',
    country: 'England',
    role: 'Wicketkeeper',
    accent: Color(0xFF243B66),
    options: ['Jos Buttler', 'Jonny Bairstow', 'MS Dhoni', 'Quinton de Kock'],
  ),
  SportsFacePuzzle(
    id: 'ben_stokes',
    answer: 'Ben Stokes',
    sport: 'Cricket',
    country: 'England',
    role: 'All-rounder',
    accent: Color(0xFF2A3558),
    options: ['Ben Stokes', 'Hardik Pandya', 'Cameron Green', 'Shakib Al Hasan'],
  ),
  SportsFacePuzzle(
    id: 'babar_azam',
    answer: 'Babar Azam',
    sport: 'Cricket',
    country: 'Pakistan',
    role: 'Batter',
    accent: Color(0xFF0F5C3A),
    options: ['Babar Azam', 'Mohammad Rizwan', 'Virat Kohli', 'Joe Root'],
  ),
  SportsFacePuzzle(
    id: 'shaheen_afridi',
    answer: 'Shaheen Afridi',
    sport: 'Cricket',
    country: 'Pakistan',
    role: 'Fast bowler',
    accent: Color(0xFF146B42),
    options: ['Shaheen Afridi', 'Haris Rauf', 'Trent Boult', 'Mohammed Siraj'],
  ),
  SportsFacePuzzle(
    id: 'kagiso_rabada',
    answer: 'Kagiso Rabada',
    sport: 'Cricket',
    country: 'South Africa',
    role: 'Fast bowler',
    accent: Color(0xFF1B5E3A),
    options: ['Kagiso Rabada', 'Anrich Nortje', 'Jasprit Bumrah', 'Pat Cummins'],
  ),
  SportsFacePuzzle(
    id: 'ab_de_villiers',
    answer: 'AB de Villiers',
    sport: 'Cricket',
    country: 'South Africa',
    role: 'Batter',
    accent: Color(0xFF205C38),
    options: ['AB de Villiers', 'Faf du Plessis', 'MS Dhoni', 'Jos Buttler'],
  ),
  SportsFacePuzzle(
    id: 'rashid_khan',
    answer: 'Rashid Khan',
    sport: 'Cricket',
    country: 'Afghanistan',
    role: 'Spinner',
    accent: Color(0xFF7A1F2B),
    options: ['Rashid Khan', 'Yuzvendra Chahal', 'Adam Zampa', 'Kuldeep Yadav'],
  ),
  SportsFacePuzzle(
    id: 'shakib_al_hasan',
    answer: 'Shakib Al Hasan',
    sport: 'Cricket',
    country: 'Bangladesh',
    role: 'All-rounder',
    accent: Color(0xFF0C4A2E),
    options: ['Shakib Al Hasan', 'Mehidy Hasan', 'Ravindra Jadeja', 'Ben Stokes'],
  ),
];

List<SportsFacePuzzle> get sportsFacePuzzles =>
    _apiPuzzles ?? seedSportsFacePuzzles;

void applySportsFacePuzzles(List<SportsFacePuzzle> puzzles) {
  _apiPuzzles = List<SportsFacePuzzle>.unmodifiable(puzzles);
}

Color _accentFromJson(dynamic value) {
  if (value is int) return Color(value);
  if (value is String) {
    final raw = value.trim().replaceFirst('#', '');
    final parsed = int.tryParse(raw, radix: 16);
    if (parsed != null) {
      return Color(raw.length <= 6 ? (0xFF000000 | parsed) : parsed);
    }
  }
  return GameColors.violet;
}

SportsFacePuzzle sportsFacePuzzleFromJson(Map<String, dynamic> json) {
  return SportsFacePuzzle(
    id: json['id'] as String? ?? 'puzzle',
    answer: json['answer'] as String? ?? '',
    imageAsset: json['imageAsset'] as String? ?? '',
    imageUrl: json['imageUrl'] as String? ?? '',
    sport: json['sport'] as String? ?? 'Cricket',
    country: json['country'] as String? ?? '',
    role: json['role'] as String? ?? '',
    accent: _accentFromJson(json['accent']),
    options: [
      for (final option in (json['options'] as List<dynamic>? ?? const []))
        option as String,
    ],
  );
}
