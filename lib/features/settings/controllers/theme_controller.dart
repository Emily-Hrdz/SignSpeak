import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({bool isDarkMode = false}) : _isDarkMode = isDarkMode;

  static const _preferenceKey = 'dark_mode_enabled';
  bool _isDarkMode;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  static Future<ThemeController> load() async {
    final preferences = await SharedPreferences.getInstance();
    return ThemeController(
      isDarkMode: preferences.getBool(_preferenceKey) ?? false,
    );
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_preferenceKey, _isDarkMode);
  }
}
