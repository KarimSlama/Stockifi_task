class Breakpoints {
  static const int largeScreenUpper = 1200;
  static const int largeScreenLower = 1025;
  static const int smallScreenUpper = 1024;
  static const int smallScreenLower = 769;
  static const int tabletUpper = 768;
  static const int tabletLower = 481;
  static const int mobileUpper = 480;
  static const int mobileLower = 360;
}

class Constants {
  static const int largeScreenSize = Breakpoints.largeScreenLower;
  static const int smallScreenSize = Breakpoints.smallScreenLower;
  static const int tabletScreenSize = Breakpoints.tabletLower;
  static const int mobileScreenSize = Breakpoints.mobileLower;

  static const double navRailWidth = 48;
  static const double navRailExtendedWidth = 180;
  static const double navRailIconSize = 30;
  static const double iconSize = 24;
  static const double imageGridSize = 168;
  static const defaultPadding = 8.0;
}

class Stores {
  static const String appStore = 'https://apple.co/3HsMeyu';
  static const String playStore =
      'https://play.google.com/store/apps/details?id=io.stockl.stocklio';
}
