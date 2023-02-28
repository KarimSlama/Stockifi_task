import 'package:flutter/material.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/utils/string_util.dart';

class InvoiceHeader extends StatelessWidget {
  const InvoiceHeader({
    Key? key,
    required this.context,
  }) : super(key: key);

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              StringUtil.localize(context).label_name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Expanded(
          flex: !Responsive.isMobile(context) ? 2 : 4,
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              //TODO:CHANGE TO LOCALIZATIONS ??
              'Pcs',
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
              StringUtil.localize(context).label_total_cost,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
