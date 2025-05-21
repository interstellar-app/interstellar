import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/utils/utils.dart';

part 'image.freezed.dart';

@freezed
class ImageModel with _$ImageModel {
  const factory ImageModel({
    required String src,
    required String? altText,
    required String? blurHash,
    required int? blurHashWidth,
    required int? blurHashHeight,
  }) = _ImageModel;

  factory ImageModel.fromMbin(JsonMap json) => ImageModel(
    src: (json['storageUrl'] ?? json['sourceUrl']) as String,
    altText: json['altText'] as String?,
    blurHash: json['blurHash'] as String?,
    blurHashWidth: json['width'] as int?,
    blurHashHeight: json['height'] as int?,
  );

  factory ImageModel.fromLemmy(String src, [String? altText]) => ImageModel(
    src: src,
    altText: altText,
    blurHash: null,
    blurHashWidth: null,
    blurHashHeight: null,
  );
}
