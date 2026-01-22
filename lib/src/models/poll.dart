import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/utils/utils.dart';

part 'poll.freezed.dart';

@freezed
abstract class PollChoiceModel with _$PollChoiceModel {
  const factory PollChoiceModel({
    required int id,
    required String text,
    required int sortOrder,
    required int numVotes,
    required bool chosen,
  }) = _PollChoiceModel;
}

@freezed
abstract class PollModel with _$PollModel {
  const factory PollModel({
    required int postId,
    required DateTime endPoll,
    required bool multiple,
    required bool localOnly,
    required List<PollChoiceModel> choices,
  }) = _PollModel;

  factory PollModel.fromPiefed(int postId, JsonMap json) {
    final choices = json['choices'] as List<dynamic>;
    final votes = json['my_votes'] as List<dynamic>? ?? [];

    return PollModel(
      postId: postId,
      endPoll: DateTime.parse(json['end_poll'] as String).toLocal(),
      multiple: (json['mode'] as String) == 'multiple',
      localOnly: json['local_only'] as bool,
      choices: choices
          .map(
            (choice) => PollChoiceModel(
              id: choice['id'],
              text: choice['choice_text'],
              sortOrder: choice['sort_order'],
              numVotes: choice['num_votes'],
              chosen: votes.contains(choice['id'] as int),
            ),
          )
          .toList(),
    );
  }
}
