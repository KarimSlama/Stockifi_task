import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/ui/toast_provider.dart';
import 'package:stocklio_flutter/utils/string_util.dart';

void showToast(
  BuildContext context,
  String message, {
  bool isTopLeft = false,
}) {
  context.read<ToastProvider>().addToastMessage(message);
}

Future<void> alert(
  BuildContext context,
  String title, {
  String? content,
}) async {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: content != null ? Text(content) : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            StringUtil.localize(context).label_ok,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<bool> confirm(
  BuildContext context,
  Widget title, {
  String? content,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: title,
      content: content != null ? Text(content) : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            StringUtil.localize(context).label_ok,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            StringUtil.localize(context).label_cancel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        )
      ],
    ),
  );

  return result ?? false;
}
