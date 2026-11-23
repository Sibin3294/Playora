import 'package:flutter/material.dart';
import 'package:playora_admin/session/admin_session.dart';
import 'package:playora_admin/theme/admin_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _overview;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final overview = await AdminSession.instance.api.overview();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final counts = (_overview?['counts'] as Map<String, dynamic>?) ?? {};
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Overview',
                  style: TextStyle(
                    color: AdminColors.text,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Live catalog counts served to the player app.',
            style: TextStyle(color: AdminColors.mute.withOpacity(0.95)),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: AdminColors.danger))
          else
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _StatCard(label: 'Categories', value: '${counts['categories'] ?? 0}'),
                _StatCard(label: 'Games', value: '${counts['games'] ?? 0}'),
                _StatCard(
                  label: 'Face puzzles',
                  value: '${counts['facePuzzles'] ?? 0}',
                ),
                _StatCard(
                  label: 'Hunt levels',
                  value: '${counts['huntLevels'] ?? 0}',
                ),
                _StatCard(
                  label: 'National teams',
                  value: '${counts['nationalTeams'] ?? 0}',
                ),
                _StatCard(
                  label: 'IPL teams',
                  value: '${counts['iplTeams'] ?? 0}',
                ),
                _StatCard(label: 'Venues', value: '${counts['venues'] ?? 0}'),
              ],
            ),
          const SizedBox(height: 28),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How publishing works',
                    style: TextStyle(
                      color: AdminColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Edits in Admin write to backend catalog JSON and refresh the in-memory API cache. '
                    'The player app picks them up on the next /api/catalog load (app restart or catalog refresh). '
                    'New game types still need a Flutter screen wired in the player app.',
                    style: TextStyle(
                      color: AdminColors.mute,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AdminColors.mute,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  color: AdminColors.accent,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
