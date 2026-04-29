import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/feed.dart';
import 'package:interstellar/src/controller/router.gr.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/config_share.dart';
import 'package:interstellar/src/models/domain.dart';
import 'package:interstellar/src/models/feed.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/explore/explore_screen.dart';
import 'package:interstellar/src/screens/feed/feed_agregator.dart';
import 'package:interstellar/src/screens/feed/feed_screen.dart';
import 'package:interstellar/src/screens/settings/about_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/context_menu.dart';
import 'package:interstellar/src/widgets/list_tile_switch.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/markdown/drafts_controller.dart';
import 'package:interstellar/src/widgets/markdown/markdown_editor.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

@RoutePage()
class FeedSettingsScreen extends StatefulWidget {
  const FeedSettingsScreen({super.key});

  @override
  State<FeedSettingsScreen> createState() => _FeedSettingsScreenState();
}

class _FeedSettingsScreenState extends State<FeedSettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    return Scaffold(
      appBar: AppBar(title: Text(l(context).feeds)),
      body: ListView(
        children: [
          ...ac.feeds.entries.map(
            (entry) => ListTile(
              title: Text(entry.key),
              subtitle: Text(
                entry.value.serverFeed ? l(context).server : l(context).client,
              ),
              enabled:
                  entry.value.clientFeed ||
                  (ac.serverSoftware == ServerSoftware.piefed &&
                      entry.value.inputs.first.name.split('@').last ==
                          ac.instanceHost),
              onTap: () async {
                final serverFeed = entry.value.serverFeed
                    ? await ac.api.feed.getByName(entry.value.inputs.first.name)
                    : null;

                final feed = await FeedAggregator.create(
                  ac,
                  entry.key,
                  ac.feeds[entry.key]!,
                );
                if (!context.mounted) return;
                context.router.push(
                  FeedRoute(
                    feedName: feed.name,
                    feed: feed,
                    details: serverFeed == null
                        ? null
                        : FeedDetails(feed: serverFeed),
                  ),
                );
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed:
                        entry.value.serverFeed &&
                            entry.value.owner != ac.selectedAccount
                        ? null
                        : () => context.router.push(
                            EditFeedRoute(
                              feed: entry.key,
                              feedData: ac.feeds[entry.key],
                            ),
                          ),
                    icon: const Icon(Symbols.edit_rounded),
                  ),
                  IconButton(
                    onPressed: () => showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l(context).feeds_delete),
                        content: Text(entry.key),
                        actions: <Widget>[
                          OutlinedButton(
                            onPressed: () => context.router.pop(),
                            child: Text(l(context).cancel),
                          ),
                          FilledButton(
                            onPressed: () async {
                              await ac.removeFeed(entry.key);

                              if (!context.mounted) return;
                              context.router.pop();
                            },
                            child: Text(l(context).delete),
                          ),
                        ],
                      ),
                    ),
                    icon: const Icon(Symbols.delete_rounded),
                  ),
                  IconButton(
                    onPressed: () async {
                      final feed = ac.feeds[entry.key]!;

                      final config = await ConfigShare.create(
                        type: ConfigShareType.feed,
                        name: entry.key,
                        payload: feed.toJson(),
                      );

                      if (!mounted) return;
                      var communityName = mbinConfigsCommunityName;
                      if (communityName.endsWith(ac.instanceHost)) {
                        communityName = communityName.split('@').first;
                      }

                      DetailedCommunityModel? community;
                      try {
                        community = await ac.api.community.getByName(
                          communityName,
                        );
                      } catch (e) {
                        //
                      }

                      if (!context.mounted) return;

                      await context.router.push(
                        CreateRoute(
                          initTitle: '[Feed] ${entry.key}',
                          initBody:
                              'Short description here...\n\n${config.toMarkdown()}',
                          initCommunity: community,
                        ),
                      );
                    },
                    icon: const Icon(Symbols.share_rounded),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.add_rounded),
            title: Text(l(context).feeds_new),
            onTap: () => newFeed(context),
          ),
        ],
      ),
    );
  }
}

