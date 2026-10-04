import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/quran_app.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/settings/presentation/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsController(
    LocalSettingsRepository(SharedPreferencesAsync()),
  );
  await settings.load();
  runApp(QuranApp(settings: settings));
}
