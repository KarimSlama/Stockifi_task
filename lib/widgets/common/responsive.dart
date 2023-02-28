import 'package:flutter/material.dart';
import 'package:stocklio_flutter/utils/constants.dart';

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget small;
  final Widget desktop;

  const Responsive({
    Key? key,
    required this.mobile,
    required this.tablet,
    required this.small,
    required this.desktop,
  }) : super(key: key);

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= Breakpoints.mobileUpper;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width <= Breakpoints.tabletUpper &&
      MediaQuery.of(context).size.width >= Breakpoints.tabletLower;

  static bool isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width <= Breakpoints.smallScreenUpper &&
      MediaQuery.of(context).size.width >= Breakpoints.smallScreenLower;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.largeScreenLower;

  @override
  Widget build(BuildContext context) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else if (isSmallScreen(context)) {
      return small;
    }

    return desktop;
  }
}
