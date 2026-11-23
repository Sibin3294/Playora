import 'package:flutter/material.dart';
import 'package:playora_admin/screens/login_screen.dart';
import 'package:playora_admin/screens/shell_screen.dart';
import 'package:playora_admin/session/admin_session.dart';
import 'package:playora_admin/theme/admin_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdminSession.instance.bootstrap();
  runApp(const PlayoraAdminApp());
}

class PlayoraAdminApp extends StatelessWidget {
  const PlayoraAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Playora Admin',
      debugShowCheckedModeBanner: false,
      theme: buildAdminTheme(),
      home: ListenableBuilder(
        listenable: AdminSession.instance,
        builder: (context, _) {
          final session = AdminSession.instance;
          if (!session.bootstrapped) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return session.loggedIn
              ? const ShellScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
