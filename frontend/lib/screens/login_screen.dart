import 'package:flutter/material.dart';
import 'package:guess_game/api/game_api.dart';
import 'package:guess_game/api/game_session.dart';
import 'package:guess_game/screens/hub_screen.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _registerMode = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_registerMode) {
        await GameSession.instance.register(
          email: _email.text.trim(),
          password: _password.text,
          name: _name.text.trim(),
        );
      } else {
        await GameSession.instance.login(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        FadeScaleRoute(page: const HubScreen()),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not reach the hunt server.';
        _busy = false;
      });
    }
  }

  Future<void> _guest() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await GameSession.instance.continueAsGuest();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        FadeScaleRoute(page: const HubScreen()),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not start a guest session.';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'PLAYORA',
                      textAlign: TextAlign.center,
                      style: hudLabelStyle(color: GameColors.cyan, size: 12),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _registerMode ? 'CREATE ACCOUNT' : 'PLAYER LOGIN',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: GameColors.text,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _registerMode
                          ? 'One account for number games, sports, and more.'
                          : 'Sign in to sync progress, or continue as guest.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: GameColors.mute,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: panelDecoration(glow: GameColors.cyan),
                      child: Column(
                        children: [
                          if (_registerMode) ...[
                            _Field(
                              controller: _name,
                              label: 'NAME',
                              hint: 'Hunter name',
                            ),
                            const SizedBox(height: 12),
                          ],
                          _Field(
                            controller: _email,
                            label: 'EMAIL',
                            hint: 'you@email.com',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            controller: _password,
                            label: 'PASSWORD',
                            hint: 'At least 6 characters',
                            obscure: true,
                          ),
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
                          const SizedBox(height: 18),
                          NeonButton(
                            label: _busy
                                ? 'PLEASE WAIT'
                                : (_registerMode ? 'REGISTER' : 'LOGIN'),
                            onPressed: _busy ? null : _submit,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () {
                              setState(() {
                                _registerMode = !_registerMode;
                                _error = null;
                              });
                            },
                      child: Text(
                        _registerMode
                            ? 'ALREADY HAVE AN ACCOUNT? LOGIN'
                            : 'NEW HUNTER? CREATE ACCOUNT',
                        style: hudLabelStyle(color: GameColors.gold, size: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    NeonButton(
                      label: 'CONTINUE AS GUEST',
                      outlined: true,
                      color: GameColors.violet,
                      height: 48,
                      onPressed: _busy ? null : _guest,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: hudLabelStyle(size: 10)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: GameColors.text,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: GameColors.mute),
            filled: true,
            fillColor: const Color(0xFF070B1A),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: GameColors.panelBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: GameColors.cyan, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}
