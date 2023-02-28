import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/report_item.dart';
import 'package:stocklio_flutter/providers/data/count_items.dart';
import 'package:stocklio_flutter/providers/data/counts.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/utils/constants.dart';
import 'package:stocklio_flutter/widgets/common/count_item_search_button.dart';
import 'package:stocklio_flutter/widgets/features/dashboard/iframe_widget.dart';
import 'package:stocklio_flutter/widgets/features/shortcuts/shortcuts_carousel.dart';
import 'package:stocklio_flutter/widgets/shimmer/stocklio_shimmer.dart';
import '../utils/string_util.dart';
import '../widgets/common/responsive.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final gridViewController = ScrollController();
  final customScrollViewController = ScrollController();

  @override
  void dispose() {
    gridViewController.dispose();
    customScrollViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countProvider = context.watch<CountProvider>()..counts;

    if (countProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    var crossAxisCount = 2;
    var childAspectRatio = 1.0;

    if (Responsive.isDesktop(context)) {
      crossAxisCount = 4;
      childAspectRatio = 1.3;
    } else if (Responsive.isTablet(context)) {
      crossAxisCount = 3;
      childAspectRatio = 1.4;
    }
    if (countProvider.isLoading) {
      final dashboardLoading = StocklioShimmer(
        baseColor: AppTheme.instance.shimmerBaseColor,
        highlightColor: AppTheme.instance.shimmerHighlightColor,
        child: NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            return CountItemSearchButton.onNotification(
              context,
              scrollNotification,
            );
          },
          child: GridView.builder(
            controller: gridViewController,
            shrinkWrap: true,
            itemCount: 4,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: Constants.defaultPadding,
              mainAxisSpacing: Constants.defaultPadding,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) {
              return Container(
                height: 40,
                width: 40,
                padding: const EdgeInsets.all(Constants.defaultPadding),
                decoration: BoxDecoration(
                  color: AppTheme.instance.shimmerBaseColor,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
              );
            },
          ),
        ),
      );
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(Constants.defaultPadding),
            child: Row(
              children: [
                Expanded(child: dashboardLoading),
              ],
            ),
          ),
        ),
      );
    }

    final countInProgress = countProvider.findStartedOrPendingCount();
    if (countInProgress != null) {
      context.read<CountItemProvider>().getCountItems(countInProgress.id!);
    }

    final counts = countProvider.counts
        .where((e) => e.state == 'complete' && e.report != null);
    final lastCount = counts.isNotEmpty ? counts.first : null;

    final countData = <String, num>{};
    if (lastCount != null) {
      final items = lastCount.report as List<ReportItem>;

      for (var item in items) {
        final type = item.type;
        final quantity = item.quantity;
        final cost = item.cost;
        final total = quantity! * cost!;
        countData[type!] = (countData[type] ?? 0) + total;
      }
    }

    final chartData = <PieChartSectionData>[];
    final total =
        countData.isEmpty ? 0 : countData.values.reduce((x, y) => x + y);
    final sortedKeys = countData.keys.toList();
    sortedKeys.sort((x, y) => countData[y]!.compareTo(countData[x]!));
    for (var i = 0; i < sortedKeys.length; i++) {
      final itemType = sortedKeys[i];
      final data = PieChartSectionData(
        title: itemType,
        color: AppTheme.instance.colors[itemType] ??
            AppTheme.instance
                .fallbackColors[i % AppTheme.instance.fallbackColors.length],
        value: countData[itemType]! / total * 100,
        showTitle: false,
        radius: 8 + countData[itemType]! / total * 40,
      );
      chartData.add(data);
    }
    final month = lastCount != null
        ? DateFormat('MMMM')
            .format(DateTime.fromMillisecondsSinceEpoch(lastCount.startTime!))
        : '';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(Constants.defaultPadding),
          child: chartData.isEmpty
              ? Center(
                  child: Text(StringUtil.localize(context)
                      .label_awaiting_your_first_count))
              : CustomScrollView(
                  controller: customScrollViewController,
                  key:
                      const PageStorageKey<String>('dashboardScrollController'),
                  slivers: [
                    SliverToBoxAdapter(
                        child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          ShortcutsCarousel(),
                        ],
                      ),
                    )),
                    SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: Constants.defaultPadding,
                        mainAxisSpacing: Constants.defaultPadding,
                        childAspectRatio: childAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          if (index == 0) {
                            return CountChart(
                              data: chartData,
                              total: total,
                              month: month,
                            );
                          }
                          return CountTypeCard(
                            data: chartData[index - 1],
                            total: total,
                          );
                        },
                        childCount: chartData.length + 1,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 68,
                      ),
                    ),
                    if (context
                        .read<ProfileProvider>()
                        .profile
                        .isIFrameDashboardEnabled)
                      const SliverToBoxAdapter(child: IFrameWidget()),
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 68,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class CountChart extends StatelessWidget {
  final List<PieChartSectionData> data;
  final num total;
  final String month;

  const CountChart({
    Key? key,
    required this.data,
    required this.total,
    required this.month,
  }) : super(key: key);

  final isHTML = kIsWeb &&
      !(const bool.fromEnvironment(
        'FLUTTER_WEB_USE_SKIA',
        defaultValue: false,
      ));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Constants.defaultPadding),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.1),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        children: [
          Expanded(
            child: !isHTML
                ? PieChart(
                    PieChartData(
                      sectionsSpace: 1,
                      startDegreeOffset: -90,
                      sections: data,
                    ),
                  )
                : const SizedBox(),
          ),
          const SizedBox(height: Constants.defaultPadding),
          Text(
            '${(total / 1000).toStringAsFixed(0)}K',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 0.7,
            ),
          ),
          Text(
            'in $month',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class CountTypeCard extends StatelessWidget {
  final PieChartSectionData data;
  final num total;

  const CountTypeCard({
    Key? key,
    required this.data,
    required this.total,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final numberFormat = context.read<ProfileProvider>().profile.numberFormat;

    return Container(
      padding: const EdgeInsets.all(Constants.defaultPadding),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.1),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.1),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: Icon(
              AppTheme.instance.icons[data.title] ??
                  AppTheme.instance.fallbackIcon,
              color: data.color,
            ),
          ),
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ProgressLine(
            color: data.color,
            percentage: data.value,
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${(data.value).toStringAsFixed(2)}%',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              Text(
                '${StringUtil.formatNumber(numberFormat, (data.value / 100 * total / 1000))}K',
              )
            ],
          )
        ],
      ),
    );
  }
}

class ProgressLine extends StatelessWidget {
  const ProgressLine({
    Key? key,
    required this.color,
    required this.percentage,
  }) : super(key: key);

  final Color color;
  final double percentage;

  final double _height = 5;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: _height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) => Container(
            width: constraints.maxWidth * (percentage / 100),
            height: _height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
