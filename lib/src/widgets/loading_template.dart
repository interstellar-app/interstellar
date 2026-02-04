import 'package:flutter/material.dart';

class LoadingTemplate extends StatelessWidget {
  const LoadingTemplate({this.title, super.key});

  final Widget? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: title),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
