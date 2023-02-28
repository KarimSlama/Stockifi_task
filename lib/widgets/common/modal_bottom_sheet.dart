import 'package:flutter/material.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/widgets/common/stocklio_scrollview.dart';

class StocklioModalBottomSheet extends StatefulWidget {
  const StocklioModalBottomSheet({
    Key? key,
    required this.children,
    this.actions = const <Widget>[],
    this.label,
    this.scrollController,
  }) : super(key: key);

  final List<Widget> children;
  final String? label;
  final List<Widget> actions;
  final ScrollController? scrollController;

  @override
  State<StocklioModalBottomSheet> createState() =>
      _StocklioModalBottomSheetState();
}

class _StocklioModalBottomSheetState extends State<StocklioModalBottomSheet> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          ///This column is error
          children: [
            if (widget.label != null)
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.instance.themeData.colorScheme.background,
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                            color: Colors.black54,
                            blurRadius: 4.0,
                            offset: Offset(0.0, 0.75))
                      ],
                    ),
                    width: MediaQuery.of(context).size.width,
                    height: 70,
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.label!,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            ...widget.actions,
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            Expanded(
              child: StocklioScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...widget.children,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
