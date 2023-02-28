// Flutter Packages
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

// 3rd-Party Packages
import 'package:get_it/get_it.dart';

// Models
import '../../models/count_area.dart';

// Services
import '../../services/count_area_service.dart';

class CountAreaProvider with ChangeNotifier {
  late CountAreaService _countAreaService;

  CountAreaProvider({
    CountAreaService? countAreaService,
  }) {
    _countAreaService = countAreaService ?? GetIt.instance<CountAreaService>();
  }

  // States
  List<CountArea> _countAreas = [];
  StreamSubscription<List<CountArea>>? _countAreasStreamSub;
  bool _isLoading = true;
  bool _isInit = false;

  // Getters
  bool get isLoading => _isLoading;
  List<CountArea> get countAreas {
    _countAreasStreamSub ?? _listenToCountAreasStream();

    return [..._countAreas];
  }

  Future<void>? cancelStreamSubscriptions() {
    return _countAreasStreamSub?.cancel();
  }

  void _listenToCountAreasStream() {
    _countAreasStreamSub = _countAreaService
        .getCountAreasStream()
        .listen((List<CountArea> countAreas) {
      _countAreas = countAreas;

      if (_countAreas.isNotEmpty) {
        selectedAreaId = _countAreas.first.id!;
      }

      if (!_isInit) {
        _isInit = true;
        _isLoading = false;
      }

      notifyListeners();
    });
  }

  Future<void> updateAreaName(
    CountArea countArea,
    String newCountAreaName,
  ) async {
    await _countAreaService.updateCountArea(
      countArea.copyWith(
        name: newCountAreaName,
      ),
    );
  }

  Future<void> updateAreaDeleted(String countAreaId) async {
    await _countAreaService.softDeleteCountArea(countAreaId);
  }

  Future<void> createArea(String countAreaName) async {
    await _countAreaService.createCountArea(CountArea(name: countAreaName));
  }

  @override
  void dispose() {
    cancelStreamSubscriptions();
    super.dispose();
  }

  // UI States
  String _selectedAreaId = '';

  String get selectedAreaId => _selectedAreaId;

  set selectedAreaId(String areaId) {
    _selectedAreaId = areaId;
    notifyListeners();
  }

  CountArea? findAreaById(String id) {
    return _countAreas.firstWhereOrNull((element) => element.id == id);
  }
}
