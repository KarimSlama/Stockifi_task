import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static final AppTheme instance = AppTheme._internal();

  late ThemeData themeData;
  late Color rowColor;
  late Color pendingInvoiceColor;
  late Color resolvedInvoiceColor;
  late Color shimmerBaseColor;
  late Color shimmerHighlightColor;
  late Color disabledTextFormFieldTextColor;
  late Color disabledTextFormFieldLabelColor;
  late Color offlineColor;
  late Map<String, Color> colors;
  late List<Color> fallbackColors;
  late Map<String, IconData> icons;
  late IconData fallbackIcon;

  AppTheme._internal() {
    themeData = ThemeData(
      /*primaryColor: Colors.deepPurpleAccent[100],*/
      colorScheme: const ColorScheme(
        primary: Color(0xffbb86fc),
        primaryContainer: Color(0xff3700b3),
        secondary: Color(0xffbb86fc),
        secondaryContainer: Color(0xff7d7d7d),
        surface: Color(0xff424242),
        background: Color(0xff212121),
        error: Color(0xffcc6647),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
        onError: Colors.white,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xff212121)),
      scaffoldBackgroundColor: const Color(0xff424242),
      fontFamily: 'Roboto',
      sliderTheme: SliderThemeData(trackShape: CustomTrackShape()),
      scrollbarTheme: const ScrollbarThemeData(
        mainAxisMargin: 0,
        crossAxisMargin: 0,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xffbb86fc),
        selectionHandleColor: Color(0xffbb86fc),
        selectionColor: Color(0xffbb86fc),
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: Color(0xffbb86fc),
      ),
    );

    disabledTextFormFieldTextColor = Colors.white38;
    disabledTextFormFieldLabelColor = Colors.white60;

    rowColor = const Color(0xff5c5c5c);
    pendingInvoiceColor = const Color.fromRGBO(255, 254, 4, 1.0);
    resolvedInvoiceColor = const Color.fromRGBO(0, 100, 5, 1.0);
    shimmerBaseColor = const Color(0xffadadad);
    shimmerHighlightColor = const Color(0xff858585);
    offlineColor = const Color(0xFFFF9E19);
    colors = {
      'Brennevin': const Color(0xffbb86fc),
      'Vin': const Color(0xffbb86fc).withOpacity(0.8),
      'Mat': const Color(0xffbb86fc).withOpacity(0.7),
    };
    fallbackColors = [
      const Color(0xffbb86fc).withOpacity(0.6),
      const Color(0xffbb86fc).withOpacity(0.5)
    ];
    icons = {
      'Brennevin': Icons.local_bar,
      'Vin': Icons.wine_bar,
      'Mat': Icons.flatware_rounded,
      'Øl': Icons.sports_bar_outlined,
      'Starkøl': Icons.sports_bar_outlined,
    };
    fallbackIcon = Icons.local_drink;
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight!;
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
