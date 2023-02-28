import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/utils/string_util.dart';

class ItemsHeader extends StatelessWidget {
  final Widget? trailing;

  const ItemsHeader({
    Key? key,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final profileProfider = context.watch<ProfileProvider>()..profile;
    final isItemCutawayEnabled = profileProfider.profile.isItemCutawayEnabled;
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Container(),
        ),
        Expanded(
          flex: !Responsive.isMobile(context) ? 2 : 4,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              StringUtil.localize(context).label_qty,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (isItemCutawayEnabled)
          Expanded(
            flex: !Responsive.isMobile(context) ? 2 : 4,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "CA%",
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        Expanded(
          flex: !Responsive.isMobile(context) ? 2 : 4,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              StringUtil.localize(context).label_cost,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        trailing ?? const SizedBox(),
      ],
    );
  }
}
