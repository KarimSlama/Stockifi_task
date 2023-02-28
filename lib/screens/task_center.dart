import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/item.dart';
import 'package:stocklio_flutter/models/task.dart';
import 'package:stocklio_flutter/providers/data/admin.dart';
import 'package:stocklio_flutter/providers/data/auth.dart';
import 'package:stocklio_flutter/providers/data/item_transfers.dart';
import 'package:stocklio_flutter/providers/data/items.dart';
import 'package:stocklio_flutter/providers/data/pos_items.dart';
import 'package:stocklio_flutter/providers/data/tasks.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/providers/ui/user_center_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';
import 'package:stocklio_flutter/widgets/common/base_button.dart';
import 'package:stocklio_flutter/widgets/common/confirm.dart';
import 'package:stocklio_flutter/widgets/features/items/item_list_tile.dart';

import '../providers/data/notifications.dart';

class TaskCenter extends StatefulWidget {
  const TaskCenter({Key? key}) : super(key: key);

  @override
  State<TaskCenter> createState() => _TaskCenterState();
}

class _TaskCenterState extends State<TaskCenter> {
  final scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>().tasks;
    final itemProvider = context.watch<ItemProvider>();
    final posItemProvider = context.watch<PosItemProvider>();

    final itemTasks = tasks.where((e) => e.path.contains('edit-item'));
    if (itemTasks.isNotEmpty) {
      itemProvider.getAllItems();
    }

    final posItemTasks = tasks.where((e) => e.path.contains('edit-pos-item'));
    if (posItemTasks.isNotEmpty) {
      posItemProvider.posItems;
    }

    final sendItemRequestTasks =
        tasks.where((element) => element.type == TaskType.sendItemRequest);

    final receiveItemRequestTasks =
        tasks.where((element) => element.type == TaskType.receiveItemRequest);

    final otherTasks = tasks.where((e) =>
        !e.path.contains('edit-item') &&
        !e.path.contains('edit-pos-item') &&
        !(e.type == TaskType.sendItemRequest) &&
        !(e.type == TaskType.receiveItemRequest));

    final sortedTasks = [
      ...itemTasks,
      ...posItemTasks.toList()
        ..sort((x, y) {
          final argsX = x.path.split('/');
          final argsY = y.path.split('/');

          num priceX = 0;
          if (argsX.isNotEmpty) {
            final posItemId = argsX.last;
            final posItem = posItemProvider.findById(posItemId);
            if (posItem != null) {
              priceX = ParseUtil.toNum(posItem.posData['price']);
            }
          }

          num priceY = 0;
          if (argsY.isNotEmpty) {
            final posItemId = argsY.last;
            final posItem = posItemProvider.findById(posItemId);
            if (posItem != null) {
              priceY = ParseUtil.toNum(posItem.posData['price']);
            }
          }

          return priceY.compareTo(priceX);
        }),
      ...sendItemRequestTasks,
      ...receiveItemRequestTasks,
      ...otherTasks,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Theme.of(context).colorScheme.background,
      child: ListView.separated(
        key: const PageStorageKey<String>('tasksScrollController'),
        controller: scrollController,
        itemCount: sortedTasks.length,
        separatorBuilder: (_, __) => const Divider(thickness: 2),
        itemBuilder: (context, index) {
          final task = sortedTasks[index];

          switch (task.type) {
            case TaskType.zeroCostItem:
              return ZeroCostItemTaskListTile(
                task: task,
                index: index,
                tasksLength: sortedTasks.length,
              );

            case TaskType.updatedPosItem:
              return ZeroCostPOSItemTaskListTile(
                task: task,
                index: index,
                tasksLength: sortedTasks.length,
              );
            case TaskType.sendItemRequest:
              return SendItemRequestTaskListTile(
                task: task,
                index: index,
                tasksLength: sortedTasks.length,
              );
            case TaskType.receiveItemRequest:
              return ReceiveItemRequestListTile(
                task: task,
                index: index,
                tasksLength: sortedTasks.length,
              );
            default:
              return ZeroCostItemTaskListTile(
                task: task,
                index: index,
                tasksLength: sortedTasks.length,
              );
          }
        },
      ),
    );
  }
}

