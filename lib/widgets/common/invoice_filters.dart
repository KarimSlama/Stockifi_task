import 'package:flutter/material.dart';
import 'package:stocklio_flutter/providers/data/invoices.dart';
import 'package:stocklio_flutter/providers/data/suppliers.dart';
import 'package:stocklio_flutter/providers/ui/supplier_ui_provider.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/widgets/common/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/utils/string_util.dart';

class InvoiceFilters extends StatelessWidget {
  const InvoiceFilters({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supplierProvider = context.watch<SupplierProvider>();
    final supplierUIProvider = context.watch<SupplierUIProvider>();
    final invoices = context.read<InvoiceProvider>().invoices;
    final currentInvoiceSuppliers = supplierProvider.suppliers
        .where((supplier) =>
            invoices.any((invoice) => invoice.supplierId == supplier.id))
        .toList();
    var supplierList = supplierUIProvider.supplierList;
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: FilterChip(
        shape: supplierList.isNotEmpty
            ? StadiumBorder(
                side: BorderSide(
                    color: AppTheme.instance.themeData.colorScheme.primary))
            : null,
        padding: const EdgeInsets.only(top: 4, left: 4, bottom: 4, right: -4),
        showCheckmark: false,
        selected: supplierList.isNotEmpty,
        onSelected: (value) {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              final supplierUIProvider = context.watch<SupplierUIProvider>();
              supplierList = supplierUIProvider.supplierList;
              return StocklioModalBottomSheet(
                label: StringUtil.localize(context).label_suppliers,
                actions: [
                  TextButton(
                    onPressed: () => supplierUIProvider.clearSupplierFilters(),
                    child: Text(StringUtil.localize(context).label_clear),
                  ),
                ],
                children: [
                  ...currentInvoiceSuppliers.map(
                    (supplier) {
                      return CheckboxListTile(
                        value: supplierList.contains(supplier),
                        controlAffinity: ListTileControlAffinity.trailing,
                        title: Text(supplier.name!),
                        activeColor: Theme.of(context).colorScheme.primary,
                        onChanged: (_) {
                          supplierList.contains(supplier)
                              ? supplierUIProvider
                                  .removeSupplierFilter(supplier)
                              : supplierUIProvider.addSupplierFilter(supplier);
                        },
                      );
                    },
                  ).toList(),
                ],
              );
            },
          );
        },
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(StringUtil.localize(context).label_supplier),
            if (supplierList.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 50),
                child: Container(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    supplierList.first.name!,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            if (supplierList.length > 1)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text('+${supplierList.length - 1}'),
              ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