void newFeed(BuildContext context) {
  final ac = context.read<AppController>();
  if (ac.serverSoftware != ServerSoftware.piefed) {
    context.router.push(EditFeedRoute(feed: null));
  } else {
    ContextMenu(
      items: [
        ContextMenuItem(
          title: l(context).clientFeed,
          subtitle: l(context).clientFeedSubtitle,
          onTap: () async {
            await context.router.push(EditFeedRoute(feed: null));
            if (!context.mounted) return;
            context.router.pop();
          },
        ),
        ContextMenuItem(
          title: l(context).serverFeed,
          subtitle: l(context).serverFeedSubtitle,
          onTap: () =>
              context.router.push(EditFeedRoute(feed: 'new', server: true)),
        ),
        ContextMenuItem(
          title: l(context).serverTopic,
          subtitle: l(context).serverTopicSubtitle,
          onTap: () => context.router.push(
            ExploreRoute(
              mode: ExploreType.topics,
              onTap: (selected, item) async {
                if (item is! FeedModel) return;

                final feed = Feed(
                  inputs: {
                    FeedInput(
                      name: normalizeName(item.name, ac.instanceHost),
                      sourceType: FeedSource.topic,
                      serverId: item.id,
                    ), // TODO(olorin99): tmp until proper getByName method can be made
                  },
                  server: true,
                  owner: null,
                );

                var title = item.title;
                if (ac.feeds[title] != null) {
                  await showDialog<void>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(l(context).feeds_exist),
                        actions: [
                          OutlinedButton(
                            onPressed: () {
                              context.router.pop();
                              context.router.pop();
                              context.router.pop();
                            },
                            child: Text(l(context).cancel),
                          ),
                          LoadingFilledButton(
                            onPressed: () async {
                              var num = 0;
                              while (ac.feeds[title] != null) {
                                title = '${item.title} ${num++}';
                              }
                              context.router.pop();
                            },
                            label: Text(l(context).rename),
                          ),
                          LoadingFilledButton(
                            onPressed: () async {
                              context.router.pop();
                            },
                            label: Text(l(context).replace),
                          ),
                        ],
                      );
                    },
                  );
                }

                if (!context.mounted) return;
                ac.setFeed(title, feed);
                context.router.pop();
              },
            ),
          ),
        ),
      ],
    ).openMenu(context);
  }
}

@RoutePage()
class EditFeedScreen extends StatefulWidget {
  const EditFeedScreen({
    @PathParam('feed') required this.feed,
    this.feedData,
    this.server = false,
    super.key,
  });

  final String? feed;
  final Feed? feedData;
  final bool server;

  @override
  State<EditFeedScreen> createState() => _EditFeedScreenState();
}

class _EditFeedScreenState extends State<EditFeedScreen> {
  late Feed feedData;
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  FeedModel? _feedModel;

  @override
  void initState() {
    super.initState();

    if (widget.feed != null) {
      nameController.text = widget.feed!;
    }

    feedData = widget.feedData == null
        ? const Feed(inputs: {}, server: false, owner: null)
        : widget.feedData!;

    if (widget.feedData != null && widget.feedData!.serverFeed) {
      context
          .read<AppController>()
          .api
          .feed
          .getByName(widget.feedData!.inputs.first.name)
          .then(
            (feed) => setState(() {
              _feedModel = feed;
              feedData = Feed(
                inputs: feed.communities
                    .map(
                      (community) => FeedInput(
                        name: normalizeName(
                          community.name,
                          context.read<AppController>().instanceHost,
                        ),
                        sourceType: FeedSource.community,
                      ),
                    )
                    .toSet(),
                server: true,
                owner: feed.owner ?? false
                    ? context.read<AppController>().selectedAccount
                    : null,
              );
              descriptionController.text = feed.description ?? '';
            }),
          );
    } else if (widget.feedData == null && widget.server) {
      // create new server feed
      _feedModel = const FeedModel(
        id: 0,
        userId: null,
        title: '',
        name: '',
        description: null,
        isNSFW: null,
        isNSFL: null,
        subscriptionCount: null,
        communityCount: 0,
        communities: [],
        public: null,
        parentId: null,
        isInstanceFeed: null,
        icon: null,
        banner: null,
        subscribed: null,
        owner: null,
        published: null,
        updated: null,
        children: [],
        apId: null,
      );
    }
  }

