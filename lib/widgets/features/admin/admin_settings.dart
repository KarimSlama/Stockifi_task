import 'package:flutter/material.dart';
import 'package:stocklio_flutter/widgets/common/stocklio_scrollview.dart';

import 'admin_powers_switch.dart';

class AdminSettings extends StatefulWidget {
  const AdminSettings({Key? key}) : super(key: key);

  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StocklioScrollView(
      controller: _scrollController,
      child: Column(
        children: const [
          AdminPowersSwitch(),
        ],
      ),
    );
  }
}
