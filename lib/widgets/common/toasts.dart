import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/app_config.dart';
import 'package:stocklio_flutter/providers/ui/toast_provider.dart';

typedef ToastListItemBuilder = Widget Function(
    BuildContext context, int index, Animation animation);

class StocklioToast extends StatefulWidget {
  const StocklioToast({Key? key}) : super(key: key);

  @override
  State<StocklioToast> createState() => _StocklioToastState();
}

class _StocklioToastState extends State<StocklioToast> {
  final toastsListKey = GlobalKey<AnimatedListState>();

  Widget buildItem(
    List<Toast> toastMessages,
    BuildContext context,
    int index,
    animation, {
    bool isRemoving = false,
  }) {
    if (!isRemoving) {
      final toastProvider = context.read<ToastProvider>();
      final appConfigProvider = context.read<AppConfigProvider>();
      final timer = toastProvider.getToastTimer(toastMessages[index].id);

      if (timer == null) {
        final newTimer = Timer(
          Duration(seconds: appConfigProvider.appConfig.toastDuration),
          () {
            toastsListKey.currentState?.removeItem(
              0,
              (context, animation) => buildItem(
                toastMessages,
                context,
                0,
                animation,
                isRemoving: true,
              ),
            );

            toastProvider.removeToast(toastMessages[index].id);
          },
        );
        toastProvider.addToastTimer(toastMessages[index].id, newTimer);
      }
    }

    final toastWidget = ToastWidget(
      key: ValueKey(toastMessages[index].id),
      index: index,
      toast: toastMessages[index],
      builder: (context, index, animation) =>
          buildItem(toastMessages, context, index, animation),
    );

    if (isRemoving) {
      return FadeTransition(
        opacity: animation,
        child: toastWidget,
      );
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: const Offset(0, 0),
      ).animate(animation),
      child: toastWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final toastProvider = context.watch<ToastProvider>();
    final toastMessages = toastProvider.toastMessages;

    if (toastProvider.hasNewToast) {
      toastsListKey.currentState?.insertItem(
        toastMessages.length - 1,
        duration: const Duration(milliseconds: 350),
      );
      toastProvider.hasNewToast = false;
    }

    if (toastMessages.isEmpty) {
      return const SizedBox.shrink();
    }

    double maxWidth;
    final val = toastMessages[0].message.length * 7.3;
    if (val <= MediaQuery.of(context).size.width * 0.5) {
      maxWidth = val;
    } else {
      maxWidth = MediaQuery.of(context).size.width * 0.5;
    }
    if (maxWidth <= 50) {
      maxWidth = MediaQuery.of(context).size.width * 0.1;
    } else if (maxWidth <= MediaQuery.of(context).size.width * 0.1) {
      maxWidth = MediaQuery.of(context).size.width * 0.1;
    }

    return Positioned(
      top: 16,
      right: 16,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          minWidth: 50,
        ),
        child: SafeArea(
          child: AnimatedList(
            reverse: true,
            shrinkWrap: true,
            key: toastsListKey,
            initialItemCount: toastMessages.length,
            itemBuilder: (context, index, animation) =>
                buildItem(toastMessages, context, index, animation),
          ),
        ),
      ),
    );
  }
}

class ToastWidget extends StatefulWidget {
  final Toast toast;
  final ToastListItemBuilder builder;
  final int index;

  const ToastWidget({
    Key? key,
    required this.toast,
    required this.builder,
    required this.index,
  }) : super(key: key);

  @override
  State<ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget> {
  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(25.0),
      child: Padding(
        key: widget.key,
        padding: const EdgeInsets.only(bottom: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.9),
          ),
          child: Text(
            widget.toast.message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.background,
            ),
          ),
        ),
      ),
    );
  }
}
