import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/models/organization.dart';
import 'package:stocklio_flutter/models/response.dart';

import 'package:stocklio_flutter/services/organization_service.dart';
import 'package:stocklio_flutter/services/profile_service.dart';

class OrganizationProvider extends ChangeNotifier {
  late final OrganizationService _organizationService;
  late final ProfileService _profileService;

  OrganizationProvider({
    OrganizationService? organizationService,
    ProfileService? profileService,
  })  : _organizationService =
            organizationService ?? GetIt.instance<OrganizationService>(),
        _profileService = profileService ?? GetIt.instance<ProfileService>();

  // States
  Organization _organization = Organization();

  StreamSubscription<Organization>? _organizationStreamSub;

  bool _isLoading = true;
  bool _isInit = false;
  String? _selectedSubsidiaryId;

  Organization get organization {
    _organizationStreamSub ?? _listenToOrgStream();
    return _organization;
  }

  Future<Response<Organization>> fetchOrg() async {
    final response = await _profileService.fetchOrg();
    return Response(data: response.data, hasError: response.hasError);
  }

  void setSelectedSubsidiaryId(String? selectedSubsidiaryId) {
    if (selectedSubsidiaryId == _selectedSubsidiaryId) return;

    _selectedSubsidiaryId = selectedSubsidiaryId;
    _organizationService.selectedSubsidiaryId = selectedSubsidiaryId;
    notifyListeners();
  }

  String? get selectedSubsidiaryId {
    _selectedSubsidiaryId = _organizationService.selectedSubsidiaryId;
    return _selectedSubsidiaryId;
  }

  // Getters
  bool get isLoading => _isLoading;

  Future<void>? cancelStreamSubscriptions() async {
    await _organizationStreamSub?.cancel();
  }

  void _listenToOrgStream() {
    final orgStream = _profileService.getOrgStream();
    _organizationStreamSub = orgStream.listen((Organization org) {
      _organization = org;
      if (!_isInit) {
        _isInit = true;
        _isLoading = false;
      }

      notifyListeners();
    });
  }
}
