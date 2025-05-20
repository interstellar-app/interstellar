import 'package:flutter/material.dart';

class _LoadingTileIndicator extends StatelessWidget {
  const _LoadingTileIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      padding: const EdgeInsets.all(2.0),
      child: const CircularProgressIndicator(
        color: Colors.white,
        strokeWidth: 3,
      ),
    );
  }
}

class LoadingListTile extends StatefulWidget {
  final Future<void> Function()? onTap;
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;

  const LoadingListTile({
    required this.onTap,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  @override
  State<LoadingListTile> createState() => _LoadingListTileState();
}

class _LoadingListTileState extends State<LoadingListTile> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.onTap == null ? Theme.of(context).disabledColor : null;

    return ListTile(
      leading: widget.leading,
      title: widget.title,
      subtitle: widget.subtitle,
      onTap: widget.onTap == null
          ? null
          : () async {
              setState(() => _isLoading = true);
              try {
                await widget.onTap!();
              } catch (e) {
                rethrow;
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
      trailing: _isLoading ? _LoadingTileIndicator() : widget.trailing,
      textColor: color,
      iconColor: color,
    );
  }
}
