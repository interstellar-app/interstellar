import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/api/notifications.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/notification.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/error_page.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'notification_count_controller.dart';
import 'notification_item.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with AutomaticKeepAliveClientMixin<NotificationsScreen> {
  NotificationsFilter filter = NotificationsFilter.all;

  final PagingController<String, NotificationModel> _pagingController =
      PagingController(firstPageKey: '');

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener(_fetchPage);
  }

  Future<void> _fetchPage(String pageKey) async {
    // Reload notification count on screen load or when screen is refreshed
    if (pageKey.isEmpty) {
      context.read<NotificationCountController>().reload();
    }

    try {
      final newPage = await context
          .read<AppController>()
          .api
          .notifications
          .list(page: nullIfEmpty(pageKey), filter: filter);

      // Check BuildContext
      if (!mounted) return;

      // Prevent duplicates
      final currentItemIds = _pagingController.itemList?.map((e) => e.id) ?? [];
      final newItems = newPage.items
          .where((e) => !currentItemIds.contains(e.id))
          .toList();

      _pagingController.appendPage(newItems, newPage.nextPage);
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentNotificationFilter = notificationFilterSelect(
      context,
    ).getOption(filter);

    return RefreshIndicator(
      onRefresh: () => Future.sync(() => _pagingController.refresh()),
      child: CustomScrollView(
        slivers: [
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
          PagedSliverList(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<NotificationModel>(
              firstPageErrorIndicatorBuilder: (context) =>
                  FirstPageErrorIndicator(
                    error: _pagingController.error,
                    onTryAgain: _pagingController.retryLastFailedRequest,
                  ),
              newPageErrorIndicatorBuilder: (context) => NewPageErrorIndicator(
                error: _pagingController.error,
                onTryAgain: _pagingController.retryLastFailedRequest,
              ),
              itemBuilder: (context, item, index) =>
                  // Hide notifications that could not be matched correctly
                  item.type == null ||
                      item.subject == null ||
                      item.creator == null ||
                      // If Lemmy, then hide items that come from the current user, in order to show only real "notifications".
                      // You also can't change the read state of said items anyway.
                      context.watch<AppController>().serverSoftware ==
                              ServerSoftware.lemmy &&
                          item.creator?.name ==
                              context.watch<AppController>().localName
                  ? SizedBox()
                  : Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      child: NotificationItem(item, (newValue) {
                        var newList = _pagingController.itemList;
                        newList![index] = newValue;
                        setState(() {
                          _pagingController.itemList = newList;
                        });
                      }),
                    ),
            ),
          ),
        ],
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
