import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';

class StocklioShimmer extends StatelessWidget {
  final Color baseColor;
  final Color highlightColor;
  final Widget child;
  final Duration period;

  const StocklioShimmer({
    Key? key,
    this.period = const Duration(milliseconds: 1500),
    required this.baseColor,
    required this.highlightColor,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      key: key,
      period: period,
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          baseColor,
          baseColor,
          highlightColor,
          baseColor,
          baseColor
        ],
        stops: const <double>[0.0, 0.35, 0.5, 0.65, 1.0],
      ),
      child: child,
    );
  }
}
