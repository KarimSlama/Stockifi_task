import 'package:flutter/material.dart';
import 'package:stocklio_flutter/widgets/shimmer/inprogress_shimmer.dart';
import '../providers/data/counts.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class InProgressPage extends StatelessWidget {
  InProgressPage({Key? key, this.itemName}) : super(key: key);
  String? itemName;

  @override
  Widget build(BuildContext context) {
    final countProvider = context.watch<CountProvider>()..counts;

    if (countProvider.isLoading) {
      return const InProgressShimmer();
    }

    return const SizedBox();
  }
}

class InProgressRoute<T> extends PageRoute<T> {
  InProgressRoute({
    required WidgetBuilder builder,
    bool fullscreenDialog = true,
  })  : _builder = builder,
        super(fullscreenDialog: fullscreenDialog);

  final WidgetBuilder _builder;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => Colors.black54;

  @override
  String? get barrierLabel => 'Settings dialog open';

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _builder(context);
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 100);
}
