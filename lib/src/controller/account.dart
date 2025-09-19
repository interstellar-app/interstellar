import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:oauth2/oauth2.dart';

part 'account.freezed.dart';
part 'account.g.dart';

@freezed
abstract class Account with _$Account {
  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory Account({
    Credentials? oauth,
    String? jwt,
    bool? isPushRegistered,
  }) = _Account;

  factory Account.fromJson(JsonMap json) => _$AccountFromJson(json);
}
