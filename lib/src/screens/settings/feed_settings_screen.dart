import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/feed.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/screens/feed/feed_screen.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/config_share.dart';
import 'package:interstellar/src/models/domain.dart';
import 'package:interstellar/src/models/feed.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:interstellar/src/screens/explore/explore_screen.dart';
import 'package:interstellar/src/screens/feed/create_screen.dart';
import 'package:interstellar/src/screens/feed/feed_agregator.dart';
import 'package:interstellar/src/screens/settings/about_screen.dart';
import 'package:interstellar/src/widgets/context_menu.dart';

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
                  !(entry.value.serverFeed &&
                      ac.serverSoftware != ServerSoftware.piefed),
              onTap: () async {
                final feed = await FeedAggregator.create(
                  ac,
                  ac.feeds[entry.key]!,
                );
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FeedScreen(feed: feed),
                  ),
                );
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditFeedScreen(
                          feed: entry.key,
                          feedData: ac.feeds[entry.key],
                        ),
                      ),
                    ),
                    icon: const Icon(Symbols.edit_rounded),
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
                      String communityName = mbinConfigsCommunityName;
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

                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CreateScreen(
                            initTitle: '[Feed] $entry.key',
                            initBody:
                                'Short description here...\n\n${config.toMarkdown()}',
                            initCommunity: community,
                          ),
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
  if (context.read<AppController>().serverSoftware != ServerSoftware.piefed) {
    pushRoute(context, builder: (context) => const EditFeedScreen(feed: null));
  } else {
    ContextMenu(
      items: [
        ContextMenuItem(
          title: '${l(context).client} ${l(context).feed}',
          onTap: () async {
            await pushRoute(
              context,
              builder: (context) => const EditFeedScreen(feed: null),
            );
            if (!context.mounted) return;
            Navigator.pop(context);
          },
        ),
        ContextMenuItem(
          title: '${l(context).server} ${l(context).feed}',
          onTap: () => pushRoute(
            context,
            builder: (context) => ExploreScreen(
              mode: ExploreType.feeds,
              onTap: (selected, item) async {
                if (item is! FeedModel) return;

                final feed = Feed(
                  name: item.title!,
                  inputs: {
                    FeedInput(
                      name: '${item.id}:${getNameHost(context, item.name)}',
                      sourceType: FeedSource.feed,
                    ), // tmp until proper getByName method can be made
                  },
                );

                String title = item.title!;
                if (context.read<AppController>().feeds[title] != null) {
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(l(context).feeds_exist),
                        actions: [
                          OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: Text(l(context).cancel),
                          ),
                          LoadingFilledButton(
                            onPressed: () async {
                              int num = 0;
                              while (context
                                      .read<AppController>()
                                      .feeds[title] !=
                                  null) {
                                title = '${item.title}${num++}';
                              }
                              Navigator.pop(context);
                            },
                            label: Text(l(context).rename),
                          ),
                          LoadingFilledButton(
                            onPressed: () async {
                              Navigator.pop(context);
                            },
                            label: Text(l(context).replace),
                          ),
                        ],
                      );
                    },
                  );
                }

                if (!context.mounted) return;
                context.read<AppController>().setFeed(title, feed);
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ),
        ),
        ContextMenuItem(
          title: '${l(context).server} ${l(context).topic}',
          onTap: () => pushRoute(
            context,
            builder: (context) => ExploreScreen(
              mode: ExploreType.topics,
              onTap: (selected, item) async {
                if (item is! FeedModel) return;

                final feed = Feed(
                  name: item.name,
                  inputs: {
                    FeedInput(
                      name: '${item.id}:${getNameHost(context, item.name)}',
                      sourceType: FeedSource.topic,
                    ), // tmp until proper getByName method can be made
                  },
                );

                String title = item.name;
                if (context.read<AppController>().feeds[title] != null) {
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(l(context).feeds_exist),
                        actions: [
                          OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: Text(l(context).cancel),
                          ),
                          LoadingFilledButton(
                            onPressed: () async {
                              int num = 0;
                              while (context
                                      .read<AppController>()
                                      .feeds[title] !=
                                  null) {
                                title = '${item.name}${num++}';
                              }
                              Navigator.pop(context);
                            },
                            label: Text(l(context).rename),
                          ),
                          LoadingFilledButton(
                            onPressed: () async {
                              Navigator.pop(context);
                            },
                            label: Text(l(context).replace),
                          ),
                        ],
                      );
                    },
                  );
                }

                if (!context.mounted) return;
                context.read<AppController>().setFeed(title, feed);
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ],
    ).openMenu(context);
  }
}

