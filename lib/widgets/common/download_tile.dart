import 'package:flutter/material.dart';

class DownloadTile extends StatelessWidget {
  final Widget title;
  final VoidCallback onTap;

  const DownloadTile({
    Key? key,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Icon(
            Icons.download_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          title,
        ],
      ),
      onTap: onTap,
    );
  }
}
