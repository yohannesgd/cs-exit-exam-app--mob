import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _useSystemTheme = true;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get useSystemTheme => _useSystemTheme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final useSystem = prefs.getBool('useSystemTheme') ?? true;
    final useDark = prefs.getBool('darkMode') ?? false;
    
    _useSystemTheme = useSystem;
    
    if (_useSystemTheme) {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = useDark ? ThemeMode.dark : ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> toggleTheme(bool useDark) async {
    final prefs = await SharedPreferences.getInstance();
    
    // When manually toggling, disable system theme
    if (_useSystemTheme) {
      _useSystemTheme = false;
      await prefs.setBool('useSystemTheme', false);
    }
    
    _themeMode = useDark ? ThemeMode.dark : ThemeMode.light;
    await prefs.setBool('darkMode', useDark);
    notifyListeners();
  }

  Future<void> setUseSystemTheme(bool value) async {
    _useSystemTheme = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useSystemTheme', value);
    
    if (value) {
      _themeMode = ThemeMode.system;
    } else {
      final useDark = prefs.getBool('darkMode') ?? false;
      _themeMode = useDark ? ThemeMode.dark : ThemeMode.light;
    }
    
    notifyListeners();
  }
}