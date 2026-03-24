import 'package:flutter/cupertino.dart';

import '../screens/home_shell.dart';
import '../services/app_storage.dart';

void runPomodoroApp() {
  runApp(const PomodoroApp());
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({
    this.storage = const SqliteAppStorage(),
    super.key,
  });

  final AppStorage storage;

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Anki Cupertino',
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.systemOrange,
        scaffoldBackgroundColor: Color(0xFF111216),
        barBackgroundColor: Color(0xCC16181D),
      ),
      home: HomeShell(storage: storage),
    );
  }
}
