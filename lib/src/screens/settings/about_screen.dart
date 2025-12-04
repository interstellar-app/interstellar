import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/screens/explore/community_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/utils/globals.dart';
import 'package:interstellar/src/widgets/open_webpage.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'debug/debug_screen.dart';

const _donateLink = 'https://github.com/sponsors/jwr1';
const _contributeLink = 'https://github.com/interstellar-app/interstellar';
const _translateLink =
    'https://hosted.weblate.org/projects/interstellar/interstellar/';
const _reportIssueLink =
    'https://github.com/interstellar-app/interstellar/issues';
const _matrixSpaceLink = 'https://matrix.to/#/#interstellar-space:matrix.org';
const _mbinCommunityName = 'interstellar@kbin.earth';
const _mbinCommunityLink = 'https://kbin.earth/m/interstellar';
const mbinConfigsCommunityName = 'interstellar_configs@kbin.earth';
const _mbinConfigsCommunityLink = 'https://kbin.earth/m/interstellar_configs';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l(context).settings_aboutInterstellar)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Symbols.bug_report_rounded),
            title: Text(l(context).settings_debug),
            onTap: () => pushRoute(
              context,
              builder: (context) => const DebugSettingsScreen(),
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.favorite_rounded),
            title: Text(l(context).settings_donate),
            onTap: () => openWebpagePrimary(context, Uri.parse(_donateLink)),
          ),
          ListTile(
            leading: const ImageIcon(AssetImage('assets/icons/github.png')),
            title: Text(l(context).settings_contribute),
            onTap: () =>
                openWebpagePrimary(context, Uri.parse(_contributeLink)),
          ),
          ListTile(
            leading: const Icon(Symbols.translate_rounded),
            title: Text(l(context).settings_translate),
            onTap: () => openWebpagePrimary(context, Uri.parse(_translateLink)),
          ),
          ListTile(
            leading: const Icon(Symbols.bug_report_rounded),
            title: Text(l(context).settings_reportIssue),
            onTap: () =>
                openWebpagePrimary(context, Uri.parse(_reportIssueLink)),
          ),
          ListTile(
            leading: const ImageIcon(AssetImage('assets/icons/matrix.png')),
            title: Text(l(context).settings_matrixSpace),
            onTap: () =>
                openWebpagePrimary(context, Uri.parse(_matrixSpaceLink)),
          ),
          ListTile(
            leading: const ImageIcon(AssetImage('assets/icons/mbin.png')),
            title: Text(l(context).settings_mbinCommunity),
            onTap: () async {
              try {
                String name = _mbinCommunityName;
                if (name.endsWith(context.read<AppController>().instanceHost)) {
                  name = name.split('@').first;
                }

                final community = await context
                    .read<AppController>()
                    .api
                    .community
                    .getByName(name);

                if (!context.mounted) return;

                pushRoute(
                  context,
                  builder: (context) =>
                      CommunityScreen(community.id, initData: community),
                );
              } catch (e) {
                if (!mounted) return;
                openWebpagePrimary(context, Uri.parse(_mbinCommunityLink));
              }
            },
          ),
          ListTile(
            leading: const Icon(Symbols.share_rounded),
            title: Text(l(context).settings_mbinConfigsCommunity),
            onTap: () async {
              try {
                String name = mbinConfigsCommunityName;
                if (name.endsWith(context.read<AppController>().instanceHost)) {
                  name = name.split('@').first;
                }

                final community = await context
                    .read<AppController>()
                    .api
                    .community
                    .getByName(name);

                if (!context.mounted) return;

                pushRoute(
                  context,
                  builder: (context) =>
                      CommunityScreen(community.id, initData: community),
                );
              } catch (e) {
                if (!mounted) return;
                openWebpagePrimary(
                  context,
                  Uri.parse(_mbinConfigsCommunityLink),
                );
              }
            },
          ),
          const Divider(),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: Image.asset('assets/icons/logo-foreground.png'),
              ),
              Text('${l(context).interstellar} v$appVersion'),
              const SizedBox(height: 36),
            ],
          ),
        ],
      ),
    );
  }
}
