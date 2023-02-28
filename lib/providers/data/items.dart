// Dart Packages
import 'dart:async';

// Flutter Packages
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fuzzy/data/result.dart';

// 3rd-Party Packages
import 'package:fuzzy/fuzzy.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/count_item.dart';
import 'package:stocklio_flutter/models/global_item.dart';
import 'package:stocklio_flutter/models/pos_item.dart';
import 'package:stocklio_flutter/providers/data/recipes.dart';
import 'package:stocklio_flutter/providers/data/users.dart';

import 'package:stocklio_flutter/utils/logger_util.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';
import 'package:stocklio_flutter/utils/recipe_util.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';
import 'package:stocklio_flutter/widgets/common/filter_enums.dart';

// Models
import '../../models/item.dart';

// Services
import '../../services/item_service.dart';

import '../../utils/extensions.dart';

class ItemProvider with ChangeNotifier {
  late ItemService _itemService;

  ItemProvider({
    ItemService? itemService,
  }) {
    _itemService = itemService ?? GetIt.instance<ItemService>();
  }

  // States
  List<Item> _items = [];
  Fuzzy<Item> _fuse = Fuzzy([]);
  StreamSubscription<List<Item>>? _itemsStreamSub;
  bool _isLoadingItems = true;
  bool _isItemsInit = false;

  List<Item> _deletedItems = [];
  Fuzzy<Item> _deletedItemsIncludedFuse = Fuzzy([]);
  StreamSubscription<List<Item>>? _deletedItemsStreamSub;
  bool _isLoadingDeletedItems = true;
  bool _isDeletedItemsInit = false;

  List<Item> _archivedItems = [];
  Fuzzy<Item> _archivedItemsFuse = Fuzzy([]);
  StreamSubscription<List<Item>>? _archivedItemsStreamSub;
  bool _isLoadingArchivedItems = true;
  bool _isArchivedItemsInit = false;

  String queryString = '';
  final List<String> _itemsTypeFilters = [];
  final List<String> _itemsVarietyFilters = [];
  bool _showArchived = false;

  bool get showArchived => _showArchived;
  List<String> get itemsTypeFilters => [..._itemsTypeFilters];
  List<String> get itemsVarietyFilters => [..._itemsVarietyFilters];

  final List<String> _inventoryTypeFilters = [];
  final List<String> _inventoryVarietyFilters = [];

  List<String> get inventoryTypeFilters => [..._inventoryTypeFilters];
  List<String> get inventoryVarietyFilters => [..._inventoryVarietyFilters];

  final _fuzzyOptions = FuzzyOptions(
    keys: [
      WeightedKey(
        name: 'name',
        getter: (Item x) => x.name ?? '',
        weight: 1,
      ),
      WeightedKey(
        name: 'type',
        getter: (Item x) => x.type ?? '',
        weight: 0.3,
      ),
      WeightedKey(
        name: 'variety',
        getter: (Item x) => x.variety ?? '',
        weight: 0.3,
      ),
    ],
    tokenize: true,
    matchAllTokens: true,
    tokenSeparator: '',
    isCaseSensitive: false,
  );

  void toggleShowArchived() {
    _showArchived = !_showArchived;
    notifyListeners();
  }

  final Map<String, List<String>> _types = {
    'Alkoholfritt': ['Alkoholfritt', 'Kaffe & Te', 'Recipe', 'Sirup & Pure'],
    'Alkoholsvak': ['RTD & FAB'],
    'Brennevin': [
      'Akvavit',
      'Armagnac',
      'Brandy',
      'Brennevin Diverse',
      'Calvados',
      'Cognac',
      'Gin',
      'Grappa',
      'Likører',
      'Mezcal',
      'Pisco',
      'Rum',
      'Tequila',
      'Vodka',
      'Whisky'
    ],
    'Cider': ['Cider'],
    'Diverse': ['Diverse', 'Ice', 'Pant'],
    'Likører': ['Likører'],
    'Mat': ['Mat', 'Snacks'],
    'Øl': ['Fatøl', 'Flaske Øl'],
    'RTD & FAB': ['RTD & FAB'],
    'Starkøl': ['Fatøl', 'Flaske Øl'],
    'Sake': ['Sake'],
    'Starkvin': ['Starkvin'],
    'Tobakksvarer': ['Sigarer', 'Sigaretter', 'Snus'],
    'Vin': [
      'Champagne',
      'Dessertvin',
      'Hvitvin',
      'Musserende',
      'Oransjevin',
      'Rosevin',
      'Rødvin'
    ],
    'Taptails': ['Taptails'],
  };

  final _units = ['ml', 'g', 'pcs'];

