// Flutter Packages
import 'package:flutter/material.dart';

// 3rd-Party Packages
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/utils/constants.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/widgets/features/invoices/comment_section.dart';
import 'package:stocklio_flutter/widgets/features/invoices/image_grid.dart';

// Models
import '../../../models/invoice.dart';

// Providers
import '../../../providers/data/invoices.dart';

// Widgets
import 'invoice_image_picker.dart';

class UnresolvedInvoice extends StatefulWidget {
  final Invoice invoice;
  final int index;

  const UnresolvedInvoice({
    Key? key,
    required this.invoice,
    required this.index,
  }) : super(key: key);

  @override
  State<UnresolvedInvoice> createState() => _UnresolvedInvoiceState();
}

class _UnresolvedInvoiceState extends State<UnresolvedInvoice> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text =
        context.read<InvoiceProvider>().unsavedComments[widget.invoice.id!] ??
            '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: Constants.imageGridSize,
                child: InvoiceImageGrid(invoice: widget.invoice),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: Constants.imageGridSize,
                child: InvoiceImagePicker(invoice: widget.invoice),
              ),
            ),
            if (Responsive.isMobile(context))
              CommentSection(
                widget: widget,
                context: context,
                controller: _controller,
              ),
          ],
        ),
        if (!Responsive.isMobile(context))
          Expanded(
            child: CommentSection(
              widget: widget,
              context: context,
              controller: _controller,
            ),
          ),
      ],
    );
  }
}
