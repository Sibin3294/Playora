import 'package:flutter/material.dart';
import 'package:playora_admin/session/admin_session.dart';
import 'package:playora_admin/theme/admin_theme.dart';

class PuzzlesScreen extends StatefulWidget {
  const PuzzlesScreen({super.key});

  @override
  State<PuzzlesScreen> createState() => _PuzzlesScreenState();
}

class _PuzzlesScreenState extends State<PuzzlesScreen> {
  List<Map<String, dynamic>> _puzzles = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      final catalog = await AdminSession.instance.api.catalog();
      final raw = catalog['sportsFacePuzzles'] as List<dynamic>? ?? [];
      if (!mounted) return;
      setState(() {
        _puzzles = [
          for (final item in raw)
            Map<String, dynamic>.from(item as Map<String, dynamic>),
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

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      _message = null;
    });
    try {
      final saved =
          await AdminSession.instance.api.saveSportsFacePuzzles(_puzzles);
      if (!mounted) return;
      setState(() {
        _puzzles = [
          for (final item in saved)
            Map<String, dynamic>.from(item as Map<String, dynamic>),
        ];
        _saving = false;
        _message = 'Published ${_puzzles.length} Face Reveal players.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _editPuzzle([int? index]) async {
    final existing = index == null
        ? <String, dynamic>{
            'id': '',
            'answer': '',
            'sport': 'Cricket',
            'country': '',
            'role': '',
            'accent': '#33F0FF',
            'imageAsset': '',
            'imageUrl': '',
            'options': <String>['', '', '', ''],
          }
        : Map<String, dynamic>.from(_puzzles[index]);

    final options = List<String>.from(
      (existing['options'] as List<dynamic>? ?? const [])
          .map((e) => e.toString()),
    );
    while (options.length < 4) {
      options.add('');
    }

    final id = TextEditingController(text: '${existing['id'] ?? ''}');
    final answer = TextEditingController(text: '${existing['answer'] ?? ''}');
    final country = TextEditingController(text: '${existing['country'] ?? ''}');
    final role = TextEditingController(text: '${existing['role'] ?? ''}');
    final accent = TextEditingController(text: '${existing['accent'] ?? '#33F0FF'}');
    final imageAsset =
        TextEditingController(text: '${existing['imageAsset'] ?? ''}');
    final optionCtrls =
        List.generate(4, (i) => TextEditingController(text: options[i]));

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AdminColors.panel,
          title: Text(index == null ? 'Add player' : 'Edit player'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: id,
                    decoration: const InputDecoration(
                      labelText: 'ID (slug)',
                      hintText: 'virat_kohli',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: answer,
                    decoration: const InputDecoration(labelText: 'Answer / name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: country,
                    decoration: const InputDecoration(labelText: 'Country'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: role,
                    decoration: const InputDecoration(labelText: 'Role'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: accent,
                    decoration: const InputDecoration(
                      labelText: 'Accent hex',
                      hintText: '#1B4F9C',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: imageAsset,
                    decoration: const InputDecoration(
                      labelText: 'Image asset (optional)',
                      hintText: 'assets/puzzles/...',
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Options (answer must be one of these)',
                      style: TextStyle(color: AdminColors.mute),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < 4; i++) ...[
                    TextField(
                      controller: optionCtrls[i],
                      decoration: InputDecoration(labelText: 'Option ${i + 1}'),
                    ),
                    const SizedBox(height: 8),
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

    if (saved != true) {
      id.dispose();
      answer.dispose();
      country.dispose();
      role.dispose();
      accent.dispose();
      imageAsset.dispose();
      for (final c in optionCtrls) {
        c.dispose();
      }
      return;
    }

    final next = <String, dynamic>{
      'id': id.text.trim(),
      'answer': answer.text.trim(),
      'sport': 'Cricket',
      'country': country.text.trim(),
      'role': role.text.trim(),
      'accent': accent.text.trim(),
      if (imageAsset.text.trim().isNotEmpty)
        'imageAsset': imageAsset.text.trim(),
      'options': [
        for (final c in optionCtrls)
          if (c.text.trim().isNotEmpty) c.text.trim(),
      ],
    };

    id.dispose();
    answer.dispose();
    country.dispose();
    role.dispose();
    accent.dispose();
    imageAsset.dispose();
    for (final c in optionCtrls) {
      c.dispose();
    }

    if (next['id'] == '' || next['answer'] == '') {
      setState(() => _error = 'ID and answer are required.');
      return;
    }

    setState(() {
      if (index == null) {
        _puzzles.add(next);
      } else {
        _puzzles[index] = next;
      }
      _message = 'Draft updated — tap Publish to push live.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Face Reveal players',
                  style: TextStyle(
                    color: AdminColors.text,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _loading ? null : () => _editPuzzle(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _loading || _saving ? null : _save,
                icon: const Icon(Icons.publish_rounded),
                label: Text(_saving ? 'Publishing…' : 'Publish'),
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(_error!, style: const TextStyle(color: AdminColors.danger)),
          ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(_message!, style: const TextStyle(color: AdminColors.ok)),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                  itemCount: _puzzles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final puzzle = _puzzles[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          '${puzzle['answer']}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${puzzle['country'] ?? ''} · ${puzzle['role'] ?? ''} · ${puzzle['id']}',
                          style: const TextStyle(color: AdminColors.mute),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () => _editPuzzle(index),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: () {
                                setState(() {
                                  _puzzles.removeAt(index);
                                  _message =
                                      'Removed locally — tap Publish to push live.';
                                });
                              },
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: AdminColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