  // Getters
  List<Item> getItems([String? uid]) {
    _itemsStreamSub ?? _listenToItemsStream(uid);
    return [..._items];
  }

  Map<String, List<String>> get types => _types;
  List<String> get units => [..._units];
  bool get isLoadingItems => _isLoadingItems;
  bool get isLoadingDeletedItems => _isLoadingDeletedItems;
  bool get isLoadingArchivedItems => _isLoadingArchivedItems;
  bool get isLoading =>
      _isLoadingItems || _isLoadingDeletedItems || isLoadingArchivedItems;

  bool? isItemDeleted(String itemId) {
    final item = getItemsInclDeleted()
        .firstWhereOrNull((element) => element.id == itemId);
    if (item == null) return null;
    return item.deleted;
  }

  List<Item> getItemsInclDeleted([String? uid]) {
    _itemsStreamSub ?? _listenToItemsStream(uid);
    _deletedItemsStreamSub ?? _listenToDeletedItemsStream(uid);
    return [..._items, ..._deletedItems];
  }

  List<Item> getArchivedItems([String? uid]) {
    _archivedItemsStreamSub ?? _listenToArchivedItemsStream(uid);
    return [..._archivedItems];
  }

  List<Item> getAllItems([String? uid]) {
    _itemsStreamSub ?? _listenToItemsStream(uid);
    _deletedItemsStreamSub ?? _listenToDeletedItemsStream(uid);
    _archivedItemsStreamSub ?? _listenToArchivedItemsStream(uid);
    return [..._items, ..._deletedItems, ..._archivedItems];
  }

  Future<List<void>> cancelStreamSubscriptions() {
    final futures = <Future>[];
    if (_itemsStreamSub != null) futures.add(_itemsStreamSub!.cancel());
    if (_deletedItemsStreamSub != null) {
      futures.add(_deletedItemsStreamSub!.cancel());
    }
    return Future.wait(futures);
  }

  void _listenToItemsStream([String? uid]) {
    final itemsStream = _itemService.getItemsStream(uid: uid);
    _itemsStreamSub = itemsStream.listen((List<Item> items) {
      _items = items;
      _fuse = Fuzzy(
        items.toList(),
        options: _fuzzyOptions,
      );

      if (!_isItemsInit) {
        _isItemsInit = true;
        _isLoadingItems = false;
      }

      notifyListeners();
    });
  }

  void _listenToDeletedItemsStream([String? uid]) {
    final deletedItemsStream = _itemService.getItemsStream(
      uid: uid,
      isFetchingDeleted: true,
    );

    _deletedItemsStreamSub = deletedItemsStream.listen((List<Item> items) {
      _deletedItems = items;

      _deletedItemsIncludedFuse = Fuzzy(
        getItemsInclDeleted(uid).toList(),
        options: _fuzzyOptions,
      );

      if (!_isDeletedItemsInit) {
        _isDeletedItemsInit = true;
        _isLoadingDeletedItems = false;
      }
      notifyListeners();
    });
  }

  void _listenToArchivedItemsStream([String? uid]) {
    final archivedItemsStream = _itemService.getItemsStream(
      uid: uid,
      isFetchingArchived: true,
    );

    _archivedItemsStreamSub = archivedItemsStream.listen((List<Item> items) {
      _archivedItems = items;

      _archivedItemsFuse = Fuzzy(
        _archivedItems.toList(),
        options: _fuzzyOptions,
      );

      if (!_isArchivedItemsInit) {
        _isArchivedItemsInit = true;
        _isLoadingArchivedItems = false;
      }
      notifyListeners();
    });
  }

  List<Item> getItemsByType(String type) {
    return [..._items.where((element) => element.type == type)];
  }

