import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSettingsProvider with ChangeNotifier {
  String? _languagePreference;
  String? get languagePreference => _languagePreference;

  Future<String?> getSavedLanguagePref() async {
    final languagePreference = await SharedPreferences.getInstance();
    _languagePreference = languagePreference.getString('language');
    return _languagePreference;
  }

  Future<void> setPreferedLanguage(String locale) async {
    final languagePreference = await SharedPreferences.getInstance();

    await languagePreference.setString('language', locale);
    _languagePreference = languagePreference.getString('language');
    notifyListeners();
  }
}
