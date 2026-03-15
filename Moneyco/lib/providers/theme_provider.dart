import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final LocalStorageService _localStorageService;

  ThemeMode _themeMode = ThemeMode.dark;

  ThemeProvider(this._localStorageService) {
    _loadTheme();
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  Future<void> _loadTheme() async {
    final isDark = await _localStorageService.loadThemeMode();
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setDarkMode(bool isDark) async {
    final nextMode = isDark ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode == nextMode) return;
    _themeMode = nextMode;
    notifyListeners();
    await _localStorageService.saveThemeMode(isDark);
  }

  Future<void> toggleTheme() async {
    await setDarkMode(!isDarkMode);
  }
}
