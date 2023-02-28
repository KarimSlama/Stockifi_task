import 'package:flutter/material.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/widgets/shimmer/shimmer_element.dart';
import 'package:stocklio_flutter/widgets/shimmer/stocklio_shimmer.dart';

class RecipeShimmer extends StatelessWidget {
  const RecipeShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StocklioShimmer(
          baseColor: AppTheme.instance.shimmerBaseColor,
          highlightColor: AppTheme.instance.shimmerHighlightColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerElement(
                  height: 28,
                ),
                SizedBox(
                  height: 8.0,
                ),
                ShimmerElement(width: 100),
                SizedBox(
                  height: 8.0,
                ),
                Divider(thickness: 2),
              ],
            ),
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
                          flex: Responsive.isMobile(context) ? 6 : 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              ShimmerElement(width: 180),
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
                        Expanded(
                          flex: Responsive.isMobile(context) ? 4 : 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: const [
                              ShimmerElement(width: 40),
                              SizedBox(
                                width: 10,
                              ),
                              ShimmerElement(width: 20),
                              SizedBox(
                                width: 10,
                              ),
                              ShimmerElement(width: 20),
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
