import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/notification.dart';
import 'package:stocklio_flutter/providers/data/notifications.dart';
import 'package:stocklio_flutter/providers/ui/recipe_list_ui_provider.dart';
import 'package:stocklio_flutter/providers/ui/user_center_provider.dart';
import 'package:stocklio_flutter/utils/string_util.dart';

class NotificationCenter extends StatefulWidget {
  const NotificationCenter({Key? key}) : super(key: key);

  @override
  State<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends State<NotificationCenter> {
  final scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>()
      ..notifications;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Theme.of(context).colorScheme.background,
      child: Column(
        children: [
          if (notificationProvider.unreadNotifications.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 40,
                child: TextButton(
                    onPressed: () {
                      notificationProvider.markAllNotificationsAsRead(
                          notificationProvider.notifications);
                    },
                    child: Text(
                        StringUtil.localize(context).label_mark_all_as_read)),
              ),
            ),
          Expanded(
            child: ListView.separated(
              separatorBuilder: (context, index) => const Divider(height: 2),
              controller: scrollController,
              itemCount: notificationProvider.notifications.length,
              itemBuilder: (context, index) => NotificationListTile(
                  notification: notificationProvider.notifications[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationListTile extends StatelessWidget {
  final StockifiNotification notification;

  const NotificationListTile({
    Key? key,
    required this.notification,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final userCenterProvider = context.watch<UserCenterProvider>();

    return ListTile(
      selected: !notification.isDismissed,
      onTap: () async {
        userCenterProvider.toggleUserCenter();
        notificationProvider.setNotificationIsDismissed(notification, true);
        if (notification.path != null) {
          var newPath = '';
          var pathArray = notification.path?.split('?');
          if (notification.body!.contains('Dish') ||
              notification.body!.contains('Dishes')) {
            final recipeListUIProvider = context.read<RecipeListUIProvider>();
            recipeListUIProvider.setRecipeListIndex(2);
            newPath = '${pathArray![0]}?${pathArray[1]}&recipeType=dish';
          } else {
            final recipeListUIProvider = context.read<RecipeListUIProvider>();
            recipeListUIProvider.setRecipeListIndex(1);
            newPath = '${pathArray![0]}?${pathArray[1]}&recipeType=prebatch';
          }
          context.go(newPath);
        }
      },
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      title: Text(notification.title ?? ''),
      subtitle: Text(notification.body ?? ''),
      trailing: const Icon(Icons.find_in_page_outlined),
    );
  }
}
