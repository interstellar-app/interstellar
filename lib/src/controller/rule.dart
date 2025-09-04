import 'package:flutter/cupertino.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:provider/provider.dart';

part 'rule.freezed.dart';
part 'rule.g.dart';

enum RuleTrigger {
  postOrCommentEncountered,
  postEncountered,
  commentEncountered,
  userEncountered,
  communityEncountered,
  pushNotificationReceived,
}

class RuleFieldOperator<T> {
  final String id;
  final String Function(BuildContext context) getName;
  final bool Function(T field, T operand) compare;

  const RuleFieldOperator({
    required this.id,
    required this.getName,
    required this.compare,
  });
}

class RuleField<T> {
  String id;
  String Function(BuildContext context) getName;
  T Function()? getter;

  /// Set of triggers field is accessible under. Defaults to all.
  List<RuleTrigger>? triggers;

  /// Set of subfields available under field. Defaults to none.
  List<RuleField>? subfields;

  /// Set of operators available under field. Defaults to none.
  List<RuleFieldOperator<T>>? operators;

  RuleField({
    required this.id,
    required this.getName,
    this.getter,
    this.triggers,
    this.subfields,
    this.operators,
  });

  RuleField? getSubfield(String? id) {
    if (id == null || subfields == null) return null;

    for (var subfield in subfields!) {
      if (subfield.id == id) return subfield;
    }

    return null;
  }

  RuleFieldOperator? getOperator(String id) {
    if (operators == null) return null;

    for (var operator in operators!) {
      if (operator.id == id) return operator;
    }

    return null;
  }
}

class RuleFieldNumber extends RuleField<double> {
  RuleFieldNumber({required super.id, required super.getName, super.getter})
    : super(
        operators: [
          RuleFieldOperator(
            id: 'equalTo',
            getName: (context) => 'Equal to',
            compare: (field, operand) => field == operand,
          ),
          RuleFieldOperator(
            id: 'lessThan',
            getName: (context) => 'Less than',
            compare: (field, operand) => field < operand,
          ),
          RuleFieldOperator(
            id: 'lessThanOrEqualTo',
            getName: (context) => 'Less than or equal to',
            compare: (field, operand) => field <= operand,
          ),
          RuleFieldOperator(
            id: 'greaterThan',
            getName: (context) => 'Greater than',
            compare: (field, operand) => field > operand,
          ),
          RuleFieldOperator(
            id: 'greaterThanOrEqualTo',
            getName: (context) => 'Greater than or equal to',
            compare: (field, operand) => field >= operand,
          ),
          RuleFieldOperator(
            id: 'divisibleBy',
            getName: (context) => 'Divisible by',
            compare: (field, operand) => field % operand == 0,
          ),
        ],
      );
}

class RuleFieldText extends RuleField<String> {
  RuleFieldText({required super.id, required super.getName, super.getter})
    : super(
        subfields: [
          RuleFieldNumber(
            id: 'charCount',
            getName: (context) => 'Character count',
            getter: () => getter!().length.toDouble(),
          ),
          RuleFieldNumber(
            id: 'wordCount',
            getName: (context) => 'Word count',
            getter: () =>
                RegExp(r'[\w-]+').allMatches(getter!()).length.toDouble(),
          ),
          RuleFieldNumber(
            id: 'lineCount',
            getName: (context) => 'Line count',
            getter: () =>
                getter!()
                    .trim()
                    .split('\n')
                    .where((line) => line.trim().isNotEmpty)
                    .length +
                1,
          ),
        ],
        operators: [
          RuleFieldOperator(
            id: 'equalTo',
            getName: (context) => 'Equal to',
            compare: (field, operand) => field == operand,
          ),
          RuleFieldOperator(
            id: 'contains',
            getName: (context) => 'Less than',
            compare: (field, operand) => field.contains(operand),
          ),
          RuleFieldOperator(
            id: 'startsWith',
            getName: (context) => 'Starts with',
            compare: (field, operand) => field.startsWith(operand),
          ),
          RuleFieldOperator(
            id: 'endsWith',
            getName: (context) => 'Ends with',
            compare: (field, operand) => field.endsWith(operand),
          ),
          RuleFieldOperator(
            id: 'matchesRegex',
            getName: (context) => 'Matches RegEx',
            compare: (field, operand) => RegExp(operand).hasMatch(field),
          ),
        ],
      );
}

@freezed
class RuleFieldRootContext with _$RuleFieldRootContext {
  const factory RuleFieldRootContext({
    required UserModel user,
    required PostModel post,
  }) = _RuleFieldRootContext;
}

