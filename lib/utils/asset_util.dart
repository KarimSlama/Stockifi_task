import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:stocklio_flutter/models/base_item.dart';

class AssetUtil {
  static const silhouettePath = 'assets/images/silhouettes';
  static const imageHeight = 200.0;

  static final List<String> assetPaths = [];

  static Map<String, dynamic> getSilhouette(BaseItem item) {
    final itemType = item.type?.toUpperCase() ?? '';
    final itemVariety = item.variety?.toUpperCase() ?? '';
    final itemUnit = item.unit?.toUpperCase() ?? '';
    final itemSilhouetteName = item.silhouetteName;

    var silhouetteName = 'bottle-default-old.png';
    var offset = 0.20; // 20% of the silhouette
    var isFillable = true;

    if (itemSilhouetteName != null) {
      silhouetteName = itemSilhouetteName;
    } else if (itemType.startsWith('VIN')) {
      if (itemVariety.endsWith('VIN')) {
        silhouetteName =
            'PRA_SOAVE_CLASSICO_12__75CL_bottle_2silhouette_fix.png';
      } else {
        silhouetteName = '200_champagne_fix.png';
      }
    } else if (itemType.startsWith('ØL') && itemVariety.startsWith('FAT')) {
      silhouetteName = 'keg.png';
    } else if (itemType.startsWith('ØL') && itemVariety.startsWith('TANK')) {
      silhouetteName = 'tank_ol.png';
      isFillable = false;
    } else if (itemType.startsWith('RECIPE')) {
      silhouetteName = '200_cocktail_fix.png';
    } else if (itemUnit.startsWith('PCS')) {
      silhouetteName = 'package.png';
      offset = 0.0;
    } else if (itemUnit.startsWith('G')) {
      offset = 0.0;
      silhouetteName = 'sack.png';
    }

    return {
      'path': _getSilhouettePath('$silhouettePath/$silhouetteName'),
      'offset': offset,
      'isFillable': isFillable,
    };
  }

  static String _getSilhouettePath(String assetName) {
    final index = assetPaths.indexOf(assetName);
    return index >= 0
        ? assetPaths[index]
        : '$silhouettePath/bottle-default-old.png';
  }

  static Future<void> loadSilhouettePaths(AssetBundle rootBundle) async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = jsonDecode(manifestContent);
    assetPaths.clear();
    assetPaths.addAll(manifestMap.keys
        .where((path) => path.startsWith(AssetUtil.silhouettePath)));
  }
}
