import 'package:interstellar/src/utils/trie.dart';

import 'package:interstellar/src/widgets/emoji_picker/emojis.g.dart';

class Emoji {
  const Emoji(this.unicode, this.label, this.group);

  final String unicode;
  final String label;
  final int group;
}

List<List<Emoji>> searchEmojis(String term) {
  final matches = term.isEmpty
      ? emojiList
      : (emojiTrie.search(Trie.normalizeTerm(term)).toList()..sort())
            .map((index) => emojiList[index])
            .toList();

  final results = List<List<Emoji>>.generate(emojiGroups.length, (i) => []);

  for (final match in matches) {
    results[match.group].add(match);
  }

  return results;
}
