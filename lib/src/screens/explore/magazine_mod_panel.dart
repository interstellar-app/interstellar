import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/magazine.dart';
import 'package:interstellar/src/screens/explore/user_item.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/error_page.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:provider/provider.dart';

class MagazineModPanel extends StatefulWidget {
  final DetailedMagazineModel initData;
  final void Function(DetailedMagazineModel) onUpdate;

  const MagazineModPanel({
    super.key,
    required this.initData,
    required this.onUpdate,
  });

  @override
  State<MagazineModPanel> createState() => _MagazineModPanelState();
}

class _MagazineModPanelState extends State<MagazineModPanel> {
  late DetailedMagazineModel _data;

  @override
  void initState() {
    super.initState();

    _data = widget.initData;
  }

  @override
  Widget build(BuildContext context) {
    onUpdate(DetailedMagazineModel newValue) {
      setState(() {
        _data = newValue;
        widget.onUpdate(newValue);
      });
    }

    return DefaultTabController(
      length: 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mod Panel for ${widget.initData.name}'),
          bottom: const TabBar(tabs: <Widget>[Tab(text: 'Bans')]),
        ),
        body: TabBarView(
          physics: appTabViewPhysics(context),
          children: <Widget>[
            MagazineModPanelBans(data: _data, onUpdate: onUpdate),
          ],
        ),
      ),
    );
  }
}

class MagazineModPanelBans extends StatefulWidget {
  final DetailedMagazineModel data;
  final void Function(DetailedMagazineModel) onUpdate;

  const MagazineModPanelBans({
    super.key,
    required this.data,
    required this.onUpdate,
  });

  @override
  State<MagazineModPanelBans> createState() => _MagazineModPanelBansState();
}

class _MagazineModPanelBansState extends State<MagazineModPanelBans> {
  final PagingController<String, MagazineBanModel> _pagingController =
      PagingController(firstPageKey: '');

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener(_fetchPage);
  }

  Future<void> _fetchPage(String pageKey) async {
    try {
      final newPage = await context
          .read<AppController>()
          .api
          .magazineModeration
          .listBans(widget.data.id, page: nullIfEmpty(pageKey));

      // Check BuildContext
      if (!mounted) return;

      // Prevent duplicates
      final currentItemIds =
          _pagingController.itemList?.map(
            (e) => (e.magazine.id, e.bannedUser.id),
          ) ??
          [];
      final newItems = newPage.items
          .where(
            (e) => !currentItemIds.contains((e.magazine.id, e.bannedUser.id)),
          )
          .toList();

      _pagingController.appendPage(newItems, newPage.nextPage);
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => Future.sync(() => _pagingController.refresh()),
      child: CustomScrollView(
        slivers: [
          PagedSliverList(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<MagazineBanModel>(
              firstPageErrorIndicatorBuilder: (context) =>
                  FirstPageErrorIndicator(
                    error: _pagingController.error,
                    onTryAgain: _pagingController.retryLastFailedRequest,
                  ),
              newPageErrorIndicatorBuilder: (context) => NewPageErrorIndicator(
                error: _pagingController.error,
                onTryAgain: _pagingController.retryLastFailedRequest,
              ),
              itemBuilder: (context, item, index) => UserItemSimple(
                item.bannedUser,
                trailingWidgets: [
                  LoadingOutlinedButton(
                    onPressed: () async {
                      await context
                          .read<AppController>()
                          .api
                          .magazineModeration
                          .removeBan(widget.data.id, item.bannedUser.id);

                      var newList = _pagingController.itemList;
                      newList!.removeAt(index);
                      setState(() {
                        _pagingController.itemList = newList;
                      });
                    },
                    label: const Text('Unban'),
                  ),
                ],
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
