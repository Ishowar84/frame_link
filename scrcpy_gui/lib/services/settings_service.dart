import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

/// Service to persist and manage app settings
class SettingsService extends ChangeNotifier {
  static const String _settingsKey = 'app_settings';
  AppSettings _settings = const AppSettings();
  bool _isLoaded = false;

  AppSettings get settings => _settings;
  bool get isLoaded => _isLoaded;

  /// Load settings from persistent storage
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_settingsKey);

      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _settings = AppSettings.fromJson(json);
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load settings: $e');
      _isLoaded = true;
    }
  }

  /// Save settings to persistent storage
  Future<void> saveSettings(AppSettings newSettings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(newSettings.toJson());
      await prefs.setString(_settingsKey, jsonString);

      _settings = newSettings;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }

  /// Update a single setting
  Future<void> updateSetting(AppSettings Function(AppSettings) updater) async {
    final newSettings = updater(_settings);
    await saveSettings(newSettings);
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    await saveSettings(const AppSettings());
  }
}
