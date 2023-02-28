// Flutter Packages
import 'package:flutter/material.dart';

// 3rd-Party Packages
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/suppliers.dart';
import 'package:stocklio_flutter/widgets/shimmer/invoice_shimmer.dart';

// Providers
import '../providers/data/items.dart';
import '../providers/data/invoices.dart';

// Widgets
import '../../../widgets/features/invoices/invoices_view.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({Key? key}) : super(key: key);

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  @override
  Widget build(BuildContext context) {
    final itemProvider = context.watch<ItemProvider>();
    final supplierProvider = context.watch<SupplierProvider>()..suppliers;

    final items = itemProvider.getAllItems();

    final invoices = context.watch<InvoiceProvider>().invoices;

    if (itemProvider.isLoading ||
        supplierProvider.isLoading ||
        context.select<InvoiceProvider, bool>(
            (invoiceProvider) => invoiceProvider.isLoading)) {
      return const InvoiceShimmer();
    }

    return InvoicesView(
      invoices: invoices,
      items: items,
    );
  }
}
