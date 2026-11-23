import 'dart:math';

class CricketVenue {
  const CricketVenue({
    required this.name,
    required this.city,
    required this.country,
    required this.capacity,
    required this.pitchReport,
    required this.outfieldNote,
    required this.weather,
  });

  final String name;
  final String city;
  final String country;
  final int capacity;
  final String pitchReport;
  final String outfieldNote;
  final String weather;

  String get headline => '$name, $city';
}

List<CricketVenue>? _apiVenues;

/// Built-in venues (offline / FORCE_LOCAL fallback).
const seedCricketVenues = <CricketVenue>[
  CricketVenue(
    name: 'Wankhede Stadium',
    city: 'Mumbai',
    country: 'India',
    capacity: 33108,
    pitchReport:
        'True bounce with good carry. New ball seams for the first 4 overs, then the surface flattens for stroke-makers.',
    outfieldNote: 'Lightning quick outfield — boundaries come easy once the ball is in the gap.',
    weather: 'Warm coastal air, clear skies',
  ),
  CricketVenue(
    name: 'Melbourne Cricket Ground',
    city: 'Melbourne',
    country: 'Australia',
    capacity: 100024,
    pitchReport:
        'Hard and lively. Pacers get steep bounce; batters who trust the bounce can free their arms through point and midwicket.',
    outfieldNote: 'Vast square — singles are honest, misfields get punished.',
    weather: 'Cool evening under lights',
  ),
  CricketVenue(
    name: 'Lords',
    city: 'London',
    country: 'England',
    capacity: 30000,
    pitchReport:
        'Classic Lords slope. Early movement both ways; scoreboard pressure if you lose early wickets.',
    outfieldNote: 'Lush and slightly heavy after the morning dew.',
    weather: 'Overcast, swing-friendly',
  ),
  CricketVenue(
    name: 'Eden Gardens',
    city: 'Kolkata',
    country: 'India',
    capacity: 68000,
    pitchReport:
        'Dry top with grip for spinners from the middle overs. Pace-on into the pitch still holds.',
    outfieldNote: 'Big boundaries square of the wicket; straight hits are the safer sixes.',
    weather: 'Humid night, packed stands',
  ),
  CricketVenue(
    name: 'Dubai International Stadium',
    city: 'Dubai',
    country: 'UAE',
    capacity: 25000,
    pitchReport:
        'Slowish two-paced strip. Change-ups and cutters bite; pure pace can sit up.',
    outfieldNote: 'Skiddy outfield after sunset — keep the ball along the carpet.',
    weather: 'Dry desert heat, no dew early',
  ),
  CricketVenue(
    name: 'SuperSport Park',
    city: 'Centurion',
    country: 'South Africa',
    capacity: 22000,
    pitchReport:
        'Green tinge with carry. First-use seamers will love the corridor; later overs favour clean strikers.',
    outfieldNote: 'Fast and true — place it and run hard for twos.',
    weather: 'Highveld breeze under lights',
  ),
];

List<CricketVenue> get cricketVenues => _apiVenues ?? seedCricketVenues;

void applyVenues(List<CricketVenue> venues) {
  _apiVenues = List<CricketVenue>.unmodifiable(venues);
}

CricketVenue pickVenue([Random? random]) {
  final rng = random ?? Random();
  final pool = cricketVenues;
  return pool[rng.nextInt(pool.length)];
}
