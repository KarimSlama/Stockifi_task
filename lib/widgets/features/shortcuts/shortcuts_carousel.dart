import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/shortcut.dart';
import 'package:stocklio_flutter/providers/data/auth.dart';
import 'package:stocklio_flutter/providers/data/shortcuts.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/utils/string_util.dart';

import '../../../utils/app_theme_util.dart';
import '../../../utils/constants.dart';
import '../../common/responsive.dart';

class ShortcutsCarousel extends StatelessWidget {
  const ShortcutsCarousel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shortcutProvider = context.watch<ShortcutProvider>()..shortcuts;
    final profileProvider = context.watch<ProfileProvider>()..profile;

    if (shortcutProvider.isLoading || profileProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final isWastageEnabled = profileProvider.profile.isWastageEnabled;
    List<Shortcut> shortcuts = [];

    for (var e in shortcutProvider.shortcuts) {
      if (e.flags.contains('isWastageEnabled')) {
        if (isWastageEnabled) {
          shortcuts.add(e);
        }

        continue;
      }
      shortcuts.add(e);
    }

    if (shortcuts.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Row(
            children: [
              const Icon(Icons.shortcut),
              const SizedBox(width: 8.0),
              Text(
                StringUtil.localize(context).label_go_to,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
        Row(
          children: [
            ...shortcuts.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ShortcutTile(shortcut: e),
              );
            }).toList()
          ],
        ),
      ],
    );
  }
}

class ShortcutTile extends StatelessWidget {
  final Shortcut shortcut;

  const ShortcutTile({
    Key? key,
    required this.shortcut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    var mobileWidth = MediaQuery.of(context).size.width / 6 + 8;
    var desktopWidth =
        (Constants.largeScreenSize - Constants.navRailWidth * 2) / 6 + 8;
    var width = isDesktop ? desktopWidth : mobileWidth;
    var height = width;

    return InkWell(
      onTap: () {
        final isAdmin = context.read<AuthProvider>().isAdmin;
        final path = isAdmin ? '/admin${shortcut.path}' : shortcut.path;
        context.go(path);
      },
      child: Container(
        clipBehavior: Clip.hardEdge,
        margin: const EdgeInsets.all(4.0),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: AppTheme.instance.themeData.colorScheme.primary,
            width: 2.0,
            style: BorderStyle.solid,
          ),
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              left: 0,
              child: Container(
                alignment: Alignment.center,
                width: width - 4,
                height: height - 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8.0),
                      bottomRight: Radius.circular(8.0)),
                ),
                child: Center(
                  child: Text(
                    shortcut.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
