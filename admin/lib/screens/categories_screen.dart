import 'package:flutter/material.dart';
import 'package:playora_admin/session/admin_session.dart';
import 'package:playora_admin/theme/admin_theme.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Map<String, dynamic>> _categories = [];
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
      final raw = catalog['hubCategories'] as List<dynamic>? ?? [];
      if (!mounted) return;
      setState(() {
        _categories = [
          for (final item in raw) _deepCopyCategory(item as Map<String, dynamic>),
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

  Map<String, dynamic> _deepCopyCategory(Map<String, dynamic> source) {
    return {
      ...source,
      'games': [
        for (final game in (source['games'] as List<dynamic>? ?? const []))
          Map<String, dynamic>.from(game as Map<String, dynamic>),
      ],
    };
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      _message = null;
    });
    try {
      final saved =
          await AdminSession.instance.api.saveHubCategories(_categories);
      if (!mounted) return;
      setState(() {
        _categories = [
          for (final item in saved)
            _deepCopyCategory(item as Map<String, dynamic>),
        ];
        _saving = false;
        _message = 'Published hub categories.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _editCategory(int index) async {
    final category = _deepCopyCategory(_categories[index]);
    final title = TextEditingController(text: '${category['title'] ?? ''}');
    final subtitle =
        TextEditingController(text: '${category['subtitle'] ?? ''}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AdminColors.panel,
          title: Text('Edit ${category['id']}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: subtitle,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Subtitle'),
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
      setState(() {
        _categories[index] = {
          ...category,
          'title': title.text.trim(),
          'subtitle': subtitle.text.trim(),
        };
        _message = 'Draft updated — tap Publish to push live.';
      });
    }
    title.dispose();
    subtitle.dispose();
  }

  Future<void> _editGame(int categoryIndex, int gameIndex) async {
    final games = List<Map<String, dynamic>>.from(
      (_categories[categoryIndex]['games'] as List).map(
        (e) => Map<String, dynamic>.from(e as Map<String, dynamic>),
      ),
    );
    final game = Map<String, dynamic>.from(games[gameIndex]);
    final title = TextEditingController(text: '${game['title'] ?? ''}');
    final tagline = TextEditingController(text: '${game['tagline'] ?? ''}');
    var availability = '${game['availability'] ?? 'playable'}';

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              backgroundColor: AdminColors.panel,
              title: Text('Edit ${game['id']}'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: tagline,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Tagline'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: availability,
                      decoration:
                          const InputDecoration(labelText: 'Availability'),
                      items: const [
                        DropdownMenuItem(
                          value: 'playable',
                          child: Text('playable'),
                        ),
                        DropdownMenuItem(
                          value: 'comingSoon',
                          child: Text('comingSoon'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setLocal(() => availability = value);
                        }
                      },
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
      },
    );

    if (ok == true) {
      games[gameIndex] = {
        ...game,
        'title': title.text.trim(),
        'tagline': tagline.text.trim(),
        'availability': availability,
      };
      setState(() {
        _categories[categoryIndex] = {
          ..._categories[categoryIndex],
          'games': games,
        };
        _message = 'Draft updated — tap Publish to push live.';
      });
    }
    title.dispose();
    tagline.dispose();
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
                  'Hub categories',
                  style: TextStyle(
                    color: AdminColors.text,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
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
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final games =
                        (category['games'] as List<dynamic>? ?? const []);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Text(
                          '${category['title']}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${category['id']} · ${games.length} games',
                          style: const TextStyle(color: AdminColors.mute),
                        ),
                        trailing: IconButton(
                          tooltip: 'Edit category',
                          onPressed: () => _editCategory(index),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        children: [
                          for (var g = 0; g < games.length; g++)
                            ListTile(
                              title: Text('${games[g]['title']}'),
                              subtitle: Text(
                                '${games[g]['id']} · ${games[g]['availability']}',
                                style: const TextStyle(color: AdminColors.mute),
                              ),
                              trailing: IconButton(
                                onPressed: () => _editGame(index, g),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
