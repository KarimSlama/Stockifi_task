import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stocklio_flutter/utils/package_util.dart';

class VersionText extends StatelessWidget {
  final PackageInfo _packageInfo = PackageUtil.packageInfo;

  VersionText({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        children: [
          Text(
            _packageInfo.version,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
