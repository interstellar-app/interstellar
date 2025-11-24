import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/database.dart';

class TagWidget extends StatelessWidget {
  const TagWidget({
    super.key,
    required this.tag,
    this.size,
  });

  final Tag tag;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 5),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: tag.backgroundColor,
      ),
      child: Text(
        textAlign: TextAlign.center,
        tag.tag,
        style: TextStyle(color: tag.textColor, fontSize: size),
      ),
    );
  }
}
