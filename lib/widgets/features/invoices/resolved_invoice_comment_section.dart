import 'package:flutter/material.dart';
import 'package:stocklio_flutter/models/invoice.dart';

class ResolvedInvoiceCommentSection extends StatelessWidget {
  const ResolvedInvoiceCommentSection({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  final Invoice invoice;

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
              if (invoice.comments != null)
                ...(invoice.comments as List)
                    .map(
                      (comment) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(comment),
                      ),
                    )
                    .toList()
            ],
          ),
        ],
      ),
    );
  }
}
