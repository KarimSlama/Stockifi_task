// Flutter Packages
import 'package:flutter/material.dart';

// 3rd-Party Packages
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/invoices.dart';

import 'package:stocklio_flutter/providers/data/suppliers.dart';

import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/utils/constants.dart';
import 'package:stocklio_flutter/utils/string_util.dart';

import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/widgets/common/stocklio_scrollview.dart';
import 'package:stocklio_flutter/widgets/features/invoices/expand_button.dart';
import 'package:stocklio_flutter/widgets/features/invoices/image_grid_container.dart';
import 'package:stocklio_flutter/widgets/features/invoices/invoice_body.dart';
import 'package:stocklio_flutter/widgets/features/invoices/resolved_invoice_comment_section.dart';

// Models
import '../../../models/invoice.dart';

class ResolvedInvoice extends StatelessWidget {
  final Invoice invoice;

  const ResolvedInvoice({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  String _formatDate(timestamp) =>
      DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(timestamp));

  @override
  Widget build(BuildContext context) {
    final isExpanded = context
        .watch<InvoiceProvider>()
        .getIsResolvedInvoiceExpanded(invoice.id ?? '');

    final supplier =
    context.watch<SupplierProvider>().findById(invoice.supplierId ?? '');

    final supplierName =
        supplier?.name ?? StringUtil.localize(context).label_unknown;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: AppTheme.instance.themeData.colorScheme.primary,
          height: 4,
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Badge.count(
                    count: invoice.files?.length ?? 0,
                    child: const Icon(
                      Icons.image_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${StringUtil.localize(context).label_invoice} #: ${invoice.number}',
                          style: Theme.of(context).textTheme.bodyLarge,
                          softWrap: true,
                          overflow: TextOverflow.clip,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${StringUtil.localize(context).label_supplier}: $supplierName',
                          style: Theme.of(context).textTheme.bodyLarge,
                          softWrap: true,
                          overflow: TextOverflow.clip,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${StringUtil.localize(context).label_delivery_date}: ${invoice.deliveryDate != null ? _formatDate(invoice.deliveryDate?.millisecondsSinceEpoch) : 'Unknown'}',
                          style: Theme.of(context).textTheme.bodyLarge,
                          softWrap: true,
                          overflow: TextOverflow.clip,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ExpandButton(
                  invoice: invoice, context: context, isExpanded: isExpanded),
            ],
          ),
        ),
        isExpanded
            ? Container(
          margin: const EdgeInsets.all(8.0),
          width: Constants.imageGridSize,
          child: ImageGridContainer(invoice: invoice),
        )
            : Container(),
        if (isExpanded)
          ResolvedInvoiceCommentSection(
            invoice: invoice,
          ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 8.0,
            ),
            child: InvoiceItemsList(invoice: invoice),
          ),
      ],
    );
  }
}

class InvoiceItemsList extends StatefulWidget {
  final Invoice invoice;

  const InvoiceItemsList({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  @override
  State<InvoiceItemsList> createState() => _InvoiceItemsListState();
}

class _InvoiceItemsListState extends State<InvoiceItemsList> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ///Resets the ScrollControllers' position to start,
    ///without this, the scrollmetric is alternately jumping to start and end
    ///of the scroll position [0 and 96] where 96 is the last value
    ///corresponding to the end of the scroll position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }
    });
    return Responsive.isMobile(context)

    ///enclosing the StocklioScrollView in its own NotificationListener
    ///so as not to affect the expanding and contracting of Search FAB
        ? NotificationListener<ScrollNotification>(
      onNotification: (_) {
        return true;
      },
      child: StocklioScrollView(
        showScrollbarOnTopAndBottom: true,
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Container(
          padding: const EdgeInsets.only(top: 12.0),
          width: MediaQuery.of(context).size.width,
          child: InvoiceBody(
            invoice: widget.invoice,
          ),
        ),
      ),
    )
        : InvoiceBody(
      invoice: widget.invoice,
    );
  }
}
