import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class SubscriptionButton extends StatelessWidget {
  final bool? isSubscribed;
  final int? subscriptionCount;
  final Future<void> Function(bool) onSubscribe;
  final bool followMode;

  const SubscriptionButton({
    required this.isSubscribed,
    required this.subscriptionCount,
    required this.onSubscribe,
    required this.followMode,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingFilterChip(
      selected: isSubscribed ?? false,
      icon: const Icon(Symbols.people_rounded),
      label: Text(
        subscriptionCount != null
            ? intFormat(subscriptionCount!)
            : l(context).subscribe,
      ),
      onSelected: whenLoggedIn(
        context,
        context.watch<AppController>().profile.askBeforeUnsubscribing
            ? (newValue) async {
                // Only show confirm dialog for unsubscribes, not subscribes
                final confirm = newValue
                    ? true
                    : await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            followMode
                                ? l(context).confirmUnfollow
                                : l(context).confirmUnsubscribe,
                          ),
                          actions: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(l(context).cancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(l(context).continue_),
                            ),
                          ],
                        ),
                      );

                if (confirm == true) await onSubscribe(newValue);
              }
            : onSubscribe,
      ),
    );
  }
}
