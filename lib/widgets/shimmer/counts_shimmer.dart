import 'package:flutter/material.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/widgets/shimmer/shimmer_element.dart';
import 'package:stocklio_flutter/widgets/shimmer/stocklio_shimmer.dart';

class CountsShimmer extends StatelessWidget {
  const CountsShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        ShimmerElement(width: 20),
                        SizedBox(
                          width: 20,
                        ),
                        ShimmerElement(width: 100),
                      ],
                    ),
                    const SizedBox(
                      height: 16.0,
                    ),
                    Row(
                      children: const [
                        ShimmerElement(width: 20),
                        SizedBox(
                          width: 20,
                        ),
                        ShimmerElement(width: 100),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 8.0,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Responsive.isMobile(context)
                        ? const ShimmerElement(width: 100)
                        : const ShimmerElement(width: 200),
                    const SizedBox(
                      width: 20,
                    ),
                    Responsive.isMobile(context)
                        ? const ShimmerElement(width: 100)
                        : const ShimmerElement(width: 200),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 16.0,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ShimmerElement(width: 100),
                        const SizedBox(
                          height: 8,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Responsive.isMobile(context)
                                ? const ShimmerElement(width: 130)
                                : const ShimmerElement(width: 200),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Responsive.isMobile(context)
                                    ? const ShimmerElement(width: 30)
                                    : const ShimmerElement(width: 60),
                                Responsive.isMobile(context)
                                    ? const SizedBox(width: 60)
                                    : const SizedBox(width: 180),
                                Responsive.isMobile(context)
                                    ? const ShimmerElement(width: 30)
                                    : const ShimmerElement(width: 60),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Responsive.isMobile(context)
                                ? const ShimmerElement(width: 80)
                                : const ShimmerElement(width: 140),
                            Responsive.isMobile(context)
                                ? const ShimmerElement(width: 80)
                                : const ShimmerElement(width: 140),
                          ],
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
