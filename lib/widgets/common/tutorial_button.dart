import 'package:flutter/material.dart';
import 'package:stocklio_flutter/providers/data/tutorials.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/widgets/features/tutorials/tutorial_gallery.dart';
import 'package:provider/provider.dart';

class TutorialButton extends StatelessWidget {
  const TutorialButton({
    Key? key,
    required this.tutorialName,
  }) : super(key: key);

  final String tutorialName;

  @override
  Widget build(BuildContext context) {
    final isTutorialsEnabled = context.select<ProfileProvider, bool>(
        (value) => value.profile.isTutorialsEnabled);
    if (!isTutorialsEnabled) return const SizedBox();

    final tutorialProvider = context.watch<TutorialProvider>()..tutorials;

    return IconButton(
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.info_outline),
      onPressed: tutorialProvider.isLoading
          ? null
          : () {
              final tutorial = tutorialProvider.findByName(tutorialName);
              if (tutorial == null) return;

              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (context) => TutorialGallery(
                    tutorial: tutorial,
                  ),
                ),
              );
            },
    );
  }
}
