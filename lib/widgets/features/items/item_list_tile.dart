// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stocklio_flutter/models/item.dart';
import 'package:stocklio_flutter/providers/data/admin.dart';
import 'package:stocklio_flutter/models/task.dart';
import 'package:stocklio_flutter/providers/data/auth.dart';
import 'package:stocklio_flutter/providers/data/item_transfers.dart';
import 'package:stocklio_flutter/providers/data/items.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';
import 'package:stocklio_flutter/utils/text_util.dart';
import 'package:stocklio_flutter/widgets/common/base_button.dart';
import 'package:stocklio_flutter/widgets/common/confirm.dart';
import '../../../providers/data/users.dart';
import '../../../utils/string_util.dart';
import 'package:provider/provider.dart';

class ItemListTile extends StatefulWidget {
  final Item item;
  final String query;

  const ItemListTile({Key? key, required this.item, this.query = ''})
      : super(key: key);

  @override
  State<ItemListTile> createState() => _ItemListTileState();
}

class _ItemListTileState extends State<ItemListTile> {
  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final user = profileProvider.profile;
    final numberFormat = user.numberFormat;

    final isAdmin = context.read<AuthProvider>().isAdmin;
    final isAdminPowersEnabled =
        context.read<AdminProvider>().isAdminPowersEnabled;
    final localizations = StringUtil.localize(context);

    return ListTile(
      title: RichText(
        text: TextSpan(
          children: [
            ...TextUtil.highlightSearchText(
                context, widget.item.name!, widget.query),
          ],
          style: const TextStyle(color: Colors.white),
        ),
      ),
      subtitle: Text(
        '${widget.item.size}${widget.item.unit}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 40),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                StringUtil.formatNumber(numberFormat, widget.item.cost),
                style: TextStyle(
                  color: widget.item.cost <= 0 ? Colors.red : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (isAdmin && isAdminPowersEnabled)
            IconButton(
              icon: Icon(
                Icons.change_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () async {
                final isReplaced =
                    await replaceItemDialog(context, widget.item);
                if (isReplaced == null) return;

                if (isReplaced) {
                  showToast(context,
                      localizations.message_item_replaced_successfully);
                } else {
                  showToast(
                      context, localizations.message_failed_to_replace_item);
                }
              },
            ),
          widget.item.archived
              ? IconButton(
                  onPressed: () async {
                    final isConfirmed = await confirm(
                        context,
                        Text(StringUtil.localize(context)
                            .message_confirm_remove_item_archives
                            .replaceAll("XXX", '${widget.item.name}')));

                    if (isConfirmed) {
                      context
                          .read<ItemProvider>()
                          .unarchiveItem(widget.item.id!);
                      showToast(
                          context,
                          StringUtil.localize(context)
                              .message_success_remove_item_archives
                              .replaceAll("XXX", '${widget.item.name}'));
                    }
                  },
                  icon: const Icon(Icons.archive),
                  color: Theme.of(context).colorScheme.primary,
                )
              : IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    final isAdmin = context.read<AuthProvider>().isAdmin;
                    final profile = context.read<ProfileProvider>().profile;
                    if (isAdmin) {
                      context.go(
                          '/admin/lists/items/edit-item/${widget.item.id}?selectedProfileId=${profile.id}');
                    } else {
                      context.go('/lists/items/edit-item/${widget.item.id}');
                    }
                  },
                ),
          if (profileProvider.profile.isTransferItemsEnabled)
            IconButton(
              icon: Icon(
                Icons.forward,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () async {
                if (profileProvider.profile.organizationId == null) {
                  return;
                }

                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => ItemTransferForm(
                      item: widget.item,
                      organizationId: profileProvider.profile.organizationId!,
                    ),
                  ),
                );
              },
            ),
          if (widget.item.starred) const Icon(Icons.star),
        ],
      ),
    );
  }
}

Future<bool?> replaceItemDialog(BuildContext context, Item item) async {
  String query = item.name ?? '';
  Item? selectedItem;
  bool isConfirmEnabled = false;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(builder: (context, setState) {
      final userId = context.read<ProfileProvider>().profile.id;
      final items = context.read<ItemProvider>().search(query).where((e) {
        if (e.id == item.id) return false;
        if (e.unit == item.unit) return true;
        if (e.unit == 'ml' && item.unit == 'g') return true;
        if (e.unit == 'g' && item.unit == 'ml') return true;
        return false;
      }).toList();

      final itemText = '${item.name}, ${item.size}${item.unit}';

      final selectedItemText = selectedItem != null
          ? '${selectedItem?.name}, ${selectedItem?.size}${selectedItem?.unit}'
          : '-';
      final localizations = StringUtil.localize(context);
      return AlertDialog(
        title: Column(
          children: [
            ListTile(
              leading: Text(StringUtil.localize(context).label_replace_item),
              title: Text(itemText),
              dense: true,
            ),
            ListTile(
              leading: Text('${StringUtil.localize(context).label_with}:'),
              title: Text(selectedItemText),
              dense: true,
            ),
          ],
        ),
        content: SizedBox(
          width: min(MediaQuery.of(context).size.width, 400),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                    hintText:
                        StringUtil.localize(context).hint_text_search_items),
                onChanged: (value) => setState(() {
                  query = value.isNotEmpty ? value : (item.name ?? '');
                }),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  separatorBuilder: (context, index) {
                    return const Divider(thickness: 2);
                  },
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final itemName = items[index].name;
                    final itemSize = items[index].size;
                    final itemUnit = items[index].unit;
                    return ListTile(
                      dense: true,
                      title: Text('$itemName, $itemSize$itemUnit'),
                      onTap: () => setState((() {
                        selectedItem = item;
                      })),
                    );
                  },
                  itemCount: items.length,
                ),
              ),
              if (selectedItem != null) const SizedBox(height: 8),
              if (selectedItem != null)
                TextField(
                  decoration: InputDecoration(
                      hintText: StringUtil.localize(context).label_replace),
                  onChanged: (value) => setState(() {
                    isConfirmEnabled = value == 'REPLACE';
                  }),
                ),
            ],
          ),
        ),
        actions: [
          if (selectedItem != null)
            TextButton(
              onPressed: isConfirmEnabled
                  ? () async {
                      bool isReplaced = false;

                      try {
                        await FirebaseFunctions.instance
                            .httpsCallable('users-replaceItem')
                            .call(
                          {
                            'userId': userId,
                            'itemId': item.id,
                            'replacementId': selectedItem?.id,
                          },
                        );

                        isReplaced = true;
                      } catch (error, stackTrace) {
                        SentryUtil.error('Failed to replace item.',
                            'replaceItemDialog', error, stackTrace);
                      }

                      Navigator.pop(context, isReplaced);
                    }
                  : null,
              child: Text(
                isConfirmEnabled
                    ? localizations.label_ok
                    : localizations.label_enter_replace_above,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.label_cancel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          )
        ],
      );
    }),
  );

  return result;
}

