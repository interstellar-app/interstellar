import 'package:flutter_test/flutter_test.dart';
import 'package:interstellar/src/utils/mbin_community_name.dart';

void main() {
  group('isValidMbinCommunityName', () {
    test('accepts letters, digits and underscores within 2-25 chars', () {
      expect(isValidMbinCommunityName('ab'), isTrue);
      expect(isValidMbinCommunityName('under_score'), isTrue);
      expect(isValidMbinCommunityName('Mixed_Case_123'), isTrue);
      expect(isValidMbinCommunityName('a' * 25), isTrue);
    });

    test('rejects empty, too short and too long names', () {
      expect(isValidMbinCommunityName(''), isFalse);
      expect(isValidMbinCommunityName('a'), isFalse);
      expect(isValidMbinCommunityName('a' * 26), isFalse);
    });

    test('rejects unsupported characters', () {
      expect(isValidMbinCommunityName('with space'), isFalse);
      expect(isValidMbinCommunityName('with-hyphen'), isFalse);
      expect(isValidMbinCommunityName('dot.separated'), isFalse);
      expect(isValidMbinCommunityName('accenté'), isFalse);
    });
  });

  group('mbinCommunityNameIssue', () {
    const invalid = MbinCommunityNameIssue.invalidCharacters;
    const tooShort = MbinCommunityNameIssue.tooShort;
    const tooLong = MbinCommunityNameIssue.tooLong;

    test('returns null for an empty (not yet entered) name', () {
      expect(mbinCommunityNameIssue(''), isNull);
    });

    test('returns null for a valid name', () {
      expect(mbinCommunityNameIssue('valid_Name_123'), isNull);
    });

    test('reports invalid characters ahead of length problems', () {
      expect(mbinCommunityNameIssue('hello world'), invalid);
      expect(mbinCommunityNameIssue('!'), invalid);
    });

    test('reports names that are too short', () {
      expect(mbinCommunityNameIssue('a'), tooShort);
    });

    test('reports names longer than 25 characters', () {
      expect(mbinCommunityNameIssue('a' * 26), tooLong);
    });
  });

  group('suggestMbinCommunityName', () {
    test('returns null when the name is already valid', () {
      expect(suggestMbinCommunityName('already_valid'), isNull);
    });

    test('replaces unsupported runs with a single underscore', () {
      final result = suggestMbinCommunityName('My Cool Community!');
      expect(result, 'My_Cool_Community');
      expect(suggestMbinCommunityName('a...b---c'), 'a_b_c');
    });

    test('trims leading and trailing underscores', () {
      expect(suggestMbinCommunityName('  hello!!  '), 'hello');
    });

    test('truncates to 25 characters without a trailing underscore', () {
      final s = suggestMbinCommunityName('abcdefghijklmnopqrstuvwx yz');
      expect(s, 'abcdefghijklmnopqrstuvwx');
      expect(isValidMbinCommunityName(s!), isTrue);
    });

    test('returns null when nothing usable can be salvaged', () {
      expect(suggestMbinCommunityName('a'), isNull);
      expect(suggestMbinCommunityName('   '), isNull);
      expect(suggestMbinCommunityName('日本語'), isNull);
    });

    test('always produces a valid name when it returns one', () {
      const inputs = [
        'hello world',
        'Trailing punctuation???',
        '***leading',
        'lots     of     spaces',
        'cafe-society #2',
      ];
      for (final input in inputs) {
        final suggestion = suggestMbinCommunityName(input);
        if (suggestion == null) continue;
        expect(isValidMbinCommunityName(suggestion), isTrue, reason: input);
      }
    });
  });
}
