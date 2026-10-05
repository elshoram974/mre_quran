import 'package:mre_quran/features/settings/data/settings_repository.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';

class MemorySettingsRepository implements SettingsRepository {
  AppSettings settings = const AppSettings();
  bool fail = false;

  @override
  Future<AppSettings> load() async {
    if (fail) throw StateError('Storage unavailable');
    return settings;
  }

  @override
  Future<void> save(AppSettings value) async {
    if (fail) throw StateError('Storage unavailable');
    settings = value;
  }
}
