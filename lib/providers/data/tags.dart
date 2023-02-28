import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/models/tag.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';
import '../../services/tag_service.dart';
import '../../utils/logger_util.dart';

class TagsProvider extends ChangeNotifier {
  late TagService _tagService;

  TagsProvider({
    TagService? tagservice,
  }) {
    _tagService = GetIt.instance<TagService>();
  }

  List<Tag> _tags = [];
  Fuzzy<Tag> _fuse = Fuzzy([]);

  bool _isLoading = true;
  bool _isInit = false;

  bool get isLoading => _isLoading;

  StreamSubscription<List<Tag>>? _tagsSub;

  List<Tag> get tags {
    try {
      _tagsSub ?? _listenToTagsStream();
      logger.i('TagsProvider - get tags is successful');
    } catch (error, stackTrace) {
      logger.e('TagsProvider - get tags failed\n$error\n$stackTrace');
      SentryUtil.error('TagsProvider get tags error!', 'TagsProvider class',
          error, stackTrace);
    }
    return [..._tags];
  }

  List<Tag> search(String query) {
    return _fuse.search(query).map((e) => e.item).toList();
  }

  void _listenToTagsStream() {
    _tagsSub = _tagService.getUserTagsStream().listen(
      (List<Tag> tags) {
        _tags = tags;

        _fuse = Fuzzy(
          tags.toList(),
          options: FuzzyOptions(
            keys: [
              WeightedKey(
                name: 'name',
                getter: (Tag x) => x.name,
                weight: 1,
              ),
            ],
          ),
        );

        if (!_isInit) {
          _isInit = true;
          _isLoading = false;
        }

        logger.i(
            'TagsProvider - _listenToTagsStream is successful ${tags.length}');
        notifyListeners();
      },
      onError: (e) {
        logger.e('TagsProvider - _listenToTagsStream failed\n$e');
      },
    );
  }

  Tag? findByName(String name) {
    return _tags.firstWhereOrNull((element) => element.name == name);
  }

  Future<String> createTag(String name) async {
    if (findByName(name) != null) {
      return 'Tag already exists';
    }

    try {
      await _tagService.createTag(Tag(name: name));

      logger.i('TagsProvider - createTag is successful');
      return 'Tag created - $name';
    } catch (error, stackTrace) {
      logger.e('TagsProvider - createTag failed $error\n$stackTrace');
      SentryUtil.error('TagsProvider.createTag() error: Tag $name',
          'TagsProvider class', error, stackTrace);
      return error.toString();
    }
  }
}
