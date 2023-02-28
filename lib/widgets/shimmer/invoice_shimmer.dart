import 'package:flutter/material.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/utils/constants.dart';
import 'package:stocklio_flutter/widgets/shimmer/shimmer_element.dart';
import 'package:stocklio_flutter/widgets/shimmer/stocklio_shimmer.dart';

class InvoiceShimmer extends StatelessWidget {
  const InvoiceShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StocklioShimmer(
          baseColor: AppTheme.instance.shimmerBaseColor,
          highlightColor: AppTheme.instance.shimmerHighlightColor,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: ShimmerElement(
              height: 28,
            ),
          ),
        ),
        const SizedBox(
          height: 8.0,
        ),
        const Divider(thickness: 2),
        const UnresolvedInvoiceShimmer(),
        const SizedBox(
          height: 8.0,
        ),
        const Divider(thickness: 2),
        const ResolvedInvoiceShimmer(),
        const Divider(thickness: 2)
      ],
    );
  }
}

class UnresolvedInvoiceShimmer extends StatelessWidget {
  const UnresolvedInvoiceShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StocklioShimmer(
      baseColor: AppTheme.instance.shimmerBaseColor,
      highlightColor: AppTheme.instance.shimmerHighlightColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: const [
                ShimmerElement(
                  width: Constants.imageGridSize,
                  height: Constants.imageGridSize,
                ),
                SizedBox(
                  height: 10,
                ),
                ShimmerElement(
                  width: Constants.imageGridSize,
                  height: 28,
                ),
              ],
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerElement(width: 100),
                  const SizedBox(
                    height: 10,
                  ),
                  const ShimmerElement(width: 120),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Expanded(child: ShimmerElement()),
                      SizedBox(
                        width: 10,
                      ),
                      ShimmerElement(width: 20),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResolvedInvoiceShimmer extends StatelessWidget {
  const ResolvedInvoiceShimmer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StocklioShimmer(
      baseColor: AppTheme.instance.shimmerBaseColor,
      highlightColor: AppTheme.instance.shimmerHighlightColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            const ShimmerElement(
              width: 20,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      ShimmerElement(width: 140),
                      ShimmerElement(width: 20),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const ShimmerElement(width: 100),
                  const SizedBox(
                    height: 10,
                  ),
                  const ShimmerElement(width: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
