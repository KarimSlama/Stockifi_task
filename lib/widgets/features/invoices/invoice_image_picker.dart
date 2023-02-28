// Flutter Packages
import 'dart:typed_data';
import 'package:flutter/material.dart';

// 3rd-Party Packages
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/file_upload.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/widgets/common/base_button.dart';
import 'package:stocklio_flutter/widgets/common/modal_bottom_sheet.dart';
import 'package:stocklio_flutter/widgets/common/uploading_dialog.dart';

// Models
import '../../../models/invoice.dart';

// Providers
import '../../../providers/data/invoices.dart';

// Utils
import 'package:stocklio_flutter/utils/file_util.dart';

class InvoiceImagePicker extends StatefulWidget {
  final Invoice? invoice;
  const InvoiceImagePicker({
    Key? key,
    this.invoice,
  }) : super(key: key);

  @override
  State<InvoiceImagePicker> createState() => _InvoiceImagePickerState();
}

class _InvoiceImagePickerState extends State<InvoiceImagePicker> {
  void getImage() {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      builder: (context) {
        return StocklioModalBottomSheet(
          children: [
            ListTile(
              leading: const Icon(Icons.description),
              title: Text(StringUtil.localize(context).label_document),
              onTap: () async {
                context.read<FileUploadProvider>().isUploading = true;

                final pickedFiles = await FileUtil.pickFiles(context);

                if (pickedFiles.isNotEmpty && mounted) {
                  showUploadingDialog(context);
                  await uploadFiles(context, pickedFiles);
                }

                if (mounted) {
                  context.read<FileUploadProvider>().isUploading = false;
                  Navigator.of(context, rootNavigator: true)
                      .popUntil((route) => route.isFirst);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: Text(StringUtil.localize(context).label_gallery),
              onTap: () async {
                context.read<FileUploadProvider>().isUploading = true;

                final pickedFiles = await FileUtil.pickImages(context) ?? [];

                if (pickedFiles.isNotEmpty && mounted) {
                  showUploadingDialog(context);
                  await uploadFiles(context, pickedFiles);
                }

                if (mounted) {
                  context.read<FileUploadProvider>().isUploading = false;
                  Navigator.of(context, rootNavigator: true)
                      .popUntil((route) => route.isFirst);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera),
              title: Text(StringUtil.localize(context).label_camera),
              onTap: () async {
                context.read<FileUploadProvider>().isUploading = true;

                final pickedFile = await FileUtil.pickImage(context);

                if (pickedFile != null && mounted) {
                  showUploadingDialog(context);
                  await uploadFiles(context, [pickedFile]);
                }

                if (mounted) {
                  context.read<FileUploadProvider>().isUploading = false;
                  Navigator.of(context, rootNavigator: true)
                      .popUntil((route) => route.isFirst);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> uploadFiles(
    BuildContext context,
    List<Uint8List> pickedFiles,
  ) async {
    final invoiceProvider = context.read<InvoiceProvider>();

    (widget.invoice != null)
        ? await invoiceProvider.updateInvoice(
            widget.invoice!,
            newImagesToUpload: pickedFiles,
          )
        : await invoiceProvider.createInvoice(
            Invoice(),
            newImagesToUpload: pickedFiles,
          );
  }

  @override
  Widget build(BuildContext context) {
    return StockifiButton(
      onPressed: getImage,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.invoice == null
                ? StringUtil.localize(context).label_add_new_invoice
                : StringUtil.localize(context).label_add_extre_image,
          ),
          const SizedBox(width: 8),
          Icon(
            widget.invoice == null
                ? Icons.photo_camera_outlined
                : Icons.add_photo_alternate_outlined,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
