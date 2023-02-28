import 'package:flutter/foundation.dart';

class TagsUIProvider extends ChangeNotifier {
  List<String> _tags = [];

  List<String> get tags => [..._tags];

  void addTag(String tag) {
    _tags.add(tag);

    notifyListeners();
  }

  void clearAllTags() {
    _tags.clear();
    notifyListeners();
  }

  void removeTag(String tag) {
    _tags.remove(tag);
    notifyListeners();
  }

  void toggleItemTag(String tag) {
    if (_tags.contains(tag)) {
      _tags.remove(tag);
    } else {
      _tags.add(tag);
    }

    notifyListeners();
  }

  set tags(List<String> tags) {
    _tags = [...tags];
  }
}
