import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/server.dart';

class ServerSoftwareIndicator extends StatelessWidget {
  final String label;
  final ServerSoftware software;

  const ServerSoftwareIndicator({
    required this.label,
    required this.software,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Badge(
      label: Text(software.title),
      backgroundColor: software.color,
      textColor: Colors.white,
      alignment: Alignment.centerRight,
      offset: const Offset(20, -6),
      child: Text(label),
    );
  }
}
