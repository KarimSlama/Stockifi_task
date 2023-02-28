import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/widgets/shimmer/shimmer_element.dart';
import 'package:stocklio_flutter/widgets/shimmer/stocklio_shimmer.dart';

class CountsItemsShimmer extends StatelessWidget {
  const CountsItemsShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const minDesktop = 100;
    const maxDesktop = 400;

    const minMobile = 50;
    const maxMobile = 150;
    return Column(
      children: [
        StocklioShimmer(
          baseColor: AppTheme.instance.shimmerBaseColor,
          highlightColor: AppTheme.instance.shimmerHighlightColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ShimmerElement(
                      width: Responsive.isMobile(context) ? 40 : 60,
                    ),
                    SizedBox(
                      width: Responsive.isMobile(context) ? 50 : 100,
                    ),
                    ShimmerElement(
                      width: Responsive.isMobile(context) ? 40 : 60,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 40.0,
                ),
                const ShimmerElement(
                  width: 120,
                ),
                const Divider(thickness: 2),
              ],
            ),
          ),
        ),
        Expanded(
          child: StocklioShimmer(
              baseColor: AppTheme.instance.shimmerBaseColor,
              highlightColor: AppTheme.instance.shimmerHighlightColor,
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 12,
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.all(8.0),
                    color: index.isEven
                        ? AppTheme.instance.rowColor.withOpacity(.2)
                        : null,
                    child: Row(
                      children: [
                        Expanded(
                          flex: Responsive.isMobile(context) ? 6 : 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Responsive.isMobile(context)
                                  ? ShimmerElement(
                                      width: minMobile +
                                          Random()
                                              .nextInt(maxMobile - minMobile)
                                              .toDouble())
                                  : ShimmerElement(
                                      width: minDesktop +
                                          Random()
                                              .nextInt(maxDesktop - minDesktop)
                                              .toDouble()),
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          flex: 4,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ShimmerElement(
                                width: Responsive.isMobile(context) ? 40 : 60,
                              ),
                              SizedBox(
                                width: Responsive.isMobile(context) ? 50 : 100,
                              ),
                              ShimmerElement(
                                width: Responsive.isMobile(context) ? 40 : 60,
                              ),
                            ],
                          ),
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
