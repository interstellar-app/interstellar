import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/utils/utils.dart';

part 'filter_list.freezed.dart';
part 'filter_list.g.dart';

enum FilterListMatchMode { simple, wholeWords, regex }

@freezed
abstract class FilterList with _$FilterList {
  const FilterList._();

  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory FilterList({
    required Set<String> phrases,
    required FilterListMatchMode matchMode,
    required bool caseSensitive,
    required bool showWithWarning,
  }) = _FilterList;

  factory FilterList.fromJson(JsonMap json) => _$FilterListFromJson(json);

  static const nullFilterList = FilterList(
    phrases: {},
    matchMode: FilterListMatchMode.simple,
    caseSensitive: false,
    showWithWarning: false,
  );

  bool hasMatch(String input) {
    switch (matchMode) {
      case FilterListMatchMode.simple:
        if (!caseSensitive) input = input.toLowerCase();

        for (var phrase in phrases) {
          if (!caseSensitive) phrase = phrase.toLowerCase();

          if (input.contains(phrase)) return true;
        }

        return false;
      case FilterListMatchMode.wholeWords:
        for (var phrase in phrases) {
          if (RegExp(
            '\\b${RegExp.escape(phrase)}\\b',
            caseSensitive: caseSensitive,
          ).hasMatch(input)) {
            return true;
          }
        }

        return false;
      case FilterListMatchMode.regex:
        for (var phrase in phrases) {
          if (RegExp(phrase, caseSensitive: caseSensitive).hasMatch(input)) {
            return true;
          }
        }

        return false;
    }
  }
}
