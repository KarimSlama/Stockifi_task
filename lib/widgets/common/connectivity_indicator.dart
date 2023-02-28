import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/utils/constants.dart';
import 'package:stocklio_flutter/utils/enums.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/widgets/common/base_button.dart';

class ConnectivityIndicator extends StatelessWidget {
  const ConnectivityIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isOnline =
        context.watch<ConnectivityStatus>() == ConnectivityStatus.online;

    if (isOnline) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      color: AppTheme.instance.offlineColor,
      child: Padding(
        padding: const EdgeInsets.only(
          left: Constants.navRailWidth * 1.8,
        ),
        child: ListTile(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  actions: [
                    StockifiButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(StringUtil.localize(context).label_ok),
                    ),
                  ],
                  content: Text(StringUtil.localize(context).message_offline),
                );
              },
            );
          },
          visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
          title: Center(
              child: Text(StringUtil.localize(context).label_you_are_offline)),
          trailing: const Icon(Icons.offline_bolt_outlined),
        ),
      ),
    );
  }
}
