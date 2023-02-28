import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/admin.dart';
import 'package:stocklio_flutter/utils/string_util.dart';

class AdminPowersSwitch extends StatelessWidget {
  const AdminPowersSwitch({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAdminPowersEnabled = context
        .select<AdminProvider, bool>((value) => value.isAdminPowersEnabled);

    return ListTile(
      title: Text(StringUtil.localize(context).label_admin_powers_enabled),
      trailing: Switch(
        value: isAdminPowersEnabled,
        activeColor: Theme.of(context).colorScheme.primary,
        onChanged: (value) {
          context.read<AdminProvider>().isAdminPowersEnabled = value;
        },
      ),
    );
  }
}
