import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/screens/explore/user_item.dart';
import 'package:interstellar/src/utils/breakpoints.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/screens/explore/user_screen.dart';
import 'package:interstellar/src/screens/feed/post_comment_screen.dart';
import 'package:interstellar/src/screens/feed/post_page.dart';
import 'package:interstellar/src/api/community_moderation.dart';
import 'package:interstellar/src/widgets/display_name.dart';
import 'package:interstellar/src/widgets/paging.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:provider/provider.dart';

@RoutePage()
class CommunityModPanelScreen extends StatefulWidget {
  final DetailedCommunityModel initData;
  final void Function(DetailedCommunityModel) onUpdate;

  const CommunityModPanelScreen({
    super.key,
    required this.initData,
    required this.onUpdate,
  });

  @override
  State<CommunityModPanelScreen> createState() => _CommunityModPanelScreenState();
}

class _CommunityModPanelScreenState extends State<CommunityModPanelScreen> {
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
  late final _pagingController =
      AdvancedPagingController<String, CommunityBanModel, (int, int)>(
        logger: context.read<AppController>().logger,
        firstPageKey: '',
        getItemId: (item) => (item.community.id, item.bannedUser.id),
        fetchPage: (pageKey) async {
          final ac = context.read<AppController>();

          final newPage = await ac.api.communityModeration.listBans(
            widget.data.id,
            page: nullIfEmpty(pageKey),
          );

          return (newPage.items, newPage.nextPage);
        },
      );

  @override
  Widget build(BuildContext context) {
    return AdvancedPagedScrollView(
      controller: _pagingController,
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

              _pagingController.removeItem(item);
            },
            label: const Text('Unban'),
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
  late final _pagingController =
      AdvancedPagingController<String, CommunityReportModel, int>(
        logger: context.read<AppController>().logger,
        firstPageKey: '',
        getItemId: (item) => item.id,
        fetchPage: (pageKey) async {
          final newPage = await context
              .read<AppController>()
              .api
              .communityModeration
              .listReports(
                widget.data.id,
                page: nullIfEmpty(pageKey),
                status: _status,
              );

          return (newPage.items, newPage.nextPage);
        },
      );
  ReportStatus _status = ReportStatus.any;

  @override
  Widget build(BuildContext context) {
    final currentReportStatus = reportStatusSelect(context).getOption(_status);

    return AdvancedPagedScrollView(
      controller: _pagingController,
      leadingSlivers: [
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
      ],
      itemBuilder: (context, item, index) {
        return InkWell(
          onTap: () {
            if (item.subjectPost != null) {
              pushRoute(
                context,
                builder: (context) =>
                    PostPage(initData: item.subjectPost, userCanModerate: true),
              );
            } else if (item.subjectComment != null) {
              pushRoute(
                context,
                builder: (context) => PostCommentScreen(
                  item.subjectComment!.postType,
                  item.subjectComment!.id,
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
                            onTap: () => pushRoute(
                              context,
                              builder: (context) =>
                                  UserScreen(item.reportedBy!.id),
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

                          _pagingController.updateItem(item, report);
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

                          _pagingController.updateItem(item, report);
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
                            .createBan(widget.data.id, item.reportedUser!.id);

                        _pagingController.removeItem(item);
                      },
                      label: Text(l(context).banUserX(item.reportedUser!.name)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
