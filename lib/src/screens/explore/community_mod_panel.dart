import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/api/community_moderation.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/router.gr.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/screens/explore/user_item.dart';
import 'package:interstellar/src/screens/feed/post_page.dart';
import 'package:interstellar/src/utils/breakpoints.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/ban_dialog.dart';
import 'package:interstellar/src/widgets/context_menu.dart';
import 'package:interstellar/src/widgets/display_name.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/paging.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

@RoutePage()
class CommunityModPanelScreen extends StatefulWidget {
  const CommunityModPanelScreen({
    @PathParam('communityId') required this.communityId,
    required this.initData,
    required this.onUpdate,
    super.key,
  });

  final int communityId;
  final DetailedCommunityModel initData;
  final void Function(DetailedCommunityModel) onUpdate;

  @override
  State<CommunityModPanelScreen> createState() =>
      _CommunityModPanelScreenState();
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
    final ac = context.read<AppController>();

    void onUpdate(DetailedCommunityModel newValue) {
      setState(() {
        _data = newValue;
        widget.onUpdate(newValue);
      });
    }

    return DefaultTabController(
      length: ac.serverSoftware == ServerSoftware.mbin ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mod Panel for ${widget.initData.name}'),
          bottom: TabBar(
            tabs: [
              if (ac.serverSoftware != ServerSoftware.lemmy)
                const Tab(text: 'Bans'),
              if (ac.serverSoftware != ServerSoftware.piefed)
                const Tab(text: 'Reports'),
            ],
          ),
        ),
        body: TabBarView(
          physics: appTabViewPhysics(context),
          children: <Widget>[
            if (ac.serverSoftware != ServerSoftware.lemmy)
              CommunityModPanelBans(data: _data, onUpdate: onUpdate),
            if (ac.serverSoftware != ServerSoftware.piefed)
              CommunityModPanelReports(data: _data, onUpdate: onUpdate),
          ],
        ),
      ),
    );
  }
}

