import 'package:flutter/material.dart';
import 'package:interstellar/src/api/notifications.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/notification.dart';
import 'package:interstellar/src/screens/account/notification/notification_count_controller.dart';
import 'package:interstellar/src/screens/account/notification/notification_item.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/paging.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with AutomaticKeepAliveClientMixin<NotificationsScreen> {
  NotificationsFilter filter = NotificationsFilter.all;

  late final _pagingController =
      AdvancedPagingController<String, NotificationModel, int>(
        logger: context.read<AppController>().logger,
        firstPageKey: '',
        getItemId: (item) => item.id,
        fetchPage: (pageKey) async {
          final ac = context.read<AppController>();

          // Reload notification count on screen load or when screen is refreshed
          if (pageKey.isEmpty) {
            context.read<NotificationCountController>().reload();
          }

          final newPage = await ac.api.notifications.list(
            page: nullIfEmpty(pageKey),
            filter: filter,
          );

          return (newPage.items, newPage.nextPage);
        },
      );

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentNotificationFilter = notificationFilterSelect(
      context,
    ).getOption(filter);

    return AdvancedPagedScrollView(
      controller: _pagingController,
      leadingSlivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    padding: chipDropdownPadding,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(currentNotificationFilter.title),
                        const Icon(Symbols.arrow_drop_down_rounded),
                      ],
                    ),
                    onPressed: () async {
                      final result = await notificationFilterSelect(
                        context,
                      ).askSelection(context, filter);

                      if (result != null) {
                        setState(() {
                          filter = result;
                          _pagingController.refresh();
                        });
                      }
                    },
                  ),
                ),
                LoadingOutlinedButton(
                  onPressed: () async {
                    await context
                        .read<AppController>()
                        .api
                        .notifications
                        .putReadAll();
                    _pagingController.refresh();

                    if (!context.mounted) return;
                    context.read<NotificationCountController>().reload();
                  },
                  label: Text(l(context).notifications_readAll),
                  icon: const Icon(Symbols.mark_chat_read, size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
      itemBuilder: (context, item, index) =>
          // Hide notifications that could not be matched correctly
          item.type == null ||
              item.subject == null ||
              item.creator == null ||
              // If Lemmy, then hide items that come from the current user, in order to show only real "notifications".
              // You also can't change the read state of said items anyway.
              context.watch<AppController>().serverSoftware ==
                      ServerSoftware.lemmy &&
                  item.creator?.name == context.watch<AppController>().localName
          ? const SizedBox()
          : Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: NotificationItem(
                item,
                (newValue) => _pagingController.updateItem(item, newValue),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}

SelectionMenu<NotificationsFilter> notificationFilterSelect(
  BuildContext context,
) => SelectionMenu(l(context).filter, [
  SelectionMenuItem(
    value: NotificationsFilter.all,
    title: l(context).filter_all,
    icon: Symbols.filter_list_rounded,
  ),
  SelectionMenuItem(
    value: NotificationsFilter.new_,
    title: l(context).filter_new,
    icon: Symbols.nest_eco_leaf_rounded,
  ),
  if (context.read<AppController>().serverSoftware == ServerSoftware.mbin ||
      context.read<AppController>().serverSoftware == ServerSoftware.piefed)
    SelectionMenuItem(
      value: NotificationsFilter.read,
      title: l(context).filter_read,
      icon: Symbols.mark_chat_read_rounded,
    ),
]);
