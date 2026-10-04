import 'package:flutter/material.dart';
import '../data/settings_repository.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._repository);

  final SettingsRepository _repository;
  ThemeMode _themeMode = ThemeMode.system;
  bool _saving = false;
  String? _error;

  ThemeMode get themeMode => _themeMode;
  bool get saving => _saving;
  String? get error => _error;

  Future<void> load() async {
    try {
      _themeMode = await _repository.loadThemeMode();
      _error = null;
    } catch (_) {
      _error = 'تعذّر تحميل الإعدادات. يمكنك المحاولة مجددًا.';
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_saving || mode == _themeMode) return;
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.saveThemeMode(mode);
      _themeMode = mode;
    } catch (_) {
      _error = 'تعذّر حفظ المظهر. حاول مرة أخرى.';
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
