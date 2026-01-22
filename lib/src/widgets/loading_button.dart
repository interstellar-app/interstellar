import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:provider/provider.dart';

class _LoadingButtonIndicator extends StatelessWidget {
  const _LoadingButtonIndicator();

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

class LoadingFilledButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final Widget label;
  final Widget? icon;
  final ButtonStyle? style;

  /// When true, vibrates `success` type on success, and `warning` type on error
  final bool uesHaptics;

  const LoadingFilledButton({
    required this.onPressed,
    required this.label,
    this.icon,
    this.style,
    this.uesHaptics = false,
    super.key,
  });

  @override
  State<LoadingFilledButton> createState() => _LoadingFilledButtonState();
}

class _LoadingFilledButtonState extends State<LoadingFilledButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    return FilledButton.icon(
      onPressed: _isLoading || widget.onPressed == null
          ? null
          : () async {
              setState(() => _isLoading = true);
              try {
                await widget.onPressed!();
                if (widget.uesHaptics) ac.vibrate(HapticsType.selection);
              } catch (e) {
                if (widget.uesHaptics) ac.vibrate(HapticsType.heavy);
                rethrow;
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
      label: widget.label,
      icon: _isLoading ? const _LoadingButtonIndicator() : widget.icon,
      style: widget.style,
    );
  }
}

class LoadingTonalButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final Widget label;
  final Widget? icon;
  final ButtonStyle? style;

  const LoadingTonalButton({
    required this.onPressed,
    required this.label,
    this.icon,
    this.style,
    super.key,
  });

  @override
  State<LoadingTonalButton> createState() => _LoadingTonalButtonState();
}

class _LoadingTonalButtonState extends State<LoadingTonalButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: _isLoading || widget.onPressed == null
          ? null
          : () async {
              setState(() => _isLoading = true);
              try {
                await widget.onPressed!();
              } catch (e) {
                rethrow;
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
      label: widget.label,
      icon: _isLoading ? const _LoadingButtonIndicator() : widget.icon,
      style: widget.style,
    );
  }
}

class LoadingOutlinedButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final Widget label;
  final Widget? icon;
  final ButtonStyle? style;

  const LoadingOutlinedButton({
    required this.onPressed,
    required this.label,
    this.icon,
    this.style,
    super.key,
  });

  @override
  State<LoadingOutlinedButton> createState() => _LoadingOutlinedButtonState();
}

class _LoadingOutlinedButtonState extends State<LoadingOutlinedButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _isLoading || widget.onPressed == null
          ? null
          : () async {
              setState(() => _isLoading = true);
              try {
                await widget.onPressed!();
              } catch (e) {
                rethrow;
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
      label: widget.label,
      icon: _isLoading ? const _LoadingButtonIndicator() : widget.icon,
      style: widget.style,
    );
  }
}

class LoadingTextButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final Widget label;
  final Widget? icon;
  final ButtonStyle? style;

  const LoadingTextButton({
    required this.onPressed,
    required this.label,
    this.icon,
    this.style,
    super.key,
  });

  @override
  State<LoadingTextButton> createState() => _LoadingTextButtonState();
}

class _LoadingTextButtonState extends State<LoadingTextButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _isLoading || widget.onPressed == null
          ? null
          : () async {
              setState(() => _isLoading = true);
              try {
                await widget.onPressed!();
              } catch (e) {
                rethrow;
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
      label: widget.label,
      icon: _isLoading ? const _LoadingButtonIndicator() : widget.icon,
      style: widget.style,
    );
  }
}

class LoadingIconButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final Future<void> Function()? onLongPress;
  final Widget icon;
  final ButtonStyle? style;
  final String? tooltip;

  const LoadingIconButton({
    required this.onPressed,
    this.onLongPress,
    required this.icon,
    this.style,
    this.tooltip,
    super.key,
  });

  @override
  State<LoadingIconButton> createState() => _LoadingIconButtonState();
}

class _LoadingIconButtonState extends State<LoadingIconButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _isLoading || widget.onPressed == null
          ? null
          : () async {
              setState(() => _isLoading = true);
              try {
                await widget.onPressed!();
              } catch (e) {
                rethrow;
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
      onLongPress: _isLoading || widget.onLongPress == null
          ? null
          : () async {
              setState(() => _isLoading = true);
              try {
                await widget.onLongPress!();
              } catch (e) {
                rethrow;
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
      icon: _isLoading ? const _LoadingButtonIndicator() : widget.icon,
      style: widget.style,
      tooltip: widget.tooltip,
    );
  }
}

class LoadingChip extends StatefulWidget {
  final Widget? icon;
  final Widget label;
  final bool selected;
  final Future<void> Function(bool)? onSelected;
  final bool enabled;

  final String? tooltip;

  const LoadingChip({
    required this.label,
    required this.selected,
    this.onSelected,
    this.icon,
    this.tooltip,
    this.enabled = true,
    super.key,
  });

  @override
  State<LoadingChip> createState() => _LoadingChipState();
}

class _LoadingChipState extends State<LoadingChip> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: widget.selected,
      showCheckmark: false,
      avatar: _isLoading ? const _LoadingButtonIndicator() : widget.icon,
      label: widget.label,
      onSelected: _isLoading || widget.onSelected == null
          ? null
          : (selected) async {
              setState(() => _isLoading = true);
              try {
                await widget.onSelected!(selected);
              } catch (e) {
                rethrow;
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
      tooltip: widget.tooltip,
    );
  }
}
