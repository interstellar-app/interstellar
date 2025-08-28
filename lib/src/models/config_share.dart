import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'config_share.freezed.dart';
part 'config_share.g.dart';

enum ConfigShareType { profile, rule, feed }

@freezed
class ConfigShare with _$ConfigShare {
  const ConfigShare._();

  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory ConfigShare({
    // Interstellar version
    required String interstellar,
    required ConfigShareType type,
    required String name,
    required DateTime date,
    required JsonMap payload,
    required String hash,
  }) = _ConfigShare;

  factory ConfigShare.fromJson(JsonMap json) => _$ConfigShareFromJson(json);

  static Future<ConfigShare> create({
    required ConfigShareType type,
    required String name,
    required JsonMap payload,
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();

    final config = ConfigShare(
      interstellar: packageInfo.version,
      type: type,
      name: name,
      date: DateTime.now(),
      payload: payload,
      hash: '',
    );

    final hash = strToMd5Base64(jsonEncode(config.toJson()));

    return config.copyWith(hash: hash);
  }

  // Once the config is parsed, use this to pass in the original json string and verify the hash.
  bool verifyHash(String jsonStr) {
    // Remove instance of hash from original string
    final hashToCheck = strToMd5Base64(jsonStr.replaceFirst(hash, ''));

    return hash == hashToCheck;
  }

  String toMarkdown() => '```interstellar\n${jsonEncode(toJson())}\n```';
}
