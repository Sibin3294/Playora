import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_game/api/game_session.dart';
import 'package:guess_game/game/guess_engine.dart';
import 'package:guess_game/game/hunt_archive.dart';
import 'package:guess_game/game/hunt_level.dart';
import 'package:guess_game/game/player_progress.dart';
import 'package:guess_game/main.dart';
import 'package:guess_game/screens/history_screen.dart';
import 'package:guess_game/screens/home_screen.dart';
import 'package:guess_game/screens/play_screen.dart';
import 'package:guess_game/screens/result_screen.dart';
import 'package:guess_game/screens/splash_screen.dart';

void main() {
  setUp(() {
    GameSession.forceLocal = true;
    HuntArchive.instance.clear();
    PlayerProgress.instance.reset();
  });

  testWidgets('splash shows the Playora brand', (tester) async {
    GameSession.forceLocal = false;
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen(duration: Duration(days: 1))),
    );
    await tester.pump();

    expect(find.text('Playora'), findsOneWidget);
    expect(find.text('MULTI-WORLD PLAY'), findsOneWidget);
    expect(find.text('NUMBERS. SPORTS. WORLDS AHEAD.'), findsOneWidget);

    GameSession.forceLocal = true;
  });

  testWidgets('hub lists game categories', (tester) async {
    await tester.pumpWidget(const GuessGameApp());
    await tester.pump();

    expect(find.text('CHOOSE YOUR\nWORLD'), findsOneWidget);
    expect(find.text('NUMBER GAMES'), findsOneWidget);
    expect(find.text('SPORTS'), findsOneWidget);
  });

  testWidgets('hub profile button opens the profile page', (tester) async {
    await tester.pumpWidget(const GuessGameApp());
    await tester.pump();

    await tester.tap(find.byTooltip('Profile'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('DISPLAY NAME'), findsOneWidget);
    expect(find.text('LOG OUT'), findsOneWidget);
  });

  testWidgets('number games open Number Hunter home', (tester) async {
    await tester.pumpWidget(const GuessGameApp());
    await tester.pump();

    await tester.tap(find.text('NUMBER GAMES'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('NUMBER HUNTER'), findsOneWidget);
    await tester.tap(find.text('ENTER'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('HUNTER'), findsOneWidget);
    expect(find.text('PLAY SCOUT'), findsOneWidget);
    expect(find.text('LEVELS'), findsOneWidget);
    expect(find.text('HISTORY'), findsOneWidget);

    await tester.tap(find.text('PLAY SCOUT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('LOCK IN'), findsOneWidget);
    expect(find.text('SCOUT'), findsOneWidget);
  });

  testWidgets('a low guess shows heat feedback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlayScreen(engine: GuessEngine(secretNumber: 90)),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('key-1')));
    await tester.pump();
    await tester.tap(find.text('LOCK IN'));
    await tester.pump();

    expect(find.text('TOO LOW'), findsOneWidget);
  });

  testWidgets('jackpot screen shows for a win', (tester) async {
    final engine = GuessEngine(secretNumber: 7);
    engine.submit(7);

    await tester.pumpWidget(
      MaterialApp(home: ResultScreen(engine: engine)),
    );
    await tester.pump();

    expect(find.text('JACKPOT'), findsOneWidget);
    expect(find.text('PLAY AGAIN'), findsOneWidget);
  });

  testWidgets('winning the last level shows the legend finale', (tester) async {
    final engine = GuessEngine.fromLevel(HuntLevel.phantom, secretNumber: 7)
      ..submit(7);

    await tester.pumpWidget(
      MaterialApp(home: ResultScreen(engine: engine)),
    );
    await tester.pump();

    expect(find.text('CAMPAIGN COMPLETE'), findsOneWidget);
    expect(find.text('LEGEND'), findsOneWidget);
    expect(find.text('PLAY PHANTOM AGAIN'), findsOneWidget);
    expect(find.text('JACKPOT'), findsNothing);
  });

  testWidgets('consolation screen shows after a loss', (tester) async {
    final engine = GuessEngine(secretNumber: 100);
    for (var value = 1; value <= 12; value++) {
      engine.submit(value);
    }

    await tester.pumpWidget(
      MaterialApp(home: ResultScreen(engine: engine)),
    );
    await tester.pump();

    expect(find.text('SO CLOSE'), findsOneWidget);
    expect(find.text('PLAY AGAIN'), findsOneWidget);
    expect(find.textContaining('still out there'), findsOneWidget);
  });

  testWidgets('history page shows an empty log', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HistoryScreen(archive: HuntArchive())),
    );
    await tester.pump();

    expect(find.text('HUNT LOG'), findsOneWidget);
    expect(find.text('NO HUNTS YET'), findsOneWidget);
  });

  testWidgets('finished hunts appear on the history page', (tester) async {
    final archive = HuntArchive();
    archive.addFromEngine(GuessEngine(secretNumber: 42)..submit(42));

    await tester.pumpWidget(
      MaterialApp(home: HistoryScreen(archive: archive)),
    );
    await tester.pump();

    expect(find.text('NO HUNTS YET'), findsNothing);
    expect(find.text('WIN'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('home levels button opens the level select screen',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    await tester.tap(find.text('LEVELS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('SELECT LEVEL'), findsOneWidget);
    expect(find.text('SCOUT'), findsWidgets);
    expect(find.text('HUNTER'), findsWidgets);
  });

  testWidgets('home history button opens the hunt log', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    await tester.tap(find.text('HISTORY'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('HUNT LOG'), findsOneWidget);
  });
}
