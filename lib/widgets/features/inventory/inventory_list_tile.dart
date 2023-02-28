import 'package:flutter/material.dart';
import 'package:stocklio_flutter/models/item.dart';
import '../../../providers/data/users.dart';

import '../../../utils/string_util.dart';

import 'package:provider/provider.dart';

class InventoryListTile extends StatelessWidget {
  final Item item;

  const InventoryListTile({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final user = profileProvider.profile;
    final numberFormat = user.numberFormat;

    return ListTile(
      title: Text('${item.name}'),
      subtitle: Text(
        '${item.size}${item.unit}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 40),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                StringUtil.formatNumber(numberFormat, item.stock),
                style: TextStyle(
                  color: item.stock <= 0 ? Colors.red : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
