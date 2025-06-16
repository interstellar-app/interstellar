import 'package:flutter/material.dart';
import 'package:interstellar/src/utils/share.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:media_kit_video/media_kit_video_controls/media_kit_video_controls.dart'
    as media_kit_video_controls;
import 'package:provider/provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart'
    as youtube_explode_dart;
import 'package:interstellar/src/controller/controller.dart';

bool isSupportedYouTubeVideo(Uri link) {
  return [
    'www.youtube.com',
    'youtube.com',
    'youtu.be',
    'm.youtube.com',
  ].contains(link.host);
}

class VideoPlayer extends StatefulWidget {
  final Uri uri;

  const VideoPlayer(this.uri, {super.key});

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  final player = Player();
  late final controller = VideoController(player);
  bool _isPlaying = false;
  youtube_explode_dart.YoutubeExplode? yt;
  String? error;

  Future<void> _initController() async {
    final autoPlay = context.read<AppController>().profile.autoPlayVideos;
    setState(() {
      _isPlaying = autoPlay;
    });
    player.stream.playing.listen((bool playing) {
      if (!mounted) return;
      setState(() {
        _isPlaying = playing;
      });
    });

    try {
      if (isSupportedYouTubeVideo(widget.uri)) {
        yt ??= youtube_explode_dart.YoutubeExplode();
        if (yt == null) return;

        final manifest = await yt!.videos.streamsClient.getManifest(widget.uri);

        if (!mounted) return;

        // Use best muxed stream if available, else use best separate video and audio streams
        // TODO: calculate best quality for device based on screen size and data saver mode, also add manual stream selection
        if (manifest.muxed.isNotEmpty) {
          final muxedStream = manifest.muxed.bestQuality;
          player.open(Media(muxedStream.url.toString()), play: autoPlay);
        } else {
          final videoStream = manifest.video.bestQuality;
          final audioStream = manifest.audio.withHighestBitrate();
          final media = Media(videoStream.url.toString());

          player.open(media, play: _isPlaying);
          player.setAudioTrack(AudioTrack.uri(audioStream.url.toString()));
        }
      } else {
        player.open(Media(widget.uri.toString()), play: _isPlaying);
      }
    } catch (e) {
      error = e.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement top buttons by setting a MaterialVideoControls & MaterialDesktopVideoControlsTheme
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.width * 9.0 / 16.0,
      child: Stack(
        children: [
          if (error != null)
            DecoratedBox(
              decoration: BoxDecoration(color: Colors.black),
              child: Center(child: Text(error!)),
            ),
          if (error == null)
            Video(
              controller: controller,
              controls: (state) {
                return Stack(
                  children: [
                    media_kit_video_controls.AdaptiveVideoControls(state),
                    if (!_isPlaying)
                      Center(child: MaterialPlayOrPauseButton(iconSize: 56)),
                    if (!state.isFullscreen())
                      Align(
                        alignment: Alignment.topRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LoadingIconButton(
                              onPressed: () async => await shareUri(widget.uri),
                              icon: const Icon(Symbols.share_rounded),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    yt?.close();
    player.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!(ModalRoute.of(context)?.isCurrent ?? false)) {
        player.pause();
      }
    });
  }
}