class ItemTransferForm extends StatelessWidget {
  final Item item;
  final String organizationId;
  final bool isEdit;
  final Task? task;

  const ItemTransferForm({
    super.key,
    required this.item,
    required this.organizationId,
  })  : isEdit = false,
        task = null;

  const ItemTransferForm.edit(
      {super.key,
      required this.item,
      required this.organizationId,
      required this.task})
      : isEdit = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text('${isEdit ? "Edit " : ""}Transfer Item'),
      ),
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Consumer<ItemTransferProvider>(
              builder: (context, value, child) {
                return ListTile(
                  title: Text(item.name?.toString() ?? ''),
                  subtitle: Text(
                    '${item.size}${item.unit}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StockifiButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff555555),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.only(top: 12, bottom: 12),
                          side: BorderSide(
                            color:
                                AppTheme.instance.themeData.colorScheme.primary,
                            width: 2.0,
                            style: BorderStyle.solid,
                          ),
                        ),
                        onPressed: () {
                          value.decreaseQuantity();
                        },
                        child: const Text(
                          '-1',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StockifiButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff555555),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.only(top: 12, bottom: 12),
                          side: BorderSide(
                            color:
                                AppTheme.instance.themeData.colorScheme.primary,
                            width: 2.0,
                            style: BorderStyle.solid,
                          ),
                        ),
                        onPressed: () {
                          value.increaseQuantity();
                        },
                        child: const Text(
                          '+1',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 2),
            Consumer<ItemTransferProvider>(
              builder: (context, value, child) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: RichText(
                    text: TextSpan(
                      children: <InlineSpan>[
                        TextSpan(
                          text: StringUtil.localize(context).label_transfer,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const WidgetSpan(
                            child: SizedBox(
                          width: 4,
                        )),
                        TextSpan(
                          text: value.quantity.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const WidgetSpan(
                            child: SizedBox(
                          width: 4,
                        )),
                        TextSpan(
                          text: item.name,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const WidgetSpan(
                            child: SizedBox(
                          width: 4,
                        )),
                        TextSpan(
                          text: StringUtil.localize(context).label_to,
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (isEdit) ...[
                          const WidgetSpan(
                              child: SizedBox(
                            width: 4,
                          )),
                          TextSpan(
                            text: task!.title.split(' to ')[1],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
            if (isEdit)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: StockifiButton.async(
                    onPressed: () async {
                      final quantity =
                          context.read<ItemTransferProvider>().quantity;

                      final isConfirmed = await confirm(
                        context,
                        Text(
                            'Are you sure you want to edit request to $quantity ${item.name}?'),
                      );

                      if (!isConfirmed) {
                        return;
                      }

                      await context
                          .read<ItemTransferProvider>()
                          .editItemTransferRequest(
                            task!.data['transferId'],
                            context.read<ItemTransferProvider>().quantity,
                          );

                      showToast(context, 'Item transfer request edited');
                      Navigator.of(context).pop();
                    },
                    child: const Text("Edit")),
              )
            else
              FutureBuilder<List<dynamic>?>(
                future: context
                    .read<ItemTransferProvider>()
                    .getOrganizationUsers(organizationId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final List<dynamic> users = snapshot.data ?? [];

                  return Expanded(
                    child: ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (context, index) =>
                          const Divider(thickness: 2),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return ListTile(
                          onTap: () async {
                            final quantity =
                                context.read<ItemTransferProvider>().quantity;
                            final profileName =
                                context.read<ProfileProvider>().profile.name ??
                                    '';

                            final isConfirmed = await confirm(
                              context,
                              Text(
                                  'Are you sure you want to transfer $quantity ${item.name} to ${user['name']}'),
                            );

                            if (!isConfirmed) {
                              context
                                  .read<ItemTransferProvider>()
                                  .resetQuantity();
                              return;
                            }

                            await context
                                .read<ItemTransferProvider>()
                                .createItemTransferRequest(
                                  profileName,
                                  user['id'],
                                  user['name'],
                                  item.id!,
                                  item.name ?? '',
                                  context.read<ItemTransferProvider>().quantity,
                                );

                            showToast(context, 'Item transfer request created');
                            Navigator.of(context).pop();
                          },
                          title: Text(user['name']),
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
