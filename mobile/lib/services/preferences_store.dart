import 'package:shared_preferences/shared_preferences.dart';

abstract class PreferencesStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
}

class LocalPreferencesStore implements PreferencesStore {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  @override
  Future<String?> getString(String key) => _preferences.getString(key);
  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);
}
