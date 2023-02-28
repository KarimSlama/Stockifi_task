import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fuzzy/fuzzy.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:stocklio_flutter/models/profile.dart';
import 'package:stocklio_flutter/services/profile_service.dart';

class SubsidiariesProvider extends ChangeNotifier {
  late final ProfileService _profileService;

  SubsidiariesProvider({
    ProfileService? profileService,
  }) : _profileService = profileService ?? GetIt.instance<ProfileService>();

  List<Profile> _profiles = [];
  bool _isLoading = true;
  bool _isInit = false;
  Fuzzy<Profile> _fuse = Fuzzy([]);
  StreamSubscription<List<Profile>>? _profilesStreamSub;
  bool _isSortedByName = true;
  bool _isSortedByCostPercentage = false;
  bool _isListReversed = false;

  // Getters
  bool get isLoading => _isLoading;
  bool get isListReversed => _isListReversed;
  bool get isSortedByName => _isSortedByName;
  bool get isSortedByCostPercentage => _isSortedByCostPercentage;

  final Map<String, num?> _costPercentages = {};
  final Map<String, String> _countDates = {};

  List<Profile> _getProfilesWithCostPercentages() {
    return _profiles
        .where((element) => _costPercentages[element.id!] != null)
        .toList();
  }

  bool get isSortByCostPercentageEnabled =>
      _getProfilesWithCostPercentages().isNotEmpty;

  List<Profile> get profiles {
    _profilesStreamSub ?? _listenToProfilesStream();

    List<Profile> profiles = [];

    if (_isSortedByName) {
      profiles = [
        ..._profiles
          ..sort(((a, b) => (a.name ?? '')
              .toLowerCase()
              .compareTo((b.name ?? '').toLowerCase())))
      ];
    } else if (_isSortedByCostPercentage) {
      final profilesWithCostPercentages = _getProfilesWithCostPercentages();

      final sortedProfiles = [
        ...profilesWithCostPercentages
          ..sort(((a, b) =>
              (_costPercentages[a.id]!).compareTo(_costPercentages[b.id]!))),
      ];

      final unsortedProfiles = [
        ..._profiles.where((element) => _costPercentages[element.id!] == null)
      ];

      profiles = [
        ...sortedProfiles,
        ...unsortedProfiles,
      ];
    } else {
      profiles = [..._profiles];
    }

    if (_isListReversed) {
      profiles = profiles.reversed.toList();
    }
    return profiles;
  }

  set isSortedByName(bool value) {
    _isSortedByName = value;

    if (_isSortedByName) {
      _isSortedByCostPercentage = false;
    }

    notifyListeners();
  }

  set isSortedByCostPercentage(bool value) {
    _isSortedByCostPercentage = value;

    if (_isSortedByCostPercentage) {
      _isSortedByName = false;
    }

    notifyListeners();
  }

  void toggleIsListReversed() {
    _isListReversed = !_isListReversed;
    notifyListeners();
  }

  Future<void>? cancelStreamSubscriptions() async {
    await _profilesStreamSub?.cancel();
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

  String _formatDate(int timestamp) => DateFormat("dd-MMM-''yy")
      .format(DateTime.fromMillisecondsSinceEpoch(timestamp));

  void _listenToProfilesStream() async {
    _profilesStreamSub = _profileService
        .getOrgProfilesStreams()
        .listen((List<Profile> profiles) async {
      for (var i = 0; i < profiles.length; i++) {
        final latestCount = await _profileService
            .fetchLatestCount(profiles[i].id!)
            .then((value) => value.data);

        _costPercentages.putIfAbsent(
            profiles[i].id!, () => latestCount?.costPercentage);

        final startTime = latestCount?.startTime ?? 0;
        final endTime = latestCount?.endTime ?? 0;
        if (startTime != 0 && endTime != 0) {
          final startDate = _formatDate(startTime);
          final endDate = _formatDate(endTime);
          final countDate = '$startDate - $endDate';
          _countDates.putIfAbsent(profiles[i].id!, () => countDate);
        }
      }

      _profiles = profiles;

      _loadFuse();
      if (!_isInit) {
        _isInit = true;
        _isLoading = false;
      }

      notifyListeners();
    });
  }

  List<Profile> search(String query) {
    final results = _fuse.search(query);
    return [...results.map((e) => e.item).toList()];
  }

  num? getLatestCountCostPercentage(String profileId) =>
      _costPercentages[profileId];

  String? getLatestCountDate(String profileId) => _countDates[profileId];
}
