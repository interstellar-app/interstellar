import 'package:interstellar/src/models/image.dart';
import 'package:interstellar/src/utils/utils.dart';

DateTime? optionalDateTime(String? value) =>
    value == null ? null : DateTime.parse(value);

List<String>? optionalStringList(Object? json) =>
    json == null ? null : (json as List<dynamic>).cast<String>();

String? mbinCalcNextPaginationPage(JsonMap pagination) {
  return (pagination['currentPage'] as int) < (pagination['maxPage'] as int)
      ? ((pagination['currentPage'] as int) + 1).toString()
      : null;
}

ImageModel? mbinGetOptionalImage(JsonMap? json) {
  return json == null || (json['storageUrl'] ?? json['sourceUrl']) == null
      ? null
      : ImageModel.fromMbin(json);
}

ImageModel? lemmyGetOptionalImage(String? src, [String? altText]) {
  return src == null ? null : ImageModel.fromLemmy(src, altText);
}

String mbinNormalizeUsername(String username) {
  return username.startsWith('@') ? username.substring(1) : username;
}

/// Converts lemmy and piefed's local name to Mbin's standard name
String getLemmyPiefedActorName(JsonMap json) {
  final name = (json['user_name'] ?? json['name']) as String;

  return (json['local'] as bool)
      ? name
      : '$name@${Uri.parse(json['actor_id'] as String).host}';
}

String? lemmyCalcNextIntPage(List<dynamic> list, String? currentPage) =>
    list.isEmpty ? null : (int.parse(currentPage ?? '0') + 1).toString();
