import 'package:shared_preferences/shared_preferences.dart';

import '../domain/adhan_settings.dart';
import '../domain/adhan_voice.dart';

/// Stores how the adhan alert behaves, on the device only.
abstract interface class AdhanRepository {
  /// Returns the saved choices.
  Future<AdhanSettings> load();

  /// Replaces the saved choices.
  Future<void> save(AdhanSettings settings);
}

/// SharedPreferences-backed [AdhanRepository].
class LocalAdhanRepository implements AdhanRepository {
  /// Creates a repository over [preferences].
  LocalAdhanRepository(this._preferences);

  final SharedPreferencesAsync _preferences;
  static const _voiceKey = 'adhan.voice';
  static const _playKey = 'adhan.play';
  static const _flipKey = 'adhan.flip';
  static const _customPathKey = 'adhan.customPath';
  static const _customNameKey = 'adhan.customName';

  @override
  Future<AdhanSettings> load() async {
    const defaults = AdhanSettings();
    return AdhanSettings(
      voiceId: await _preferences.getString(_voiceKey) ?? AdhanVoice.defaultId,
      playAdhan: await _preferences.getBool(_playKey) ?? defaults.playAdhan,
      stopWhenFlipped:
          await _preferences.getBool(_flipKey) ?? defaults.stopWhenFlipped,
      customPath: await _preferences.getString(_customPathKey),
      customName: await _preferences.getString(_customNameKey),
    );
  }

  @override
  Future<void> save(AdhanSettings settings) async {
    await _preferences.setString(_voiceKey, settings.voiceId);
    await _preferences.setBool(_playKey, settings.playAdhan);
    await _preferences.setBool(_flipKey, settings.stopWhenFlipped);
    final path = settings.customPath;
    final name = settings.customName;
    if (path == null) {
      await _preferences.remove(_customPathKey);
      await _preferences.remove(_customNameKey);
    } else {
      await _preferences.setString(_customPathKey, path);
      if (name != null) await _preferences.setString(_customNameKey, name);
    }
  }
}
