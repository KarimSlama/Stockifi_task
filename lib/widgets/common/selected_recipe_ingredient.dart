import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/item.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/utils/string_util.dart';

class SelectedRecipeIngredient extends StatelessWidget {
  const SelectedRecipeIngredient({
    Key? key,
    required this.item,
  }) : super(key: key);

  final Item? item;

  @override
  Widget build(BuildContext context) {
    final numberFormat = context.read<ProfileProvider>().profile.numberFormat;
    final itemCostText = StringUtil.formatNumber(numberFormat, item?.cost ?? 0);
    final profileProvider = context.watch<ProfileProvider>()..profile;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          StringUtil.localize(context).label_ingredient,
          style: TextStyle(
              color: AppTheme.instance.disabledTextFormFieldLabelColor,
              fontSize: 12),
        ),
        Text(
          '${item?.name}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          '${item?.size}${item?.unit} (${item?.variety}) $itemCostText${profileProvider.profile.currencyShort}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
