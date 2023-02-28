import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/invoice.dart';
import 'package:stocklio_flutter/providers/data/invoices.dart';

class ExpandButton extends StatelessWidget {
  const ExpandButton({
    Key? key,
    required this.invoice,
    required this.context,
    required this.isExpanded,
  }) : super(key: key);

  final Invoice invoice;
  final BuildContext context;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        context
            .read<InvoiceProvider>()
            .toggleResolvedInvoiceExpanded(invoice.id!);
      },
      icon: Icon(
        isExpanded ? Icons.expand_less : Icons.expand_more,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
