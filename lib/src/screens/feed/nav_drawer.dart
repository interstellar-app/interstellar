import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/domain.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/explore/domain_screen.dart';
import 'package:interstellar/src/screens/explore/explore_screen.dart';
import 'package:interstellar/src/screens/explore/community_screen.dart';
import 'package:interstellar/src/screens/explore/user_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:interstellar/src/widgets/loading_list_tile.dart';
import 'package:interstellar/src/widgets/settings_header.dart';
import 'package:interstellar/src/widgets/star_button.dart';
import 'package:provider/provider.dart';

import 'feed_agregator.dart';
import 'feed_screen.dart';

class NavDrawer extends StatefulWidget {
  const NavDrawer({super.key});

  @override
  State<NavDrawer> createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  List<DetailedCommunityModel>? subbedCommunities;
  List<DetailedUserModel>? subbedUsers;
  List<DomainModel>? subbedDomains;

  @override
  void initState() {
    super.initState();

    if (context.read<AppController>().isLoggedIn) {
      context
          .read<AppController>()
          .api
          .community
          .list(filter: ExploreFilter.subscribed)
          .then((value) {
            if (mounted) {
              setState(() => subbedCommunities = value.items);
            }
          });
      if (context.read<AppController>().serverSoftware == ServerSoftware.mbin) {
        context
            .read<AppController>()
            .api
            .users
            .list(filter: ExploreFilter.subscribed)
            .then((value) {
              if (mounted) {
                setState(() => subbedUsers = value.items);
              }
            });
        context
            .read<AppController>()
            .api
            .domains
            .list(filter: ExploreFilter.subscribed)
            .then((value) {
              if (mounted) {
                setState(() => subbedDomains = value.items);
              }
            });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ExpansionTile(
          title: SettingsHeader('Stars'),
          children: [
            if (ac.stars.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  l(context).stars_empty,
                  style: const TextStyle(fontWeight: FontWeight.w300),
                ),
              ),
            ...(ac.stars.toList()..sort()).map(
              (star) => ListTile(
                title: Text(ac.profile.alwaysShowInstance ? star.substring(1) : star.substring(1).split('@').first),
                onTap: () async {
                  String name = star.substring(1);
                  if (name.endsWith(ac.instanceHost)) {
                    name = name.split('@').first;
                  }

                  switch (star[0]) {
                    case '@':
                      final user = await ac.api.users.getByName(name);

                      if (!context.mounted) return;

                      pushRoute(
                        context,
                        builder: (context) => UserScreen(user.id, initData: user),
                      );
                      break;

                    case '!':
                      final community = await ac.api.community.getByName(name);

                      if (!context.mounted) return;

                      pushRoute(
                        context,
                        builder: (context) =>
                            CommunityScreen(community.id, initData: community),
                      );
                      break;
                  }
                },
                trailing: StarButton(star),
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: SettingsHeader(l(context).feeds),
          children: [
            if (ac.feeds.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  l(context).feeds_empty,
                  style: const TextStyle(fontWeight: FontWeight.w300),
                ),
              ),
            ...ac.feeds.entries.map(
              (feed) => LoadingListTile(
                title: Text(feed.value.name),
                onTap: () async {
                  final aggregator = await FeedAggregator.create(
                    ac,
                    feed.value,
                  );
                  if (!context.mounted) return;
                  pushRoute(
                    context,
                    builder: (context) => FeedScreen(feed: aggregator),
                  );
                },
              ),
            ),
          ],
        ),
        if (ac.isLoggedIn)
          ExpansionTile(
            title: SettingsHeader(l(context).subscriptions),
            children: [
              if (subbedCommunities == null)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [CircularProgressIndicator()],
                ),
              if (subbedCommunities != null && subbedCommunities!.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    l(context).subscriptions_community_empty,
                    style: const TextStyle(fontWeight: FontWeight.w300),
                  ),
                ),
              if (subbedCommunities != null)
                ...subbedCommunities!
                    .asMap()
                    .map(
                      (index, community) => MapEntry(
                        index,
                        ListTile(
                          title: Text(ac.profile.alwaysShowInstance ? community.name : community.name.split('@').first),
                          leading: community.icon == null
                              ? null
                              : Avatar(community.icon, radius: 16),
                          trailing: StarButton(
                            community.name.contains('@')
                                ? '!${community.name}'
                                : '!${community.name}@${ac.instanceHost}',
                          ),
                          onTap: () => pushRoute(
                              context,
                              builder: (context) => CommunityScreen(
                                community.id,
                                initData: community,
                                onUpdate: (newValue) {
                                  setState(() {
                                    final newSubbedCommunities = [
                                      ...subbedCommunities!,
                                    ];
                                    newSubbedCommunities[index] = newValue;
                                    subbedCommunities = newSubbedCommunities;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    )
                    .values,
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextButton(
                  onPressed: () => pushRoute(
                      context,
                      builder: (context) => const ExploreScreen(
                        subOnlyMode: ExploreType.communities,
                      ),
                  ),
                  child: Text(l(context).subscriptions_community_all),
                ),
              ),
            ],
          ),
        if (ac.isLoggedIn)
          ExpansionTile(
            title: SettingsHeader(l(context).subscriptions_user),
            children: [
              if (subbedUsers == null)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [CircularProgressIndicator()],
                ),
              if (subbedUsers != null && subbedUsers!.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    l(context).subscriptions_user_empty,
                    style: const TextStyle(fontWeight: FontWeight.w300),
                  ),
                ),
              if (subbedUsers != null)
                ...subbedUsers!
                    .asMap()
                    .map(
                      (index, user) => MapEntry(
                        index,
                        ListTile(
                          title: Text(ac.profile.alwaysShowInstance ? user.name : user.name.split('@').first),
                          leading: user.avatar == null
                              ? null
                              : Avatar(user.avatar, radius: 16),
                          trailing: StarButton(
                            user.name.contains('@')
                                ? '@${user.name}'
                                : '@${user.name}@${ac.instanceHost}',
                          ),
                          onTap: () => pushRoute(
                              context,
                              builder: (context) => UserScreen(
                                user.id,
                                initData: user,
                                onUpdate: (newValue) {
                                  setState(() {
                                    final newSubbedUsers = [...subbedUsers!];
                                    newSubbedUsers[index] = newValue;
                                    subbedUsers = newSubbedUsers;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    )
                    .values,
              if (subbedUsers != null && subbedUsers!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextButton(
                    onPressed: () => pushRoute(
                        context,
                        builder: (context) => const ExploreScreen(
                          subOnlyMode: ExploreType.people,
                        ),
                    ),
                    child: Text(l(context).subscriptions_user_all),
                  ),
                ),
            ],
          ),
        if (ac.isLoggedIn)
          ExpansionTile(
            title: SettingsHeader(l(context).subscriptions_domain),
            children: [
              if (subbedDomains == null)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [CircularProgressIndicator()],
                ),
              if (subbedDomains != null && subbedDomains!.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    l(context).subscriptions_domain_empty,
                    style: const TextStyle(fontWeight: FontWeight.w300),
                  ),
                ),
              if (subbedDomains != null)
                ...subbedDomains!
                    .asMap()
                    .map(
                      (index, domain) => MapEntry(
                        index,
                        ListTile(
                          title: Text(domain.name),
                          onTap: () => pushRoute(
                              context,
                              builder: (context) => DomainScreen(
                                domain.id,
                                initData: domain,
                                onUpdate: (newValue) {
                                  setState(() {
                                    final newSubbedDomains = [
                                      ...subbedDomains!,
                                    ];
                                    newSubbedDomains[index] = newValue;
                                    subbedDomains = newSubbedDomains;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    )
                    .values,
              if (subbedDomains != null && subbedDomains!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextButton(
                    onPressed: () => pushRoute(
                        context,
                        builder: (context) => const ExploreScreen(
                          subOnlyMode: ExploreType.domains,
                        ),
                      ),
                    child: Text(l(context).subscriptions_domain_all),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
