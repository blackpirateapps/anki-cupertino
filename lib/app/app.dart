import 'package:flutter/cupertino.dart';

import '../screens/home_shell.dart';

void runPomodoroApp() {
  runApp(const PomodoroApp());
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

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
      home: HomeShell(),
    );
  }
}

