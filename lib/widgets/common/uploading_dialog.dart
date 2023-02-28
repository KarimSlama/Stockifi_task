import 'package:flutter/material.dart';
import 'package:stocklio_flutter/providers/data/file_upload.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/utils/string_util.dart';

void showUploadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return WillPopScope(
        onWillPop: () async {
          return !context.read<FileUploadProvider>().isUploading;
        },
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(StringUtil.localize(context).label_uploading_files),
            ],
          ),
        ),
      );
    },
  );
}
