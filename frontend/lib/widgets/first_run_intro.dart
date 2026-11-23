import 'package:flutter/material.dart';
import 'package:guess_game/intro/first_run_store.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/neon_button.dart';

class FirstRunPage {
  const FirstRunPage({
    required this.title,
    required this.body,
    required this.accent,
    this.icon = Icons.auto_awesome_rounded,
  });

  final String title;
  final String body;
  final Color accent;
  final IconData icon;
}

/// Shows a one-time multi-page intro if [id] has never been seen.
Future<void> maybeShowFirstRunIntro(
  BuildContext context, {
  required String id,
  required List<FirstRunPage> pages,
}) async {
  if (pages.isEmpty) return;
  final show = await FirstRunStore.instance.shouldShow(id);
  if (!show || !context.mounted) return;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'First run intro',
    barrierColor: Colors.black.withOpacity(0.72),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _FirstRunIntroDialog(id: id, pages: pages);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _FirstRunIntroDialog extends StatefulWidget {
  const _FirstRunIntroDialog({
    required this.id,
    required this.pages,
  });

  final String id;
  final List<FirstRunPage> pages;

  @override
  State<_FirstRunIntroDialog> createState() => _FirstRunIntroDialogState();
}

class _FirstRunIntroDialogState extends State<_FirstRunIntroDialog> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await FirstRunStore.instance.markSeen(widget.id);
    if (mounted) Navigator.of(context).pop();
  }

  void _next() {
    if (_index >= widget.pages.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.pages[_index];
    final isLast = _index == widget.pages.length - 1;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: panelDecoration(glow: page.accent),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'QUICK INTRO',
                        style: hudLabelStyle(color: page.accent, size: 11),
                      ),
                      const Spacer(),
                      Text(
                        '${_index + 1}/${widget.pages.length}',
                        style: hudLabelStyle(size: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 220,
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: widget.pages.length,
                      onPageChanged: (value) => setState(() => _index = value),
                      itemBuilder: (context, index) {
                        final item = widget.pages[index];
                        return Column(
                          children: [
                            Icon(item.icon, color: item.accent, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: item.accent,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.body,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: GameColors.mute,
                                height: 1.4,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < widget.pages.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: i == _index ? 18 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? page.accent
                                : GameColors.panelBorder,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  NeonButton(
                    label: isLast ? 'GOT IT' : 'NEXT',
                    color: page.accent,
                    height: 48,
                    onPressed: _next,
                  ),
                  if (!isLast) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        'SKIP',
                        style: hudLabelStyle(color: GameColors.mute, size: 11),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
