import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/models/profile.dart';
import 'package:stocklio_flutter/services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  late final AdminService _adminService;

  AdminProvider({AdminService? adminService}) {
    _adminService = adminService ?? GetIt.instance<AdminService>();
  }

  // States
  List<Profile> _profiles = [];

  String? _selectedProfileId;
  bool _isSelectedProfileAnOrganization = false;

  Fuzzy<Profile> _fuse = Fuzzy([]);
  bool _isAdminPowersEnabled = true;

  bool get isAdminPowersEnabled => _isAdminPowersEnabled;

  set isAdminPowersEnabled(bool value) {
    _isAdminPowersEnabled = value;
    notifyListeners();
  }

  void setSelectedProfileId(
    String? selectedProfileId, [
    bool isSelectedProfileAnOrganization = false,
  ]) async {
    if (selectedProfileId == _selectedProfileId) return;

    _selectedProfileId = selectedProfileId;
    _adminService.selectedProfileId = selectedProfileId;
    _adminService.isSelectedProfileAnOrganization =
        isSelectedProfileAnOrganization;
    notifyListeners();
  }

  String? get selectedProfileId {
    _selectedProfileId = _adminService.selectedProfileId;
    return _selectedProfileId;
  }

  bool get isSelectedProfileAnOrganization {
    _isSelectedProfileAnOrganization =
        _adminService.isSelectedProfileAnOrganization;
    return _isSelectedProfileAnOrganization;
  }

  Future<void> fetchAndSetProfiles() async {
    _profiles = await _adminService.getAllProfiles();
    _loadFuse();
    notifyListeners();
  }

  // Getters
  List<Profile> get profiles {
    return [
      ..._profiles
        ..sort(((a, b) => (a.name ?? '')
            .toLowerCase()
            .compareTo((b.name ?? '').toLowerCase())))
    ];
  }

  void _loadFuse() {
    _fuse = Fuzzy(
      _profiles,
      options: FuzzyOptions(
        keys: [
          WeightedKey(
              name: 'name', getter: (Profile x) => x.name ?? '', weight: 1),
          WeightedKey(
              name: 'email', getter: (Profile x) => x.email ?? '', weight: 1),
        ],
        tokenize: true,
      ),
    );
  }

  List<Profile> search(String query) {
    final results = _fuse.search(query);
    return [...results.map((e) => e.item).toList()];
  }
}
