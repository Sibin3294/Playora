import 'package:flutter/material.dart';
import 'package:guess_game/api/game_api.dart';
import 'package:guess_game/api/game_session.dart';
import 'package:guess_game/intro/first_run_store.dart';
import 'package:guess_game/screens/login_screen.dart';
import 'package:guess_game/streak/play_streak.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/first_run_intro.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static Route<void> route() => FadeScaleRoute(page: const ProfileScreen());

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _name;
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  bool _savingName = false;
  bool _savingPassword = false;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: GameSession.instance.name ?? '');
    GameSession.instance.refreshProfile().catchError((_) {});
    PlayStreakStore.instance.load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      maybeShowFirstRunIntro(
        context,
        id: FirstRunStore.profileStreakId,
        pages: const [
          FirstRunPage(
            title: 'YOUR PROFILE',
            body:
                'Update your name when signed in. Streak tags stay on this profile once you unlock them.',
            accent: GameColors.magenta,
            icon: Icons.person_outline_rounded,
          ),
          FirstRunPage(
            title: 'DAILY STREAK',
            body:
                'Play any game on consecutive days. Bronze at 7, Silver at 15, Gold at 30. Miss a day and the streak resets.',
            accent: GameColors.gold,
            icon: Icons.local_fire_department_rounded,
          ),
        ],
      );
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    setState(() {
      _savingName = true;
      _error = null;
      _message = null;
    });
    try {
      await GameSession.instance.updateDisplayName(_name.text);
      if (!mounted) return;
      setState(() {
        _savingName = false;
        _message = 'Profile updated.';
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _savingName = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savingName = false;
        _error = 'Could not update profile.';
      });
    }
  }

  Future<void> _savePassword() async {
    setState(() {
      _savingPassword = true;
      _error = null;
      _message = null;
    });
    try {
      await GameSession.instance.changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      _currentPassword.clear();
      _newPassword.clear();
      setState(() {
        _savingPassword = false;
        _message = 'Password changed.';
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _savingPassword = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savingPassword = false;
        _error = 'Could not change password.';
      });
    }
  }

  Future<void> _logout() async {
    final session = GameSession.instance;
    if (session.isLoggedIn || session.ready) {
      await session.logout();
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      FadeScaleRoute(page: const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([
              GameSession.instance,
              PlayStreakStore.instance,
            ]),
            builder: (context, _) {
              final session = GameSession.instance;
              final streak = PlayStreakStore.instance;
              final displayName =
                  (session.name?.trim().isNotEmpty ?? false)
                      ? session.name!.trim()
                      : (session.isLoggedIn ? 'Hunter' : 'Guest');

              return Padding(
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
                        Text(
                          'PROFILE',
                          style: hudLabelStyle(color: GameColors.cyan, size: 12),
                        ),
                      ],
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            Center(
                              child: Container(
                                width: 96,
                                height: 96,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const RadialGradient(
                                    colors: [
                                      Color(0xFF6A35B8),
                                      Color(0xFF120A2C),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: GameColors.cyan,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: GameColors.cyan.withOpacity(0.28),
                                      blurRadius: 28,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  displayName.characters.first.toUpperCase(),
                                  style: const TextStyle(
                                    color: GameColors.text,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              displayName.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: GameColors.text,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              session.offline
                                  ? 'OFFLINE GUEST'
                                  : (session.isLoggedIn
                                      ? 'SIGNED IN'
                                      : 'GUEST SESSION'),
                              textAlign: TextAlign.center,
                              style: hudLabelStyle(
                                color: session.isLoggedIn
                                    ? GameColors.lime
                                    : GameColors.gold,
                                size: 10,
                              ),
                            ),
                            if (session.email != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                session.email!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: GameColors.mute,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            _StreakBanner(streak: streak),
                            const SizedBox(height: 22),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: panelDecoration(glow: GameColors.cyan),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'DISPLAY NAME',
                                    style: hudLabelStyle(size: 10),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _name,
                                    style: const TextStyle(
                                      color: GameColors.text,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Your hunter name',
                                      hintStyle: const TextStyle(
                                        color: GameColors.mute,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF070B1A),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: GameColors.panelBorder,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: GameColors.cyan,
                                          width: 1.6,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  NeonButton(
                                    label: _savingName
                                        ? 'SAVING'
                                        : 'SAVE NAME',
                                    height: 48,
                                    onPressed: _savingName ? null : _saveName,
                                  ),
                                ],
                              ),
                            ),
                            if (session.isLoggedIn) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration:
                                    panelDecoration(glow: GameColors.magenta),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'CHANGE PASSWORD',
                                      style: hudLabelStyle(size: 10),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _currentPassword,
                                      obscureText: true,
                                      style: const TextStyle(
                                        color: GameColors.text,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      decoration: _fieldDecoration(
                                        'Current password',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _newPassword,
                                      obscureText: true,
                                      style: const TextStyle(
                                        color: GameColors.text,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      decoration: _fieldDecoration(
                                        'New password (min 6)',
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    NeonButton(
                                      label: _savingPassword
                                          ? 'UPDATING'
                                          : 'UPDATE PASSWORD',
                                      color: GameColors.magenta,
                                      height: 48,
                                      onPressed: _savingPassword
                                          ? null
                                          : _savePassword,
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 14),
                              Text(
                                session.offline
                                    ? 'Create an account when you are back online to sync this profile.'
                                    : 'Sign in to sync points across devices and protect your account.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: GameColors.mute,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: GameColors.coral,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            if (_message != null) ...[
                              const SizedBox(height: 14),
                              Text(
                                _message!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: GameColors.lime,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            NeonButton(
                              label: 'LOG OUT',
                              outlined: true,
                              color: GameColors.coral,
                              height: 48,
                              onPressed: _logout,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: GameColors.mute),
      filled: true,
      fillColor: const Color(0xFF070B1A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: GameColors.panelBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: GameColors.magenta, width: 1.6),
      ),
    );
  }
}

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.streak});

  final PlayStreakStore streak;

  Color get _tagColor {
    switch (streak.earnedTag) {
      case StreakTag.gold:
        return GameColors.gold;
      case StreakTag.silver:
        return const Color(0xFFC0C7D6);
      case StreakTag.bronze:
        return const Color(0xFFCD7F32);
      case StreakTag.none:
        return GameColors.cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _tagColor;
    final hasTag = streak.earnedTag != StreakTag.none;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: panelDecoration(glow: accent),
      child: Column(
        children: [
          if (hasTag) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accent),
                color: accent.withOpacity(0.14),
              ),
              child: Text(
                '${streak.earnedTag.label} USER',
                style: hudLabelStyle(color: accent, size: 10),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Icon(Icons.local_fire_department_rounded, color: accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      streak.currentStreak > 0
                          ? '${streak.currentStreak}-DAY STREAK'
                          : 'NO ACTIVE STREAK',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasTag
                          ? 'Best streak ${streak.longestStreak} days'
                          : 'Play 7 days for Bronze · 15 Silver · 30 Gold',
                      style: const TextStyle(
                        color: GameColors.mute,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