class CommunityModPanelBans extends StatefulWidget {
  const CommunityModPanelBans({
    required this.data,
    required this.onUpdate,
    super.key,
  });
  final DetailedCommunityModel data;
  final void Function(DetailedCommunityModel) onUpdate;

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
  const CommunityModPanelReports({
    required this.data,
    required this.onUpdate,
    super.key,
  });
  final DetailedCommunityModel data;
  final void Function(DetailedCommunityModel) onUpdate;

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
        return CommunityModReport(
          communityId: widget.data.id,
          report: item,
          updateItem: (newItem) {
            if (newItem == null) {
              _pagingController.removeItem(item);
            } else {
              _pagingController.updateItem(item, newItem);
            }
          },
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

class CommunityModReport extends StatefulWidget {
  const CommunityModReport({
    required this.communityId,
    required this.report,
    required this.updateItem,
    super.key,
  });

  final int communityId;
  final CommunityReportModel report;
  final void Function(CommunityReportModel? newItem) updateItem;

  @override
  State<CommunityModReport> createState() => _CommunityModReportState();
}

class _CommunityModReportState extends State<CommunityModReport> {
  bool _deleted = false;

  @override
  void initState() {
    super.initState();

    _deleted =
        widget.report.subjectPost?.visibility == PostVisibility.trashed ||
        widget.report.subjectPost?.visibility == PostVisibility.soft_deleted;
  }

  void _modMenu(BuildContext context) {
    final ac = context.read<AppController>();
    ContextMenu(
      items: [
        ContextMenuItem(
          title: l(context).pin,
          onTap: () async => ac.api.moderation.postPin(
            widget.report.subjectPost!.type,
            widget.report.subjectPost!.id,
            !widget.report.subjectPost!.isPinned,
          ),
        ),
        ContextMenuItem(
          title: l(context).notSafeForWork_mark,
          onTap: () async => ac.api.moderation.postMarkNSFW(
            widget.report.subjectPost!.type,
            widget.report.subjectPost!.id,
            !widget.report.subjectPost!.isNSFW,
          ),
        ),
        ContextMenuItem(
          title: l(context).delete,
          onTap: () async => ac.api.moderation.postDelete(
            widget.report.subjectPost!.type,
            widget.report.subjectPost!.id,
            !_deleted,
          ),
        ),
        ContextMenuItem(
          title: l(context).banUser,
          onTap: () async => openBanDialog(
            context,
            user: widget.report.subjectPost!.user,
            community: widget.report.subjectPost!.community,
          ),
        ),
        ContextMenuItem(
          title: l(context).lock,
          onTap: () async => ac.api.moderation.postLock(
            widget.report.subjectPost!.type,
            widget.report.subjectPost!.id,
            !widget.report.subjectPost!.isLocked,
          ),
        ),
      ],
    ).openMenu(context);
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.read<AppController>();

    return InkWell(
      onTap: () {
        if (widget.report.subjectPost != null) {
          pushPostPage(
            context,
            communityName: widget.report.subjectPost!.community.name,
            postId: widget.report.subjectPost!.id,
            postType: widget.report.subjectPost!.type,
            initData: widget.report.subjectPost,
            userCanModerate: true,
          );
        } else if (widget.report.subjectComment != null) {
          context.router.push(
            PostCommentRoute(
              postType: widget.report.subjectComment!.postType,
              commentId: widget.report.subjectComment!.id,
            ),
          );
        }
      },
      onLongPress: widget.report.subjectPost == null
          ? null
          : () => _modMenu(context),
      onSecondaryTap: widget.report.subjectPost == null
          ? null
          : () => _modMenu(context),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(l(context).reportedBy),
                      DisplayName(
                        widget.report.reportedBy!.name,
                        icon: widget.report.reportedBy!.avatar,
                        onTap: () => context.router.push(
                          UserRoute(
                            username: widget.report.reportedBy!.name,
                            userId: widget.report.reportedBy!.id,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text('${l(context).reason}: ${widget.report.reason}'),
                  Row(
                    children: [
                      Text('${l(context).status}: '),
                      Text(
                        widget.report.status.name,
                        style: TextStyle(
                          color: widget.report.status == ReportStatus.pending
                              ? Colors.blue
                              : widget.report.status == ReportStatus.approved
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
                LoadingOutlinedButton(
                  onPressed: () async {
                    await ac.api.communityModeration.createBan(
                      widget.communityId,
                      widget.report.reportedUser!.id,
                    );

                    widget.updateItem(null);
                  },
                  label: Text(
                    l(context).banUserX(widget.report.reportedUser!.name),
                  ),
                ),
                LoadingOutlinedButton(
                  onPressed: () async {
                    if (ac.serverSoftware != ServerSoftware.mbin &&
                        widget.report.subjectPost != null) {
                      final post = await ac.api.moderation.postDelete(
                        widget.report.subjectPost!.type,
                        widget.report.subjectPost!.id,
                        !_deleted,
                      );
                      setState(() {
                        _deleted =
                            post.visibility == PostVisibility.trashed ||
                            post.visibility == PostVisibility.soft_deleted;
                      });
                    } else {
                      setState(() {
                        _deleted = !_deleted;
                      });
                    }
                  },
                  icon: const Icon(Symbols.delete_rounded),
                  label: _deleted
                      ? Text(l(context).restore)
                      : Text(l(context).delete),
                  style: _deleted
                      ? OutlinedButton.styleFrom(foregroundColor: Colors.blue)
                      : OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
                LoadingOutlinedButton(
                  onPressed: () async {
                    final report = await ac.api.communityModeration.resolve(
                      widget.communityId,
                      widget.report.id,
                      widget.report.status == ReportStatus.pending,
                    );

                    widget.updateItem(report);
                  },
                  icon: const Icon(Symbols.check_rounded),
                  label: widget.report.status != ReportStatus.pending
                      ? Text(l(context).unresolve)
                      : Text(l(context).resolve),
                  style: widget.report.status != ReportStatus.pending
                      ? OutlinedButton.styleFrom(foregroundColor: Colors.green)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
      if (context.read<AppController>().serverSoftware == ServerSoftware.mbin)
        SelectionMenuItem(
          value: ReportStatus.approved,
          title: l(context).reportStatus_approved,
          icon: Symbols.check_rounded,
        ),
      if (context.read<AppController>().serverSoftware == ServerSoftware.mbin)
        SelectionMenuItem(
          value: ReportStatus.rejected,
          title: l(context).reportStatus_rejected,
          icon: Symbols.close_rounded,
        ),
    ]);
