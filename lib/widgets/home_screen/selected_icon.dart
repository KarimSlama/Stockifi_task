import 'package:flutter/material.dart';
import 'package:stocklio_flutter/utils/constants.dart';

class SelectedIcon extends StatelessWidget {
  const SelectedIcon({
    Key? key,
    required this.context,
    required this.icon,
  }) : super(key: key);

  final BuildContext context;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          alignment: Alignment.centerLeft,
          width: 4,
          height: Constants.navRailWidth,
          color: Theme.of(context).colorScheme.primary,
        ),
        Center(
          child: Container(
              width: Constants.navRailWidth,
              height: Constants.navRailWidth,
              color: Theme.of(context).colorScheme.primary.withOpacity(.1),
              child: Icon(icon, size: Constants.navRailIconSize)),
        ),
      ],
    );
  }
}
