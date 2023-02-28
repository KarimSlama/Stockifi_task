import 'package:flutter/material.dart';
import 'package:stocklio_flutter/utils/constants.dart';

class SelectedLabel extends StatelessWidget {
  const SelectedLabel({
    Key? key,
    required this.context,
    required this.title,
  }) : super(key: key);

  final BuildContext context;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
            topRight: Radius.circular(Constants.navRailWidth / 2),
            bottomRight: Radius.circular(Constants.navRailWidth / 2)),
      ),
      width: Constants.navRailExtendedWidth - Constants.navRailWidth - 12,
      height: Constants.navRailWidth,
      child: Text(
        title,
        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }
}
