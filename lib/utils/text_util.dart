import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/users.dart';

class TextUtil {
  static bool hasTextOverflow(
    String text, {
    TextStyle? style,
    double minWidth = 0,
    double maxWidth = double.infinity,
    int maxLines = 1,
    double totalHorizontalPadding = 0,
  }) {
    if (maxWidth != double.infinity) {
      maxWidth -= totalHorizontalPadding;
    }

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: minWidth, maxWidth: maxWidth);

    return textPainter.didExceedMaxLines;
  }

  static List<TextSpan> highlightSearchText(
      BuildContext context, String source, String query) {
    final isSearchHighlightEnabled = context.select<ProfileProvider, bool>(
        (value) => value.profile.isSearchHighlightEnabled);
    if (!isSearchHighlightEnabled) return [TextSpan(text: source)];

    final children = <TextSpan>[];

    final fuzzy = Fuzzy([source]);
    final results = fuzzy.search(query);

    if (query.isEmpty || results.isEmpty) {
      return [TextSpan(text: source)];
    }

    final arr = source.characters.map((e) => e).toList();
    final indices = results.first.matches.first.matchedIndices;

    for (var i = 0; i < arr.length; i++) {
      if (indices.any((e) => i.clamp(e.start, e.end) == i)) {
        children.add(TextSpan(
          text: arr[i],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.instance.themeData.colorScheme.background,
            backgroundColor: Colors.white,
          ),
        ));
      } else {
        children.add(TextSpan(text: arr[i]));
      }
    }
    return children;
  }
}
