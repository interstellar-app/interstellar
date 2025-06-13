import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/screens/explore/user_item.dart';
import 'package:interstellar/src/utils/breakpoints.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/error_page.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/screens/explore/user_screen.dart';
import 'package:interstellar/src/screens/feed/post_comment_screen.dart';
import 'package:interstellar/src/screens/feed/post_page.dart';
import 'package:interstellar/src/api/community_moderation.dart';
import 'package:interstellar/src/widgets/display_name.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:provider/provider.dart';

class CommunityModPanel extends StatefulWidget {
  final DetailedCommunityModel initData;
  final void Function(DetailedCommunityModel) onUpdate;

  const CommunityModPanel({
    super.key,
    required this.initData,
    required this.onUpdate,
  });

  @override
  State<CommunityModPanel> createState() => _CommunityModPanelState();
}

class _CommunityModPanelState extends State<CommunityModPanel> {
  late DetailedCommunityModel _data;

  @override
  void initState() {
    super.initState();

    _data = widget.initData;
  }

  @override
  Widget build(BuildContext context) {
    onUpdate(DetailedCommunityModel newValue) {
      setState(() {
        _data = newValue;
        widget.onUpdate(newValue);
      });
    }

    return DefaultTabController(
      length:
          context.read<AppController>().serverSoftware == ServerSoftware.mbin
          ? 2
          : 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mod Panel for ${widget.initData.name}'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Bans'),
              if (context.read<AppController>().serverSoftware ==
                  ServerSoftware.mbin)
                Tab(text: 'Reports'),
            ],
          ),
        ),
        body: TabBarView(
          physics: appTabViewPhysics(context),
          children: <Widget>[
            CommunityModPanelBans(data: _data, onUpdate: onUpdate),
            if (context.read<AppController>().serverSoftware ==
                ServerSoftware.mbin)
              CommunityModPanelReports(data: _data, onUpdate: onUpdate),
          ],
        ),
      ),
    );
  }
}

class CommunityModPanelBans extends StatefulWidget {
  final DetailedCommunityModel data;
  final void Function(DetailedCommunityModel) onUpdate;

  const CommunityModPanelBans({
    super.key,
    required this.data,
    required this.onUpdate,
  });

  @override
  State<CommunityModPanelBans> createState() => _CommunityModPanelBansState();
}

class _CommunityModPanelBansState extends State<CommunityModPanelBans> {
  final PagingController<String, CommunityBanModel> _pagingController =
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
          .communityModeration
          .listBans(widget.data.id, page: nullIfEmpty(pageKey));

      // Check BuildContext
      if (!mounted) return;

