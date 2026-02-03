import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/domain.dart';
import 'package:interstellar/src/screens/feed/feed_agregator.dart';
import 'package:interstellar/src/screens/feed/feed_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/subscription_button.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

@RoutePage()
class DomainScreen extends StatefulWidget {
  final int domainId;
  final DomainModel? initData;
  final void Function(DomainModel)? onUpdate;

  const DomainScreen(this.domainId, {super.key, this.initData, this.onUpdate});

  @override
  State<DomainScreen> createState() => _DomainScreenState();
}

class _DomainScreenState extends State<DomainScreen> {
  DomainModel? _data;

  @override
  void initState() {
    super.initState();

    _data = widget.initData;

    if (_data == null) {
      context.read<AppController>().api.domains.get(widget.domainId).then((
        value,
      ) {
        if (!mounted) return;
        setState(() {
          _data = value;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeedScreen(
      feed: FeedAggregator.fromSingleSource(
        context.read<AppController>(),
        name: _data?.name ?? '',
        source: FeedSource.domain,
        sourceId: widget.domainId,
      ),
      details: _data != null
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _data!.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          softWrap: true,
                        ),
                      ),
                      SubscriptionButton(
                        isSubscribed: _data!.isUserSubscribed,
                        subscriptionCount: _data!.subscriptionsCount,
                        onSubscribe: (selected) async {
                          final newValue = await context
                              .read<AppController>()
                              .api
                              .domains
                              .putSubscribe(_data!.id, selected);

                          setState(() {
                            _data = newValue;
                          });
                          if (widget.onUpdate != null) {
                            widget.onUpdate!(newValue);
                          }
                        },
                        followMode: false,
                      ),
                      if (whenLoggedIn(context, true) ?? false)
                        LoadingIconButton(
                          onPressed: () async {
                            final newValue = await context
                                .read<AppController>()
                                .api
                                .domains
                                .putBlock(_data!.id, !_data!.isBlockedByUser!);

                            setState(() {
                              _data = newValue;
                            });
                            if (widget.onUpdate != null) {
                              widget.onUpdate!(newValue);
                            }
                          },
                          icon: const Icon(Symbols.block_rounded),
                          style: ButtonStyle(
                            foregroundColor: WidgetStatePropertyAll(
                              _data!.isBlockedByUser ?? false
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).disabledColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
