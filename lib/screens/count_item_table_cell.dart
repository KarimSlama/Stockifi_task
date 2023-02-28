import 'dart:math';

import 'package:flutter/material.dart';

class CountItemTableCell extends StatelessWidget {
  final Widget child;
  final void Function()? onTap;

  const CountItemTableCell({Key? key, required this.child, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsiveCellHeight = MediaQuery.of(context).size.height * 0.06;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 1.0),
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xff555555),
            borderRadius: BorderRadius.circular(4),
          ),
          height: min(responsiveCellHeight, 64),
          child: Center(
            child: child,
          ),
        ),
      ),
    );
  }
}
