import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/widgets/shimmer/shimmer_element.dart';
import 'package:stocklio_flutter/widgets/shimmer/stocklio_shimmer.dart';

class InProgressShimmer extends StatelessWidget {
  const InProgressShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var min = 100;
    var max = 300;
    return Column(
      children: [
        StocklioShimmer(
          baseColor: AppTheme.instance.shimmerBaseColor,
          highlightColor: AppTheme.instance.shimmerHighlightColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: ShimmerElement(
                  height: 28,
                ),
              ),
              const SizedBox(
                height: 16.0,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(spacing: 1.0, runSpacing: 1.0, children: [
                  ...List<ShimmerElement>.generate(
                      12,
                      (_) => ShimmerElement(
                          width: min + Random().nextInt(max - min).toDouble()))
                ]),
              ),
              const SizedBox(
                height: 8.0,
              ),
            ],
          ),
        ),
        Expanded(
          child: StocklioShimmer(
              baseColor: AppTheme.instance.shimmerBaseColor,
              highlightColor: AppTheme.instance.shimmerHighlightColor,
              child: ListView.separated(
                controller: ScrollController(),
                separatorBuilder: (context, index) =>
                    const Divider(thickness: 2),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              ShimmerElement(
                                width: 400,
                              ),
                              SizedBox(
                                height: 8,
                              ),
                              ShimmerElement(width: 100),
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        const ShimmerElement(
                          width: 20,
                        ),
                      ],
                    ),
                  );
                },
              )),
        ),
      ],
    );
  }
}
