// Flutter Packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/base_item.dart';
import 'package:stocklio_flutter/models/item.dart';
import 'package:stocklio_flutter/models/wastage_item.dart';
import 'package:stocklio_flutter/providers/data/wastage_items.dart';
import 'package:stocklio_flutter/providers/ui/wastage_ui_provider.dart';

// 3rd-Party Packages
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/utils/constants.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';
import 'package:stocklio_flutter/widgets/common/base_button.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/utils/string_util.dart';

class AddWastage extends StatefulWidget {
  final Item item;
  final WastageItem? wastageItem;
  final num wastageItemEntrySize;
  final String? wastageItemEntryId;
  final String wastageId;

  const AddWastage({
    Key? key,
    this.wastageItem,
    this.wastageItemEntrySize = 0,
    this.wastageItemEntryId,
    required this.item,
    required this.wastageId,
  }) : super(key: key);

  @override
  State<AddWastage> createState() => _AddWastageState();
}

class _AddWastageState extends State<AddWastage> {
  final sizeController = TextEditingController();
  int fullBottleCounter = 0;
  var selectedItem = ValueNotifier<BaseItem?>(null);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wastageUIProvider = context.read<WastageUIProvider>();

      bool isPerKilo = false;

      selectedItem.value = widget.item as BaseItem;
      wastageUIProvider.setOriginalSelectedItem(widget.item as BaseItem);

      if (widget.wastageItem != null) {
        isPerKilo = widget.wastageItem!.isPerKilo;
      }

      wastageUIProvider.setIsPerKilo(isPerKilo);
      fullBottleCounter = (widget.wastageItemEntrySize ~/
              (isPerKilo ? 1000 : widget.item.size!))
          .toInt();

      final size = widget.wastageItemEntrySize
          .remainder((isPerKilo ? 1000 : widget.item.size!));

