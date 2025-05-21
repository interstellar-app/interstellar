import 'package:blurhash_ffi/blurhash_ffi.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/models/image.dart';

class Avatar extends StatelessWidget {
  final ImageModel? image;
  final ImageProvider<Object>? overrideImageProvider;
  final double? radius;
  final double? borderRadius;
  final Color? backgroundColor;

  const Avatar(
    this.image, {
    super.key,
    this.overrideImageProvider,
    this.radius,
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius != null && borderRadius != null
          ? radius! + borderRadius!
          : radius,
      backgroundColor:
          backgroundColor ??
          (radius == null || borderRadius == null ? Colors.transparent : null),
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        foregroundImage:
            overrideImageProvider ??
            (image == null ? null : NetworkImage(image!.src)),
        backgroundImage: image == null
            ? const AssetImage('assets/icons/logo.png')
            : (image!.blurHash != null
                  ? BlurhashFfiImage(image!.blurHash!) as ImageProvider<Object>
                  : null),
        radius: radius,
      ),
    );
  }
}
