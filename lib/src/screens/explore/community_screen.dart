import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/api/notifications.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/screens/feed/feed_agregator.dart';
import 'package:interstellar/src/screens/feed/feed_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/markdown/markdown.dart';
import 'package:interstellar/src/widgets/notification_control_segment.dart';
import 'package:interstellar/src/widgets/star_button.dart';
import 'package:interstellar/src/widgets/subscription_button.dart';
import 'package:interstellar/src/widgets/menus/community_menu.dart';
import 'package:interstellar/src/widgets/tags/tag_widget.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

@RoutePage()
class CommunityScreen extends StatefulWidget {
  final int communityId;
  final DetailedCommunityModel? initData;
  final void Function(DetailedCommunityModel)? onUpdate;

  const CommunityScreen(
    @PathParam('id') this.communityId, {
    super.key,
    this.initData,
    this.onUpdate,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  DetailedCommunityModel? _data;

  @override
  void initState() {
    super.initState();

    _data = widget.initData;

    if (_data == null) {
      context.read<AppController>().api.community.get(widget.communityId).then((
        value,
      ) {
        if (!mounted) return;
        setState(() {
          _data = value;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    final globalName = _data == null
        ? null
        : _data!.name.contains('@')
        ? '!${_data!.name}'
        : '!${_data!.name}@${ac.instanceHost}';

    return FeedScreen(
      feed: FeedAggregator.fromSingleSource(
        ac,
        name: _data?.name ?? '',
        source: FeedSource.community,
        sourceId: widget.communityId,
      ),
      createPostCommunity: _data,
      details: _data == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final actions = Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SubscriptionButton(
                            isSubscribed: _data!.isUserSubscribed,
                            subscriptionCount: _data!.subscriptionsCount,
                            onSubscribe: (selected) async {
                              var newValue = await ac.api.community.subscribe(
                                _data!.id,
                                selected,
                              );

                              setState(() {
                                _data = newValue;
                              });
                              if (widget.onUpdate != null) {
                                widget.onUpdate!(newValue);
                              }
                            },
                            followMode: false,
                          ),
                          StarButton(globalName!),
                          if (whenLoggedIn(context, true) == true)
                            LoadingIconButton(
                              onPressed: () async {
                                final newValue = await ac.api.community.block(
                                  _data!.id,
                                  !_data!.isBlockedByUser!,
                                );

                                setState(() {
                                  _data = newValue;
                                });
                                if (widget.onUpdate != null) {
                                  widget.onUpdate!(newValue);
                                }
                              },
                              icon: const Icon(Symbols.block_rounded),
                              style: ButtonStyle(
                                foregroundColor: WidgetStatePropertyAll(
                                  _data!.isBlockedByUser == true
                                      ? Theme.of(context).colorScheme.error
                                      : Theme.of(context).disabledColor,
                                ),
                              ),
                            ),
                          IconButton(
                            onPressed: () => showCommunityMenu(
                              context,
                              detailedCommunity: _data,
                              update: (newCommunity) {
                                setState(() {
                                  _data = newCommunity;
                                });
                                if (widget.onUpdate != null) {
                                  widget.onUpdate!(newCommunity);
                                }
                              },
                            ),
                            icon: Icon(Symbols.more_vert_rounded),
                          ),
                        ],
                      ),
                      if (_data!.notificationControlStatus != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: NotificationControlSegment(
                            _data!.notificationControlStatus!,
                            (newStatus) async {
                              await ac.api.notifications.updateControl(
                                targetType: NotificationControlUpdateTargetType
                                    .community,
                                targetId: _data!.id,
                                status: newStatus,
                              );

                              final newValue = _data!.copyWith(
                                notificationControlStatus: newStatus,
                              );
                              setState(() {
                                _data = newValue;
                              });
                              if (widget.onUpdate != null) {
                                widget.onUpdate!(newValue);
                              }
                            },
                          ),
                        ),
                    ],
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          if (_data!.icon != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Avatar(_data!.icon, radius: 32),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _data!.title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    if (_data!.isPostingRestrictedToMods)
                                      const PostingRestrictedIndicator(),
                                  ],
                                ),
                                InkWell(
                                  onTap: () async {
                                    await Clipboard.setData(
                                      ClipboardData(
                                        text: _data!.name.contains('@')
                                            ? '!${_data!.name}'
                                            : '!${_data!.name}@${ac.instanceHost}',
                                      ),
                                    );

                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l(context).copied),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: Text(globalName),
                                ),
                              ],
                            ),
                          ),
                          if (constraints.maxWidth > 600) actions,
                        ],
                      ),
                      if (constraints.maxWidth <= 600) actions,
                      if (_data!.description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Markdown(
                            _data!.description!,
                            getNameHost(context, _data!.name),
                          ),
                        ),
                      if (ac.serverSoftware == ServerSoftware.piefed &&
                          _data != null &&
                          _data!.flairs.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Wrap(
                            runSpacing: 5,
                            children: _data!.flairs
                                .map((tag) => TagWidget(tag: tag))
                                .toList(),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

class PostingRestrictedIndicator extends StatelessWidget {
  const PostingRestrictedIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Tooltip(
        message: l(context).postingRestricted,
        triggerMode: TooltipTriggerMode.tap,
        child: const Icon(Symbols.lock_rounded, size: 16),
      ),
    );
  }
}
