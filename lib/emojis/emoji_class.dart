import 'package:interstellar/emojis/emojis.g.dart';
import 'package:interstellar/src/utils/trie.dart';

class Emoji {
  final String unicode;
  final String label;
  final List<String> tags;
  final int? group;
  final int? order;

  const Emoji(this.unicode, this.label, this.tags, [this.group, this.order]);

  @override
  String toString() => '$unicode - $label $tags\n';
}

List<Emoji> searchEmojis(String term) => emojiTrie
    .search(Trie.normalizeTerm(term))
    .map((index) => emojiList[index])
    .toList();
