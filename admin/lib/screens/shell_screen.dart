import 'package:flutter/material.dart';
import 'package:playora_admin/screens/categories_screen.dart';
import 'package:playora_admin/screens/dashboard_screen.dart';
import 'package:playora_admin/screens/puzzles_screen.dart';
import 'package:playora_admin/screens/sports_rosters_screen.dart';
import 'package:playora_admin/session/admin_session.dart';
import 'package:playora_admin/theme/admin_theme.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  static const _pages = [
    DashboardScreen(),
    SportsRostersScreen(),
    PuzzlesScreen(),
    CategoriesScreen(),
  ];

  static const _labels = [
    'Overview',
    'Sports',
    'Puzzles',
    'Categories',
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final email = AdminSession.instance.email ?? 'admin';

    final nav = NavigationRail(
      selectedIndex: _index,
      onDestinationSelected: (value) => setState(() => _index = value),
      backgroundColor: AdminColors.panel,
      indicatorColor: AdminColors.accent.withOpacity(0.18),
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 24),
        child: Column(
          children: [
            const Text(
              'PLAYORA',
              style: TextStyle(
                color: AdminColors.accent,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ADMIN',
              style: TextStyle(
                color: AdminColors.mute.withOpacity(0.9),
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: Text('Overview'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.sports_cricket_outlined),
          selectedIcon: Icon(Icons.sports_cricket_rounded),
          label: Text('Sports'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.face_retouching_natural_outlined),
          selectedIcon: Icon(Icons.face_retouching_natural),
          label: Text('Puzzles'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.category_outlined),
          selectedIcon: Icon(Icons.category_rounded),
          label: Text('Categories'),
        ),
      ],
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: IconButton(
              tooltip: 'Log out ($email)',
              onPressed: () => AdminSession.instance.logout(),
              icon: const Icon(Icons.logout_rounded, color: AdminColors.danger),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      body: Row(
        children: [
          if (wide) nav,
          Expanded(
            child: Column(
              children: [
                if (!wide)
                  Material(
                    color: AdminColors.panel,
                    child: SafeArea(
                      bottom: false,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var i = 0; i < _labels.length; i++)
                              TextButton(
                                onPressed: () => setState(() => _index = i),
                                child: Text(
                                  _labels[i],
                                  style: TextStyle(
                                    color: _index == i
                                        ? AdminColors.accent
                                        : AdminColors.mute,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            IconButton(
                              onPressed: () => AdminSession.instance.logout(),
                              icon: const Icon(
                                Icons.logout_rounded,
                                color: AdminColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(child: _pages[_index]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
