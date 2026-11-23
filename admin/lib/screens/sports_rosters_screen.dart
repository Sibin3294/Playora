import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:playora_admin/session/admin_session.dart';
import 'package:playora_admin/theme/admin_theme.dart';

const _roleOptions = <String>[
  'opener',
  'batter',
  'middleOrder',
  'wicketKeeper',
  'allRounder',
  'bowler',
];

class SportsRostersScreen extends StatefulWidget {
  const SportsRostersScreen({super.key});

  @override
  State<SportsRostersScreen> createState() => _SportsRostersScreenState();
}

class _SportsRostersScreenState extends State<SportsRostersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Map<String, dynamic>> _national = [];
  List<Map<String, dynamic>> _ipl = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _activeTeams =>
      _tabs.index == 0 ? _national : _ipl;

  set _activeTeams(List<Map<String, dynamic>> value) {
    if (_tabs.index == 0) {
      _national = value;
    } else {
      _ipl = value;
    }
  }

  Map<String, dynamic> _copyTeam(Map<String, dynamic> source) {
    return {
      ...source,
      'players': [
        for (final player in (source['players'] as List<dynamic>? ?? const []))
          Map<String, dynamic>.from(player as Map<String, dynamic>),
      ],
    };
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      final catalog = await AdminSession.instance.api.catalog();
      final national = catalog['nationalTeams'] as List<dynamic>? ?? [];
      final ipl = (catalog['ipl'] as Map<String, dynamic>?)?['teams']
              as List<dynamic>? ??
          [];
      if (!mounted) return;
      setState(() {
        _national = [
          for (final item in national)
            _copyTeam(item as Map<String, dynamic>),
        ];
        _ipl = [
          for (final item in ipl) _copyTeam(item as Map<String, dynamic>),
        ];
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

  Future<void> _publish() async {
    setState(() {
      _saving = true;
      _error = null;
      _message = null;
    });
    try {
      if (_tabs.index == 0) {
        final saved =
            await AdminSession.instance.api.saveNationalTeams(_national);
        _national = [
          for (final item in saved) _copyTeam(item as Map<String, dynamic>),
        ];
        _message = 'Published ${saved.length} national teams.';
      } else {
        final saved = await AdminSession.instance.api.saveIplTeams(_ipl);
        _ipl = [
          for (final item in saved) _copyTeam(item as Map<String, dynamic>),
        ];
        _message = 'Published ${saved.length} IPL teams.';
      }
      if (!mounted) return;
      setState(() => _saving = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _editTeam([int? index]) async {
    final existing = index == null
        ? <String, dynamic>{
            'id': '',
            'name': '',
            'shortName': '',
            'players': <Map<String, dynamic>>[],
          }
        : _copyTeam(_activeTeams[index]);

    final id = TextEditingController(text: '${existing['id'] ?? ''}');
    final name = TextEditingController(text: '${existing['name'] ?? ''}');
    final short =
        TextEditingController(text: '${existing['shortName'] ?? ''}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AdminColors.panel,
          title: Text(index == null ? 'Add team' : 'Edit team'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: id,
                  enabled: index == null,
                  decoration: const InputDecoration(
                    labelText: 'Team ID',
                    hintText: 'ind / mi',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: short,
                  decoration: const InputDecoration(labelText: 'Short name'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      final next = {
        ...existing,
        'id': id.text.trim().toLowerCase(),
        'name': name.text.trim(),
        'shortName': short.text.trim().toUpperCase(),
      };
      if (next['id'] == '' || next['name'] == '') {
        setState(() => _error = 'Team ID and name are required.');
      } else {
        setState(() {
          final teams = [..._activeTeams];
          if (index == null) {
            teams.add(next);
          } else {
            teams[index] = next;
          }
          _activeTeams = teams;
          _message = 'Draft updated — tap Publish to push live.';
        });
      }
    }

    id.dispose();
    name.dispose();
    short.dispose();
  }

  Future<void> _editPlayer(int teamIndex, [int? playerIndex]) async {
    final team = _copyTeam(_activeTeams[teamIndex]);
    final players = List<Map<String, dynamic>>.from(
      (team['players'] as List).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );
    final existing = playerIndex == null
        ? <String, dynamic>{
            'id': '',
            'name': '',
            'teamId': team['id'],
            'roles': <String>['batter'],
            'batRating': 70,
            'bowlRating': 40,
            'fieldRating': 70,
            'isOverseas': false,
          }
        : Map<String, dynamic>.from(players[playerIndex]);

    final id = TextEditingController(text: '${existing['id'] ?? ''}');
    final name = TextEditingController(text: '${existing['name'] ?? ''}');
    final bat = TextEditingController(text: '${existing['batRating'] ?? 70}');
    final bowl =
        TextEditingController(text: '${existing['bowlRating'] ?? 40}');
    final field =
        TextEditingController(text: '${existing['fieldRating'] ?? 70}');
    final selectedRoles = <String>{
      for (final role in (existing['roles'] as List<dynamic>? ?? const []))
        role.toString(),
    };
    var overseas = existing['isOverseas'] == true;
    final isIpl = _tabs.index == 1;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              backgroundColor: AdminColors.panel,
              title: Text(playerIndex == null ? 'Add player' : 'Edit player'),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: id,
                        enabled: playerIndex == null,
                        decoration: const InputDecoration(
                          labelText: 'Player ID',
                          hintText: 'ind_15',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: name,
                        decoration:
                            const InputDecoration(labelText: 'Player name'),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Roles',
                        style: TextStyle(color: AdminColors.mute),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final role in _roleOptions)
                            FilterChip(
                              label: Text(role),
                              selected: selectedRoles.contains(role),
                              onSelected: (selected) {
                                setLocal(() {
                                  if (selected) {
                                    selectedRoles.add(role);
                                  } else {
                                    selectedRoles.remove(role);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: bat,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration:
                                  const InputDecoration(labelText: 'Bat'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: bowl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration:
                                  const InputDecoration(labelText: 'Bowl'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: field,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration:
                                  const InputDecoration(labelText: 'Field'),
                            ),
                          ),
                        ],
                      ),
                      if (isIpl) ...[
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Overseas player'),
                          value: overseas,
                          onChanged: (value) =>
                              setLocal(() => overseas = value),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true) {
      final next = <String, dynamic>{
        'id': id.text.trim(),
        'name': name.text.trim(),
        'teamId': team['id'],
        'roles': selectedRoles.toList(),
        'batRating': int.tryParse(bat.text) ?? 70,
        'bowlRating': int.tryParse(bowl.text) ?? 40,
        'fieldRating': int.tryParse(field.text) ?? 70,
        'isOverseas': isIpl ? overseas : false,
      };
      if (next['id'] == '' ||
          next['name'] == '' ||
          (next['roles'] as List).isEmpty) {
        setState(() => _error = 'Player id, name, and at least one role required.');
      } else {
        if (playerIndex == null) {
          players.add(next);
        } else {
          players[playerIndex] = next;
        }
        setState(() {
          final teams = [..._activeTeams];
          teams[teamIndex] = {...team, 'players': players};
          _activeTeams = teams;
          _message = 'Draft updated — tap Publish to push live.';
        });
      }
    }

    id.dispose();
    name.dispose();
    bat.dispose();
    bowl.dispose();
    field.dispose();
  }

  void _deleteTeam(int index) {
    setState(() {
      final teams = [..._activeTeams]..removeAt(index);
      _activeTeams = teams;
      _message = 'Team removed locally — tap Publish to push live.';
    });
  }

  void _deletePlayer(int teamIndex, int playerIndex) {
    setState(() {
      final teams = [..._activeTeams];
      final team = _copyTeam(teams[teamIndex]);
      final players = List<Map<String, dynamic>>.from(
        (team['players'] as List).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      )..removeAt(playerIndex);
      teams[teamIndex] = {...team, 'players': players};
      _activeTeams = teams;
      _message = 'Player removed locally — tap Publish to push live.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Sports rosters',
                  style: TextStyle(
                    color: AdminColors.text,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _loading ? null : () => _editTeam(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add team'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _loading || _saving ? null : _publish,
                icon: const Icon(Icons.publish_rounded),
                label: Text(_saving ? 'Publishing…' : 'Publish'),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabs,
          onTap: (_) => setState(() {
            _error = null;
            _message = null;
          }),
          tabs: [
            Tab(text: 'National (${_national.length})'),
            Tab(text: 'IPL (${_ipl.length})'),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _error!,
                style: const TextStyle(color: AdminColors.danger),
              ),
            ),
          ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _message!,
                style: const TextStyle(color: AdminColors.ok),
              ),
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _TeamList(
                      teams: _national,
                      showOverseas: false,
                      onEditTeam: _editTeam,
                      onDeleteTeam: _deleteTeam,
                      onAddPlayer: (teamIndex) => _editPlayer(teamIndex),
                      onEditPlayer: _editPlayer,
                      onDeletePlayer: _deletePlayer,
                    ),
                    _TeamList(
                      teams: _ipl,
                      showOverseas: true,
                      onEditTeam: _editTeam,
                      onDeleteTeam: _deleteTeam,
                      onAddPlayer: (teamIndex) => _editPlayer(teamIndex),
                      onEditPlayer: _editPlayer,
                      onDeletePlayer: _deletePlayer,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TeamList extends StatelessWidget {
  const _TeamList({
    required this.teams,
    required this.showOverseas,
    required this.onEditTeam,
    required this.onDeleteTeam,
    required this.onAddPlayer,
    required this.onEditPlayer,
    required this.onDeletePlayer,
  });

  final List<Map<String, dynamic>> teams;
  final bool showOverseas;
  final Future<void> Function([int? index]) onEditTeam;
  final void Function(int index) onDeleteTeam;
  final void Function(int teamIndex) onAddPlayer;
  final Future<void> Function(int teamIndex, [int? playerIndex]) onEditPlayer;
  final void Function(int teamIndex, int playerIndex) onDeletePlayer;

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) {
      return const Center(
        child: Text(
          'No teams yet. Add a team to get started.',
          style: TextStyle(color: AdminColors.mute),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      itemCount: teams.length,
      itemBuilder: (context, teamIndex) {
        final team = teams[teamIndex];
        final players = (team['players'] as List<dynamic>? ?? const []);
        final overseasCount = players
            .where((p) => (p as Map)['isOverseas'] == true)
            .length;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              '${team['name']} (${team['shortName']})',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              '${team['id']} · ${players.length} players'
              '${showOverseas ? ' · $overseasCount overseas' : ''}',
              style: const TextStyle(color: AdminColors.mute),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => onEditTeam(teamIndex),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit team'),
                    ),
                    TextButton.icon(
                      onPressed: () => onAddPlayer(teamIndex),
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: const Text('Add player'),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => onDeleteTeam(teamIndex),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AdminColors.danger,
                      ),
                      label: const Text(
                        'Delete team',
                        style: TextStyle(color: AdminColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
              for (var p = 0; p < players.length; p++)
                ListTile(
                  dense: true,
                  title: Text(
                    '${players[p]['name']}'
                    '${showOverseas && players[p]['isOverseas'] == true ? '  ·  overseas' : ''}',
                  ),
                  subtitle: Text(
                    '${players[p]['id']} · '
                    '${((players[p]['roles'] as List?) ?? const []).join(', ')} · '
                    'B${players[p]['batRating']} / Bo${players[p]['bowlRating']} / F${players[p]['fieldRating']}',
                    style: const TextStyle(color: AdminColors.mute),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () => onEditPlayer(teamIndex, p),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () => onDeletePlayer(teamIndex, p),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AdminColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
