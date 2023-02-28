import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:stocklio_flutter/models/global_item.dart';
import 'package:stocklio_flutter/models/item.dart';
import 'package:stocklio_flutter/providers/data/count_items.dart';
import 'package:stocklio_flutter/providers/data/counts.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/providers/ui/tags_ui_provider.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/providers/data/tasks.dart';
import 'package:stocklio_flutter/providers/ui/toast_provider.dart';
import 'package:stocklio_flutter/utils/formatters.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/widgets/common/base_button.dart';
import 'package:stocklio_flutter/widgets/common/padded_text.dart';
import 'package:stocklio_flutter/widgets/common/stocklio_scrollview.dart';
import 'package:stocklio_flutter/widgets/features/tags/tags.dart';
import '../models/task.dart';
import '../providers/data/items.dart';
import '../widgets/common/confirm.dart';
import 'package:provider/provider.dart';
import '../providers/data/global_items.dart';
import '../utils/extensions.dart';

class CreateItemPage extends StatefulWidget {
  final Item? item;
  final Task? task;
  final String newItemName;

  const CreateItemPage({
    Key? key,
    this.item,
    this.task,
    this.newItemName = '',
  }) : super(key: key);

  @override
  CreateItemPageState createState() => CreateItemPageState();
}

class CreateItemPageState extends State<CreateItemPage>
    with AutomaticKeepAliveClientMixin {
  final _suggestionsController = SuggestionsBoxController();
  final _nameController = TextEditingController();
  final _sizeController = TextEditingController();
  final _costController = TextEditingController();
  final _cutawayController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _sizeFocusNode = FocusNode();
  final _costFocusNode = FocusNode();
  final _cutawayFocusNode = FocusNode();

  final _scrollControllers = List.generate(2, (index) => ScrollController());

  final _form = GlobalKey<FormState>();
  final _selectedItemform = GlobalKey<FormState>();

  List<String> _units = [];
  String? _selectedUnit;
  String? _selectedType;
  String? _selectedVariety;

  GlobalItem? _selectedItem;
  var _isInit = true;
  var _isLoading = false;

  String newItemName = '';

  @override
  void initState() {
    super.initState();
    newItemName = widget.newItemName;
    _costFocusNode.addListener(() {
      if (_costFocusNode.hasFocus) {
        _costController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _costController.text.length,
        );
      }
    });

    if (widget.item != null) {
      context.read<TagsUIProvider>().tags = (widget.item?.tags ?? []);
    }
  }

  @override
  void dispose() {
    for (var element in _scrollControllers) {
      element.dispose();
    }
    _nameController.clear();
    _nameController.dispose();
    _sizeController.dispose();
    _costController.dispose();
    _cutawayController.dispose();

    _nameFocusNode.dispose();
    _sizeFocusNode.dispose();
    _costFocusNode.dispose();
    _cutawayFocusNode.dispose();
    newItemName = '';
    super.dispose();
  }

  void resetForm() {
    setState(() {
      _selectedUnit = null;
      _selectedType = null;
      _selectedVariety = null;
      _selectedItem = null;
      _nameController.clear();
      _sizeController.clear();
      _costController.clear();
      _cutawayController.clear();
    });
    context.read<TagsUIProvider>().clearAllTags();
    context.read<ItemProvider>().resetItem();
  }

  @override
  void didChangeDependencies() {
    final itemProvider = context.read<ItemProvider>();
    if (_isInit) {
      _nameController.text = itemProvider.name!;
      _sizeController.text =
          (itemProvider.size == null) ? '' : itemProvider.size.toString();
      _costController.text =
          (itemProvider.cost == null) ? '' : itemProvider.cost.toString();
      _cutawayController.text = (itemProvider.cutaway == null)
          ? '10'
          : ((itemProvider.cutaway ?? 10) * 100).toString();
      _selectedUnit = itemProvider.selectedUnit;
      _selectedType = itemProvider.selectedType;
      _selectedVariety = itemProvider.selectedVariety;
      _selectedItem = itemProvider.selectedItem;
      _units = itemProvider.units;
    }

    if (widget.item != null) {
      var cutaway = widget.item?.cutaway ?? 0;

      _nameController.text = widget.item?.name ?? '';
      _sizeController.text = widget.item?.size.toString() ?? '';
      _selectedUnit = widget.item?.unit ?? '';
      _selectedType = widget.item?.type ?? '';
      _selectedVariety = widget.item?.variety ?? '';
      _costController.text = widget.item?.cost.toString() ?? '';
      _cutawayController.text = (cutaway * 100).toString();
      _costFocusNode.requestFocus();
      _cutawayFocusNode.requestFocus();
    }

    if (newItemName.isNotEmpty) {
      _nameController.text = newItemName;
      itemProvider.resetItem();
      _selectedItem = null;
    }

    _isInit = false;
    super.didChangeDependencies();
  }

  void _saveForm() {
    final itemProvider = context.read<ItemProvider>();
    Item? itemToSave;
    final isValid =
        _form.currentState != null ? _form.currentState!.validate() : false;

    final tags = context.read<TagsUIProvider>().tags;

    if (_selectedItem != null) {
      itemToSave = Item(
        unit: _selectedItem!.unit,
        type: _selectedItem!.type,
        variety: _selectedItem!.variety,
        name: _selectedItem!.name,
        cutaway: (ParseUtil.toNum(_cutawayController.text.isNotEmpty
                ? _cutawayController.text
                : '0') /
            100),
        cost: ParseUtil.toNum(
            _costController.text.isNotEmpty ? _costController.text : '0'),
        size: _selectedItem!.size.toInt(),
        globalId: _selectedItem!.id,
        tags: tags,
      );
      saveItem(itemToSave);
      Navigator.pop(context);
    } else if (isValid) {
      itemToSave = Item(
        unit: _selectedUnit,
        type: _selectedType,
        variety: _selectedVariety,
        name: _nameController.text,
        cutaway: (ParseUtil.toNum(_cutawayController.text.isNotEmpty
                ? _cutawayController.text
                : '0') /
            100),
        cost: ParseUtil.toNum(
            _costController.text.isNotEmpty ? _costController.text : '0'),
        size: ParseUtil.toInt(_sizeController.text),
        globalId: _selectedItem?.id,
        tags: tags,
      );

      saveItem(itemToSave);
      itemProvider.resetItem();
      Navigator.pop(context);
    }
  }

  void saveItem(Item itemToSave) {
    var isItemInCount = false;
    String result;
    final itemProvider = context.read<ItemProvider>();
    final taskProvider = context.read<TaskProvider>();

    final currentCount =
        context.read<CountProvider>().findStartedOrPendingCount();

    if (widget.item != null) {
      itemToSave = itemToSave.copyWith(id: widget.item!.id);
      isItemInCount = context
          .read<CountItemProvider>()
          .isItemOrRecipeInCount(currentCount?.id, itemToSave.id);
    }

    final isInCurrentCount = currentCount != null && isItemInCount;

    if (isInCurrentCount) {
      final task = widget.item != null
          ? taskProvider.findTask(
              path: 'lists/items/edit-item/${widget.item!.id}')
          : null;

      if (itemToSave.cost == 0 && task == null) {
        context.read<TaskProvider>().createTask(
          type: TaskType.zeroCostItem,
          title: '${itemToSave.name} has a cost of 0',
          path: 'lists/items/edit-item/${itemToSave.id}',
          data: {'itemId': itemToSave.id},
        );
        context
            .read<ToastProvider>()
            .addToastMessage('Please define cost for ${itemToSave.name}.');
      } else if (itemToSave.cost == 0 && task != null) {
        context.read<TaskProvider>().updateTask(
          type: TaskType.zeroCostItem,
          title: '${itemToSave.name} has a cost of 0',
          path: 'lists/items/edit-item/${itemToSave.id}',
          data: {'itemId': itemToSave.id},
        );
        context
            .read<ToastProvider>()
            .addToastMessage('Please define cost for ${itemToSave.name}.');
      }
    }

    setState(() {
      _isLoading = true;
    });

    if (widget.item != null) {
      final task = taskProvider.findTask(
          path: 'lists/items/edit-item/${widget.item!.id}');
      itemProvider.updateItem(itemToSave, currentCount?.id).whenComplete(() {
        if (task != null && itemToSave.cost > 0) {
          taskProvider.softDeleteTask(taskId: task.id!);
        }
      });
      result = 'Item updated - ${itemToSave.name}';
    } else {
      itemProvider.createItem(itemToSave);
      result = 'Item created - ${itemToSave.name}';
    }

    setState(() {
      _isLoading = false;
    });

    showToast(context, result);

    if (widget.item == null) {
      itemProvider.resetItem();
      resetForm();
    }

    if (widget.task != null && itemToSave.cost > 0) {
      context.read<TaskProvider>().softDeleteTask(taskId: widget.task!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final globalItemProvider = context.watch<GlobalItemProvider>()..globalItems;
    final profileProvider = context.watch<ProfileProvider>()..profile;
    final isItemCutawayEnabled = profileProvider.profile.isItemCutawayEnabled;

    if (globalItemProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final itemProvider = context.read<ItemProvider>();

    Map<String, List<String>> types = {...itemProvider.types};
    List<String> varieties = types[_selectedType] ?? [];

    if (widget.item != null) {
      final String itemType = widget.item?.type ?? '?';
      final String itemVariety = widget.item?.variety ?? '?';

      if (!varieties.contains(itemVariety)) {
        varieties.add(itemVariety);
      }

      types.putIfAbsent(itemType, () => [...varieties]);
    }

    if (_isLoading) {
      return Center(
        child: StocklioScrollView(
          controller: _scrollControllers[1],
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_selectedItem != null) {
      return StocklioScrollView(
        controller: _scrollControllers[0],
        child: Form(
          key: _selectedItemform,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Center(
                child: PaddedText(
                  'Pre-Filled Item',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Card(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                      color: Theme.of(context).colorScheme.primary, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                margin: EdgeInsets.zero,
                color: Theme.of(context).colorScheme.background,
                elevation: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      leading:
                          Text('${StringUtil.localize(context).label_name}:'),
                      title: Text(_selectedItem!.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        color: Theme.of(context).colorScheme.primary,
                        onPressed: () {
                          setState(() {
                            itemProvider.resetItem();
                            _selectedItem = null;
                          });
                        },
                      ),
                    ),
                    ListTile(
                      leading:
                          Text('${StringUtil.localize(context).label_size}:'),
                      title:
                          Text('${_selectedItem!.size}${_selectedItem!.unit}'),
                    ),
                    ListTile(
                      leading:
                          Text('${StringUtil.localize(context).label_type}:'),
                      title: Text(_selectedItem!.type),
                    ),
                    ListTile(
                      leading: Text(
                          '${StringUtil.localize(context).label_variety}:'),
                      title: Text(_selectedItem!.variety),
                    ),
                  ],
                ),
              ),
              TextFormField(
                controller: _costController,
                decoration: InputDecoration(
                  labelText:
                      'Cost in ${profileProvider.profile.currencyLong} - optional',
                  alignLabelWithHint: true,
                ),
                inputFormatters: [
                  DecimalInputFormatter(),
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (value) {
                  context.read<ItemProvider>().cost = value;
                },
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              if (isItemCutawayEnabled)
                TextFormField(
                  controller: _cutawayController,
                  decoration: const InputDecoration(
                    labelText: 'Cutaway in Percentage - optional',
                    alignLabelWithHint: true,
                  ),
                  inputFormatters: [
                    DecimalInputFormatter(),
                    LengthLimitingTextInputFormatter(5),
                  ],
                  onChanged: (value) {
                    if (ParseUtil.toNum(value) > 100) {
                      _cutawayController.text = '100';
                    }
                    context.read<ItemProvider>().cutaway =
                        ParseUtil.toNum(_cutawayController.text);
                  },
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              const SizedBox(height: 16),
              StockifiButton(
                onPressed: _saveForm,
                child: Text(StringUtil.localize(context).label_submit),
              ),
            ],
          ),
        ),
      );
    }

    return StocklioScrollView(
      controller: _scrollControllers[1],
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            TypeAheadFormField(
              suggestionsBoxController: _suggestionsController,
              hideOnEmpty: true,
              textFieldConfiguration: TextFieldConfiguration(
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  alignLabelWithHint: true,
                ),
                controller: _nameController,
                onChanged: (value) {
                  newItemName = value;
                  context.read<ItemProvider>().name = value;
                },
                focusNode: _nameFocusNode,
                onSubmitted: (value) {
                  FocusScope.of(context).requestFocus(_sizeFocusNode);
                },
                textInputAction: TextInputAction.next,
              ),
              validator: (value) {
                return value!.trim().isEmpty ? 'Please enter name.' : null;
              },
              onSuggestionSelected: (suggestion) {
                setState(() {
                  _selectedItem = suggestion as GlobalItem?;
                });

                context.read<ItemProvider>().selectedItem =
                    suggestion as GlobalItem?;
              },
              itemBuilder: (context, itemData) {
                if (itemData == null) {
                  return ListTile(
                    title: GestureDetector(
                      onTap: () {
                        setState(() {
                          _nameController.text =
                              _nameController.text.toTitleCase();
                        });
                        _sizeFocusNode.requestFocus();
                      },
                      child: Text(
                        'Create New Item: ${_nameController.text.toTitleCase()}',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }

                final item = itemData as GlobalItem;
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('${item.size}${item.unit}'),
                );
              },
              suggestionsCallback: (pattern) {
                if (pattern.isEmpty || widget.item != null) return [];
                final query = context.read<ItemProvider>().name!;
                final results = globalItemProvider.search(query, limit: 9);
                return [null, ...results];
              },
              suggestionsBoxDecoration: SuggestionsBoxDecoration(
                color: Theme.of(context).colorScheme.background,
              ),
            ),
            GestureDetector(
              onTap: widget.item == null
                  ? null
                  : () {
                      showToast(
                        context,
                        'Size is not editable',
                      );
                    },
              child: TextFormField(
                style: _selectedType != 'Diverse' && widget.item == null
                    ? null
                    : TextStyle(
                        color:
                            AppTheme.instance.disabledTextFormFieldTextColor),
                enabled: widget.item == null && _selectedType != 'Diverse',
                controller: _sizeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelStyle: TextStyle(
                      color: AppTheme.instance.disabledTextFormFieldLabelColor),
                  labelText: 'Size',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  return value!.trim().isEmpty ? 'Please enter size.' : null;
                },
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^[1-9]\d{0,6}')),
                ],
                onChanged: (value) {
                  context.read<ItemProvider>().size = value;
                },
                focusNode: _sizeFocusNode,
                onFieldSubmitted: (value) {
                  FocusScope.of(context).requestFocus(_costFocusNode);
                },
                textInputAction: TextInputAction.next,
              ),
            ),
            GestureDetector(
              onTap: widget.item == null
                  ? null
                  : () {
                      showToast(
                        context,
                        'Unit is not editable',
                      );
                    },
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'Unit',
                ),
                validator: (value) {
                  return _selectedUnit == null ? 'Please select unit.' : null;
                },
                value: _selectedUnit,
                items: _units.map((e) {
                  return DropdownMenuItem<String>(value: e, child: Text(e));
                }).toList(),
                onChanged: widget.item != null || _selectedType == 'Diverse'
                    ? null
                    : (value) {
                        setState(() {
                          _selectedUnit = value;
                        });
                        context.read<ItemProvider>().selectedUnit = value;
                      },
              ),
            ),
            GestureDetector(
              onTap: widget.item == null
                  ? null
                  : () {
                      showToast(
                        context,
                        'Type is not editable',
                      );
                    },
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'Type',
                ),
                validator: (value) {
                  return _selectedType == null ? 'Please select type.' : null;
                },
                value: _selectedType,
                items: types.keys.map((e) {
                  return DropdownMenuItem<String>(value: e, child: Text(e));
                }).toList(),
                onChanged: widget.item != null
                    ? null
                    : (value) {
                        final previousSelectedType =
                            context.read<ItemProvider>().selectedType;
                        setState(() {
                          _selectedType = value;
                          _selectedVariety = types[_selectedType]!.length >= 2
                              ? null
                              : types[_selectedType]!.first;
                          context.read<ItemProvider>().selectedVariety =
                              _selectedVariety;
                        });
                        if (_selectedType == 'Diverse') {
                          context.read<ItemProvider>().size = '1';
                          context.read<ItemProvider>().selectedUnit = 'pcs';
                          _selectedUnit = 'pcs';
                          _sizeController.text = '1';
                          showToast(
                              context,
                              StringUtil.localize(context)
                                  .message_diverse_selected);
                        } else if (_selectedType != 'Diverse' &&
                            previousSelectedType == 'Diverse') {
                          setState(() {
                            _sizeController.text = '';
                            _selectedUnit = null;
                          });
                          context.read<ItemProvider>().selectedUnit = null;
                          context.read<ItemProvider>().size = '';
                        }
                        context.read<ItemProvider>().selectedType = value;
                      },
              ),
            ),
            GestureDetector(
              onTap: widget.item == null
                  ? null
                  : () {
                      showToast(
                        context,
                        'Variety is not editable',
                      );
                    },
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'Variety',
                ),
                validator: (value) {
                  return _selectedVariety == null
                      ? 'Please select variety.'
                      : null;
                },
                value: _selectedVariety,
                items: varieties.map((e) {
                  return DropdownMenuItem<String>(value: e, child: Text(e));
                }).toList(),
                onChanged: widget.item != null
                    ? null
                    : (value) {
                        setState(() {
                          _selectedVariety = value;
                        });

                        context.read<ItemProvider>().selectedVariety = value;
                      },
              ),
            ),
            TextFormField(
              focusNode: _costFocusNode,
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Cost - optional',
                alignLabelWithHint: true,
              ),
              inputFormatters: [
                DecimalInputFormatter(),
                LengthLimitingTextInputFormatter(10),
              ],
              onChanged: (value) {
                context.read<ItemProvider>().cost = value;
              },
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
            ),
            if (isItemCutawayEnabled && _selectedType == "Mat")
              TextFormField(
                focusNode: _cutawayFocusNode,
                controller: _cutawayController,
                decoration: const InputDecoration(
                  labelText: 'Cutaway % - optional',
                  alignLabelWithHint: true,
                ),
                inputFormatters: [
                  DecimalInputFormatter(),
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (value) {
                  if (ParseUtil.toNum(value) > 100) {
                    _cutawayController.text = '100';
                  }
                  context.read<ItemProvider>().cutaway =
                      ParseUtil.toNum(_cutawayController.text);
                },
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
              ),
            const SizedBox(height: 16),
            if (context.read<ProfileProvider>().profile.isItemTagsEnabled)
              const ItemTags(),
            const SizedBox(height: 16),
            StockifiButton.async(
              onPressed: _saveForm,
              child: Text(StringUtil.localize(context).label_submit),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
