import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/invoice.dart';
import 'package:stocklio_flutter/providers/data/invoices.dart';
import 'package:stocklio_flutter/providers/data/items.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';
import 'package:stocklio_flutter/utils/text_util.dart';
import 'package:stocklio_flutter/widgets/common/confirm.dart';
import 'package:stocklio_flutter/widgets/common/padded_text.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/widgets/features/invoices/invoice_header.dart';

class InvoiceBody extends StatefulWidget {
  final Invoice invoice;
  const InvoiceBody({Key? key, required this.invoice}) : super(key: key);

  @override
  State<InvoiceBody> createState() => _InvoiceBodyState();
}

class _InvoiceBodyState extends State<InvoiceBody> {
  void _showLongText(String itemName) {
    final invoiceUiProvider = context.read<InvoiceUIProvider>();
    invoiceUiProvider.setIsPressed(true);
    showToast(context, itemName);
  }

  void _truncateLongText() {
    final invoiceUiProvider = context.read<InvoiceUIProvider>();
    invoiceUiProvider.setIsPressed(false);
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<ItemProvider>().getAllItems();
    final invoiceUiProvider = context.watch<InvoiceUIProvider>();

    final numberFormat = context.read<ProfileProvider>().profile.numberFormat;
    final sortedKeys = widget.invoice.items!.keys.toList();
    sortedKeys.sort((x, y) {
      final itemX = widget.invoice.items![x];
      final itemY = widget.invoice.items![y];
      return (itemX['index'] ?? 1000) - (itemY['index'] ?? 1000);
    });
    final foodTotal = ParseUtil.toNum(widget.invoice.foodTotal ?? 0);
    var total = foodTotal;
    return Column(
      children: [
        InvoiceHeader(context: context),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: widget.invoice.items!.length + 1,
          itemBuilder: (context, index) {
            if (index == widget.invoice.items!.length) {
              return Column(
                children: [
                  if (foodTotal != 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PaddedText(
                          StringUtil.localize(context).label_food_total,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        PaddedText(
                          StringUtil.formatNumber(numberFormat, foodTotal),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  Container(
                    color: widget.invoice.items!.length.isEven
                        ? AppTheme.instance.rowColor
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PaddedText(
                          StringUtil.localize(context).label_grand_total,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        PaddedText(
                          StringUtil.formatNumber(numberFormat, total),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final itemId = sortedKeys[index];
            final item = widget.invoice.items![itemId];
            var quantity = ParseUtil.toNum(item['quantity']);
            var cost = ParseUtil.toNum(item['cost']);
            var name = items.firstWhere((x) => x.id == itemId).name;
            total += quantity * cost;

            var isPressed = invoiceUiProvider.isPressed;

            return Container(
              color: index.isEven ? AppTheme.instance.rowColor : null,
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: LayoutBuilder(builder: (context, constraints) {
                      return GestureDetector(
                        onTap: () {
                          if (TextUtil.hasTextOverflow(
                            name!,
                            style: Theme.of(context).textTheme.bodyLarge!,
                            maxWidth: constraints.maxWidth,
                            totalHorizontalPadding: 16,
                          )) {
                            isPressed
                                ? _truncateLongText()
                                : _showLongText(name);
                          }
                        },
                        child: isPressed
                            ? PaddedText(
                                '$name',
                              )
                            : PaddedText(
                                '$name',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      );
                    }),
                  ),
                  Expanded(
                    flex: !Responsive.isMobile(context) ? 2 : 4,
                    child: PaddedText(
                      StringUtil.formatNumber(
                        numberFormat,
                        quantity,
                        quantity % 1 != 0
                            ? '${quantity % 1}'.length.clamp(0, 2)
                            : 0,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: !Responsive.isMobile(context) ? 2 : 4,
                    child: PaddedText(
                      StringUtil.formatNumber(numberFormat, quantity * cost),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
