import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/domain.dart';
import 'package:interstellar/src/models/magazine.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/explore/domain_screen.dart';
import 'package:interstellar/src/screens/explore/explore_screen.dart';
import 'package:interstellar/src/screens/explore/magazine_screen.dart';
import 'package:interstellar/src/screens/explore/user_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:interstellar/src/widgets/settings_header.dart';
import 'package:interstellar/src/widgets/star_button.dart';
import 'package:provider/provider.dart';

class NavDrawer extends StatefulWidget {
  const NavDrawer({super.key});

  @override
  State<NavDrawer> createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  List<DetailedMagazineModel>? subbedMagazines;
  List<DetailedUserModel>? subbedUsers;
  List<DomainModel>? subbedDomains;

  @override
  void initState() {
    super.initState();

    if (context.read<AppController>().isLoggedIn) {
      context
          .read<AppController>()
          .api
          .magazines
          .list(filter: ExploreFilter.subscribed)
          .then((value) {
            if (mounted && value.items.isNotEmpty) {
              setState(() => subbedMagazines = value.items);
            }
          });
      if (context.read<AppController>().serverSoftware == ServerSoftware.mbin) {
        context
            .read<AppController>()
            .api
            .users
            .list(filter: ExploreFilter.subscribed)
            .then((value) {
              if (mounted && value.items.isNotEmpty) {
                setState(() => subbedUsers = value.items);
              }
            });
        context
            .read<AppController>()
            .api
            .domains
            .list(filter: ExploreFilter.subscribed)
            .then((value) {
              if (mounted && value.items.isNotEmpty) {
                setState(() => subbedDomains = value.items);
              }
            });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SettingsHeader(l(context).stars),
            ),
            if (context.watch<AppController>().stars.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  l(context).stars_empty,
                  style: const TextStyle(fontWeight: FontWeight.w300),
                ),
              ),
            ...(context.watch<AppController>().stars.toList()..sort()).map(
              (star) => ListTile(
                title: Text(star),
                onTap: () async {
                  String name = star.substring(1);
                  if (name.endsWith(
                    context.read<AppController>().instanceHost,
                  )) {
                    name = name.split('@').first;
                  }

                  switch (star[0]) {
                    case '@':
                      final user = await context
                          .read<AppController>()
                          .api
                          .users
                          .getByName(name);

                      if (!mounted) return;

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              UserScreen(user.id, initData: user),
                        ),
                      );
                      break;

                    case '!':
                      final magazine = await context
                          .read<AppController>()
                          .api
                          .magazines
                          .getByName(name);

                      if (!mounted) return;

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              MagazineScreen(magazine.id, initData: magazine),
                        ),
                      );
                      break;
                  }
                },
                trailing: StarButton(star),
              ),
            ),
            if (context.read<AppController>().isLoggedIn &&
                subbedMagazines == null &&
                subbedUsers == null &&
                subbedDomains == null)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [CircularProgressIndicator()],
              ),
            if (context.watch<AppController>().isLoggedIn &&
                (subbedMagazines != null ||
                    subbedUsers != null ||
                    subbedDomains != null)) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SettingsHeader(l(context).subscriptions),
              ),
              if (subbedMagazines != null) ...[
                ...subbedMagazines!
                    .asMap()
                    .map(
                      (index, magazine) => MapEntry(
                        index,
                        ListTile(
                          title: Text(magazine.name),
                          leading: magazine.icon == null
                              ? null
                              : Avatar(magazine.icon, radius: 16),
                          trailing: StarButton(
                            magazine.name.contains('@')
                                ? '!${magazine.name}'
                                : '!${magazine.name}@${context.watch<AppController>().instanceHost}',
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MagazineScreen(
                                  magazine.id,
                                  initData: magazine,
                                  onUpdate: (newValue) {
                                    setState(() {
                                      final newSubbedMagazines = [
                                        ...subbedMagazines!,
                                      ];
                                      newSubbedMagazines[index] = newValue;
                                      subbedMagazines = newSubbedMagazines;
                                    });
                                  },
                                ),
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
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ExploreScreen(
                          subOnlyMode: ExploreType.magazines,
                        ),
                      ),
                    ),
                    child: Text(l(context).subscriptions_magazine_all),
                  ),
                ),
              ],
            ],
            if (context.read<AppController>().serverSoftware ==
                    ServerSoftware.mbin &&
                subbedUsers != null) ...[
              ...subbedUsers!
                  .asMap()
                  .map(
                    (index, user) => MapEntry(
                      index,
                      ListTile(
                        title: Text(user.name),
                        leading: user.avatar == null
                            ? null
                            : Avatar(user.avatar, radius: 16),
                        trailing: StarButton(
                          user.name.contains('@')
                              ? '@${user.name}'
                              : '@${user.name}@${context.watch<AppController>().instanceHost}',
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
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
                          );
                        },
                      ),
                    ),
                  )
                  .values,
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const ExploreScreen(subOnlyMode: ExploreType.people),
                    ),
                  ),
                  child: Text(l(context).subscriptions_user_all),
                ),
              ),
            ],
            if (context.read<AppController>().serverSoftware ==
                    ServerSoftware.mbin &&
                subbedDomains != null) ...[
              ...subbedDomains!
                  .asMap()
                  .map(
                    (index, domain) => MapEntry(
                      index,
                      ListTile(
                        title: Text(domain.name),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
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
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const ExploreScreen(subOnlyMode: ExploreType.domains),
                    ),
                  ),
                  child: Text(l(context).subscriptions_domain_all),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
