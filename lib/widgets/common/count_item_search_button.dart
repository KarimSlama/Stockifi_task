import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/count_areas.dart';
import 'package:stocklio_flutter/providers/data/counts.dart';
import 'package:stocklio_flutter/providers/ui/search_button.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/widgets/common/tutorial_button.dart';

import '../../screens/in_progress_new.dart';

class CountItemSearchButton extends StatelessWidget {
  const CountItemSearchButton({Key? key}) : super(key: key);

  static bool onNotification(
    BuildContext context,
    ScrollNotification scrollNotification,
  ) {
    if (scrollNotification is UserScrollNotification) {
      if (scrollNotification.direction == ScrollDirection.forward) {
        context.read<SearchButtonProvider>().isSearchButtonExtended = true;
      }

      if (scrollNotification.direction == ScrollDirection.reverse) {
        context.read<SearchButtonProvider>().isSearchButtonExtended = false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final countProvider = context.watch<CountProvider>()..counts;
    final countAreaProvider = context.watch<CountAreaProvider>()..countAreas;

    if (countProvider.isLoading || countAreaProvider.isLoading) {
      return const SizedBox();
    }

    final startedCount = countProvider.findStartedOrPendingCount();
    final selectedAreaId = countAreaProvider.selectedAreaId;
    final isExtended = context.select<SearchButtonProvider, bool>(
        (value) => value.isSearchButtonExtended);

    if ((startedCount?.state ?? '') != 'started') return const SizedBox();

    final onPressed = (countProvider.isLoading || countAreaProvider.isLoading)
        ? null
        : () {
            openCountItemView(context, startedCount?.id ?? '', selectedAreaId);
          };

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TutorialButton(
          tutorialName: StringUtil.localize(context).message_tutorial,
        ),
        FloatingActionButton.extended(
          onPressed: onPressed,
          extendedPadding:
              isExtended ? null : const EdgeInsets.only(left: 12, right: 12),
          label: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity:
                    animation.drive(CurveTween(curve: Curves.easeInOutCubic)),
                child: SizeTransition(
                  sizeFactor: animation,
                  axis: Axis.horizontal,
                  child: child,
                ),
              );
            },
            child: !isExtended
                ? const Icon(Icons.search)
                : Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 4.0),
                        child: Icon(Icons.search),
                      ),
                      Text(
                        StringUtil.localize(context).label_search,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

void openCountItemView(
  BuildContext context,
  String countId,
  String areaId, [
  String? countItemId,
]) {
  // TODO: Create separate route similar to edit item
  Navigator.of(context, rootNavigator: true).push(
    InProgressRoute(
      builder: (context) {
        return const SizedBox();
      },
    ),
  );
}
