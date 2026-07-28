import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/api_service.dart';
import 'services/cache_service.dart';
import 'state/library_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final controller = LibraryController(
    api: HttpLibraryApi(),
    cache: PreferencesStatusCache(preferences),
  );
  runApp(CampusResourceTrackerApp(controller: controller));
}
