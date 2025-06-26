import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/api/notifications.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/screens/explore/community_mod_panel.dart';
import 'package:interstellar/src/screens/explore/community_owner_panel.dart';
import 'package:interstellar/src/screens/explore/user_item.dart';
import 'package:interstellar/src/screens/feed/feed_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/markdown/markdown.dart';
import 'package:interstellar/src/widgets/notification_control_segment.dart';
import 'package:interstellar/src/widgets/open_webpage.dart';
import 'package:interstellar/src/widgets/star_button.dart';
import 'package:interstellar/src/widgets/subscription_button.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class CommunityScreen extends StatefulWidget {
  final int communityId;
  final DetailedCommunityModel? initData;
  final void Function(DetailedCommunityModel)? onUpdate;

  const CommunityScreen(
    this.communityId, {
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
      context
          .read<AppController>()
          .api
          .community
          .get(widget.communityId)
          .then(
            (value) => setState(() {
              _data = value;
            }),
          );
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

    final loggedInUser = ac.localName;

    final isModerator = _data == null
        ? false
        : _data!.moderators.any((mod) => mod.name == loggedInUser);

    return FeedScreen(
      source: FeedSource.community,
      sourceId: widget.communityId,
      title: _data?.name ?? '',
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
                          MenuAnchor(
                            builder:
                                (
                                  BuildContext context,
                                  MenuController controller,
                                  Widget? child,
                                ) {
                                  return IconButton(
                                    icon: const Icon(Symbols.more_vert_rounded),
                                    onPressed: () {
                                      if (controller.isOpen) {
                                        controller.close();
                                      } else {
                                        controller.open();
                                      }
                                    },
                                  );
                                },
                            menuChildren: [
                              MenuItemButton(
                                onPressed: () => openWebpagePrimary(
                                  context,
                                  Uri.https(
                                    ac.instanceHost,
                                    ac.serverSoftware == ServerSoftware.mbin
                                        ? '/m/${_data!.name}'
                                        : '/c/${_data!.name}',
                                  ),
                                ),
                                child: Text(l(context).openInBrowser),
                              ),
                              MenuItemButton(
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(l(context).modsOf(_data!.name)),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: _data!.moderators
                                          .map(
                                            (mod) => UserItemSimple(
                                              mod,
                                              isOwner:
                                                  mod.id == _data!.owner?.id,
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
                                child: Text(l(context).viewMods),
                              ),
                              if (isModerator)
                                MenuItemButton(
                                  onPressed: () => pushRoute(
                                    context,
                                    builder: (context) => CommunityModPanel(
                                      initData: _data!,
                                      onUpdate: (newValue) {
                                        setState(() {
                                          _data = newValue;
                                        });
                                        if (widget.onUpdate != null) {
                                          widget.onUpdate!(newValue);
                                        }
                                      },
                                    ),
                                  ),
                                  child: Text(l(context).modPanel),
                                ),
                              if (_data!.owner != null &&
                                  _data!.owner!.name == ac.localName)
                                MenuItemButton(
                                  onPressed: () => pushRoute(
                                    context,
                                    builder: (context) => CommunityOwnerPanel(
                                      initData: _data!,
                                      onUpdate: (newValue) {
                                        setState(() {
                                          _data = newValue;
                                        });
                                        if (widget.onUpdate != null) {
                                          widget.onUpdate!(newValue);
                                        }
                                      },
                                    ),
                                  ),
                                  child: Text(l(context).ownerPanel),
                                ),
                            ],
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

                                    if (!mounted) return;
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