      if (size != 0) {
        sizeController.text = size.toStringAsFixed(2);
      }
    });
  }

  @override
  void dispose() {
    sizeController.dispose();
    selectedItem.dispose();
    super.dispose();
  }

  num getWastageCost(int itemSize, num itemCost) {
    return (getWastageSize(itemSize) / itemSize) * itemCost;
  }

  num getWastageSize(int itemSize) {
    final size = ParseUtil.toNum(
        sizeController.text.isEmpty ? '0' : sizeController.text);
    final fullBottleSize = fullBottleCounter * itemSize;
    return size + fullBottleSize;
  }

  @override
  Widget build(BuildContext context) {
    final wastageUIProvider = context.watch<WastageUIProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      switchPerKilo(wastageUIProvider);
    });

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Container(
          alignment: Alignment.topCenter,
          width: Responsive.isDesktop(context)
              ? Constants.largeScreenSize - Constants.navRailWidth * 2
              : null,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder<BaseItem?>(
                    valueListenable: selectedItem,
                    builder: (_, selectedItemValue, __) {
                      return Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedItemValue?.name ?? '',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${selectedItemValue?.size}${selectedItemValue?.unit} · ${selectedItemValue?.cost?.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          ],
                        ),
                      );
                    },
                  ),
                  ValueListenableBuilder<BaseItem?>(
                    valueListenable: selectedItem,
                    builder: (_, selectedItemValue, __) {
                      if (selectedItemValue == null) {
                        return const SizedBox();
                      }

                      final selectedItemSize = selectedItemValue.size;
                      final selectedItemCost = selectedItemValue.cost;
                      final wastageCost =
                          getWastageCost(selectedItemSize!, selectedItemCost!);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            selectedItemValue.unit == 'g'
                                ? 'per kilo'
                                : selectedItemValue.unit == 'ml'
                                    ? 'per liter'
                                    : '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Visibility(
                            visible: selectedItemValue.unit != 'pcs',
                            child: Switch(
                              activeColor: AppTheme
                                  .instance.themeData.colorScheme.primary,
                              activeTrackColor: AppTheme
                                  .instance.themeData.colorScheme.primary
                                  .withOpacity(0.7),
                              value: wastageUIProvider.isPerKilo,
                              onChanged: wastageCost == 0
                                  ? (_) {
                                      wastageUIProvider.setIsPerKilo(_);
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      );
                    },
                  )
                ],
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  StockifiButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff555555),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.only(top: 12, bottom: 12),
                      side: BorderSide(
                        color: AppTheme.instance.themeData.colorScheme.primary,
                        width: 2.0,
                        style: BorderStyle.solid,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        fullBottleCounter++;
                      });
                    },
                    child: const Text(
                      '+1',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Container(
                    width: 220,
                    height: 48,
                    padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                    decoration: BoxDecoration(
                      color: AppTheme.instance.themeData.colorScheme.background,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: AppTheme.instance.themeData.colorScheme.primary,
                        width: 2.0,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        fullBottleCounter > 0
                            ? Text('$fullBottleCounter + ')
                            : const SizedBox.shrink(),
                        Expanded(
                          child: TextField(
                            style: const TextStyle(fontSize: 15),
                            autofocus: true,
                            controller: sizeController,
                            textAlign: TextAlign.end,
                            showCursor: true,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isCollapsed: true,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        ValueListenableBuilder<BaseItem?>(
                          valueListenable: selectedItem,
                          builder: (_, selectedItemValue, __) {
                            if (selectedItemValue == null) {
                              return const SizedBox();
                            }
                            final selectedItemSize = selectedItemValue.size;
                            final selectedItemCost = selectedItemValue.cost;
                            final selectedItemUnit = selectedItemValue.unit;
                            return Text(
                                '$selectedItemUnit/${selectedItemSize!}$selectedItemUnit - ${getWastageCost(selectedItemSize, selectedItemCost!).toStringAsFixed(2)}');
                          },
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  StockifiButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff555555),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.only(top: 12, bottom: 12),
                      side: BorderSide(
                        color: AppTheme.instance.themeData.colorScheme.primary,
                        width: 2.0,
                        style: BorderStyle.solid,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        if (fullBottleCounter > 0) {
                          fullBottleCounter--;
                        }
                      });
                    },
                    child: const Text(
                      '-1',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ValueListenableBuilder<BaseItem?>(
                    valueListenable: selectedItem,
                    builder: (context, selectedItemValue, child) {
                      return StockifiButton.async(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                        onPressed: () async {
                          final wastageUIProvider =
                              context.read<WastageUIProvider>();
                          final originalSelectedItemSize =
                              wastageUIProvider.originalSelectedItem?.size;

                          await context
                              .read<WastageItemProvider>()
                              .updateWastageItemEntry(
                                wastageItemEntryId: widget.wastageItemEntryId,
                                wastageItemEntrySize: getWastageSize(
                                        selectedItemValue!.size!) /
                                    ParseUtil.toNum(
                                        originalSelectedItemSize.toString()),
                                wastageItem: widget.wastageItem,
                                item: selectedItemValue as Item,
                                wastageId: widget.wastageId,
                                isPerKilo: wastageUIProvider.isPerKilo,
                              );

                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Text(StringUtil.localize(context).label_submit),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void switchPerKilo(WastageUIProvider wastageUIProvider) {
    if ((wastageUIProvider.isPerKilo && selectedItem.value != null)) {
      var selectedItemProxyItem = Item();
      final costProxy =
          double.parse('${selectedItem.value?.cost?.toString()}') /
              double.parse('${selectedItem.value?.size?.toString()}') *
              1000;
      selectedItemProxyItem = selectedItem.value as Item;
      selectedItemProxyItem =
          selectedItemProxyItem.copyWith(size: 1000, cost: costProxy);
      selectedItem.value = selectedItemProxyItem as BaseItem;
    } else if (!wastageUIProvider.isPerKilo && selectedItem.value != null) {
      if (wastageUIProvider.originalSelectedItem != null) {
        selectedItem.value = wastageUIProvider.originalSelectedItem;
      }
    }
  }
}
