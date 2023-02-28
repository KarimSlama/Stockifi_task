import 'package:flutter/material.dart';

import 'connectivity_indicator.dart';

class StocklioPage extends StatelessWidget {
  final String title;
  final Widget child;

  const StocklioPage({
    Key? key,
    this.title = 'Page',
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class StocklioModal extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget child;
  final bool fullscreenDialog;
  final bool resizeToAvoidBottomInset;
  final Function? onClose;

  const StocklioModal({
    Key? key,
    this.title = '',
    this.subtitle = '',
    this.actions = const [],
    this.fullscreenDialog = true,
    required this.child,
    this.resizeToAvoidBottomInset = true,
    this.onClose,
  }) : super(key: key);

  void _tap(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!fullscreenDialog) {
      return GestureDetector(
        onTap: () => _tap(context),
        child: Align(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            width: 300,
            height: 600,
            child: child,
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (onClose != null) {
              onClose!();
            } else {
              _tap(context);
            }
          },
        ),
        centerTitle: false,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12.0),
              )
          ],
        ),
        actions: actions,
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
      body: Column(
        children: [
          const ConnectivityIndicator(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({
    Key? key,
    required this.index,
    required this.children,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.sizing = StackFit.loose,
  }) : super(key: key);

  final int index;
  final List<Widget> children;
  final AlignmentGeometry alignment;
  final TextDirection? textDirection;
  final StackFit sizing;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late Map<int, bool> _innerWidgetMap;

  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.index;
    _innerWidgetMap = Map<int, bool>.fromEntries(
      List<MapEntry<int, bool>>.generate(
        widget.children.length,
        (int i) => MapEntry<int, bool>(i, i == index),
      ),
    );
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _changeIndex(widget.index);
    }
  }

  void _activeCurrentIndex(int index) {
    if (_innerWidgetMap[index] != true) {
      _innerWidgetMap[index] = true;
    }
  }

  void _changeIndex(int value) {
    if (value == index) {
      return;
    }
    setState(() {
      index = value;
    });
  }

  bool _hasInit(int index) {
    final result = _innerWidgetMap[index];
    if (result == null) {
      return false;
    }
    return result == true;
  }

  List<Widget> _buildChildren(BuildContext context) {
    final list = <Widget>[];
    for (var i = 0; i < widget.children.length; i++) {
      if (_hasInit(i)) {
        list.add(widget.children[i]);
      } else {
        list.add(const SizedBox.shrink());
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    _activeCurrentIndex(index);
    return IndexedStack(
      index: index,
      alignment: widget.alignment,
      sizing: widget.sizing,
      textDirection: widget.textDirection,
      children: _buildChildren(context),
    );
  }
}
