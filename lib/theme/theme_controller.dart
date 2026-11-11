import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's light/dark choice, set from Profile and remembered on this phone.
class ThemeController extends ChangeNotifier {
  static const _key = 'themeMode';

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;

  /// Reads the saved choice. Light is the default.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _mode = ThemeMode.values.firstWhere(
        (m) => m.name == prefs.getString(_key),
        orElse: () => ThemeMode.light,
      );
    } catch (_) {
      // Storage unavailable: keep the default.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {}
  }
}
