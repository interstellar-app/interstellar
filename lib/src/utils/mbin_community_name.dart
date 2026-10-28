/// Helpers for validating and repairing Mbin magazine (community) names.
///
/// Mbin restricts magazine names to 2-25 characters consisting only of
/// letters, digits and underscores (`RegPatterns::MAGAZINE_NAME` /
/// `/^[a-zA-Z0-9_]{2,25}$/` upstream). Lemmy and PieFed use different rules,
/// so callers should only apply these checks when talking to an Mbin server.
library;

const int mbinCommunityNameMinLength = 2;
const int mbinCommunityNameMaxLength = 25;

final RegExp _mbinCommunityNameRegExp = RegExp(r'^[a-zA-Z0-9_]{2,25}$');
final RegExp _mbinCommunityNameInvalidChars = RegExp(r'[^a-zA-Z0-9_]');

/// Whether [name] is a valid Mbin magazine name that can be submitted as-is.
bool isValidMbinCommunityName(String name) =>
    _mbinCommunityNameRegExp.hasMatch(name);

/// The reason [name] is not a valid Mbin magazine name, or `null` when it is
/// valid (or still empty, which is treated as "not entered yet").
MbinCommunityNameIssue? mbinCommunityNameIssue(String name) {
  if (name.isEmpty) return null;
  if (_mbinCommunityNameInvalidChars.hasMatch(name)) {
    return MbinCommunityNameIssue.invalidCharacters;
  }
  if (name.length < mbinCommunityNameMinLength) {
    return MbinCommunityNameIssue.tooShort;
  }
  if (name.length > mbinCommunityNameMaxLength) {
    return MbinCommunityNameIssue.tooLong;
  }
  return null;
}

enum MbinCommunityNameIssue { invalidCharacters, tooShort, tooLong }

/// A best-effort valid name derived from [name], or `null` when nothing
/// usable can be salvaged (e.g. the input has no letters/digits at all) or
/// when [name] is already valid.
String? suggestMbinCommunityName(String name) {
  if (isValidMbinCommunityName(name)) return null;

  // Replace every run of unsupported characters (whitespace, punctuation,
  // accented letters, ...) with a single underscore, then tidy up the
  // underscores so the result reads naturally.
  var suggestion = name
      .replaceAll(_mbinCommunityNameInvalidChars, '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  if (suggestion.length > mbinCommunityNameMaxLength) {
    suggestion = suggestion
        .substring(0, mbinCommunityNameMaxLength)
        .replaceAll(RegExp(r'_+$'), '');
  }

  if (suggestion.length < mbinCommunityNameMinLength) return null;
  if (suggestion == name) return null;

  return suggestion;
}
