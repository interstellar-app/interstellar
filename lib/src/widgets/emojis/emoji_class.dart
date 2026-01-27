class Emoji {
  final String unicode;
  final String label;
  final int? group;
  final int? order;
  final List<String>? tags;
  final List<String>? emoticon;

  const Emoji(
    this.unicode,
    this.label, [
    this.group,
    this.order,
    this.tags,
    this.emoticon,
  ]);
}
