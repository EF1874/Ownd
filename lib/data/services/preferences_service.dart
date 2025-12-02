import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError();
});

class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static const _keyIsGridView = 'is_grid_view';
  static const _keySortBy = 'sort_by';

  bool get isGridView => _prefs.getBool(_keyIsGridView) ?? false;

  Future<void> setGridView(bool value) async {
    await _prefs.setBool(_keyIsGridView, value);
  }

  String get sortBy => _prefs.getString(_keySortBy) ?? 'date_desc';

  Future<void> setSortBy(String value) async {
    await _prefs.setString(_keySortBy, value);
  }
}
