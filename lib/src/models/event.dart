import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/utils/models.dart';
import 'package:interstellar/src/utils/utils.dart';

part 'event.freezed.dart';
part 'event.g.dart';

@freezed
abstract class LocationModel with _$LocationModel {
  const factory LocationModel({
    required String address,
    required String city,
    required String country,
  }) = _LocationModel;

  factory LocationModel.fromJson(JsonMap json) => _$LocationModelFromJson(json);
}

@freezed
abstract class EventModel with _$EventModel {
  const factory EventModel({
    required int postId,
    required DateTime start,
    required DateTime? end,
    required String? timezone,
    required int maxAttendees,
    required int participantCount,
    required bool full,
    required Uri? onlineUrl,
    required String joinMode,
    required String? externalParticipationUrl,
    required bool anonymousParticipation,
    required bool online,
    required String? buyTicketsUrl,
    required String eventFeeCurrency,
    required int eventFee,
    required LocationModel? location,
  }) = _EventModel;

  factory EventModel.fromPiefed(int postId, JsonMap json) => EventModel(
    postId: postId,
    start: DateTime.parse(json['start']! as String),
    end: optionalDateTime(json['end'] as String?),
    timezone: json['timezone'] as String?,
    maxAttendees: json['max_attendees'] as int? ?? 0,
    participantCount: json['participant_count'] as int? ?? 0,
    full: json['full'] as bool? ?? false,
    onlineUrl: json['online_link'] == null
        ? null
        : Uri.parse(json['online_link']! as String),
    joinMode: json['join_mode'] as String? ?? 'free',
    externalParticipationUrl: json['external_participation_url'] as String?,
    anonymousParticipation: json['anonymous_participation'] as bool? ?? false,
    online: json['online'] as bool? ?? false,
    buyTicketsUrl: json['buy_tickets_link'] as String?,
    eventFeeCurrency: json['event_fee_currency'] as String? ?? 'USD',
    eventFee: json['event_fee_amount'] as int? ?? 0,
    location: json['location'] == null
        ? null
        : LocationModel.fromJson(json['location']! as JsonMap),
  );
}
