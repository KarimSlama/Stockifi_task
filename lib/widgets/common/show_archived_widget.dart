import 'package:flutter/material.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';

class ShowArchivedChip extends StatelessWidget {
  const ShowArchivedChip({
    Key? key,
    required this.showArchived,
    required this.onTap,
  }) : super(key: key);

  final bool showArchived;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'Show archived',
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      shape: showArchived
          ? StadiumBorder(
              side: BorderSide(
                  color: AppTheme.instance.themeData.colorScheme.primary))
          : null,
      padding: const EdgeInsets.only(
        top: 4,
        left: 4,
        bottom: 4,
        right: 4,
      ),
      showCheckmark: false,
      selected: showArchived,
      onSelected: (_) => onTap(),
    );
  }
}
