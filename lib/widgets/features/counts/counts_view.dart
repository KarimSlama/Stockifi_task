import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/count.dart';
import 'package:stocklio_flutter/models/organization.dart';
import 'package:stocklio_flutter/models/profile.dart';
import 'package:stocklio_flutter/models/response.dart';
import 'package:stocklio_flutter/providers/data/counts.dart';
import 'package:stocklio_flutter/providers/data/organization.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/widgets/common/base_button.dart';

class CountsView extends StatefulWidget {
  final List<Count> counts;
  final Profile? user;

  const CountsView({Key? key, required this.counts, required this.user})
      : super(key: key);

  @override
  State<CountsView> createState() => _CountsViewState();
}

class _CountsViewState extends State<CountsView> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDate(timestamp) => DateFormat("dd-MMM-''yy")
      .format(DateTime.fromMillisecondsSinceEpoch(timestamp));

  @override
  Widget build(BuildContext context) {
    final countProvider = context.watch<CountProvider>();
    final viewableCounts = countProvider.completedCounts;
    final recentlyCompletedCount = countProvider.recentlyCompletedCount;
    final selectedCount = countProvider.selectedCount ?? recentlyCompletedCount;

    if (countProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (viewableCounts.isEmpty || widget.user == null) {
      return Center(
          child: Text(
              StringUtil.localize(context).label_no_completed_counts_found));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: StockifiButton(
            onPressed: () {},
            child: DropdownButton<String>(
              iconEnabledColor: Theme.of(context).colorScheme.onPrimary,
              underline: Container(),
              iconSize: 20,
              isDense: true,
              isExpanded: true,
              value: selectedCount?.id ?? viewableCounts.first.id,
              items: [
                ...viewableCounts.map((count) {
                  final startDate = _formatDate(count.startTime);
                  final endDate = _formatDate(count.endTime);
                  return DropdownMenuItem<String>(
                    value: count.id,
                    child: Text(
                      '$startDate - $endDate',
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
              ],
              selectedItemBuilder: (context) => [
                ...viewableCounts.map((count) {
                  final startDate = _formatDate(count.startTime);
                  final endDate = _formatDate(count.endTime);
                  return Text(
                    '${StringUtil.localize(context).label_perio}: $startDate - $endDate',
                    style: const TextStyle(fontSize: 14),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                countProvider.setSelectedCount(value!);
                _scrollController.jumpTo(0);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: FutureBuilder<Response<Organization>>(
              future: context.read<OrganizationProvider>().fetchOrg(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return const SizedBox();
              }),
        ),
      ],
    );
  }
}
