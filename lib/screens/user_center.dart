import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/notifications.dart';
import 'package:stocklio_flutter/providers/data/tasks.dart';
import 'package:stocklio_flutter/providers/ui/user_center_provider.dart';
import 'package:stocklio_flutter/screens/task_center.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/widgets/common/padded_text.dart';
import 'package:stocklio_flutter/widgets/features/notifications/notification_center.dart';

class UserCenterPopup extends StatefulWidget {
  const UserCenterPopup({Key? key, this.initialIndex = 1}) : super(key: key);

  final int initialIndex;

  @override
  State<UserCenterPopup> createState() => _UserCenterPopupState();
}

class _UserCenterPopupState extends State<UserCenterPopup>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialIndex,
  );

  @override
  Widget build(BuildContext context) {
    final isVisible = context.watch<UserCenterProvider>().isVisible;

    return Visibility(
      visible: isVisible,
      child: Positioned(
        top: 2,
        right: 8,
        child: SizedBox(
          width: 318,
          height: 500,
          child: Column(
            children: [
              Container(
                color: Theme.of(context).colorScheme.background,
                child: TabBar(
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  controller: _tabController,
                  tabs: [
                    Consumer<NotificationProvider>(
                      builder: ((context, value, child) {
                        final unreadNotificationsLength =
                            value.unreadNotifications.length;

                        final text = PaddedText(
                          StringUtil.localize(context).label_notifications,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        );
                        if (unreadNotificationsLength == 0) return text;
                        return PaddedText(
                          '${StringUtil.localize(context).label_notifications} ($unreadNotificationsLength)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        );
                      }),
                    ),
                    Consumer<TaskProvider>(
                      builder: ((context, value, child) {
                        final tasksLength = value.tasks.length;

                        final text = PaddedText(
                          StringUtil.localize(context).label_tasks,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        );
                        if (tasksLength == 0) return text;
                        return PaddedText(
                          '${StringUtil.localize(context).label_tasks} ($tasksLength)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    NotificationCenter(),
                    TaskCenter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserCenterButton extends StatelessWidget {
  const UserCenterButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final userCenterProvider = context.watch<UserCenterProvider>();
    final tasks = context.watch<TaskProvider>().tasks;
    final notifications =
        context.watch<NotificationProvider>().unreadNotifications;

    final total = tasks.length + notifications.length;

    return IconButton(
      onPressed: () {
        userCenterProvider.toggleUserCenter();
      },
      icon: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.all_inbox_rounded),
          if (total > 0)
            Positioned(
              top: total < 10 ? -2 : -4,
              right: total < 10 ? -2 : -4,
              child: const Badge(
                smallSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}
