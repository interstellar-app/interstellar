class Trie<T> {
  Set<T> ends;
  Map<int, Trie<T>> children;

  Trie([Set<T>? ends, Map<int, Trie<T>>? children])
    : ends = ends ?? <T>{},
      children = children ?? <int, Trie<T>>{};

  void addChild(String term, Set<T> newEnds) {
    if (term.isEmpty) {
      ends.addAll(newEnds);
      return;
    }

    final char = term.codeUnitAt(0);
    children[char] ??= Trie<T>();
    children[char]!.addChild(term.substring(1), newEnds);
  }

  Set<T> search(String term) {
    final results = <T>{};

    if (term.isEmpty) {
      results.addAll(ends);

      for (final child in children.values) {
        results.addAll(child.search(term));
      }
    } else {
      final char = term.codeUnitAt(0);

      final subResults = children[char]?.search(term.substring(1));

      if (subResults != null) results.addAll(subResults);
    }

    return results;
  }

  @override
  String toString() => 'Trie($ends,$children)';

  static String normalizeTerm(String term) {
    term = term.toLowerCase();

    // Replace anything that's alphanumeric with a single space
    final replacedTerm = term.replaceAll('[^0-9a-z]+', ' ');
    // If term only contains symbols, than don't use replaced term.
    if (replacedTerm.isNotEmpty) term = replacedTerm;

    term = term.trim();

    return term;
  }
}
