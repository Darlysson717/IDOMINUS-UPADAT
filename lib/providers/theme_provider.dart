import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool _useSystemTheme = true;

  bool get isDarkMode => _isDarkMode;
  bool get useSystemTheme => _useSystemTheme;

  ThemeMode get themeMode {
    if (_useSystemTheme) {
      return ThemeMode.system;
    }
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _useSystemTheme = prefs.getBool('useSystemTheme') ?? true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    _useSystemTheme = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    await prefs.setBool('useSystemTheme', false);
  }

  Future<void> setUseSystemTheme(bool value) async {
    _useSystemTheme = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useSystemTheme', value);
  }

  Future<void> toggleTheme() async {
    if (_useSystemTheme) {
      // Se estava usando sistema, alterna para manual com base no sistema atual
      final brightness = WidgetsBinding.instance.window.platformBrightness;
      _isDarkMode = brightness == Brightness.dark;
      _useSystemTheme = false;
    } else {
      _isDarkMode = !_isDarkMode;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('useSystemTheme', _useSystemTheme);
  }
}