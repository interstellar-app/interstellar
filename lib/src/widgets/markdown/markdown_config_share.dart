import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart' as mdf;
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/filter_list.dart';
import 'package:interstellar/src/controller/profile.dart';
import 'package:interstellar/src/models/config_share.dart';
import 'package:interstellar/src/screens/settings/filter_lists_screen.dart';
import 'package:interstellar/src/screens/settings/profile_selection.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class ConfigShareMarkdownSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^```interstellar$');

  final String endString = r'```';

  @override
  md.Node parse(md.BlockParser parser) {
    parser.advance();

    final List<String> body = [];

    while (!parser.isDone) {
      if (parser.current.content == endString) {
        parser.advance();
        break;
      } else {
        body.add(parser.current.content);
        parser.advance();
      }
    }

    final md.Node spoiler = md.Element('p', [
      md.Element('config-share', [md.Text(body.join('\n'))]),
    ]);

    return spoiler;
  }
}

class ConfigShareMarkdownBuilder extends mdf.MarkdownElementBuilder {
  ConfigShareMarkdownBuilder();

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return ConfigShareWidget(text: element.textContent);
  }
}

class ConfigShareWidget extends StatefulWidget {
  final String text;

  const ConfigShareWidget({super.key, required this.text});

  @override
  State<ConfigShareWidget> createState() => _ConfigShareWidgetState();
}

class _ConfigShareWidgetState extends State<ConfigShareWidget> {
  late ConfigShare config;

  ProfileOptional? configProfile;
  FilterList? configFilterList;

  bool invalid = false;

  @override
  void initState() {
    super.initState();

    try {
      config = ConfigShare.fromJson(jsonDecode(widget.text));
      if (!config.verifyHash(widget.text)) {
        setState(() {
          invalid = true;
        });
        return;
      }
      switch (config.type) {
        case ConfigShareType.profile:
          configProfile = ProfileOptional.fromJson(config.payload);
          break;
        case ConfigShareType.filterList:
          configFilterList = FilterList.fromJson(config.payload);
          break;
      }
      setState(() {});
    } catch (_) {
      setState(() {
        invalid = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: invalid
            ? const Center(child: Icon(Symbols.warning_rounded))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(switch (config.type) {
                    ConfigShareType.profile => l(
                      context,
                    ).configShare_profile_title,
                    ConfigShareType.filterList => l(
                      context,
                    ).configShare_filterList_title,
                  }),
                  Text(
                    l(context).configShare_created(
                      dateOnlyFormat(config.date),
                      config.interstellar,
                    ),
                  ),
                  Text(switch (config.type) {
                    ConfigShareType.profile => l(
                      context,
                    ).configShare_profile_info(config.payload.length),
                    ConfigShareType.filterList =>
                      l(context).configShare_filterList_info(
                        configFilterList!.phrases.length,
                      ),
                  }),
                  const SizedBox(height: 8),
                  LoadingFilledButton(
                    icon: const Icon(Symbols.download_rounded),
                    onPressed: switch (config.type) {
                      ConfigShareType.profile => () async {
                        final profileList = await context
                            .read<AppController>()
                            .getProfileNames();

                        if (!mounted) return;

                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(
                              profile: config.name,
                              profileList: profileList,
                              importProfile: configProfile!,
                            ),
                          ),
                        );
                      },
                      ConfigShareType.filterList => () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditFilterListScreen(
                              filterList: config.name,
                              importFilterList: configFilterList!,
                            ),
                          ),
                        );
                      },
                    },
                    label: Text(switch (config.type) {
                      ConfigShareType.profile => l(context).profile_import,
                      ConfigShareType.filterList => l(
                        context,
                      ).filterList_import,
                    }),
                  ),
                ],
              ),
      ),
    );
  }
}