      // Prevent duplicates
      final currentItemIds =
          _pagingController.itemList?.map(
            (e) => (e.community.id, e.bannedUser.id),
          ) ??
          [];
      final newItems = newPage.items
          .where(
            (e) => !currentItemIds.contains((e.community.id, e.bannedUser.id)),
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
            builderDelegate: PagedChildBuilderDelegate<CommunityBanModel>(
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
                          .communityModeration
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

class CommunityModPanelReports extends StatefulWidget {
  final DetailedCommunityModel data;
  final void Function(DetailedCommunityModel) onUpdate;

  const CommunityModPanelReports({
    super.key,
    required this.data,
    required this.onUpdate,
  });

  @override
  State<CommunityModPanelReports> createState() =>
      _MagazineModPanelReportsState();
}

class _MagazineModPanelReportsState extends State<CommunityModPanelReports> {
  final PagingController<String, CommunityReportModel> _pagingController =
      PagingController(firstPageKey: '');
  ReportStatus _status = ReportStatus.any;

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
          .communityModeration
          .listReports(
            widget.data.id,
            page: nullIfEmpty(pageKey),
            status: _status,
          );

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
    final currentReportStatus = reportStatusSelect(context).getOption(_status);

    return RefreshIndicator(
      onRefresh: () => Future.sync(() => _pagingController.refresh()),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ActionChip(
                    padding: chipDropdownPadding,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(currentReportStatus.title),
                        const Icon(Symbols.arrow_drop_down_rounded),
                      ],
                    ),
                    onPressed: () async {
                      final result = await reportStatusSelect(
                        context,
                      ).askSelection(context, _status);
                      if (result != null) {
                        setState(() {
                          _status = result;
                          _pagingController.refresh();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          PagedSliverList(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<CommunityReportModel>(
              firstPageErrorIndicatorBuilder: (context) =>
                  FirstPageErrorIndicator(
                    error: _pagingController.error,
                    onTryAgain: _pagingController.retryLastFailedRequest,
                  ),
              newPageErrorIndicatorBuilder: (context) => NewPageErrorIndicator(
                error: _pagingController.error,
                onTryAgain: _pagingController.retryLastFailedRequest,
              ),
              itemBuilder: (context, item, index) {
                return InkWell(
                  onTap: () {
                    if (item.subjectPost != null) {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, _, __) => PostPage(
                            initData: item.subjectPost,
                            userCanModerate: true,
                          ),
                        ),
                      );
                    } else if (item.subjectComment != null) {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, _, __) => PostCommentScreen(
                            item.subjectComment!.postType,
                            item.subjectComment!.id,
                          ),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(l(context).reportedBy),
                                  DisplayName(
                                    item.reportedBy!.name,
                                    icon: item.reportedBy!.avatar,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            UserScreen(item.reportedBy!.id),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text('${l(context).reason}: ${item.reason}'),
                              Row(
                                children: [
                                  Text('${l(context).status}: '),
                                  Text(
                                    item.status.name,
                                    style: TextStyle(
                                      color: item.status == ReportStatus.pending
                                          ? Colors.blue
                                          : item.status == ReportStatus.approved
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Flex(
                          direction: Breakpoints.isCompact(context)
                              ? Axis.vertical
                              : Axis.horizontal,
                          spacing: 4,
                          children: [
                            if (item.status != ReportStatus.approved)
                              LoadingOutlinedButton(
                                onPressed: () async {
                                  final report = await context
                                      .read<AppController>()
                                      .api
                                      .communityModeration
                                      .acceptReport(widget.data.id, item.id);

                                  var newList = _pagingController.itemList;
                                  newList![index] = report;
                                  setState(() {
                                    _pagingController.itemList = newList;
                                  });
                                },
                                label: Text(l(context).report_accept),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green,
                                ),
                              ),
                            if (item.status != ReportStatus.rejected)
                              LoadingOutlinedButton(
                                onPressed: () async {
                                  final report = await context
                                      .read<AppController>()
                                      .api
                                      .communityModeration
                                      .rejectReport(widget.data.id, item.id);

                                  var newList = _pagingController.itemList;
                                  newList![index] = report;
                                  setState(() {
                                    _pagingController.itemList = newList;
                                  });
                                },
                                label: Text(l(context).report_reject),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            LoadingOutlinedButton(
                              onPressed: () async {
                                await context
                                    .read<AppController>()
                                    .api
                                    .communityModeration
                                    .createBan(
                                      widget.data.id,
                                      item.reportedUser!.id,
                                    );

                                var newList = _pagingController.itemList;
                                newList!.removeAt(index);
                                setState(() {
                                  _pagingController.itemList = newList;
                                });
                              },
                              label: Text(
                                l(context).banUserX(item.reportedUser!.name),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
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

SelectionMenu<ReportStatus> reportStatusSelect(BuildContext context) =>
    SelectionMenu(l(context).filter, [
      SelectionMenuItem(
        value: ReportStatus.any,
        title: l(context).reportStatus_any,
        icon: Symbols.filter_list_rounded,
      ),
      SelectionMenuItem(
        value: ReportStatus.pending,
        title: l(context).reportStatus_pending,
        icon: Symbols.schedule_rounded,
      ),
      SelectionMenuItem(
        value: ReportStatus.approved,
        title: l(context).reportStatus_approved,
        icon: Symbols.check_rounded,
      ),
      SelectionMenuItem(
        value: ReportStatus.rejected,
        title: l(context).reportStatus_rejected,
        icon: Symbols.close_rounded,
      ),
    ]);
