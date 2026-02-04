import 'dart:convert';

import 'package:build/build.dart';
import 'package:http/http.dart' as http;
import 'package:interstellar/src/utils/trie.dart';

Builder emojiBuilder(BuilderOptions options) =>
    EmojiBuilder(options.config['sourcePrefix']);

class EmojiBuilder implements Builder {
  EmojiBuilder(this._sourcePrefix);

  final String _sourcePrefix;

  @override
  Future<void> build(BuildStep buildStep) async {
    await buildStep.writeAsString(
      AssetId(
        buildStep.inputId.package,
        'lib/src/widgets/emoji_picker/emojis.g.dart',
      ),
      await _generateContent(),
    );
  }

  @override
  final buildExtensions = const {
    r'$package$': ['lib/src/widgets/emoji_picker/emojis.g.dart'],
  };

  Future<String> _generateContent() async {
    final dataResponse = await http.get(
      Uri.parse('$_sourcePrefix/compact.raw.json'),
    );
    final dataJson = jsonDecode(dataResponse.body);

    final messagesResponse = await http.get(
      Uri.parse('$_sourcePrefix/messages.raw.json'),
    );
    final messagesJson = jsonDecode(messagesResponse.body);

    final s = StringBuffer()
      ..write('''
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: prefer_single_quotes

import 'package:interstellar/src/utils/trie.dart';

import "./emoji_class.dart";

''');

    final emojiGroups = <String>[];

    for (var i = 0; i < (messagesJson['groups'] as List).length; i++) {
      final group = messagesJson['groups'][i];

      assert(group['order'] == i, 'Emoji group order value should match index');

      emojiGroups.add(group['message']);
    }

    s
      ..write('final emojiGroups = ')
      ..write(jsonEncode(emojiGroups))
      ..write(';\n');

    final trie = Trie<int>();

    s.write('final emojiList = [\n');

    {
      var i = 0;
      for (final emoji in dataJson) {
        if (emoji['group'] == null || emoji['order'] == null) continue;

        assert(emoji['order'] == i + 1, 'Emoji order value should match index');

        final tags = [
          ...?emoji['tags'],
          ...?(emoji['emoticon'] is String
              ? [emoji['emoticon']]
              : emoji['emoticon']),
        ];

        trie.addChild(Trie.normalizeTerm(emoji['label']), {i});
        for (final tag in tags) {
          trie.addChild(Trie.normalizeTerm(tag), {i});
        }

        s
          ..write('const Emoji("')
          ..write(emoji['unicode'])
          ..write('","')
          ..write(emoji['label'])
          ..write('",')
          ..write(emoji['group'])
          ..write('),\n');

        i++;
      }
    }

    s
      ..write('];\n\n')
      ..write('final Trie<int> emojiTrie = ')
      ..write(trie.toString())
      ..write(';\n');

    return s.toString();
  }
}
