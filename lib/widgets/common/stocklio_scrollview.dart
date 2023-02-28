import 'package:flutter/material.dart';

class StocklioScrollView extends StatefulWidget {
  final Widget child;
  final ScrollController? controller;
  final Axis? scrollDirection;
  final bool showScrollbarOnTopAndBottom;
  final bool showScrollbar;
  final EdgeInsets padding;

  const StocklioScrollView({
    Key? key,
    required this.child,
    this.controller,
    this.scrollDirection,
    this.showScrollbarOnTopAndBottom = false,
    this.showScrollbar = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0),
  }) : super(key: key);

  @override
  State<StocklioScrollView> createState() => _StocklioScrollViewState();
}

class _StocklioScrollViewState extends State<StocklioScrollView> {
  final scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scrollView = SingleChildScrollView(
      key: widget.key,
      scrollDirection: widget.scrollDirection ?? Axis.vertical,
      controller: widget.controller ?? scrollController,
      child: Padding(
        padding: widget.padding,
        child: widget.child,
      ),
    );

    if (!widget.showScrollbar) return scrollView;

    final scrollViewWithScrollbar = Scrollbar(
      controller: widget.controller ?? scrollController,
      thumbVisibility: true,
      scrollbarOrientation:
          widget.showScrollbarOnTopAndBottom ? ScrollbarOrientation.top : null,
      child: scrollView,
    );

    return widget.showScrollbarOnTopAndBottom
        ? Scrollbar(
            thumbVisibility: true,
            controller: widget.controller ?? scrollController,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: scrollViewWithScrollbar,
          )
        : scrollViewWithScrollbar;
  }
}
