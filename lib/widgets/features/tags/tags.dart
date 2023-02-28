import 'package:flutter/material.dart';

import 'package:stocklio_flutter/providers/data/tags.dart';
import 'package:stocklio_flutter/providers/ui/tags_ui_provider.dart';
import 'package:stocklio_flutter/utils/logger_util.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/widgets/common/base_button.dart';
import 'package:stocklio_flutter/widgets/common/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class ItemTags extends StatelessWidget {
  const ItemTags({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tags = context.watch<TagsUIProvider>().tags;

    final List<Widget> tagWidgets = tags.map(
      (tag) {
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tag),
              const SizedBox(width: 4),
              const Icon(
                Icons.close,
                size: 16,
              ),
            ],
          ),
          onSelected: (_) => context.read<TagsUIProvider>().removeTag(tag),
        );
      },
    ).toList();

    tagWidgets.insert(
      0,
      FilterChip(
        backgroundColor: Theme.of(context).colorScheme.primary,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(StringUtil.localize(context).label_add_tag),
            const SizedBox(width: 4),
            const Icon(
              Icons.add,
              size: 16,
            ),
          ],
        ),
        onSelected: (value) {
          showModalBottomSheet(
            useRootNavigator: true,
            context: context,
            builder: (ctx) {
              return const TagsModal();
            },
          );
        },
      ),
    );

    return Wrap(
      spacing: 4,
      runSpacing: -8,
      children: tagWidgets,
    );
  }
}

class TagsModal extends StatefulWidget {
  const TagsModal({super.key});

  @override
  State<TagsModal> createState() => _TagsModalState();
}

class _TagsModalState extends State<TagsModal> {
  final _searchTagController = TextEditingController();
  final _scrollController = ScrollController();
  final _tagFocusNode = FocusNode();
  var isSelectedAll = false;

  String _query = '';

  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _searchTagController.dispose();
    try {
      _scrollController.dispose();
    } catch (e) {
      logger.i('TagsModal _scrollController: $e');
    }

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    setIsSelectedAll();
  }

  void setIsSelectedAll() {
    final tagsProvider = context.read<TagsProvider>()..tags;
    final tagsUIProviderTags = context.read<TagsUIProvider>().tags;
    final tags = tagsProvider.search(_query);
    final tagsFiltered = tags
        .where((tagObject) =>
            tagsUIProviderTags.any((tagString) => tagString == tagObject.name))
        .toList();

    ///Prevent setting [isSelectedAll] to true if both tagsFiltered and tags are empty
    if (tagsFiltered.isNotEmpty && tagsFiltered.length == tags.length) {
      setState(() {
        isSelectedAll = true;
      });
    } else {
      setState(() {
        isSelectedAll = false;
      });
    }
  }

  void _createTag() {
    final isValid =
        _form.currentState != null ? _form.currentState!.validate() : false;

    if (isValid) {
      context.read<TagsProvider>().createTag(_searchTagController.text);
      context.read<TagsUIProvider>().addTag(_searchTagController.text);
      _query = "";
      _searchTagController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagsProvider = context.watch<TagsProvider>()..tags;

    if (tagsProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    final tags = tagsProvider.search(_query);

    return StocklioModalBottomSheet(
      scrollController: _scrollController,
      label: StringUtil.localize(context).label_add_tag,
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Form(
                    key: _form,
                    child: TextFormField(
                      focusNode: _tagFocusNode,
                      decoration: InputDecoration(
                        labelText: StringUtil.localize(context).label_search,
                      ),
                      controller: _searchTagController,
                      validator: (value) {
                        return value!.trim().isEmpty
                            ? StringUtil.localize(context)
                                .label_please_enter_tag_name
                            : null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _query = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                StockifiButton(
                  onPressed: _createTag,
                  child: Text(StringUtil.localize(context).label_add_tag),
                ),
                _searchTagController.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _searchTagController.clear();
                            _query = _searchTagController.text;
                          });
                        },
                      ),
              ],
            ),
          ),
        ),
        if (tags.length > 2)
          CheckboxListTile(
            value: isSelectedAll,
            onChanged: (_) {
              setState(() {
                isSelectedAll = !isSelectedAll;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final tagsUIProvider = context.read<TagsUIProvider>();
                if (isSelectedAll) {
                  for (var tag in tags) {
                    if (!tagsUIProvider.tags.contains(tag.name)) {
                      context.read<TagsUIProvider>().addTag(tag.name);
                    }
                  }
                } else {
                  context.read<TagsUIProvider>().clearAllTags();
                }
              });
            },
            controlAffinity: ListTileControlAffinity.trailing,
            title: const Text('Select all'),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ...tags.map(
          (e) {
            return CheckboxListTile(
              value: isSelectedAll ||
                  context.watch<TagsUIProvider>().tags.contains(e.name),
              onChanged: (_) {
                final tagsUIProvider = context.read<TagsUIProvider>();
                tagsUIProvider.toggleItemTag(e.name);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setIsSelectedAll();
                });
              },
              controlAffinity: ListTileControlAffinity.trailing,
              title: Text(e.name),
              activeColor: Theme.of(context).colorScheme.primary,
            );
          },
        ).toList(),
      ],
    );
  }
}