  void addInput(FeedInput input) {
    setState(() {
      feedData = feedData.copyWith(inputs: {...feedData.inputs, input});
    });
  }

  void removeInput(FeedInput input) {
    final inputs = {...feedData.inputs}..remove(input);

    setState(() {
      feedData = feedData.copyWith(inputs: inputs);
    });
  }

  Future<void> save() async {
    final ac = context.read<AppController>();
    final name = nameController.text;
    final description = descriptionController.text;

    // create new serverfeed
    if (widget.server && widget.feedData == null) {
      final feed = await ac.api.feed.create(
        title: name,
        description: description,
        nsfw: _feedModel?.isNSFW,
        nsfl: _feedModel?.isNSFL,
        public: _feedModel?.public,
        communities: feedData.inputs.map((input) => input.name).toList(),
      );

      await ac.setFeed(
        feed.title,
        Feed(
          server: true,
          owner: ac.selectedAccount,
          inputs: {
            FeedInput(
              name: normalizeName(feed.name, ac.instanceHost),
              sourceType: FeedSource.feed,
            ),
          },
        ),
      );

      if (!mounted) return;
      context.router.pop();
      return;
    }

    // edit existing server feed
    if (_feedModel != null && (_feedModel!.owner ?? false)) {
      await ac.api.feed.edit(
        feedId: _feedModel!.id,
        title: name,
        description: description,
        nsfw: _feedModel!.isNSFW,
        nsfl: _feedModel!.isNSFL,
        public: _feedModel!.public,
        communities: feedData.inputs.map((input) => input.name).toList(),
      );

      if (!mounted) return;
      context.router.pop();
      return;
    }

    if (widget.feed != null && name != widget.feed) {
      await ac.renameFeed(widget.feed!, name);
    }

    await ac.setFeed(name, feedData);
    if (!mounted) return;
    context.router.pop();
  }