  List<Item> search(
    String query, {
    DateTime? dateCountCreated,
    bool searchDeletedItems = false,
    bool searchArchivedItems = false,
    int limit = 0,
    FilterSetting filterSetting = FilterSetting.items,
    List<String>? countItemTypeFilters,
    List<String>? countItemVarietyFilters,
  }) {
    var searchResults = <Item>[];
    var itemIds = <String>[];
    try {
      if (query.isEmpty) {
        for (var item in _items) {
          if (item.starred) {
            searchResults.add(item);
            itemIds.add(item.id!);
          }
        }
      }

      List<Result<Item>> results = [];

      if (searchDeletedItems) {
        results = _deletedItemsIncludedFuse.search(query);
      } else if (searchArchivedItems) {
        results = _archivedItemsFuse.search(query);
      } else {
        results = _fuse.search(query);
      }

      for (var element in results) {
        if (!itemIds.contains(element.item.id)) {
          searchResults.add(element.item);
          if (limit > 0 && searchResults.length == limit) break;
        }
      }

      logger.i('ItemProvider - search is successful ${searchResults.length}');
    } catch (error, stackTrace) {
      logger.e('ItemProvider - search failed $error');
      SentryUtil.error('ItemProvider.search() error: query $query',
          'ItemProvider class', error, stackTrace);
    }

    var typeFiltered = <Item>[];
    var varietyFiltered = <Item>[];

    var typeFilters = <String>[];
    var varietyFilters = <String>[];

    if (filterSetting == FilterSetting.items) {
      typeFilters = countItemTypeFilters ?? _itemsTypeFilters;
      varietyFilters = countItemVarietyFilters ?? _itemsVarietyFilters;
    } else if (filterSetting == FilterSetting.inventory) {
      typeFilters = _inventoryTypeFilters;
      varietyFilters = _inventoryVarietyFilters;
    }

    if (typeFilters.isNotEmpty) {
      typeFiltered = searchResults
          .where((element) => typeFilters.contains(element.type))
          .toList();
    }

    if (varietyFilters.isNotEmpty) {
      varietyFiltered = searchResults
          .where((element) => varietyFilters.contains(element.variety))
          .toList();
    }

    if (typeFilters.isNotEmpty || varietyFilters.isNotEmpty) {
      searchResults = <Item>{...typeFiltered, ...varietyFiltered}.toList();
    }

    return searchResults;
  }

  Item? findById(
    String id, {
    bool deletedIncluded = true,
    bool archivedIncluded = true,
  }) {
    final item = [
      ..._items,
      if (archivedIncluded) ..._archivedItems,
      if (deletedIncluded) ..._deletedItems,
    ].firstWhereOrNull((e) => e.id == id);
    return item;
  }

  ///filterItemsById() is a more optimized version of findById(). Instead of iterating through all available items
  /// for every countitems, here we are filtering first the only items necessary for the iteration for every countitem.
  /// This significantly reduces time, which previously thought to be causing infinit loop of 'findbyid is successful null'
  List<Item>? filterItemsById(List<CountItem> listOfCountItems) {
    final items = [..._items, ..._archivedItems, ..._deletedItems]
        .where((item) => listOfCountItems.any((e) => e.itemId == item.id))
        .toList();
    return items;
  }

  Future<String> createItem(Item item) async {
    try {
      final newItem = item.copyWith(name: item.name!.toTitleCase());

      await _itemService.createItem(newItem);

      logger.i('ItemProvider - createItem is successful');
      return 'Item created - ${newItem.name}';
    } catch (error, stackTrace) {
      logger.e('ItemProvider - createItem failed $error\n$stackTrace');
      SentryUtil.error('ItemProvider.createItem() error: Item $item',
          'ItemProvider class', error, stackTrace);
      return error.toString();
    }
  }

  Future<String> updateItem(Item item, [String? currentCountId]) async {
    try {
      await _itemService.updateItem(item, currentCountId);

      logger.i('ItemProvider - updateItem is successful');
      return 'Item updated';
    } catch (error, stackTrace) {
      logger.e('ItemProvider - updateItem failed $error\n$stackTrace');
      SentryUtil.error(
          'ItemProvider.updateItem() error: Item $item, currentCountId $currentCountId',
          'ItemProvider class',
          error,
          stackTrace);
      return error.toString();
    }
  }

  Future<String> updateItemDeleted(Item item, bool deleted) async {
    try {
      await _itemService.updateItemDeletedStatus(item, deleted: deleted);

      logger.i('ItemProvider - updateItemDeleted is successful');
      return 'Item created';
    } catch (error, stackTrace) {
      logger.e('ItemProvider - updateItemDeleted failed\n$error\n$stackTrace');
      SentryUtil.error(
        'ItemProvider.updateItemDeleted() error: Item $item, deleted $deleted',
        'ItemProvider class',
        error,
        stackTrace,
      );
      return error.toString();
    }
  }

  Future<String> archiveItem(String itemId) async {
    try {
      await _itemService.setArchived(itemId, true);

      logger.i('ItemProvider - archiveItem is successful');
      return 'Item created';
    } catch (error, stackTrace) {
      logger.e('ItemProvider - archiveItem failed\n$error\n$stackTrace');
      SentryUtil.error(
        'ItemProvider.archiveItem() error: Item $itemId',
        'ItemProvider class',
        error,
        stackTrace,
      );
      return error.toString();
    }
  }

  Future<String> unarchiveItem(String itemId) async {
    try {
      await _itemService.setArchived(itemId, false);

      logger.i('ItemProvider - unarchiveItem is successful');
      return 'Item created';
    } catch (error, stackTrace) {
      logger.e('ItemProvider - unarchiveItem failed\n$error\n$stackTrace');
      SentryUtil.error(
        'ItemProvider.unarchiveItem() error: Item $itemId',
        'ItemProvider class',
        error,
        stackTrace,
      );
      return error.toString();
    }
  }

