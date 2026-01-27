import 'dart:convert';

import 'package:build/build.dart';
import 'package:http/http.dart' as http;
import 'package:interstellar/src/utils/trie.dart';

Builder emojiBuilder(BuilderOptions options) =>
    EmojiBuilder(options.config['sourcePrefix']);

class EmojiBuilder implements Builder {
  String _sourcePrefix;

  EmojiBuilder(this._sourcePrefix);

  @override
  Future build(BuildStep buildStep) async {
    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, 'lib/emojis/emojis.g.dart'),
      await _generateContent(),
    );
  }

  @override
  final buildExtensions = const {
    r'$package$': ['lib/emojis/emojis.g.dart'],
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

    final s = StringBuffer();

    s.write('''
// ignore_for_file: prefer_single_quotes

import 'package:interstellar/src/utils/trie.dart';

import "./emoji_class.dart";

''');

    s.write('final emojiGroups = [\n');

    for (var i = 0; i < (messagesJson['groups'] as List).length; i++) {
      final group = messagesJson['groups'][i];

      assert(group['order'] == i);

      s.write('"${group['message']}",\n');
    }

    s.write('];\n\n');

    final trie = Trie<int>();

    s.write('final emojiList = [\n');

    for (var i = 0; i < (dataJson as List).length; i++) {
      final emoji = dataJson[i];

      final tags = [
        ...?emoji['tags'],
        ...?(emoji['emoticon'] is String
            ? [emoji['emoticon']]
            : emoji['emoticon']),
      ];

      trie.addChild(Trie.normalizeTerm(emoji['label']), {i});
      for (var tag in tags) {
        trie.addChild(Trie.normalizeTerm(tag), {i});
      }

      s.write('Emoji("');
      s.write(emoji['unicode']);
      s.write('","');
      s.write(emoji['label']);
      s.write('",');
      s.write(jsonEncode(tags).replaceAll(r'$', r'\$'));
      if (emoji['group'] != null || emoji['order'] != null) {
        s.write(',');
        s.write(emoji['group']);
        s.write(',');
        s.write(emoji['order']);
      }
      s.write('),\n');
    }

    s.write('];\n\n');

    s.write('final Trie<int> emojiTrie = ');
    s.write(trie.toString());
    s.write(';\n');

    return s.toString();
  }
}
