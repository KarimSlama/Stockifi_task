// Flutter Packages
import 'dart:async';

import 'package:flutter/foundation.dart';

// 3rd-Party Packages
import 'package:get_it/get_it.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:stocklio_flutter/utils/logger_util.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';

// Models
import '../../models/global_item.dart';

// Services
import '../../services/global_item_service.dart';

class GlobalItemProvider with ChangeNotifier {
  late GlobalItemService _globalItemService;

  GlobalItemProvider({GlobalItemService? globalItemService}) {
    _globalItemService =
        globalItemService ?? GetIt.instance<GlobalItemService>();
  }

  // States
  List<GlobalItem> _globalItems = [];
  Fuzzy<GlobalItem> _fuse = Fuzzy([]);
  StreamSubscription? _globalItemsStreamSub;
  bool _isLoading = true;
  bool _isInit = false;

  // Getters
  List<GlobalItem> get globalItems {
    _globalItemsStreamSub ?? _listenToGlobalItemsStream();
    return [..._globalItems];
  }

  bool get isLoading => _isLoading;

  Future<void>? cancelStreamSubscriptions() {
    return _globalItemsStreamSub?.cancel();
  }

  @override
  void dispose() {
    cancelStreamSubscriptions();
    super.dispose();
  }

  void _listenToGlobalItemsStream() {
    _globalItemsStreamSub = _globalItemService
        .getGlobalItemsStream()
        .listen((List<GlobalItem> globalItems) {
      _globalItems = globalItems;

      _fuse = Fuzzy(
        _globalItems,
        options: FuzzyOptions(
          keys: [
            WeightedKey(name: 'name', getter: (x) => x.name, weight: 1),
            WeightedKey(name: 'type', getter: (x) => x.type, weight: 0.3),
            WeightedKey(name: 'variety', getter: (x) => x.variety, weight: 0.3),
          ],
        ),
      );

      if (!_isInit) {
        _isInit = true;
        _isLoading = false;
      }

      notifyListeners();
    });
  }

  List<GlobalItem> search(String query, {int limit = 0}) {
    var searchResults = <GlobalItem>[];
    if (query.isEmpty) return searchResults;

    try {
      final results = _fuse.search(query);
      for (var result in results) {
        searchResults.add(result.item);
        if (limit > 0 && searchResults.length == limit) break;
      }
      logger.i(
          'GlobalItemProvider - global item search is successful ${searchResults.length}');
    } catch (error, stackTrace) {
      logger.e('GlobalItemProvider - global item search failed $error');
      SentryUtil.error('GlobalItemProvider.search() error: query $query',
          'GlobalItemProvider class', error, stackTrace);
    }

    return searchResults;
  }
}
