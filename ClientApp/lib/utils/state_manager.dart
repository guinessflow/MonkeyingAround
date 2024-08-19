import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StateManager {
  static const String _categoryGridScrollPositionKey = 'categoryGridScrollPosition';
  Future<void> saveCurrentIndex(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_index', index);
  }

  Future<int> restoreCurrentIndex() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('current_index') ?? 0;
  }

// Add other state management methods here as needed
  Future<void> saveSelectedCategoryIndex(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_category_index', index);
  }

  Future<int?> restoreSelectedCategoryIndex() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('selected_category_index');
  }

  Future<void> saveSelectedTabIndex(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_tab_index', index);
  }

  Future<int?> restoreSelectedTabIndex() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('selected_tab_index');
  }

  Future<void> saveCurrentAuthorsPage(int page) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_authors_page', page);
  }

  Future<int> restoreCurrentAuthorsPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('current_authors_page') ?? 1;
  }

  Future<void> saveCategoryGridScrollPosition(double position) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(_categoryGridScrollPositionKey, position);
  }

  Future<double?> restoreCategoryGridScrollPosition() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_categoryGridScrollPositionKey);
  }

  Future<void> saveSelectedThemeMode(ThemeMode themeMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedThemeMode', themeMode.index);
  }

  Future<ThemeMode> loadSelectedThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int themeIndex = prefs.getInt('selectedThemeMode') ?? ThemeMode.system.index;
    return ThemeMode.values[themeIndex];
  }

  // Save the selected font
  Future<void> saveSelectedFont(String fontFamily) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_font', fontFamily);
  }

  // Restore the selected font
  Future<String> restoreSelectedFont() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_font') ?? 'Quicksand';
  }
}
