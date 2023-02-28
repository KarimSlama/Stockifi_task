// Flutter Packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/invoices.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/providers/ui/supplier_ui_provider.dart';
import 'package:stocklio_flutter/widgets/common/count_item_search_button.dart';
import 'package:stocklio_flutter/widgets/common/invoice_filters.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/widgets/shimmer/invoice_shimmer.dart';
import 'package:stocklio_flutter/utils/string_util.dart';

// Models
import '../../../models/invoice.dart';
import '../../../models/item.dart';

// Widgets
import 'invoice_image_picker.dart';
import 'resolved_invoice.dart';
import 'unresolved_invoice.dart';

class InvoicesView extends StatefulWidget {
  final List<Item> items;
  final List<Invoice> invoices;

  const InvoicesView({
    Key? key,
    required this.items,
    this.invoices = const [],
  }) : super(key: key);

  @override
  State<InvoicesView> createState() => _InvoicesViewState();
}

class _InvoicesViewState extends State<InvoicesView> {
  late ScrollController _scrollController;
  late final InvoiceUIProvider invoiceUIProvider;

  @override
  void initState() {
    super.initState();
    invoiceUIProvider = context.read<InvoiceUIProvider>();

    _scrollController =
        ScrollController(initialScrollOffset: invoiceUIProvider.scrollPosition);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final supplierUIProvider = context.watch<SupplierUIProvider>();
    final accessLevel = profileProvider.profile.accessLevel;
    final invoices = context.watch<InvoiceProvider>().invoices;

    var unresolvedInvoices =
        invoices.where((invoice) => invoice.state == 'unresolved').toList();
    var filteredInvoice = supplierUIProvider.supplierList.isNotEmpty
        ? [
            ...unresolvedInvoices,
            ...invoices
                .where((invoice) => supplierUIProvider.supplierList
                    .any((supplier) => invoice.supplierId == supplier.id))
                .toList()
          ]
        : invoices;

    if (accessLevel < 2) {
      const textStyle = TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );
      return Center(
        child: Responsive.isMobile(context)
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    StringUtil.localize(context).text_upgrade1,
                    textAlign: TextAlign.center,
                    style: textStyle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    StringUtil.localize(context).text_upgrade2,
                    textAlign: TextAlign.center,
                    style: textStyle,
                  ),
                ],
              )
            : Text(
                '${StringUtil.localize(context).text_upgrade1} ${StringUtil.localize(context).text_upgrade2}',
                textAlign: TextAlign.center,
                style: textStyle,
              ),
      );
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          width: double.infinity,
          child: const InvoiceImagePicker(),
        ),
        const SizedBox(height: 8),
        const Align(alignment: Alignment.centerLeft, child: InvoiceFilters()),
        const SizedBox(height: 8),
        if (filteredInvoice.isEmpty)
          Center(
            child: Text(StringUtil.localize(context).label_no_invoices_found),
          ),
        if (filteredInvoice.isNotEmpty)
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                invoiceUIProvider
                    .setScrollPosition(_scrollController.position.pixels);
                return CountItemSearchButton.onNotification(
                  context,
                  scrollNotification,
                );
              },
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: ListView.separated(
                  controller: _scrollController,
                  itemCount: filteredInvoice.length + 1,
                  separatorBuilder: (context, index) =>
                      const Divider(thickness: 2),
                  itemBuilder: (context, index) {
                    if (index == filteredInvoice.length) {
                      return const SizedBox(height: 68);
                    }

                    final invoice = filteredInvoice[index];

                    if (invoice.state == 'loading') {
                      return const UnresolvedInvoiceShimmer();
                    }

                    if (invoice.state != 'resolved') {
                      return UnresolvedInvoice(
                        invoice: invoice,
                        index: index,
                      );
                    } else if (invoice.state == 'resolved') {
                      return ResolvedInvoice(invoice: invoice);
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
