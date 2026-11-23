import 'package:mre_quran/features/fasting/data/fasting_repository.dart';
import 'package:mre_quran/features/fasting/domain/sunnah_fasts.dart';

/// Keeps the fasting reminders' choices in memory.
class MemoryFastingRepository implements FastingRepository {
  /// The choices; every fast on by default, as on a new install.
  FastingSettings settings = const FastingSettings();

  @override
  Future<FastingSettings> load() async => settings;

  @override
  Future<void> save(FastingSettings value) async => settings = value;
}
