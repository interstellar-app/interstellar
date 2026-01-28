import 'package:interstellar/emojis/emojis.g.dart';
import 'package:interstellar/src/utils/trie.dart';

class Emoji {
  final String unicode;
  final String label;
  final int group;

  const Emoji(this.unicode, this.label, this.group);
}

List<List<Emoji>> searchEmojis(String term) {
  final matches = term.isEmpty
      ? emojiList
      : (emojiTrie.search(Trie.normalizeTerm(term)).toList()..sort())
            .map((index) => emojiList[index])
            .toList();

  final List<List<Emoji>> results = List.generate(
    emojiGroups.length,
    (i) => [],
  );

  for (var match in matches) {
    results[match.group].add(match);
  }

  return results;
}
