// Flutter Packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/users.dart';

// 3rd-Party Packages
import 'package:stocklio_flutter/utils/text_util.dart';

class SearchItem extends StatelessWidget {
  const SearchItem({
    Key? key,
    required String query,
    required this.name,
    this.size = '',
    this.unit = '',
    this.variety = '',
    this.cost = '0',
    this.onTap,
    this.subtitle,
    this.trailing,
  })  : _query = query,
        super(key: key);

  final Function()? onTap;
  final String name;
  final String size;
  final String unit;
  final String variety;
  final String _query;
  final String cost;
  final Widget? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>()..profile;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
      dense: true,
      onTap: onTap,
      title: RichText(
        text: TextSpan(
          children: TextUtil.highlightSearchText(context, name, _query),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      subtitle: subtitle ??
          RichText(
            text: TextSpan(
              children: [
                ...TextUtil.highlightSearchText(context, size, _query),
                TextSpan(text: unit),
                const TextSpan(text: ' ('),
                ...TextUtil.highlightSearchText(context, variety, _query),
                TextSpan(
                    text: ') · $cost${profileProvider.profile.currencyShort}'),
              ],
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      trailing: trailing,
    );
  }
}
