import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

const _prefsKey = 'app_locale';

final localeControllerProvider =
    StateNotifierProvider<LocaleController, Locale>((ref) {
  return LocaleController();
});

class LocaleController extends StateNotifier<Locale> {
  LocaleController() : super(const Locale('en')) {
    _load();
  }

  Future<void> setLocale(Locale locale) async {
    if (!AppLocalizations.supportedLocales
        .any((l) => l.languageCode == locale.languageCode)) {
      return;
    }
    state = Locale(locale.languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, state.languageCode);
  }

  Future<void> toggleEnAr() async {
    final next = (state.languageCode == 'ar') ? const Locale('en') : const Locale('ar');
    await setLocale(next);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == null) return;
    final locale = Locale(code);
    if (AppLocalizations.supportedLocales
        .any((l) => l.languageCode == locale.languageCode)) {
      state = locale;
    }
  }
}