  Future<void> delete() async {
    final ac = context.read<AppController>();

    if (_feedModel != null) {
      await ac.api.feed.delete(feedId: _feedModel!.id);
      await ac.removeFeed(widget.feed!);
      if (!mounted) return;
      context.router.pop();
      return;
    }

    await ac.removeFeed(widget.feed!);
    if (!mounted) return;
    context.router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();
    return Scaffold(
      appBar: AppBar(
        title: Text(l(context).feeds_edit(widget.feed ?? nameController.text)),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextEditor(
              nameController,
              label: l(context).filterList_name,
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_feedModel != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: MarkdownEditor(
                descriptionController,
                label: l(context).description,
                onChanged: (_) => setState(() {}),
                originInstance: ac.instanceHost,
                draftController: context.watch<DraftsController>().auto(
                  'feed_description:${_feedModel!.name}:${ac.instanceHost}:${_feedModel!.id}',
                ),
              ),
            ),
            ListTileSwitch(
              title: Text(l(context).isNSFW),
              value: _feedModel!.isNSFW ?? false,
              onChanged: (newValue) => setState(() {
                _feedModel = _feedModel!.copyWith(isNSFW: newValue);
              }),
            ),
            ListTileSwitch(
              title: Text(l(context).isNSFL),
              value: _feedModel!.isNSFL ?? false,
              onChanged: (newValue) => setState(() {
                _feedModel = _feedModel!.copyWith(isNSFL: newValue);
              }),
            ),
            ListTileSwitch(
              title: Text(l(context).public),
              value: _feedModel!.public ?? false,
              onChanged: (newValue) => setState(() {
                _feedModel = _feedModel!.copyWith(public: newValue);
              }),
            ),
            const SizedBox(height: 16),
          ],
          ListTile(
            title: Text(
              l(context).feeds_inputs,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...feedData.inputs.map((input) {
            return ListTile(
              title: Text(input.name),
              trailing: IconButton(
                onPressed: () {
                  removeInput(input);
                },
                icon: const Icon(Symbols.delete_rounded),
              ),
            );
          }),
          ListTile(
            leading: const Icon(Symbols.add_rounded),
            title: Text(l(context).feeds_input),
            onTap: () async => context.router.push(
              ExploreRoute(
                selected: feedData.inputs
                    .map(
                      (input) => denormalizeName(input.name, ac.instanceHost),
                    )
                    .toSet(),
                onTap: (selected, item) {
                  final name = switch (item) {
                    final DetailedCommunityModel i => normalizeName(
                      i.name,
                      ac.instanceHost,
                    ),
                    final DetailedUserModel i => normalizeName(
                      i.name,
                      ac.instanceHost,
                    ),
                    final DomainModel i => i.name,
                    final FeedModel i => normalizeName(i.name, ac.instanceHost),
                    _ => null,
                  };
                  final source = switch (item) {
                    DetailedCommunityModel _ => FeedSource.community,
                    DetailedUserModel _ => FeedSource.user,
                    DomainModel _ => FeedSource.domain,
                    FeedModel _ => FeedSource.feed,
                    _ => null,
                  };
                  final id = switch (item) {
                    final FeedModel i => i.id,
                    _ => null,
                  };

                  if (name == null || source == null) return;

                  if (selected) {
                    addInput(
                      FeedInput(name: name, sourceType: source, serverId: id),
                    );
                  } else {
                    removeInput(
                      FeedInput(name: name, sourceType: source, serverId: id),
                    );
                  }
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LoadingFilledButton(
              icon: const Icon(Symbols.save_rounded),
              onPressed:
                  nameController.text.isEmpty ||
                      (nameController.text != widget.feed &&
                          ac.filterLists.containsKey(nameController.text))
                  ? null
                  : save,
              label: Text(l(context).saveChanges),
            ),
          ),
          if (widget.feed != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton.icon(
                icon: const Icon(Symbols.delete_rounded),
                onPressed: () async {
                  showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l(context).feeds_delete),
                      content: Text(widget.feed!),
                      actions: <Widget>[
                        OutlinedButton(
                          onPressed: () => context.router.pop(),
                          child: Text(l(context).cancel),
                        ),
                        FilledButton(
                          onPressed: () async {
                            await delete();

                            if (!context.mounted) return;
                            context.router.pop(true);
                          },
                          child: Text(l(context).delete),
                        ),
                      ],
                    ),
                  );
                },
                label: Text(l(context).feeds_delete),
              ),
            ),
        ],
      ),
    );
  }
}

void showAddToFeedMenu(BuildContext context, String name, FeedSource source) {
  final ac = context.read<AppController>();
  ContextMenu(
    title: l(context).feeds,
    items: [
      ...ac.feeds.entries
          .where((feed) => feed.value.clientFeed)
          .map(
            (feed) => ContextMenuItem(
              title: feed.key,
              onTap: () async {
                final newFeed = feed.value.copyWith(
                  inputs: {
                    ...feed.value.inputs,
                    FeedInput(name: name, sourceType: source),
                  },
                );
                await ac.setFeed(feed.key, newFeed);
                if (!context.mounted) return;
                context.router.pop();
              },
            ),
          ),
      ContextMenuItem(
        title: l(context).feeds_new,
        icon: Symbols.add_rounded,
        onTap: () => context.router.push(EditFeedRoute(feed: null)),
      ),
    ],
  ).openMenu(context);
}