class ZeroCostItemTaskListTile extends StatelessWidget {
  final Task task;
  final int index;
  final int tasksLength;

  const ZeroCostItemTaskListTile({
    required this.task,
    required this.index,
    required this.tasksLength,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subtitleLength = task.title.length;
    final itemName = task.title.substring(0, subtitleLength - 1);
    final itemCost = task.title.substring(subtitleLength - 1, subtitleLength);
    final subtitle = RichText(
        text: TextSpan(children: <TextSpan>[
      TextSpan(text: itemName, style: const TextStyle(color: Colors.white70)),
      TextSpan(
          text: itemCost,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ))
    ]));

    return Row(
      children: [
        Text(
          '${tasksLength - index}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: ListTile(
            onTap: () {
              final isAdmin = context.read<AuthProvider>().isAdmin;
              final selectedProfileId =
                  context.read<AdminProvider>().selectedProfileId;
              final queryParams = isAdmin
                  ? '?taskId=${task.id}&selectedProfileId=$selectedProfileId'
                  : '?taskId=${task.id}';

              final firstChar = task.path[0];
              context.go(
                // FIXME: Avoid having task paths with no '/' as first char
                firstChar != '/'
                    ? '/${task.path}$queryParams'
                    : '${task.path}$queryParams',
              );

              context.read<UserCenterProvider>().hideUserCenter();
            },
            title: Text(
                StringUtil.localize(context).label_tap_here_to_update_cost),
            subtitle: subtitle,
            trailing: const Icon(Icons.edit),
          ),
        ),
      ],
    );
  }
}

class ZeroCostPOSItemTaskListTile extends StatelessWidget {
  final Task task;
  final int index;
  final int tasksLength;

  const ZeroCostPOSItemTaskListTile({
    required this.task,
    required this.index,
    required this.tasksLength,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subtitleLength = task.title.length;
    final itemName = task.title.substring(0, subtitleLength - 1);
    final itemCost = task.title.substring(subtitleLength - 1, subtitleLength);
    final subtitle = RichText(
        text: TextSpan(children: <TextSpan>[
      TextSpan(text: itemName, style: const TextStyle(color: Colors.white70)),
      TextSpan(text: itemCost),
    ]));

    return Row(
      children: [
        Text(
          '${tasksLength - index}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: ListTile(
            onTap: () {
              context.go(task.path);
              context.read<UserCenterProvider>().hideUserCenter();
            },
            title: Text(
                StringUtil.localize(context).label_tap_here_to_update_cost),
            subtitle: subtitle,
            trailing: const Icon(Icons.edit),
          ),
        ),
      ],
    );
  }
}

class SendItemRequestTaskListTile extends StatelessWidget {
  final Task task;
  final int index;
  final int tasksLength;

  const SendItemRequestTaskListTile({
    super.key,
    required this.task,
    required this.index,
    required this.tasksLength,
  });

  @override
  Widget build(BuildContext context) {
    final itemTransferProvider = context.read<ItemTransferProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final itemProvider = context.watch<ItemProvider>()..getAllItems();

    final items = itemProvider.getItems();
    final item =
        items.where((element) => element.id == task.data["itemId"]).toList();

    return Row(
      children: [
        Text(
          '${tasksLength - index}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: ListTile(
            title:
                Text(StringUtil.localize(context).label_item_transfer_request),
            subtitle: Text(task.title),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                if (profileProvider.profile.organizationId == null ||
                    item.isEmpty) {
                  return;
                }
                context
                    .read<ItemTransferProvider>()
                    .setQuantity(task.data["quantity"] ?? 0);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => ItemTransferForm.edit(
                        task: task,
                        item: item[0],
                        organizationId:
                            profileProvider.profile.organizationId!),
                  ),
                );
              },
            ),
            onTap: () async {
              final isConfirmed = await confirm(
                  context,
                  Text(StringUtil.localize(context)
                      .label_cancel_item_request_confirmation));

              if (!isConfirmed) return;

              itemTransferProvider
                  .cancelItemTransferRequest(task.data['transferId']);

              notificationProvider.createNotification(
                title: 'Item transfer request was cancelled',
                body: '"${task.title}" was cancelled',
                data: task.data,
                path: '',
              );
            },
          ),
        )
      ],
    );
  }
}