  Future<void> unStarItems() async {
    try {
      await _itemService.unStarItems(
        _items.where((item) => item.starred).toList(),
      );

      logger.i('ItemProvider - softDeleteNewItems is successful');
    } catch (error, stackTrace) {
      logger.e('ItemProvider - softDeleteNewItems failed\n$error\n$stackTrace');
      SentryUtil.error('ItemProvider.softDeleteNewItems() error',
          'ItemProvider class', error, stackTrace);
    }
  }

  List<String> getVarietiesByTypes(List<String> types) {
    var varieties = <String>[];

    for (var type in types) {
      varieties.addAll(_types[type] ?? []);
    }

    return varieties;
  }

  List<String> get allVarieties {
    var varieties = <String>[];

    for (var element in _types.values) {
      varieties.addAll(element);
    }

    return varieties;
  }

  void toggleItemsTypeFilter(String value) {
    final index = _itemsTypeFilters.indexWhere((element) => element == value);

    if (index == -1) {
      _itemsTypeFilters.add(value);
    } else {
      _itemsTypeFilters.removeAt(index);
    }
    notifyListeners();
  }

  void toggleItemsVarietyFilter(String value) {
    final index =
        _itemsVarietyFilters.indexWhere((element) => element == value);

    if (index == -1) {
      _itemsVarietyFilters.add(value);
    } else {
      _itemsVarietyFilters.removeAt(index);
    }
    notifyListeners();
  }

  void toggleInventoryTypeFilter(String value) {
    final index =
        _inventoryTypeFilters.indexWhere((element) => element == value);

    if (index == -1) {
      _inventoryTypeFilters.add(value);
    } else {
      _inventoryTypeFilters.removeAt(index);
    }
    notifyListeners();
  }

  void toggleInventoryVarietyFilter(String value) {
    final index =
        _inventoryVarietyFilters.indexWhere((element) => element == value);

    if (index == -1) {
      _inventoryVarietyFilters.add(value);
    } else {
      _inventoryVarietyFilters.removeAt(index);
    }
    notifyListeners();
  }

  void clearItemsTypeFilters() {
    _itemsTypeFilters.clear();
    notifyListeners();
  }

  void clearItemsVarietyFilters() {
    _itemsVarietyFilters.clear();
    notifyListeners();
  }

  void clearInventoryTypeFilters() {
    _inventoryTypeFilters.clear();
    notifyListeners();
  }

  void clearInventoryVarietyFilters() {
    _inventoryVarietyFilters.clear();
    notifyListeners();
  }

  void resetItem() {
    selectedUnit = null;
    selectedType = null;
    selectedVariety = null;
    selectedItem = null;
    name = '';
    size = '';
    cost = '';
    cutaway = 0;
  }

  String? name = '';
  String? size = '';
  String? cost = '';
  num? cutaway = 0;
  String? selectedUnit;
  String? selectedType;
  String? selectedVariety;
  GlobalItem? selectedItem;

  @override
  void dispose() {
    cancelStreamSubscriptions();
    super.dispose();
  }

  double getPOSItemCostPercent(PosItem posItem, BuildContext context) {
    final itemProvider = context.read<ItemProvider>();
    final profileProvider = context.read<ProfileProvider>()..profile;
    final recipeProvider = context.read<RecipeProvider>()..recipes;
    final itemPrice = ParseUtil.toNum(posItem.posData['price']) * 0.8;

    var totalCost = 0.0;
    for (var itemId in posItem.items.keys) {
      final item = itemProvider.findById(itemId);
      if (item != null) {
        num cutaway = 0;
        if (profileProvider.profile.isItemCutawayEnabled) {
          cutaway = item.cutaway;
        }
        final itemCost = item.cost * (1 + cutaway);
        final ingredientCost =
            ParseUtil.toNum(posItem.items[itemId] ?? 0) * itemCost;
        totalCost += ingredientCost;
      } else {
        final recipe = recipeProvider.findById(itemId);
        if (recipe != null) {
          final recipeCost = RecipeUtil.getRecipeCost(context, recipe);
          final ingredientCost =
              ParseUtil.toNum(posItem.items[itemId] ?? 0) * recipeCost;
          totalCost += ingredientCost;
        }
      }
    }
    if (itemPrice == 0 || totalCost == 0) return 0;

    final itemCostPercent = totalCost / itemPrice * 100;
    return itemCostPercent.toPrecision(2);
  }
}
