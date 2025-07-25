import 'dart:io';
import 'dart:math';
import 'package:blurhash_ffi/blurhash_ffi.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/models/image.dart';
import 'package:interstellar/src/utils/share.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/blur.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/wrapper.dart';
import 'package:interstellar/src/widgets/super_hero.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:interstellar/src/controller/controller.dart';

class AdvancedImage extends StatelessWidget {
  final ImageModel image;
  final BoxFit fit;
  final String? openTitle;
  final bool enableBlur;
  final String? hero;

  const AdvancedImage(
    this.image, {
    super.key,
    this.fit = BoxFit.contain,
    this.openTitle,
    this.enableBlur = false,
    this.hero,
  });

  @override
  Widget build(BuildContext context) {
    final blurHashSizeFactor = image.blurHash == null
        ? null
        : sqrt(1080 / (image.blurHashWidth! * image.blurHashHeight!));

    return SuperHero(
      tag: image.toString() + (hero ?? ''),
      child: Wrapper(
        shouldWrap: openTitle != null,
        parentBuilder: (child) => GestureDetector(
          onTap: () => pushRoute(
            context,
            builder: (context) => AdvancedImagePage(
              image,
              title: openTitle!,
              hero: hero,
              fit: fit,
            ),
          ),
          child: child,
        ),
        child: Wrapper(
          shouldWrap: enableBlur,
          parentBuilder: (child) => Blur(child),
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.passthrough,
            children: [
              if (image.blurHash != null)
                Image(
                  fit: fit,
                  image: BlurhashFfiImage(
                    image.blurHash!,
                    decodingWidth: (blurHashSizeFactor! * image.blurHashWidth!)
                        .ceil(),
                    decodingHeight: (blurHashSizeFactor * image.blurHashHeight!)
                        .ceil(),
                    scale: blurHashSizeFactor,
                  ),
                ),
              Image.network(image.src, fit: fit),
            ],
          ),
        ),
      ),
    );
  }
}

class AdvancedImagePage extends StatefulWidget {
  final ImageModel image;
  final String title;
  final String? hero;
  final BoxFit fit;

  const AdvancedImagePage(
    this.image, {
    super.key,
    required this.title,
    this.hero,
    this.fit = BoxFit.contain,
  });

  @override
  State<AdvancedImagePage> createState() => _AdvancedImagePageState();
}

class _AdvancedImagePageState extends State<AdvancedImagePage>
    with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late final AnimationController _animationController;
  Animation<Matrix4>? _animation;
  double _scale = 1.0;

  void _returnToCenter() {
    _animationController.reset();
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity(),
    ).animate(_animationController);
    _animation!.addListener(_onAnimate);
    _animationController.forward();
  }

  void _onAnimate() {
    _transformationController.value = _animation!.value;
    if (!_animationController.isAnimating) {
      _animation!.removeListener(_onAnimate);
      _animation = null;
      _animationController.reset();
      _scale = 1.0;
    }
  }

  void _handleTransform() {
    if (!context.mounted || _scale != 1) return;
    final translation = _transformationController.value.getTranslation();
    if (translation.y > MediaQuery.sizeOf(context).height / 3 ||
        translation.y < -MediaQuery.sizeOf(context).height / 3) {
      _transformationController.removeListener(_handleTransform);
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: context.read<AppController>().profile.animationSpeed == 0
          ? Duration.zero
          : Duration(
              milliseconds:
                  (300 / context.read<AppController>().profile.animationSpeed)
                      .toInt(),
            ),
    );
    _transformationController.addListener(_handleTransform);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const shadows = <Shadow>[
      Shadow(color: Colors.black, blurRadius: 1.0, offset: Offset(0, 1)),
    ];

    final titleStyle = Theme.of(
      context,
    ).textTheme.titleLarge!.copyWith(shadows: shadows);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.title, style: titleStyle),
        iconTheme: const IconThemeData(color: Colors.white, shadows: shadows),
        backgroundColor: Colors.transparent,
        actions: [
          LoadingIconButton(
            onPressed: () async {
              await downloadFile(
                Uri.parse(widget.image.src),
                widget.image.src.split('/').last,
              );
            },
            icon: const Icon(Symbols.download_rounded),
          ),
          if (!Platform.isLinux)
            LoadingIconButton(
              onPressed: () async => await shareFile(
                Uri.parse(widget.image.src),
                widget.image.src.split('/').last,
              ),
              icon: const Icon(Symbols.share_rounded),
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onDoubleTap: () {
                _returnToCenter();
              },
              child: InteractiveViewer(
                transformationController: _transformationController,
                panAxis: PanAxis.vertical,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                onInteractionUpdate: (ScaleUpdateDetails details) {
                  _scale *= details.scale;
                },
                onInteractionEnd: (ScaleEndDetails details) {
                  if (_scale == 1.0) {
                    _returnToCenter();
                  }
                },
                child: SafeArea(
                  child: Center(
                    child: AdvancedImage(
                      widget.image,
                      hero: widget.hero,
                      fit: widget.fit,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.image.altText != null)
            Align(
              alignment: Alignment.bottomRight,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l(context).altText),
                        content: Text(widget.image.altText!),
                        actions: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l(context).close),
                          ),
                        ],
                      ),
                    ),
                    child: Text('ALT', style: TextStyle(fontSize: 20)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
