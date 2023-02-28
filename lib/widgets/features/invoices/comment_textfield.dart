import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/invoices.dart';
import 'package:stocklio_flutter/widgets/features/invoices/unresolved_invoice.dart';
import 'package:stocklio_flutter/utils/string_util.dart';

class CommentTextField extends StatelessWidget {
  final TextEditingController _controller;
  final UnresolvedInvoice _widget;

  const CommentTextField({
    Key? key,
    required controller,
    required widget,
  })  : _controller = controller,
        _widget = widget,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: StringUtil.localize(context).hint_text_add_comment,
        isDense: true,
      ),
      textCapitalization: TextCapitalization.sentences,
      onChanged: (value) {
        context
            .read<InvoiceProvider>()
            .editUnsavedComment(_widget.invoice.id!, value);
      },
    );
  }
}