class RuleFieldRoot extends RuleField<RuleFieldRootContext> {
  RuleFieldRoot({super.getter})
    : super(
        id: '',
        getName: (context) => '',
        subfields: [
          RuleFieldText(
            id: 'body',
            getName: (context) => 'Body',
            getter: () => getter!().post.body ?? '',
          ),
          RuleFieldNumber(
            id: 'upvotes',
            getName: (context) => 'Upvotes',
            getter: () => getter!().post.upvotes?.toDouble() ?? 0,
          ),
          RuleField<UserModel>(
            id: 'user',
            getName: (context) => 'User',
            getter: () => getter!().user,
            subfields: [
              RuleFieldText(
                id: 'name',
                getName: (context) => 'Name',
                getter: () => getter!().user.name,
              ),
            ],
          ),
        ],
      );
}

// enum RuleConditionField {
//   context,

//   body,
//   title,
//   lang,

//   link,

//   imageSrc,
//   imageAlt,

//   userName,
//   userAvatarSrc,
//   userCreatedAt,
//   userIsBot,

//   communityName,
//   communityIconSrc,

//   upVotes,
//   downVotes,
//   points,
//   boosts,
//   numComments,

//   createdAt,
//   editedAt,
//   lastActiveAt,

//   isNsfw,
//   isPinned,
//   isRead,
//   canMod,
// }

// enum RuleConditionNameSubField { full, local, global }

// enum RuleConditionUriSubField { full, scheme, host, path, query, fragment }

// enum RuleConditionOperator {
//   and,
//   or,

//   equals,
//   contains,
//   startsWith,
//   endsWith,
//   matchesRegex,

//   greaterThan,
//   greaterThanOrEqualTo,
//   lessThan,
//   lessThanOrEqualTo,
//   inRangeOf,
// }

@freezed
class RuleCondition with _$RuleCondition {
  const RuleCondition._();

  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory RuleCondition({
    bool? not,

    List<RuleCondition>? and,

    List<RuleCondition>? or,

    String? field,
    String? operator,
    Object? operand,
  }) = _RuleCondition;

  factory RuleCondition.fromJson(JsonMap json) => _$RuleConditionFromJson(json);

  // bool checkMatchPost(PostModel post) {}
}

@freezed
class Rule with _$Rule {
  const Rule._();

  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory Rule({
    required RuleTrigger trigger,
    required RuleCondition? condition,
    required List<dynamic> actions,
  }) = _Rule;

  factory Rule.fromJson(JsonMap json) => _$RuleFromJson(json);

  static const nullRule = Rule(
    trigger: RuleTrigger.postOrCommentEncountered,
    condition: null,
    actions: [],
  );
}

enum ContentIndicatorIcon { info, success, warning, error }

@freezed
class ContentIndicator with _$ContentIndicator {
  const factory ContentIndicator({
    ContentIndicatorIcon? icon,
    String? text,
    int? color,
    String? tooltip,
  }) = _ContentIndicator;
}

class RuleContentModifier {
  bool? hide;
  String? title;
  String? body;
  String? replyTemplate;
  String? backgroundHighlight;
  bool? collapse;
  List<ContentIndicator>? indicators;
  List<String>? alternateLinks;
  bool? treatNsfw;
}

RuleContentModifier rulePostOrCommentEncountered(
  BuildContext context,
  Object postOrComment,
) {
  final ac = context.read<AppController>();

  RuleContentModifier modifier = RuleContentModifier();
  return modifier;
  final ruleActivations = ac.profile.rules;

  for (var ruleEntry in ac.rules.entries) {
    if (ruleActivations[ruleEntry.key] == true) {
      final rule = ruleEntry.value;

      if (evaluateCondition(rule.condition)) {
        // Trigger here
      }
    }
  }
}

bool evaluateCondition(RuleCondition? condition) {
  if (condition == null) return true;

  bool output = false;

  if (condition.and != null) {
    for (var subCondition in condition.and!) {
      if (!evaluateCondition(subCondition)) {
        output = false;
        break;
      }
    }
    output = true;
  } else if (condition.or != null) {
    for (var subCondition in condition.and!) {
      if (evaluateCondition(subCondition)) {
        output = true;
        break;
      }
    }
    output = false;
  } else if (condition.field != null) {
    final fieldSegments = condition.field!.split('.');
  }

  return condition.not == true ? !output : output;
}
