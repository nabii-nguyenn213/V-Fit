import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/network_providers.dart';

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeController(prefs.getBool('vfit.darkMode') == true, prefs.setBool);
});

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController(bool darkMode, this._save)
      : super(darkMode ? ThemeMode.dark : ThemeMode.light);

  final Future<bool> Function(String key, bool value) _save;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == state) {
      return;
    }
    state = mode;
    await _save('vfit.darkMode', mode == ThemeMode.dark);
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }
}
