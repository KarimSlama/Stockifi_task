import 'package:flutter/material.dart';
import 'package:stocklio_flutter/models/invoice.dart';
import 'package:stocklio_flutter/widgets/features/invoices/image_grid.dart';

class ImageGridContainer extends StatelessWidget {
  const ImageGridContainer({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return InvoiceImageGrid(
      invoice: invoice,
    );
  }
}
