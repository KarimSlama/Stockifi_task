import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/count_areas.dart';
import 'package:stocklio_flutter/providers/data/counts.dart';
import 'package:stocklio_flutter/providers/ui/existing_count_ui_provider.dart';
import 'package:stocklio_flutter/utils/constants.dart';
import 'package:stocklio_flutter/utils/string_util.dart';

class SelectedTitle extends StatelessWidget {
  final int selectedIndex;
  const SelectedTitle({Key? key, required this.selectedIndex})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var count = context.watch<CountProvider>().findStartedOrPendingCount();
    var isVisibleSearchBar =
        context.watch<ExistingCountUIProvider>().isVisibleSearchBar;
    var countState = ValueNotifier<String>('');
    if (count != null) {
      countState.value = count.state!;
    }
    switch (selectedIndex) {
      case 0:
        return _createTitle(
            StringUtil.localize(context).nav_label_dashboard,
            const Icon(Icons.dashboard_rounded,
                size: Constants.navRailIconSize));
      case 1:
        final countAreaProvider = context.watch<CountAreaProvider>()
          ..countAreas;

        var areaStrings = [];

        if (!countAreaProvider.isLoading) {
          final selectedAreaId = countAreaProvider.selectedAreaId;
          final selectedArea = countAreaProvider.findAreaById(selectedAreaId);
          if (selectedArea != null) areaStrings = selectedArea.name.split(' ');
        }

        return Row(
          children: [
            _createTitle(
              StringUtil.localize(context).nav_label_current_count,
              const Icon(
                Icons.play_arrow_rounded,
                size: Constants.navRailIconSize,
              ),
            ),
            const SizedBox(width: 8),
            Visibility(
              visible: !isVisibleSearchBar,
              child: ValueListenableBuilder<String>(
                  valueListenable: countState,
                  builder: (BuildContext context, String value, Widget? child) {
                    return value == 'started'
                        ? Expanded(
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  ...areaStrings.map(
                                    (e) => Container(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: Text(
                                        e,
                                        style: TextStyle(
                                          fontSize: 12.0,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox();
                  }),
            ),
          ],
        );

      case 2:
        return _createTitle(
            StringUtil.localize(context).nav_label_previous_counts,
            const Icon(Icons.history_rounded, size: Constants.navRailIconSize));
      case 3:
        return _createTitle(
            StringUtil.localize(context).nav_label_invoices,
            const Icon(Icons.request_quote_outlined,
                size: Constants.navRailIconSize));
      case 4:
        return _createTitle(
            StringUtil.localize(context).nav_label_lists,
            const Icon(Icons.list_alt_rounded,
                size: Constants.navRailIconSize));
      case 5:
        return _createTitle(
            StringUtil.localize(context).nav_label_reports,
            const Icon(Icons.insert_chart_outlined_rounded,
                size: Constants.navRailIconSize));
      case 6:
        return _createTitle(
            StringUtil.localize(context).nav_label_inventory_status,
            const Icon(Icons.preview_rounded, size: Constants.navRailIconSize));
      default:
        return _createTitle(StringUtil.localize(context).nav_label_default,
            const Icon(Icons.quiz_rounded, size: Constants.navRailIconSize));
    }
  }

  Widget _createTitle(String title, Icon icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(
          width: 4,
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 22),
        )
      ],
    );
  }
}
