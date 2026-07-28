import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'state/library_controller.dart';

class CampusResourceTrackerApp extends StatefulWidget {
  const CampusResourceTrackerApp({
    required this.controller,
    this.showSplash = true,
    super.key,
  });

  final LibraryController controller;
  final bool showSplash;

  @override
  State<CampusResourceTrackerApp> createState() =>
      _CampusResourceTrackerAppState();
}

class _CampusResourceTrackerAppState extends State<CampusResourceTrackerApp> {
  late bool _showSplash;

  @override
  void initState() {
    super.initState();
    _showSplash = widget.showSplash;
    widget.controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Resource Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: _showSplash
          ? SplashScreen(
              onFinished: () {
                if (mounted) {
                  setState(() => _showSplash = false);
                }
              },
            )
          : MainShell(controller: widget.controller),
    );
  }
}
