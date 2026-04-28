import 'package:shared_preferences/shared_preferences.dart';

class DemoConfig {
  static bool isDemoMode = false;

  static const _key = 'isDemoMode';

  /// Load persisted value (call before runApp)
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isDemoMode = prefs.getBool(_key) ?? false;
    } catch (_) {
      isDemoMode = false;
    }
  }

  static Future<void> setDemo(bool value) async {
    isDemoMode = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {}
  }
}
