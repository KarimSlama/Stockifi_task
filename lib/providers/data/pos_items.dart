// Flutter Packages
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fuzzy/data/result.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:collection/collection.dart';

// 3rd-Party Packages
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/models/response.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';

// Models
import '../../models/pos_item.dart';

// Services
import '../../services/pos_item_service.dart';
import '../../utils/logger_util.dart';

class PosItemProvider with ChangeNotifier {
  late PosItemService _posItemService;

  PosItemProvider({
    PosItemService? posItemService,
  }) {
    _posItemService = posItemService ?? GetIt.instance<PosItemService>();
  }

  // States
  List<PosItem> _posItems = [];
  StreamSubscription? _posItemsStreamSub;
  bool _isLoading = true;
  bool _isInit = false;
  Fuzzy<PosItem> _fuse = Fuzzy([]);

  List<PosItem> _archivedPosItems = [];
  StreamSubscription? _archivedPosItemsStreamSub;
  bool _isLoadingArchivedPosItems = true;
  bool _isArchivedPosItemsInit = false;
  Fuzzy<PosItem> _archivedPosItemsFuse = Fuzzy([]);

  final _units = ['ml', 'g', 'pcs'];
  Set<String> itemsInPOS = {};
  bool _showArchived = false;

  // Getters
  bool get showArchived => _showArchived;
  List<String> get units => [..._units];
  bool get isLoading => _isLoading;
  bool get isLoadingArchivedPosItems => _isLoadingArchivedPosItems;

  List<PosItem> get posItems {
    _posItemsStreamSub ?? _listenToPosItemsStream();
    return [..._posItems];
  }

  List<PosItem> getArchivedPosItems() {
    _archivedPosItemsStreamSub ?? _listenToArchivedPosItemsStream();
    return [..._archivedPosItems];
  }

  Future<void>? cancelStreamSubscriptions() {
    return _posItemsStreamSub?.cancel();
  }

  PosItem? findById(
    String id, {
    bool archivedIncluded = true,
  }) {
    return [
      ..._posItems,
      if (archivedIncluded) ..._archivedPosItems,
    ].firstWhereOrNull((element) => element.id == id);
  }

  void toggleShowArchived() {
    _showArchived = !_showArchived;
    notifyListeners();
  }

  void _listenToPosItemsStream() {
    _posItemsStreamSub =
        _posItemService.getPosItemsStream().listen((List<PosItem> posItems) {
      _posItems = posItems;

      _loadFuse();
      if (!_isInit) {
        _isInit = true;
        _isLoading = false;
      }

      notifyListeners();
    });
  }

  void _listenToArchivedPosItemsStream() {
    final archivedPosItemsStream =
        _posItemService.getPosItemsStream(isFetchingArchived: true);
    _archivedPosItemsStreamSub =
        archivedPosItemsStream.listen((List<PosItem> posItems) {
      _archivedPosItems = posItems;

      _archivedPosItemsFuse = Fuzzy(
        getArchivedPosItems().toList(),
        options: FuzzyOptions(
          keys: [
            WeightedKey(
              name: 'name',
              getter: (PosItem x) => x.posData['name']!,
              weight: 1,
            ),
            WeightedKey(
              name: 'items',
              getter: (PosItem x) {
                return (x.items).keys.toString();
              },
              weight: 0.8,
            ),
          ],
          tokenize: true,
        ),
      );

      if (!_isArchivedPosItemsInit) {
        _isArchivedPosItemsInit = true;
        _isLoadingArchivedPosItems = false;
      }
      notifyListeners();
    });
  }

  Future<Response> updatePOSItem(
    PosItem posItem, {
    String? taskId,
  }) async {
    try {
      await _posItemService.updatePOSItem(posItem, taskId: taskId);

      logger.i('PosItemProvider - updatePOSItem is successful');
      return Response(message: 'POS Item updated');
    } catch (error, stackTrace) {
      logger.e('PosItemProvider - updatePOSItem failed\n$error\n$stackTrace');

      SentryUtil.error(
          'PosItemProvider.updatePOSItem() error: PosItem $posItem',
          'PosItemProvider class',
          error,
          stackTrace);
      return Response(message: 'POS Item updated', hasError: true);
    }
  }

  Future<Response> setArchived(String posItemId) async {
    try {
      await _posItemService.setArchived(posItemId, true);

      logger.i('PosItemProvider - setArchived is successful');
      return Response(message: 'POS Item updated');
    } catch (error, stackTrace) {
      logger.e('PosItemProvider - setArchived failed\n$error\n$stackTrace');

      SentryUtil.error(
        'PosItemProvider.setArchived() error: PosItem $posItemId',
        'PosItemProvider class',
        error,
        stackTrace,
      );
      return Response(message: 'POS Item archived', hasError: true);
    }
  }

  Future<Response> unarchivePOSItem(String posItemId) async {
    try {
      await _posItemService.setArchived(posItemId, false);

      logger.i('PosItemProvider - unsetArchived is successful');
      return Response(message: 'POS Item updated');
    } catch (error, stackTrace) {
      logger.e('PosItemProvider - unsetArchived failed\n$error\n$stackTrace');

      SentryUtil.error(
        'PosItemProvider.unsetArchived() error: PosItem $posItemId',
        'PosItemProvider class',
        error,
        stackTrace,
      );
      return Response(message: 'POS Item removed from archive', hasError: true);
    }
  }

  bool isItemOrRecipeInAnyPosItem(String itemId) {
    var value = false;

    for (var posItem in _posItems) {
      if (posItem.items.containsKey(itemId)) {
        itemsInPOS.add(posItem.id!);
      }
    }
    for (var posItem in _posItems) {
      value = posItem.items.containsKey(itemId);
      if (value == true) break;
    }

    return value;
  }

  List<PosItem> search(
    String query, {
    bool searchArchivedPosItems = false,
  }) {
    List<Result<PosItem>> results = [];

    if (searchArchivedPosItems) {
      results = _archivedPosItemsFuse.search(query);
    } else {
      results = _fuse.search(query);
    }

    return [...results.map((e) => e.item).toList()];
  }

  void _loadFuse() {
    _fuse = Fuzzy(
      _posItems,
      options: FuzzyOptions(
        keys: [
          WeightedKey(
            name: 'name',
            getter: (PosItem x) => x.posData['name']!,
            weight: 1,
          ),
          WeightedKey(
            name: 'items',
            getter: (PosItem x) {
              return (x.items).keys.toString();
            },
            weight: 0.8,
          ),
        ],
        tokenize: true,
      ),
    );
  }

  @override
  void dispose() {
    cancelStreamSubscriptions();
    super.dispose();
  }
}
