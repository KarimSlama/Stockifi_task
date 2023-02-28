import 'package:flutter/material.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';

class ShimmerElement extends StatelessWidget {
  final double? width;
  final double? height;
  final double? radius;
  const ShimmerElement({
    this.width,
    this.height = 20,
    this.radius = 8,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: AppTheme.instance.shimmerBaseColor,
          borderRadius: BorderRadius.circular(radius!)),
      height: height,
      width: width,
    );
  }
}