class ReceiveItemRequestListTile extends StatelessWidget {
  final Task task;
  final int index;
  final int tasksLength;

  const ReceiveItemRequestListTile({
    super.key,
    required this.task,
    required this.index,
    required this.tasksLength,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${tasksLength - index}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: ListTile(
            title:
                Text(StringUtil.localize(context).label_item_transfer_request),
            subtitle: Text(task.title),
            onTap: () async {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) =>
                      ReceiveItemTransferSelectItem(task: task),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}

class ReceiveItemTransferSelectItem extends StatefulWidget {
  final Task task;

  const ReceiveItemTransferSelectItem({
    super.key,
    required this.task,
  });

  @override
  State<ReceiveItemTransferSelectItem> createState() =>
      _ReceiveItemTransferSelectItemState();
}

class _ReceiveItemTransferSelectItemState
    extends State<ReceiveItemTransferSelectItem> {
  String query = '';
  Item? selectedItem;

  @override
  Widget build(BuildContext context) {
    final itemProvider = context.watch<ItemProvider>()..getAllItems();
    final notificationProvider = context.read<NotificationProvider>();

    final items = query.isEmpty
        ? context.read<ItemProvider>().getItems()
        : context.read<ItemProvider>().search(query);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                StringUtil.localize(context)
                    .label_select_item_that_corresponds_to_the_transfer_request,
                style: const TextStyle(fontSize: 16),
                softWrap: true,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                    hintText:
                        StringUtil.localize(context).hint_text_search_items),
                onChanged: (value) {
                  setState(() {
                    query = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              Visibility(
                visible: !itemProvider.isLoading,
                replacement: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                child: Expanded(
                  child: ListView.separated(
                    separatorBuilder: (context, index) {
                      return const Divider(thickness: 2);
                    },
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final itemName = item.name;
                      final itemSize = item.size;
                      final itemUnit = item.unit;
                      return ListTile(
                        dense: true,
                        title: Text('$itemName, $itemSize$itemUnit'),
                        onTap: () {
                          setState(() {
                            selectedItem = item;
                          });
                        },
                      );
                    },
                    itemCount: items.length,
                  ),
                ),
              ),
              if (selectedItem != null)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Text(
                        '${StringUtil.localize(context).label_selected_item}: ',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${selectedItem?.name} ${selectedItem?.size}${selectedItem?.unit}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              StockifiButton.async(
                onPressed: selectedItem == null
                    ? null
                    : () async {
                        context
                            .read<ItemTransferProvider>()
                            .acceptItemTransferRequest(
                              widget.task.data['transferId'],
                              selectedItem!.id!,
                            );

                        showToast(
                            context,
                            StringUtil.localize(context)
                                .label_item_transfer_request_accepted);

                        notificationProvider.createNotification(
                          title: 'Item transfer request was accepted',
                          body: '"${widget.task.title}" was accepted',
                          data: widget.task.data,
                          path: '',
                        );

                        Navigator.of(context).pop();
                      },
                confirmationCallback: () => confirm(
                  context,
                  Text(StringUtil.localize(context)
                      .label_accept_item_request_confirmation),
                ),
                child: Text(StringUtil.localize(context).label_accept),
              ),
              StockifiButton.async(
                child: Text(StringUtil.localize(context).label_cancel),
                onPressed: () async {
                  await context
                      .read<ItemTransferProvider>()
                      .cancelItemTransferRequest(
                        widget.task.data['transferId'],
                      );

                  notificationProvider.createNotification(
                    title: 'Item transfer request was cancelled',
                    body: '"${widget.task.title}" was cancelled',
                    data: widget.task.data,
                    path: '',
                  );
                },
                confirmationCallback: () => confirm(
                  context,
                  Text(StringUtil.localize(context)
                      .label_cancel_item_request_confirmation),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
