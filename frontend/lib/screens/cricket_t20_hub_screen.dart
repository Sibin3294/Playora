import 'package:flutter/material.dart';
import 'package:guess_game/cricket/models.dart';
import 'package:guess_game/intro/first_run_store.dart';
import 'package:guess_game/screens/cricket_draft_screen.dart';
import 'package:guess_game/screens/cricket_league_hub_screen.dart';
import 'package:guess_game/screens/cricket_room_hub_screen.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/feature_tip.dart';
import 'package:guess_game/widgets/first_run_intro.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

class CricketT20HubScreen extends StatefulWidget {
  const CricketT20HubScreen({super.key});

  static Route<void> route() =>
      FadeScaleRoute(page: const CricketT20HubScreen());

  @override
  State<CricketT20HubScreen> createState() => _CricketT20HubScreenState();
}

class _CricketT20HubScreenState extends State<CricketT20HubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      maybeShowFirstRunIntro(
        context,
        id: FirstRunStore.cricketBattleId,
        pages: const [
          FirstRunPage(
            title: 'CHOOSE YOUR BATTLE',
            body:
                'Exhibition is a one-off vs the system. Private Room invites a friend. League autoplays a full season for the cup.',
            accent: GameColors.lime,
            icon: Icons.sports_cricket_rounded,
          ),
          FirstRunPage(
            title: 'SAME DRAFT RULES',
            body:
                'Spin packs, fill every XI slot including the keeper, then toss and play T20 overs.',
            accent: GameColors.cyan,
            icon: Icons.groups_rounded,
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: GameColors.mute,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'T20 ARENA',
                        style: hudLabelStyle(color: GameColors.lime, size: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showGameRules(context),
                      style: TextButton.styleFrom(
                        foregroundColor: GameColors.gold,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                      child: Text(
                        'GAME RULES',
                        style: hudLabelStyle(color: GameColors.gold, size: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'CHOOSE YOUR\nBATTLE',
                  style: TextStyle(
                    color: GameColors.text,
                    fontSize: 36,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Face the system, invite a friend to a private room, or enter a league season for the cup.',
                  style: TextStyle(
                    color: GameColors.mute,
                    height: 1.4,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: ListView(
                    children: [
                      _ModeCard(
                        title: 'FACE THE SYSTEM',
                        subtitle:
                            'Spin national packs, draft your XI, then play live over by over.',
                        accent: GameColors.cyan,
                        button: 'START EXHIBITION',
                        onPressed: () {
                          Navigator.of(context).push(
                            CricketDraftScreen.route(CricketFormat.t20),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      FeatureTip(
                        id: FirstRunStore.tipPrivateRoomId,
                        title: 'New · Private Room',
                        message:
                            'Share a room code with a friend and play T20 head-to-head.',
                        accent: GameColors.gold,
                        child: _ModeCard(
                          title: 'PRIVATE ROOM',
                          subtitle:
                              'Create a room code and play T20 head-to-head. Needs Wi‑Fi + API (unlike exhibition & league).',
                          accent: GameColors.gold,
                          button: 'OPEN ROOMS',
                          onPressed: () {
                            Navigator.of(context).push(
                              CricketRoomHubScreen.route(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ModeCard(
                        title: 'LEAGUE COMPETITIONS',
                        subtitle:
                            'Draft an XI, autoplay the season, chase playoffs and the trophy.',
                        accent: GameColors.lime,
                        button: 'OPEN LEAGUES',
                        onPressed: () {
                          Navigator.of(context).push(
                            CricketLeagueHubScreen.route(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showGameRules(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: panelDecoration(glow: GameColors.gold),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'GAMEPLAY RULES',
                      style: hudLabelStyle(color: GameColors.gold, size: 12),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: GameColors.mute,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: const [
                    _RulesSection(
                      title: 'SHARED BASICS',
                      accent: GameColors.cyan,
                      bullets: [
                        'T20 format: each side bats for up to 20 overs.',
                        'Draft a full XI into fixed slots (openers, middle order, keeper, all-rounders, bowlers).',
                        'A wicket-keeper must fill the keeper slot; keepers can also bat higher if their roles allow.',
                        'After the draft you pick bat or bowl preference, then the toss decides who bats first.',
                      ],
                    ),
                    SizedBox(height: 16),
                    _RulesSection(
                      title: 'FACE THE SYSTEM',
                      accent: GameColors.cyan,
                      bullets: [
                        'One exhibition match against a system XI.',
                        'Spin national packs, draft your players, then play live over by over.',
                        'Chase the target or defend your total. Match ends when overs finish or wickets fall.',
                      ],
                    ),
                    SizedBox(height: 16),
                    _RulesSection(
                      title: 'PRIVATE ROOM',
                      accent: GameColors.gold,
                      bullets: [
                        'Create a room to get a shareable code, or join with a friend’s code.',
                        'Guests and signed-in users can play. Both draft a T20 XI with the same rules as exhibition.',
                        'When both ready up, the host simulates the match and both phones open the shared result.',
                        'Needs the API on the same Wi‑Fi (like online Number Hunter).',
                      ],
                    ),
                    SizedBox(height: 16),
                    _RulesSection(
                      title: 'LEAGUE COMPETITIONS',
                      accent: GameColors.lime,
                      bullets: [
                        'Pick a league, name your franchise, and draft an XI from that competition’s pool.',
                        'The season autoplays your fixtures. Each result shows win/loss on the segment strip (green win, coral loss, gold tie).',
                        'Win enough league games to finish in the top four and reach the playoffs.',
                        'Playoff path: Qualifier 1, Eliminator, Qualifier 2, then the Final. Losing Q1 still leaves a path through Q2.',
                        'Win the Final to lift the trophy. You can skip ahead to the season outcome anytime.',
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              NeonButton(
                label: 'GOT IT',
                color: GameColors.gold,
                height: 48,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _RulesSection extends StatelessWidget {
  const _RulesSection({
    required this.title,
    required this.accent,
    required this.bullets,
  });

  final String title;
  final Color accent;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: hudLabelStyle(color: accent, size: 10)),
        const SizedBox(height: 10),
        for (final bullet in bullets) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bullet,
                    style: const TextStyle(
                      color: GameColors.mute,
                      height: 1.4,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.button,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final String button;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: panelDecoration(glow: accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: GameColors.text,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: GameColors.mute, height: 1.4),
          ),
          const SizedBox(height: 16),
          NeonButton(
            label: button,
            color: accent,
            height: 48,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
