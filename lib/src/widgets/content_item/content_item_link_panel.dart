import 'package:flutter/material.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/open_webpage.dart';
import 'package:interstellar/src/widgets/video.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart'
    as youtube_explode_dart;

class _LinkAltSource {
  const _LinkAltSource({required this.name, required this.urlPrefix});

  final String name;
  final String urlPrefix;
}

const _linkAltSources = [
  _LinkAltSource(name: '12ft.io', urlPrefix: 'https://12ft.io/proxy?q='),
  _LinkAltSource(name: 'Archive Today', urlPrefix: 'https://archive.ph/'),
  _LinkAltSource(
    name: 'Ghost Archive',
    urlPrefix: 'https://ghostarchive.org/search?term=',
  ),
  _LinkAltSource(
    name: 'Ground News',
    urlPrefix: 'https://ground.news/find?url=',
  ),
  _LinkAltSource(
    name: 'Internet Archive',
    urlPrefix: 'http://web.archive.org/web/',
  ),
];

const _youtubeAltSources = [
  _LinkAltSource(name: 'Invidious', urlPrefix: 'https://yewtu.be/watch?v='),
  _LinkAltSource(name: 'Piped', urlPrefix: 'https://piped.video/watch?v='),
  _LinkAltSource(
    name: 'YouTube',
    urlPrefix: 'https://www.youtube.com/watch?v=',
  ),
];

class ContentItemLinkPanel extends StatefulWidget {
  const ContentItemLinkPanel({super.key, required this.link});

  final Uri link;

  @override
  State<ContentItemLinkPanel> createState() => _ContentItemLinkPanelState();
}

class _ContentItemLinkPanelState extends State<ContentItemLinkPanel> {
  String? _youtubeVideoId;

  @override
  void initState() {
    super.initState();

    if (isSupportedYouTubeVideo(widget.link)) {
      _youtubeVideoId = youtube_explode_dart.VideoId.parseVideoId(
        widget.link.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          MenuAnchor(
            builder:
                (
                  BuildContext context,
                  MenuController controller,
                  Widget? child,
                ) {
                  return SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      icon: Icon(
                        _youtubeVideoId != null
                            ? Symbols.play_circle_rounded
                            : Symbols.link_rounded,
                      ),
                      onPressed: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      style: TextButton.styleFrom(shape: const LinearBorder()),
                    ),
                  );
                },
            menuChildren: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(l(context).alternativeSources),
              ),
              ...(_youtubeVideoId != null
                      ? _youtubeAltSources
                      : _linkAltSources)
                  .map(
                    (source) => MenuItemButton(
                      onPressed: () => openWebpagePrimary(
                        context,
                        Uri.parse(
                          source.urlPrefix +
                              (_youtubeVideoId ?? widget.link.toString()),
                        ),
                      ),
                      child: Text(source.name),
                    ),
                  ),
            ],
          ),
          Expanded(
            child: SizedBox(
              height: 40,
              child: InkWell(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: widget.link.host,
                          style: Theme.of(context).textTheme.bodyMedium!.apply(
                            decoration: TextDecoration.underline,
                            fontWeightDelta: 100,
                          ),
                        ),
                        TextSpan(
                          text: widget.link.toString().substring(
                            ('${widget.link.scheme}://${widget.link.host}')
                                .length,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium!.apply(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    softWrap: false,
                    overflow: TextOverflow.fade,
                  ),
                ),
                onTap: () {
                  openWebpagePrimary(context, widget.link);
                },
                onLongPress: () {
                  openWebpageSecondary(context, widget.link);
                },
                onSecondaryTap: () {
                  openWebpageSecondary(context, widget.link);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
