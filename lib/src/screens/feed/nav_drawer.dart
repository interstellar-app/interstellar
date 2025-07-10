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

class NavDrawPersistentState {
  const NavDrawPersistentState({
    this.fetchTime = 0,
    this.initExpandedStars = false,
    this.initExpandedFeeds = false,
    this.initExpandedSubscriptions = false,
    this.initExpandedFollows = false,
    this.initExpandedDomains = false,
    this.subbedCommunities = const [],
    this.subbedUsers = const [],
    this.subbedDomains = const [],
  });

  final int fetchTime;

  final bool initExpandedStars;
  final bool initExpandedFeeds;
  final bool initExpandedSubscriptions;
  final bool initExpandedFollows;
  final bool initExpandedDomains;

  final List<DetailedCommunityModel> subbedCommunities;
  final List<DetailedUserModel> subbedUsers;
  final List<DomainModel> subbedDomains;

  NavDrawPersistentState copyWith({
    bool? initExpandedStars,
    bool? initExpandedFeeds,
    bool? initExpandedSubscriptions,
    bool? initExpandedFollows,
    bool? initExpandedDomains,
    List<DetailedCommunityModel>? subbedCommunities,
    List<DetailedUserModel>? subbedUsers,
    List<DomainModel>? subbedDomains,
  }) => NavDrawPersistentState(
    initExpandedStars: initExpandedStars ?? this.initExpandedStars,
    initExpandedFeeds: initExpandedFeeds ?? this.initExpandedFeeds,
    initExpandedSubscriptions:
        initExpandedSubscriptions ?? this.initExpandedSubscriptions,
    initExpandedFollows: initExpandedFollows ?? this.initExpandedFollows,
    initExpandedDomains: initExpandedDomains ?? this.initExpandedDomains,
    subbedCommunities: subbedCommunities ?? this.subbedCommunities,
    subbedUsers: subbedUsers ?? this.subbedUsers,
    subbedDomains: subbedDomains ?? this.subbedDomains,
  );
}

Future<NavDrawPersistentState> fetchNavDrawerState(AppController ac) async {
  final fetchTime = DateTime.now();
  final initExpandedStars = (await ac.fetchCachedValue('nav-stars')) ?? false;
  final initExpandedFeeds = (await ac.fetchCachedValue('nav-feeds')) ?? false;
  final initExpandedSubscriptions =
      (await ac.fetchCachedValue('nav-subscriptions')) ?? false;
  final initExpandedFollows =
      (await ac.fetchCachedValue('nav-follows')) ?? false;
  final initExpandedDomains =
      (await ac.fetchCachedValue('nav-domains')) ?? false;

  List<DetailedCommunityModel> subbedCommunities = [];
  List<DetailedUserModel> subbedUsers = [];
  List<DomainModel> subbedDomains = [];
  if (ac.isLoggedIn) {
    subbedCommunities = (await ac.api.community.list(
      filter: ExploreFilter.subscribed,
    )).items;
    if (ac.serverSoftware == ServerSoftware.mbin) {
      subbedUsers = (await ac.api.users.list(
        filter: ExploreFilter.subscribed,
      )).items;
      subbedDomains = (await ac.api.domains.list(
        filter: ExploreFilter.subscribed,
      )).items;
    }
  }

  return NavDrawPersistentState(
    fetchTime: fetchTime.millisecondsSinceEpoch,
    initExpandedStars: initExpandedStars,
    initExpandedFeeds: initExpandedFeeds,
    initExpandedSubscriptions: initExpandedSubscriptions,
    initExpandedFollows: initExpandedFollows,
    initExpandedDomains: initExpandedDomains,
    subbedCommunities: subbedCommunities,
    subbedUsers: subbedUsers,
    subbedDomains: subbedDomains,
  );
}

class NavDrawer extends StatefulWidget {
  const NavDrawer({
    super.key,
    this.drawerState = const NavDrawPersistentState(),
    this.updateState,
  });

  final NavDrawPersistentState drawerState;
  final Future<void> Function(NavDrawPersistentState?)? updateState;

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

    // if state older than 15 minus refresh
    if (widget.drawerState.fetchTime <
        DateTime.now().subtract(Duration(minutes: 15)).millisecondsSinceEpoch) {
      widget.updateState!(null);
    }
    subbedCommunities = widget.drawerState.subbedCommunities;
    subbedUsers = widget.drawerState.subbedUsers;
    subbedDomains = widget.drawerState.subbedDomains;
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ExpansionTile(
          title: SettingsHeader(l(context).stars),
          onExpansionChanged: (bool value) {
            ac.cacheValue('nav-stars', value);
            widget.updateState!(
              widget.drawerState.copyWith(initExpandedStars: value),
            );
          },
          initiallyExpanded: widget.drawerState.initExpandedStars,
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
                title: Text(
                  ac.profile.alwaysShowInstance
                      ? star.substring(1)
                      : star.substring(1).split('@').first,
                ),
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
                        builder: (context) =>
                            UserScreen(user.id, initData: user),
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
          onExpansionChanged: (bool value) {
            ac.cacheValue('nav-feeds', value);
            widget.updateState!(
              widget.drawerState.copyWith(initExpandedFeeds: value),
            );
          },
          initiallyExpanded: widget.drawerState.initExpandedFeeds,
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
            onExpansionChanged: (bool value) {
              ac.cacheValue('nav-subscriptions', value);
              widget.updateState!(
                widget.drawerState.copyWith(initExpandedSubscriptions: value),
              );
            },
            initiallyExpanded: widget.drawerState.initExpandedSubscriptions,
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
                          title: Text(
                            ac.profile.alwaysShowInstance
                                ? community.name
                                : community.name.split('@').first,
                          ),
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
                          ),
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
            onExpansionChanged: (bool value) {
              ac.cacheValue('nav-follows', value);
              widget.updateState!(
                widget.drawerState.copyWith(initExpandedFollows: value),
              );
            },
            initiallyExpanded: widget.drawerState.initExpandedFollows,
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
                          title: Text(
                            ac.profile.alwaysShowInstance
                                ? user.name
                                : user.name.split('@').first,
                          ),
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
                          ),
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
                      builder: (context) =>
                          const ExploreScreen(subOnlyMode: ExploreType.people),
                    ),
                    child: Text(l(context).subscriptions_user_all),
                  ),
                ),
            ],
          ),
        if (ac.isLoggedIn)
          ExpansionTile(
            title: SettingsHeader(l(context).subscriptions_domain),
            onExpansionChanged: (bool value) {
              ac.cacheValue('nav-domains', value);
              widget.updateState!(
                widget.drawerState.copyWith(initExpandedDomains: value),
              );
            },
            initiallyExpanded: widget.drawerState.initExpandedDomains,
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
                                  final newSubbedDomains = [...subbedDomains!];
                                  newSubbedDomains[index] = newValue;
                                  subbedDomains = newSubbedDomains;
                                });
                              },
                            ),
                          ),
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
                      builder: (context) =>
                          const ExploreScreen(subOnlyMode: ExploreType.domains),
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
