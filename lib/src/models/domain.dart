import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/utils/models.dart';
import 'package:interstellar/src/utils/utils.dart';

part 'domain.freezed.dart';

@freezed
class DomainListModel with _$DomainListModel {
  const factory DomainListModel({
    required List<DomainModel> items,
    required String? nextPage,
  }) = _DomainListModel;

  factory DomainListModel.fromMbin(JsonMap json) => DomainListModel(
    items: (json['items'] as List<dynamic>)
        .map((post) => DomainModel.fromMbin(post as JsonMap))
        .toList(),
    nextPage: mbinCalcNextPaginationPage(json['pagination'] as JsonMap),
  );
}

@freezed
class DomainModel with _$DomainModel {
  const factory DomainModel({
    required int id,
    required String name,
    required int entryCount,
    required int subscriptionsCount,
    required bool? isUserSubscribed,
    required bool? isBlockedByUser,
  }) = _DomainModel;

  factory DomainModel.fromMbin(JsonMap json) => DomainModel(
    id: json['domainId'] as int,
    name: json['name'] as String,
    entryCount: json['entryCount'] as int,
    subscriptionsCount: json['subscriptionsCount'] as int,
    isUserSubscribed: json['isUserSubscribed'] as bool?,
    isBlockedByUser: json['isBlockedByUser'] as bool?,
  );
}