class EditFeedScreen extends StatefulWidget {
  final String? feed;
  final Feed? feedData;

  const EditFeedScreen({required this.feed, this.feedData, super.key});

  @override
  State<EditFeedScreen> createState() => _EditFeedScreenState();
}

class _EditFeedScreenState extends State<EditFeedScreen> {
  late Feed feedData;
  final nameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.feed != null) {
      nameController.text = widget.feed!;
    }

    feedData = widget.feedData == null
        ? Feed(name: '', inputs: {})
        : widget.feedData!;
  }

  void addInput(FeedInput input) {
    setState(() {
      feedData = feedData.copyWith(inputs: {...feedData.inputs, input});
    });
  }

  void removeInput(FeedInput input) {
    final inputs = {...feedData.inputs};
    inputs.remove(input);
    setState(() {
      feedData = feedData.copyWith(inputs: inputs);
    });
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
            onTap: () async => pushRoute(
              context,
              builder: (context) => ExploreScreen(
                selected: feedData.inputs.map((input) => input.name).toSet(),
                onTap: (selected, item) {
                  var name = switch (item) {
                    DetailedCommunityModel i => i.name,
                    DetailedUserModel i => i.name,
                    DomainModel i => i.name,
                    FeedModel i => i.id.toString(),
                    _ => null,
                  };
                  final source = switch (item) {
                    DetailedCommunityModel _ => FeedSource.community,
                    DetailedUserModel _ => FeedSource.user,
                    DomainModel _ => FeedSource.domain,
                    FeedModel _ => FeedSource.feed,
                    _ => null,
                  };

                  if (name == null || source == null) return;

                  name = normalizeName(name, ac.instanceHost);

                  if (selected) {
                    addInput(FeedInput(name: name, sourceType: source));
                  } else {
                    removeInput(FeedInput(name: name, sourceType: source));
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
                  : () async {
                      final name = nameController.text;
                      if (widget.feed != null && name != widget.feed) {
                        await ac.renameFeed(widget.feed!, name);
                      }

                      await ac.setFeed(name, feedData.copyWith(name: name));
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
              label: Text(l(context).saveChanges),
            ),
          ),
          if (widget.feed != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton.icon(
                icon: const Icon(Symbols.delete_rounded),
                onPressed: () {
                  showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: Text(l(context).feeds_delete),
                      content: Text(widget.feed!),
                      actions: <Widget>[
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l(context).cancel),
                        ),
                        FilledButton(
                          onPressed: () async {
                            await ac.removeFeed(widget.feed!);

                            if (!context.mounted) return;
                            Navigator.pop(context);
                            Navigator.pop(context);
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
      ...ac.feeds.values.where((feed) => feed.clientFeed).map(
        (feed) => ContextMenuItem(
          title: feed.name,
          onTap: () async {
            final newFeed = feed.copyWith(
              inputs: {
                ...feed.inputs,
                FeedInput(name: name, sourceType: source),
              },
            );
            await ac.setFeed(feed.name, newFeed);
            if (!context.mounted) return;
            Navigator.pop(context);
          },
        ),
      ),
      ContextMenuItem(
        title: l(context).feeds_new,
        icon: Symbols.add_rounded,
        onTap: () => pushRoute(
          context,
          builder: (context) => const EditFeedScreen(feed: null),
        ),
      ),
    ],
  ).openMenu(context);
}
