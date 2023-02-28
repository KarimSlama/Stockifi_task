import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/invoices.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/widgets/features/invoices/comment_textfield.dart';
import 'package:stocklio_flutter/widgets/features/invoices/unresolved_invoice.dart';

class CommentSection extends StatelessWidget {
  const CommentSection({
    Key? key,
    required this.widget,
    required TextEditingController controller,
    required this.context,
  })  : _controller = controller,
        super(key: key);

  final UnresolvedInvoice widget;
  final TextEditingController _controller;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.invoice.comments != null)
                ...(widget.invoice.comments as List)
                    .map(
                      (comment) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(comment),
                      ),
                    )
                    .toList()
            ],
          ),
          Row(
            children: [
              Responsive.isMobile(context)
                  ? SizedBox(
                      width: 240,
                      child: CommentTextField(
                        controller: _controller,
                        widget: widget,
                      ),
                    )
                  : Expanded(
                      child: CommentTextField(
                        controller: _controller,
                        widget: widget,
                      ),
                    ),
              IconButton(
                onPressed: () {
                  if (_controller.text.trim().isNotEmpty) {
                    final invoiceProvider = context.read<InvoiceProvider>();

                    invoiceProvider.addInvoiceComment(
                        widget.invoice.id!, _controller.text);

                    invoiceProvider.unsavedComments[widget.invoice.id!] = '';

                    _controller.clear();
                  }
                },
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
